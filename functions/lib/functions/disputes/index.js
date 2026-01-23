"use strict";
/**
 * Dispute Management Cloud Functions
 *
 * Handles dispute lifecycle: creation, updates, approval, submission, and closure.
 * Implements FCRA 30/45 day SLA tracking and status transitions.
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
exports.disputesClose = exports.disputesApprove = exports.disputesSubmit = exports.disputesList = exports.disputesUpdate = exports.disputesGet = exports.disputesCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const audit_1 = require("../../utils/audit");
const config_1 = require("../../config");
const joi_1 = __importDefault(require("joi"));
// ============================================================================
// Constants
// ============================================================================
/**
 * Valid status transitions for disputes
 */
const STATUS_TRANSITIONS = {
    draft: ["pending_review"],
    pending_review: ["approved", "rejected", "draft"],
    approved: ["mailed"],
    rejected: ["draft"],
    mailed: ["delivered", "bureau_investigating"],
    delivered: ["bureau_investigating"],
    bureau_investigating: ["resolved", "closed"],
    resolved: ["closed"],
    closed: [],
};
/**
 * Statuses that can still be edited
 */
const EDITABLE_STATUSES = ["draft", "pending_review", "rejected"];
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Validate status transition is allowed
 */
function validateStatusTransition(currentStatus, newStatus) {
    const allowedTransitions = STATUS_TRANSITIONS[currentStatus];
    if (!allowedTransitions.includes(newStatus)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot transition from '${currentStatus}' to '${newStatus}'. Allowed transitions: ${allowedTransitions.join(", ") || "none"}`, 400);
    }
}
/**
 * Verify dispute access and return dispute document
 */
async function verifyDisputeAccess(disputeId, tenantId) {
    const disputeDoc = await admin_1.db.collection("disputes").doc(disputeId).get();
    (0, errors_1.assertExists)(disputeDoc.exists ? disputeDoc.data() : null, "Dispute", disputeId);
    const dispute = { id: disputeDoc.id, ...disputeDoc.data() };
    if (dispute.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this dispute");
    }
    return dispute;
}
/**
 * Verify tradeline exists and belongs to tenant
 */
async function verifyTradelineAccess(tradelineId, tenantId) {
    const tradelineDoc = await admin_1.db.collection("tradelines").doc(tradelineId).get();
    (0, errors_1.assertExists)(tradelineDoc.exists ? tradelineDoc.data() : null, "Tradeline", tradelineId);
    const tradeline = { id: tradelineDoc.id, ...tradelineDoc.data() };
    if (tradeline.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this tradeline");
    }
    return tradeline;
}
/**
 * Verify consumer exists and belongs to tenant
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
// ============================================================================
// disputesCreate - Create a new dispute
// ============================================================================
async function createDisputeHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.createDisputeSchema, data);
    // Check tenant dispute limits
    const currentMonth = new Date();
    currentMonth.setDate(1);
    currentMonth.setHours(0, 0, 0, 0);
    const disputesThisMonth = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("timestamps.createdAt", ">=", firestore_1.Timestamp.fromDate(currentMonth))
        .count()
        .get();
    const maxDisputes = tenant.features?.maxDisputesPerMonth || 500;
    if (disputesThisMonth.data().count >= maxDisputes) {
        throw new errors_1.AppError(errors_1.ErrorCode.TENANT_LIMIT_EXCEEDED, `Monthly dispute limit reached. Maximum ${maxDisputes} disputes per month allowed.`, 400);
    }
    // Verify consumer and tradeline access
    await verifyConsumerAccess(validatedData.consumerId, tenantId);
    const tradeline = await verifyTradelineAccess(validatedData.tradelineId, tenantId);
    // Verify tradeline belongs to the consumer
    if (tradeline.consumerId !== validatedData.consumerId) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Tradeline does not belong to the specified consumer", 400);
    }
    // Check if there's already an active dispute for this tradeline+bureau
    const existingDispute = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("tradelineId", "==", validatedData.tradelineId)
        .where("bureau", "==", validatedData.bureau)
        .where("status", "not-in", ["closed", "resolved"])
        .limit(1)
        .get();
    if (!existingDispute.empty) {
        throw new errors_1.AppError(errors_1.ErrorCode.ALREADY_EXISTS, "An active dispute already exists for this tradeline and bureau", 409);
    }
    // Create dispute
    const disputeId = (0, uuid_1.v4)();
    const now = firestore_1.FieldValue.serverTimestamp();
    const timestamps = {
        createdAt: now,
    };
    const sla = {
        baseDays: config_1.slaConfig.baseDays,
        extendedDays: config_1.slaConfig.extensionDays,
        isExtended: false,
    };
    const dispute = {
        id: disputeId,
        consumerId: validatedData.consumerId,
        tradelineId: validatedData.tradelineId,
        tenantId,
        bureau: validatedData.bureau,
        type: validatedData.type,
        reasonCodes: validatedData.reasonCodes,
        reasonDetails: validatedData.reasonDetails || {},
        narrative: validatedData.narrative || "",
        status: "draft",
        priority: validatedData.priority || "normal",
        assignedTo: actorId, // Assign to creator by default
        timestamps,
        sla,
        letterIds: [],
        evidenceIds: validatedData.evidenceIds || [],
        tags: [],
        createdBy: actorId,
        updatedAt: now,
    };
    await admin_1.db.collection("disputes").doc(disputeId).set(dispute);
    // Update tradeline dispute status
    await admin_1.db.collection("tradelines").doc(validatedData.tradelineId).update({
        disputeStatus: "in_dispute",
        disputeFlag: true,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "dispute",
        entityId: disputeId,
        action: "create",
        newState: dispute,
        metadata: {
            source: "dispute_management",
            consumerId: validatedData.consumerId,
            tradelineId: validatedData.tradelineId,
        },
    });
    return {
        success: true,
        data: dispute,
    };
}
exports.disputesCreate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:write"], createDisputeHandler)));
// ============================================================================
// disputesGet - Get dispute details
// ============================================================================
async function getDisputeHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ disputeId: validation_1.schemas.documentId.required() }), data);
    const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    return {
        success: true,
        data: dispute,
    };
}
exports.disputesGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:read"], getDisputeHandler)));
// ============================================================================
// disputesUpdate - Update dispute details
// ============================================================================
async function updateDisputeHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedDisputeId = (0, validation_1.validate)(joi_1.default.object({ disputeId: validation_1.schemas.documentId.required() }), { disputeId: data.disputeId });
    const validatedData = (0, validation_1.validate)(validation_1.updateDisputeSchema, data);
    // Get current dispute
    const disputeRef = admin_1.db.collection("disputes").doc(validatedDisputeId.disputeId);
    const currentDispute = await verifyDisputeAccess(validatedDisputeId.disputeId, tenantId);
    // Check if dispute is editable
    if (!EDITABLE_STATUSES.includes(currentDispute.status)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot edit dispute in '${currentDispute.status}' status. Editable statuses: ${EDITABLE_STATUSES.join(", ")}`, 400);
    }
    // Build update object
    const updates = {
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (validatedData.narrative !== undefined) {
        updates.narrative = validatedData.narrative;
    }
    if (validatedData.priority !== undefined) {
        updates.priority = validatedData.priority;
    }
    if (validatedData.assignedTo !== undefined) {
        updates.assignedTo = validatedData.assignedTo;
    }
    if (validatedData.reasonCodes !== undefined) {
        updates.reasonCodes = validatedData.reasonCodes;
    }
    if (validatedData.reasonDetails !== undefined) {
        updates.reasonDetails = validatedData.reasonDetails;
    }
    if (validatedData.internalNotes !== undefined) {
        updates.internalNotes = validatedData.internalNotes;
    }
    if (validatedData.tags !== undefined) {
        updates.tags = validatedData.tags;
    }
    // Update dispute
    await disputeRef.update(updates);
    // Get updated dispute
    const updatedDoc = await disputeRef.get();
    const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "dispute",
        entityId: validatedDisputeId.disputeId,
        action: "update",
        previousState: currentDispute,
        newState: updatedDispute,
    });
    return {
        success: true,
        data: updatedDispute,
    };
}
exports.disputesUpdate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:write"], updateDisputeHandler)));
// ============================================================================
// disputesList - List disputes with filters
// ============================================================================
async function listDisputesHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    const filters = (0, validation_1.validate)(joi_1.default.object({
        consumerId: validation_1.schemas.documentId,
        status: joi_1.default.alternatives().try(joi_1.default.string().valid("draft", "pending_review", "approved", "rejected", "mailed", "delivered", "bureau_investigating", "resolved", "closed"), joi_1.default.array().items(joi_1.default.string().valid("draft", "pending_review", "approved", "rejected", "mailed", "delivered", "bureau_investigating", "resolved", "closed"))),
        bureau: validation_1.schemas.bureau,
        assignedTo: validation_1.schemas.documentId,
        priority: validation_1.schemas.priority,
    }), data);
    // Build query
    let query = admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .orderBy("timestamps.createdAt", "desc");
    // Apply filters
    if (filters.consumerId) {
        query = query.where("consumerId", "==", filters.consumerId);
    }
    if (filters.status) {
        if (Array.isArray(filters.status)) {
            query = query.where("status", "in", filters.status);
        }
        else {
            query = query.where("status", "==", filters.status);
        }
    }
    if (filters.bureau) {
        query = query.where("bureau", "==", filters.bureau);
    }
    if (filters.assignedTo) {
        query = query.where("assignedTo", "==", filters.assignedTo);
    }
    if (filters.priority) {
        query = query.where("priority", "==", filters.priority);
    }
    // Apply cursor if provided
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("disputes").doc(pagination.cursor).get();
        if (cursorDoc.exists) {
            query = query.startAfter(cursorDoc);
        }
    }
    // Execute query with limit + 1 to check for more
    const snapshot = await query.limit(pagination.limit + 1).get();
    const hasMore = snapshot.docs.length > pagination.limit;
    const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
    const disputes = docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    // Get total count
    let countQuery = admin_1.db.collection("disputes").where("tenantId", "==", tenantId);
    if (filters.consumerId) {
        countQuery = countQuery.where("consumerId", "==", filters.consumerId);
    }
    if (filters.status && !Array.isArray(filters.status)) {
        countQuery = countQuery.where("status", "==", filters.status);
    }
    const countSnapshot = await countQuery.count().get();
    const totalCount = countSnapshot.data().count;
    return {
        success: true,
        data: {
            items: disputes,
            pagination: {
                total: totalCount,
                limit: pagination.limit,
                hasMore,
                nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
            },
        },
    };
}
exports.disputesList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:read"], listDisputesHandler)));
// ============================================================================
// disputesSubmit - Submit dispute for review
// ============================================================================
async function submitDisputeHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ disputeId: validation_1.schemas.documentId.required() }), data);
    // Get current dispute
    const disputeRef = admin_1.db.collection("disputes").doc(validatedData.disputeId);
    const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    // Validate status transition
    validateStatusTransition(currentDispute.status, "pending_review");
    // Validate dispute is ready for submission
    if (!currentDispute.narrative || currentDispute.narrative.length < 50) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Dispute narrative must be at least 50 characters", 400);
    }
    if (!currentDispute.reasonCodes || currentDispute.reasonCodes.length === 0) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "At least one reason code is required", 400);
    }
    // Update status
    await disputeRef.update({
        status: "pending_review",
        "timestamps.submittedAt": firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Get updated dispute
    const updatedDoc = await disputeRef.get();
    const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "dispute",
        entityId: validatedData.disputeId,
        action: "status_change",
        actionDetail: "Submitted for review",
        previousState: { status: currentDispute.status },
        newState: { status: "pending_review" },
    });
    return {
        success: true,
        data: updatedDispute,
    };
}
exports.disputesSubmit = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:write"], submitDisputeHandler)));
// ============================================================================
// disputesApprove - Approve a dispute (owner/operator only)
// ============================================================================
async function approveDisputeHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Only owner and operator can approve
    (0, auth_1.requireRole)(context, ["owner", "operator"]);
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        disputeId: validation_1.schemas.documentId.required(),
        comments: joi_1.default.string().max(1000),
    }), data);
    // Get current dispute
    const disputeRef = admin_1.db.collection("disputes").doc(validatedData.disputeId);
    const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    // Validate status transition
    validateStatusTransition(currentDispute.status, "approved");
    // Update status
    await disputeRef.update({
        status: "approved",
        "timestamps.approvedAt": firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        internalNotes: validatedData.comments
            ? `${currentDispute.internalNotes || ""}\n[Approved] ${validatedData.comments}`.trim()
            : currentDispute.internalNotes,
    });
    // Get updated dispute
    const updatedDoc = await disputeRef.get();
    const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "dispute",
        entityId: validatedData.disputeId,
        action: "approve",
        actionDetail: validatedData.comments || "Approved",
        previousState: { status: currentDispute.status },
        newState: { status: "approved" },
    });
    return {
        success: true,
        data: updatedDispute,
    };
}
exports.disputesApprove = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:approve"], approveDisputeHandler)));
// ============================================================================
// disputesClose - Close a dispute with outcome
// ============================================================================
async function closeDisputeHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        disputeId: validation_1.schemas.documentId.required(),
        outcome: joi_1.default.string().valid("corrected", "verified_accurate", "deleted", "pending", "no_response", "frivolous").required(),
        outcomeDetails: joi_1.default.object({
            balanceCorrected: joi_1.default.boolean(),
            statusCorrected: joi_1.default.boolean(),
            accountDeleted: joi_1.default.boolean(),
            noChange: joi_1.default.boolean(),
            bureauResponse: joi_1.default.string().max(2000),
            responseDate: joi_1.default.date().iso(),
        }),
        internalNotes: joi_1.default.string().max(2000),
    }), data);
    // Get current dispute
    const disputeRef = admin_1.db.collection("disputes").doc(validatedData.disputeId);
    const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    // Can only close disputes that are in valid closing states
    const closableStatuses = ["bureau_investigating", "resolved", "delivered"];
    if (!closableStatuses.includes(currentDispute.status)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot close dispute in '${currentDispute.status}' status. Must be in: ${closableStatuses.join(", ")}`, 400);
    }
    // Update dispute
    const updates = {
        status: "closed",
        outcome: validatedData.outcome,
        "timestamps.closedAt": firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (validatedData.outcomeDetails) {
        updates.outcomeDetails = {
            ...validatedData.outcomeDetails,
            responseDate: validatedData.outcomeDetails.responseDate
                ? firestore_1.Timestamp.fromDate(new Date(validatedData.outcomeDetails.responseDate))
                : undefined,
        };
    }
    if (validatedData.internalNotes) {
        updates.internalNotes = `${currentDispute.internalNotes || ""}\n[Closed] ${validatedData.internalNotes}`.trim();
    }
    await disputeRef.update(updates);
    // Update tradeline dispute status based on outcome
    const tradelineUpdate = {
        disputeStatus: "resolved",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (validatedData.outcome === "deleted") {
        tradelineUpdate.disputeFlag = false;
    }
    await admin_1.db.collection("tradelines").doc(currentDispute.tradelineId).update(tradelineUpdate);
    // Get updated dispute
    const updatedDoc = await disputeRef.get();
    const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "dispute",
        entityId: validatedData.disputeId,
        action: "status_change",
        actionDetail: `Closed with outcome: ${validatedData.outcome}`,
        previousState: { status: currentDispute.status },
        newState: { status: "closed", outcome: validatedData.outcome },
    });
    return {
        success: true,
        data: updatedDispute,
    };
}
exports.disputesClose = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["disputes:write"], closeDisputeHandler)));
//# sourceMappingURL=index.js.map