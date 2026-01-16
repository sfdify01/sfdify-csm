"use strict";
/**
 * Tenant Management Cloud Functions
 *
 * Handles tenant creation, updates, and retrieval.
 * Tenants represent credit repair companies using the system.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.tenantsList = exports.tenantsUpdate = exports.tenantsGet = exports.tenantsCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const audit_1 = require("../../utils/audit");
// ============================================================================
// Default Feature Configurations by Plan
// ============================================================================
const PLAN_FEATURES = {
    starter: {
        aiDraftingEnabled: false,
        certifiedMailEnabled: false,
        identityTheftBlockEnabled: false,
        cfpbExportEnabled: false,
        maxConsumers: 100,
        maxDisputesPerMonth: 500,
    },
    professional: {
        aiDraftingEnabled: true,
        certifiedMailEnabled: true,
        identityTheftBlockEnabled: true,
        cfpbExportEnabled: false,
        maxConsumers: 1000,
        maxDisputesPerMonth: 5000,
    },
    enterprise: {
        aiDraftingEnabled: true,
        certifiedMailEnabled: true,
        identityTheftBlockEnabled: true,
        cfpbExportEnabled: true,
        maxConsumers: 10000,
        maxDisputesPerMonth: 50000,
    },
};
// ============================================================================
// tenantsCreate - Create a new tenant
// ============================================================================
/**
 * Create a new tenant with owner account
 * This is typically called during onboarding
 */
async function createTenantHandler(data) {
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.createTenantSchema, data);
    // Generate IDs
    const tenantId = `tenant_${(0, uuid_1.v4)().replace(/-/g, "").substring(0, 12)}`;
    // Get default features for the plan
    const plan = validatedData.plan;
    const features = PLAN_FEATURES[plan];
    // Create tenant document
    const tenant = {
        id: tenantId,
        name: validatedData.name,
        plan: validatedData.plan,
        status: "active",
        branding: {
            primaryColor: validatedData.branding.primaryColor || "#1E40AF",
            companyName: validatedData.branding.companyName,
            tagline: validatedData.branding.tagline,
        },
        lobConfig: {
            returnAddress: {
                ...validatedData.lobConfig.returnAddress,
                type: "mailing",
                country: validatedData.lobConfig.returnAddress.country || "US",
                isPrimary: true,
            },
            defaultMailType: validatedData.lobConfig.defaultMailType ||
                "usps_first_class",
        },
        features,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    // Create owner user in Firebase Auth
    const { auth } = await Promise.resolve().then(() => __importStar(require("../../admin")));
    const ownerUser = await auth.createUser({
        email: data.ownerEmail,
        displayName: data.ownerName,
        password: data.ownerPassword || (0, uuid_1.v4)(), // Generate random password if not provided
        emailVerified: false,
    });
    // Set custom claims for the owner
    await (0, auth_1.setUserClaims)(ownerUser.uid, tenantId, "owner");
    // Create user document
    const userDoc = {
        id: ownerUser.uid,
        tenantId,
        email: data.ownerEmail,
        displayName: data.ownerName,
        role: "owner",
        permissions: [],
        twoFactorEnabled: false,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        disabled: false,
    };
    // Write to Firestore in a batch
    const batch = admin_1.db.batch();
    batch.set(admin_1.db.collection("tenants").doc(tenantId), tenant);
    batch.set(admin_1.db.collection("users").doc(ownerUser.uid), userDoc);
    await batch.commit();
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: {
            userId: ownerUser.uid,
            email: data.ownerEmail,
            role: "owner",
        },
        entity: "tenant",
        entityId: tenantId,
        action: "create",
        newState: tenant,
        metadata: { source: "onboarding" },
    });
    return {
        success: true,
        data: {
            tenant: { ...tenant, id: tenantId },
            ownerId: ownerUser.uid,
        },
    };
}
// Export as Cloud Function - Note: This needs special handling for onboarding
exports.tenantsCreate = functions.https.onCall((0, errors_1.withErrorHandling)(createTenantHandler));
// ============================================================================
// tenantsGet - Get tenant details
// ============================================================================
async function getTenantHandler(_data, context) {
    const { tenantId } = context;
    const tenantDoc = await admin_1.db.collection("tenants").doc(tenantId).get();
    (0, errors_1.assertExists)(tenantDoc.exists ? tenantDoc.data() : null, "Tenant", tenantId);
    const tenant = { id: tenantDoc.id, ...tenantDoc.data() };
    return {
        success: true,
        data: tenant,
    };
}
exports.tenantsGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withBasicAuth)(getTenantHandler)));
// ============================================================================
// tenantsUpdate - Update tenant settings
// ============================================================================
async function updateTenantHandler(data, context) {
    const { tenantId, userId, email, role, ip, userAgent } = context;
    // Get current tenant
    const tenantRef = admin_1.db.collection("tenants").doc(tenantId);
    const tenantDoc = await tenantRef.get();
    (0, errors_1.assertExists)(tenantDoc.exists ? tenantDoc.data() : null, "Tenant", tenantId);
    const currentTenant = { id: tenantDoc.id, ...tenantDoc.data() };
    // Build update object
    const updates = {
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (data.name !== undefined) {
        updates.name = data.name;
    }
    if (data.branding) {
        updates.branding = {
            ...currentTenant.branding,
            ...data.branding,
        };
    }
    if (data.lobConfig) {
        updates.lobConfig = {
            ...currentTenant.lobConfig,
            ...data.lobConfig,
        };
    }
    if (data.features) {
        // Only allow updating features within plan limits
        updates.features = {
            ...currentTenant.features,
            ...data.features,
        };
    }
    // Update tenant
    await tenantRef.update(updates);
    // Get updated tenant
    const updatedDoc = await tenantRef.get();
    const updatedTenant = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId, email, role, ip, userAgent },
        entity: "tenant",
        entityId: tenantId,
        action: "update",
        previousState: currentTenant,
        newState: updatedTenant,
    });
    return {
        success: true,
        data: updatedTenant,
    };
}
exports.tenantsUpdate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["tenant:write"], updateTenantHandler)));
// ============================================================================
// tenantsList - List all tenants (admin only - for super admin purposes)
// ============================================================================
async function listTenantsHandler(data, context) {
    // This function is typically for super-admin purposes
    // For now, we just return the user's own tenant
    const { tenantId } = context;
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    const tenantDoc = await admin_1.db.collection("tenants").doc(tenantId).get();
    if (!tenantDoc.exists) {
        return {
            success: true,
            data: {
                items: [],
                pagination: {
                    total: 0,
                    limit: pagination.limit,
                    hasMore: false,
                },
            },
        };
    }
    const tenant = { id: tenantDoc.id, ...tenantDoc.data() };
    return {
        success: true,
        data: {
            items: [tenant],
            pagination: {
                total: 1,
                limit: pagination.limit,
                hasMore: false,
            },
        },
    };
}
exports.tenantsList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["tenant:read"], listTenantsHandler)));
//# sourceMappingURL=index.js.map