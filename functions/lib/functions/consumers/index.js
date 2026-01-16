"use strict";
/**
 * Consumer Management Cloud Functions
 *
 * Handles consumer CRUD, SmartCredit connection, and report management.
 * PII fields (firstName, lastName, dob, ssnLast4) are encrypted at rest.
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.consumersTradelinesList = exports.consumersReportsRefresh = exports.consumersSmartCreditDisconnect = exports.consumersSmartCreditConnect = exports.consumersList = exports.consumersUpdate = exports.consumersGet = exports.consumersCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const encryption_1 = require("../../utils/encryption");
const audit_1 = require("../../utils/audit");
const joi_1 = __importDefault(require("joi"));
// ============================================================================
// Constants
// ============================================================================
const PII_FIELDS = ["firstName", "lastName", "dob", "ssnLast4"];
const CONSENT_VERSIONS = {
    terms: "1.0.0",
    privacy: "1.0.0",
    fcraDisclosure: "1.0.0",
};
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Mask consumer PII for list views and unauthorized access
 */
function maskConsumerPii(consumer) {
    return {
        ...consumer,
        firstName: (0, encryption_1.maskValue)(consumer.firstName, 1),
        lastName: (0, encryption_1.maskValue)(consumer.lastName, 2),
        dob: "****-**-**",
        ssnLast4: "****",
    };
}
/**
 * Decrypt consumer PII fields
 */
async function decryptConsumerPii(consumer) {
    return (0, encryption_1.decryptPiiFields)(consumer, PII_FIELDS);
}
/**
 * Check if consumer belongs to tenant
 */
async function verifyConsumerAccess(consumerId, tenantId) {
    const consumerDoc = await admin_1.db.collection("consumers").doc(consumerId).get();
    (0, errors_1.assertExists)(consumerDoc.exists ? consumerDoc.data() : null, "Consumer", consumerId);
    const consumer = { id: consumerDoc.id, ...consumerDoc.data() };
    if (consumer.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this consumer");
    }
    return consumer;
}
/**
 * Generate consumer lookup hash for duplicate detection
 */
