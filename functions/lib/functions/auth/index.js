"use strict";
/**
 * Public Authentication Cloud Functions
 *
 * These functions are PUBLIC (no auth required) and handle:
 * - Self-service signup with email/password
 * - Google Sign-In completion (tenant setup for new Google users)
 *
 * Unlike other functions, these don't use withAuth middleware
 * since they're called by unauthenticated users.
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
exports.authCheckStatus = exports.authCompleteGoogleSignUp = exports.authSignUp = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
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
// Validation Helpers
// ============================================================================
function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Invalid email address", 400);
    }
}
function validatePassword(password) {
    if (!password || password.length < 8) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Password must be at least 8 characters", 400);
    }
    // Check for at least one uppercase, one lowercase, one number
    if (!/[A-Z]/.test(password)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Password must contain at least one uppercase letter", 400);
    }
    if (!/[a-z]/.test(password)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Password must contain at least one lowercase letter", 400);
    }
    if (!/[0-9]/.test(password)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Password must contain at least one number", 400);
    }
}
function validateDisplayName(name) {
    if (!name || name.trim().length < 2) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Display name must be at least 2 characters", 400);
    }
}
function validateCompanyName(name) {
    if (!name || name.trim().length < 2) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Company name must be at least 2 characters", 400);
    }
}
// ============================================================================
// Helper: Create Tenant and User
// ============================================================================
async function createTenantAndUser(userId, email, displayName, companyName, plan) {
    // Generate tenant ID
    const tenantId = `tenant_${(0, uuid_1.v4)().replace(/-/g, "").substring(0, 12)}`;
    // Get default features for the plan
    const features = PLAN_FEATURES[plan];
    // Create tenant document
    const tenant = {
        id: tenantId,
        name: companyName,
        plan,
        status: "active",
        branding: {
            primaryColor: "#1E40AF",
            companyName: companyName,
        },
        lobConfig: {
            returnAddress: {
                type: "mailing",
                street1: "",
                city: "",
                state: "",
                zipCode: "",
                country: "US",
                isPrimary: true,
            },
            defaultMailType: "usps_first_class",
        },
        features,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    // Create user document
    const userDoc = {
        id: userId,
        tenantId,
        email,
        displayName,
        role: "owner",
        permissions: auth_1.ROLE_PERMISSIONS.owner,
        twoFactorEnabled: false,
        disabled: false,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    // Set custom claims BEFORE writing to Firestore
    // This ensures the token is ready when user signs in
    await (0, auth_1.setUserClaims)(userId, tenantId, "owner");
    // Write to Firestore in a batch
    const batch = admin_1.db.batch();
    batch.set(admin_1.db.collection("tenants").doc(tenantId), tenant);
    batch.set(admin_1.db.collection("users").doc(userId), userDoc);
    await batch.commit();
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: {
            userId,
            email,
            role: "owner",
        },
        entity: "tenant",
        entityId: tenantId,
        action: "create",
        newState: { ...tenant, id: tenantId },
        metadata: { source: "self_service_signup" },
    });
    return { tenantId };
}
// ============================================================================
// authSignUp - Email/Password Registration
// ============================================================================
/**
 * Self-service signup with email and password.
 * Creates a new Firebase Auth user, tenant, and user document.
 *
 * This is a PUBLIC function - no authentication required.
 */