function generateConsumerHash(firstName, lastName, dob, ssnLast4) {
    const combined = `${firstName.toLowerCase()}|${lastName.toLowerCase()}|${dob}|${ssnLast4}`;
    return (0, encryption_1.hashPii)(combined);
}
// ============================================================================
// consumersCreate - Create a new consumer
// ============================================================================
async function createConsumerHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.createConsumerSchema, data);
    // Check tenant consumer limits
    const consumersSnapshot = await admin_1.db
        .collection("consumers")
        .where("tenantId", "==", tenantId)
        .count()
        .get();
    const currentConsumerCount = consumersSnapshot.data().count;
    const maxConsumers = tenant.features?.maxConsumers || 100;
    if (currentConsumerCount >= maxConsumers) {
        throw new errors_1.AppError(errors_1.ErrorCode.TENANT_LIMIT_EXCEEDED, `Consumer limit reached for your plan. Maximum ${maxConsumers} consumers allowed.`, 400);
    }
    // Check for duplicate consumer using hash
    const consumerHash = generateConsumerHash(validatedData.firstName, validatedData.lastName, validatedData.dob, validatedData.ssnLast4);
    const duplicateSnapshot = await admin_1.db
        .collection("consumers")
        .where("tenantId", "==", tenantId)
        .where("lookupHash", "==", consumerHash)
        .limit(1)
        .get();
    if (!duplicateSnapshot.empty) {
        throw new errors_1.ConflictError("A consumer with this information already exists in your account");
    }
    // Encrypt PII fields
    const encryptedFirstName = await (0, encryption_1.encryptPii)(validatedData.firstName);
    const encryptedLastName = await (0, encryption_1.encryptPii)(validatedData.lastName);
    const encryptedDob = await (0, encryption_1.encryptPii)(validatedData.dob);
    const encryptedSsnLast4 = await (0, encryption_1.encryptPii)(validatedData.ssnLast4);
    // Ensure at least one address is marked primary
    const addresses = validatedData.addresses.map((addr, index) => ({
        ...addr,
        isPrimary: index === 0 ? true : addr.isPrimary || false,
        verified: false,
    }));
    // Process phones with defaults
    const phones = (validatedData.phones || []).map((phone, index) => ({
        ...phone,
        isPrimary: index === 0 ? true : phone.isPrimary || false,
        verified: false,
    }));
    // Process emails with defaults
    const emails = (validatedData.emails || []).map((email, index) => ({
        ...email,
        isPrimary: index === 0 ? true : email.isPrimary || false,
        verified: false,
    }));
    // Build consent record
    const consent = {
        agreedAt: firestore_1.FieldValue.serverTimestamp(),
        ipAddress: ip || "unknown",
        userAgent: userAgent,
        termsVersion: CONSENT_VERSIONS.terms,
        privacyVersion: CONSENT_VERSIONS.privacy,
        fcraDisclosureVersion: CONSENT_VERSIONS.fcraDisclosure,
    };
    // Create consumer document
    const consumerId = (0, uuid_1.v4)();
    const consumer = {
        id: consumerId,
        tenantId,
        firstName: encryptedFirstName,
        lastName: encryptedLastName,
        dob: encryptedDob,
        ssnLast4: encryptedSsnLast4,
        addresses,
        phones,
        emails,
        kycStatus: "pending",
        consent,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: actorId,
        lookupHash: consumerHash,
    };
    await admin_1.db.collection("consumers").doc(consumerId).set(consumer);
    // Audit log (with masked PII)
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "consumer",
        entityId: consumerId,
        action: "create",
        newState: {
            ...consumer,
            firstName: "[ENCRYPTED]",
            lastName: "[ENCRYPTED]",
            dob: "[ENCRYPTED]",
            ssnLast4: "[ENCRYPTED]",
        },
        metadata: { source: "consumer_management" },
    });
    // Return decrypted consumer for response
    const responseConsumer = {
        ...consumer,
        firstName: validatedData.firstName,
        lastName: validatedData.lastName,
        dob: validatedData.dob,
        ssnLast4: validatedData.ssnLast4,
    };
    return {
        success: true,
        data: responseConsumer,
    };
}
exports.consumersCreate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:write"], createConsumerHandler)));
// ============================================================================
// consumersGet - Get consumer details
// ============================================================================
async function getConsumerHandler(data, context) {
    const { tenantId, role } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId.required(),
        includePii: joi_1.default.boolean().default(false),
    }), data);
    // Get and verify consumer access
    const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);
    // Decrypt PII if requested and user has permission
    // Only owner and operator roles can see full PII
    const canSeePii = ["owner", "operator"].includes(role) && validatedData.includePii;
    if (canSeePii) {
        const decryptedConsumer = await decryptConsumerPii(consumer);
        return {
            success: true,
            data: decryptedConsumer,
        };
    }
    // Return masked consumer
    return {
        success: true,
        data: maskConsumerPii(consumer),
    };
}
exports.consumersGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:read"], getConsumerHandler)));
// ============================================================================
// consumersUpdate - Update consumer details
// ============================================================================
async function updateConsumerHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedConsumerId = (0, validation_1.validate)(joi_1.default.object({ consumerId: validation_1.schemas.documentId.required() }), { consumerId: data.consumerId });
    const validatedData = (0, validation_1.validate)(validation_1.updateConsumerSchema, data);
    // Get current consumer
    const consumerRef = admin_1.db.collection("consumers").doc(validatedConsumerId.consumerId);
    const currentConsumer = await verifyConsumerAccess(validatedConsumerId.consumerId, tenantId);
    // Build update object
    const updates = {
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (validatedData.addresses) {
        // Ensure at least one primary address
        const addresses = validatedData.addresses.map((addr, index) => ({
            ...addr,
            isPrimary: index === 0 ? true : addr.isPrimary || false,
        }));
        updates.addresses = addresses;
    }
    if (validatedData.phones) {
        const phones = validatedData.phones.map((phone, index) => ({
            ...phone,
            isPrimary: index === 0 ? true : phone.isPrimary || false,
            verified: false,
        }));
        updates.phones = phones;
    }
    if (validatedData.emails) {
        const emails = validatedData.emails.map((email, index) => ({
            ...email,
            isPrimary: index === 0 ? true : email.isPrimary || false,
            verified: false,
        }));
        updates.emails = emails;
    }
    // Update consumer
    await consumerRef.update(updates);
    // Get updated consumer
    const updatedDoc = await consumerRef.get();
    const updatedConsumer = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "consumer",
        entityId: validatedConsumerId.consumerId,
        action: "update",
        previousState: {
            addresses: currentConsumer.addresses,
            phones: currentConsumer.phones,
            emails: currentConsumer.emails,
        },
        newState: {
            addresses: updates.addresses || currentConsumer.addresses,
            phones: updates.phones || currentConsumer.phones,
            emails: updates.emails || currentConsumer.emails,
        },
    });
    // Return masked consumer (PII wasn't changed)
    return {
        success: true,
        data: maskConsumerPii(updatedConsumer),
    };
}
exports.consumersUpdate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:write"], updateConsumerHandler)));
// ============================================================================
// consumersList - List consumers in tenant
// ============================================================================
async function listConsumersHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    const filters = (0, validation_1.validate)(joi_1.default.object({
        search: joi_1.default.string().max(100),
        kycStatus: joi_1.default.string().valid("pending", "verified", "failed"),
    }), data);
    // Build query
    let query = admin_1.db
        .collection("consumers")
        .where("tenantId", "==", tenantId)
        .orderBy("createdAt", "desc");
    // Filter by KYC status if specified
    if (filters.kycStatus) {
        query = query.where("kycStatus", "==", filters.kycStatus);
    }
    // Apply cursor if provided
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("consumers").doc(pagination.cursor).get();
        if (cursorDoc.exists) {
            query = query.startAfter(cursorDoc);
        }
    }
    // Execute query with limit + 1 to check for more
    const snapshot = await query.limit(pagination.limit + 1).get();
    const hasMore = snapshot.docs.length > pagination.limit;
    const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
    // Map and mask consumers
    const consumers = docs.map((doc) => {
        const consumer = { id: doc.id, ...doc.data() };
        return maskConsumerPii(consumer);
    });
    // Get total count (with optional KYC filter)
    let countQuery = admin_1.db.collection("consumers").where("tenantId", "==", tenantId);
    if (filters.kycStatus) {
        countQuery = countQuery.where("kycStatus", "==", filters.kycStatus);
    }
    const countSnapshot = await countQuery.count().get();
    return {
        success: true,
        data: {
            items: consumers,
            pagination: {
                total: countSnapshot.data().count,
                limit: pagination.limit,
                hasMore,
                nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
            },
        },
    };
}
exports.consumersList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:read"], listConsumersHandler)));
// ============================================================================
// consumersSmartCreditConnect - Initiate SmartCredit OAuth connection
// ============================================================================
async function smartCreditConnectHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId.required(),
        redirectUri: joi_1.default.string().uri().required(),
    }), data);
    // Verify consumer access
    const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);
    // Check if already connected
    if (consumer.smartCreditConnectionId) {
        // Check connection status
        const connectionDoc = await admin_1.db
            .collection("smartcredit_connections")
            .doc(consumer.smartCreditConnectionId)
            .get();
        if (connectionDoc.exists) {
            const connection = connectionDoc.data();
            if (connection.status === "connected") {
                throw new errors_1.ConflictError("Consumer already has an active SmartCredit connection");
            }
        }
    }
    // Check if tenant has SmartCredit configured
    if (!tenant.smartCreditConfig) {
        throw new errors_1.AppError(errors_1.ErrorCode.INTEGRATION_NOT_CONFIGURED, "SmartCredit integration is not configured for this tenant", 400);
    }
    // Generate state for OAuth flow
    const state = (0, uuid_1.v4)();
    // Store pending connection
    const pendingConnectionId = (0, uuid_1.v4)();
    await admin_1.db.collection("smartcredit_pending_connections").doc(pendingConnectionId).set({
        id: pendingConnectionId,
        consumerId: validatedData.consumerId,
        tenantId,
        state,
        redirectUri: validatedData.redirectUri,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        expiresAt: firestore_1.Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000)), // 10 minutes
        status: "pending",
    });
    // Build SmartCredit authorization URL
    // In a real implementation, this would use the actual SmartCredit OAuth endpoint
    const smartCreditAuthBaseUrl = "https://api.smartcredit.com/oauth/authorize";
    const params = new URLSearchParams({
        client_id: tenant.smartCreditConfig.clientIdSecretRef, // Would decrypt this in production
        redirect_uri: `${tenant.smartCreditConfig.webhookEndpoint}/callback`,
        response_type: "code",
        scope: "credit_report credit_score",
        state,
    });
    const authorizationUrl = `${smartCreditAuthBaseUrl}?${params.toString()}`;
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "consumer",
        entityId: validatedData.consumerId,
        action: "update",
        metadata: {
            source: "smartcredit_connect",
            action: "oauth_initiated",
            pendingConnectionId,
        },
    });
    return {
        success: true,
        data: {
            authorizationUrl,
            state,
        },
    };
}
exports.consumersSmartCreditConnect = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:write"], smartCreditConnectHandler)));
// ============================================================================
// consumersSmartCreditDisconnect - Revoke SmartCredit connection
// ============================================================================
async function smartCreditDisconnectHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId.required(),
    }), data);
    // Verify consumer access
    const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);
    if (!consumer.smartCreditConnectionId) {
        throw new errors_1.NotFoundError("Consumer does not have a SmartCredit connection");
    }
    // Get connection
    const connectionRef = admin_1.db
        .collection("smartcredit_connections")
        .doc(consumer.smartCreditConnectionId);
    const connectionDoc = await connectionRef.get();
    if (!connectionDoc.exists) {
        throw new errors_1.NotFoundError("SmartCredit connection not found");
    }
    const connection = connectionDoc.data();
    // Revoke the connection
    await connectionRef.update({
        status: "revoked",
        revokedAt: firestore_1.FieldValue.serverTimestamp(),
        accessToken: "", // Clear tokens
        refreshToken: "",
    });
    // Remove connection reference from consumer
    await admin_1.db.collection("consumers").doc(validatedData.consumerId).update({
        smartCreditConnectionId: firestore_1.FieldValue.delete(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "consumer",
        entityId: validatedData.consumerId,
        action: "update",
        metadata: {
            source: "smartcredit_disconnect",
            connectionId: consumer.smartCreditConnectionId,
            previousStatus: connection.status,
        },
    });
    return {
        success: true,
        data: { disconnected: true },
    };
}
exports.consumersSmartCreditDisconnect = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:write"], smartCreditDisconnectHandler)));
// ============================================================================
// consumersReportsRefresh - Refresh credit reports from SmartCredit
// ============================================================================
async function reportsRefreshHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId.required(),
        bureaus: joi_1.default.array().items(validation_1.schemas.bureau).default(["equifax", "experian", "transunion"]),
    }), data);
    // Verify consumer access
    const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);
    // Check SmartCredit connection
    if (!consumer.smartCreditConnectionId) {
        throw new errors_1.AppError(errors_1.ErrorCode.INTEGRATION_NOT_CONFIGURED, "Consumer does not have an active SmartCredit connection. Connect to SmartCredit first.", 400);
    }
    // Verify connection is active
    const connectionDoc = await admin_1.db
        .collection("smartcredit_connections")
        .doc(consumer.smartCreditConnectionId)
        .get();
    if (!connectionDoc.exists) {
        throw new errors_1.NotFoundError("SmartCredit connection not found");
    }
    const connection = connectionDoc.data();
    if (connection.status !== "connected") {
        throw new errors_1.AppError(errors_1.ErrorCode.INTEGRATION_ERROR, `SmartCredit connection is ${connection.status}. Please reconnect.`, 400);
    }
    // Check if token is expired
    if (connection.tokenExpiresAt.toDate() < new Date()) {
        throw new errors_1.AppError(errors_1.ErrorCode.INTEGRATION_ERROR, "SmartCredit session has expired. Please reconnect.", 400);
    }
    // Queue report refresh tasks for each bureau
    // In a real implementation, this would call SmartCredit API
    const bureaus = validatedData.bureaus || ["equifax", "experian", "transunion"];
    // Create pending report entries
    for (const bureau of bureaus) {
        const reportId = (0, uuid_1.v4)();
        await admin_1.db.collection("credit_reports").doc(reportId).set({
            id: reportId,
            consumerId: validatedData.consumerId,
            tenantId,
            bureau,
            pulledAt: firestore_1.FieldValue.serverTimestamp(),
            status: "processing",
            rawJsonRef: "",
            hash: "",
            scoreFactors: [],
            summary: {
                totalAccounts: 0,
                openAccounts: 0,
                closedAccounts: 0,
                delinquentAccounts: 0,
                derogatoryAccounts: 0,
                totalBalance: 0,
                totalCreditLimit: 0,
                utilizationPercent: 0,
            },
            publicRecords: [],
            inquiries: [],
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            expiresAt: firestore_1.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)), // 30 days
        });
    }
    // Update connection last refresh timestamp
    await admin_1.db
        .collection("smartcredit_connections")
        .doc(consumer.smartCreditConnectionId)
        .update({
        lastRefreshedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "consumer",
        entityId: validatedData.consumerId,
        action: "update",
        metadata: {
            source: "reports_refresh",
            bureaus,
        },
    });
    return {
        success: true,
        data: {
            requested: true,
            bureaus,
        },
    };
}
exports.consumersReportsRefresh = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:write"], reportsRefreshHandler)));
// ============================================================================
// consumersTradelinesList - List tradelines for a consumer
// ============================================================================
async function tradelinesListHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId.required(),
        bureau: validation_1.schemas.bureau,
        disputeStatus: joi_1.default.string().valid("none", "in_dispute", "resolved"),
        limit: joi_1.default.number().integer().min(1).max(100).default(50),
        cursor: joi_1.default.string().max(1000),
    }), data);
    // Verify consumer access
    await verifyConsumerAccess(validatedData.consumerId, tenantId);
    // Build query
    let query = admin_1.db
        .collection("tradelines")
        .where("tenantId", "==", tenantId)
        .where("consumerId", "==", validatedData.consumerId)
        .orderBy("lastReportedDate", "desc");
    // Filter by bureau if specified
    if (validatedData.bureau) {
        query = query.where("bureau", "==", validatedData.bureau);
    }
    // Filter by dispute status if specified
    if (validatedData.disputeStatus) {
        query = query.where("disputeStatus", "==", validatedData.disputeStatus);
    }
    // Apply cursor if provided
    if (validatedData.cursor) {
        const cursorDoc = await admin_1.db.collection("tradelines").doc(validatedData.cursor).get();
        if (cursorDoc.exists) {
            query = query.startAfter(cursorDoc);
        }
    }
    // Execute query with limit + 1 to check for more
    const limit = validatedData.limit || 50;
    const snapshot = await query.limit(limit + 1).get();
    const hasMore = snapshot.docs.length > limit;
    const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
    const tradelines = docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    // Get total count with filters
    let countQuery = admin_1.db
        .collection("tradelines")
        .where("tenantId", "==", tenantId)
        .where("consumerId", "==", validatedData.consumerId);
    if (validatedData.bureau) {
        countQuery = countQuery.where("bureau", "==", validatedData.bureau);
    }
    if (validatedData.disputeStatus) {
        countQuery = countQuery.where("disputeStatus", "==", validatedData.disputeStatus);
    }
    const countSnapshot = await countQuery.count().get();
    return {
        success: true,
        data: {
            items: tradelines,
            pagination: {
                total: countSnapshot.data().count,
                limit,
                hasMore,
                nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
            },
        },
    };
}
exports.consumersTradelinesList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["consumers:read"], tradelinesListHandler)));
//# sourceMappingURL=index.js.map