async function signUpHandler(data) {
    // Validate input
    validateEmail(data.email);
    validatePassword(data.password);
    validateDisplayName(data.displayName);
    validateCompanyName(data.companyName);
    const plan = data.plan || "starter";
    if (!["starter", "professional", "enterprise"].includes(plan)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Invalid plan selected", 400);
    }
    // Check if email already exists
    try {
        const existingUser = await admin_1.auth.getUserByEmail(data.email);
        if (existingUser) {
            throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "An account with this email already exists", 400);
        }
    }
    catch (error) {
        // User not found is expected - continue with creation
        if (error instanceof Error &&
            "code" in error &&
            error.code !== "auth/user-not-found") {
            throw error;
        }
    }
    // Create Firebase Auth user
    const userRecord = await admin_1.auth.createUser({
        email: data.email,
        password: data.password,
        displayName: data.displayName,
        emailVerified: false,
    });
    try {
        // Create tenant and user document
        const { tenantId } = await createTenantAndUser(userRecord.uid, data.email, data.displayName, data.companyName, plan);
        return {
            success: true,
            data: {
                userId: userRecord.uid,
                tenantId,
                email: data.email,
                displayName: data.displayName,
                role: "owner",
            },
        };
    }
    catch (error) {
        // If tenant/user creation fails, clean up the Auth user
        try {
            await admin_1.auth.deleteUser(userRecord.uid);
        }
        catch {
            // Ignore cleanup errors
        }
        throw error;
    }
}
exports.authSignUp = functions.https.onCall((0, errors_1.withErrorHandling)(signUpHandler));
// ============================================================================
// authCompleteGoogleSignUp - Complete Google Sign-In with Tenant Setup
// ============================================================================
/**
 * Complete registration for a Google Sign-In user.
 * The user already exists in Firebase Auth (from Google sign-in on client),
 * but doesn't have a tenant yet.
 *
 * This function REQUIRES authentication (user signed in via Google)
 * but doesn't require a tenant (since that's what we're creating).
 */
async function completeGoogleSignUpHandler(data, context) {
    // This function requires the user to be signed in via Google
    if (!context.auth) {
        throw new errors_1.AppError(errors_1.ErrorCode.UNAUTHENTICATED, "Authentication required. Please sign in with Google first.", 401);
    }
    const { uid, token } = context.auth;
    const email = token.email;
    const displayName = token.name || email?.split("@")[0] || "User";
    if (!email) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Email not available from Google account", 400);
    }
    // Check if user already has a tenant
    const existingClaims = token;
    if (existingClaims.tenantId) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "You already have an account. Please sign in instead.", 400);
    }
    // Check if user document already exists
    const existingUserDoc = await admin_1.db.collection("users").doc(uid).get();
    if (existingUserDoc.exists) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Account setup already completed. Please sign in.", 400);
    }
    // Validate input
    validateCompanyName(data.companyName);
    const plan = data.plan || "starter";
    if (!["starter", "professional", "enterprise"].includes(plan)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Invalid plan selected", 400);
    }
    // Create tenant and user document
    const { tenantId } = await createTenantAndUser(uid, email, displayName, data.companyName, plan);
    return {
        success: true,
        data: {
            userId: uid,
            tenantId,
            email,
            displayName,
            role: "owner",
        },
    };
}
exports.authCompleteGoogleSignUp = functions.https.onCall((0, errors_1.withErrorHandling)(completeGoogleSignUpHandler));
// ============================================================================
// authCheckStatus - Check if current user has completed setup
// ============================================================================
/**
 * Check if the current authenticated user has completed account setup.
 * Used by frontend to determine whether to show company setup page.
 *
 * Returns:
 * - needsSetup: true if user exists in Auth but has no tenant
 * - isComplete: true if user has both Auth and tenant configured
 */
async function checkStatusHandler(_data, context) {
    if (!context.auth) {
        return {
            success: true,
            data: {
                needsSetup: false,
                isComplete: false,
            },
        };
    }
    const { uid, token } = context.auth;
    const claims = token;
    // Check if user has tenant in claims
    if (claims.tenantId) {
        return {
            success: true,
            data: {
                needsSetup: false,
                isComplete: true,
                email: token.email || undefined,
                displayName: token.name || undefined,
            },
        };
    }
    // Check if user document exists
    const userDoc = await admin_1.db.collection("users").doc(uid).get();
    if (userDoc.exists) {
        // User doc exists but claims might be stale - refresh claims
        const userData = userDoc.data();
        if (userData?.tenantId) {
            // Refresh claims
            await (0, auth_1.setUserClaims)(uid, userData.tenantId, userData.role || "owner");
            return {
                success: true,
                data: {
                    needsSetup: false,
                    isComplete: true,
                    email: token.email || undefined,
                    displayName: token.name || undefined,
                },
            };
        }
    }
    // User needs to complete setup
    return {
        success: true,
        data: {
            needsSetup: true,
            isComplete: false,
            email: token.email || undefined,
            displayName: token.name || undefined,
        },
    };
}
exports.authCheckStatus = functions.https.onCall((0, errors_1.withErrorHandling)(checkStatusHandler));
//# sourceMappingURL=index.js.map