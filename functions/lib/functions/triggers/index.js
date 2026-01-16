"use strict";
/**
 * Firestore Trigger Cloud Functions
 *
 * Handles automatic actions on document changes including:
 * - SLA deadline calculations
 * - Audit logging
 * - Status synchronization
 * - Notifications
 * - Statistics aggregation
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
exports.onSmartCreditConnectionChange = exports.onEvidenceUpload = exports.onConsumerCreate = exports.onLetterStatusChange = exports.onDisputeUpdate = exports.onDisputeCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const firestore_1 = require("firebase-admin/firestore");
const audit_1 = require("../../utils/audit");
const config_1 = require("../../config");
const uuid_1 = require("uuid");
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Calculate the FCRA-compliant SLA due date
 * Standard: baseDays (30 days)
 * Extended: baseDays + extensionDays (45 days total)
 */
function calculateSlaDueDate(createdAt, isExtended) {
    const dueDate = new Date(createdAt);
    const days = isExtended
        ? config_1.slaConfig.baseDays + config_1.slaConfig.extensionDays
        : config_1.slaConfig.baseDays;
    dueDate.setDate(dueDate.getDate() + days);
    return dueDate;
}
/**
 * Create a notification record
 */
async function createNotification(tenantId, type, title, message, data) {
    const notificationId = (0, uuid_1.v4)();
    await admin_1.db.collection("notifications").doc(notificationId).set({
        id: notificationId,
        tenantId,
        type,
        title,
        message,
        data,
        status: "pending",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        channels: ["email"],
    });
}
/**
 * Update tenant statistics
 */
async function updateTenantStats(tenantId, field, increment) {
    await admin_1.db.collection("tenants").doc(tenantId).update({
        [`stats.${field}`]: firestore_1.FieldValue.increment(increment),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
// ============================================================================
// onDisputeCreate - Trigger when a new dispute is created
// ============================================================================
exports.onDisputeCreate = functions.firestore
    .document("disputes/{disputeId}")
    .onCreate(async (snapshot, context) => {
    const disputeId = context.params.disputeId;
    const disputeData = snapshot.data();
    try {
        functions.logger.info("Dispute created trigger fired", { disputeId });
        const createdAt = disputeData.timestamps?.createdAt?.toDate() || new Date();
        // Determine if this is an extended SLA case based on dispute type
        const extendedTypes = ["reinvestigation", "605b_identity_theft"];
        const isExtended = extendedTypes.includes(disputeData.type);
        // Calculate SLA deadline
        const dueAt = calculateSlaDueDate(createdAt, isExtended);
        const warningAt = new Date(dueAt);
        warningAt.setDate(warningAt.getDate() - config_1.slaConfig.reminderDays[0]);
        // Update dispute with SLA information
        await snapshot.ref.update({
            "timestamps.dueAt": firestore_1.Timestamp.fromDate(dueAt),
            "sla.baseDays": config_1.slaConfig.baseDays,
            "sla.extendedDays": isExtended ? config_1.slaConfig.extensionDays : 0,
            "sla.isExtended": isExtended,
        });
        // Create audit log for dispute creation
        await (0, audit_1.logAuditEvent)({
            tenantId: disputeData.tenantId,
            actor: {
                userId: disputeData.createdBy || "system",
                role: "operator",
            },
            entity: "dispute",
            entityId: disputeId,
            action: "create",
            newState: {
                status: disputeData.status,
                bureau: disputeData.bureau,
                type: disputeData.type,
            },
            metadata: {
                source: "trigger",
                isExtended,
                slaBaseDays: config_1.slaConfig.baseDays,
            },
        });
        // Update tenant dispute count
        await updateTenantStats(disputeData.tenantId, "totalDisputes", 1);
        await updateTenantStats(disputeData.tenantId, "activeDisputes", 1);
        // Send notification about new dispute
        await createNotification(disputeData.tenantId, "dispute_created", "New Dispute Created", `A new dispute has been created for consumer ${disputeData.consumerId}`, {
            disputeId,
            consumerId: disputeData.consumerId,
            bureau: disputeData.bureau,
            dueAt: dueAt.toISOString(),
        });
        functions.logger.info("Dispute creation trigger completed", {
            disputeId,
            dueAt: dueAt.toISOString(),
            isExtended,
        });
        return { success: true, disputeId, dueAt };
    }
    catch (error) {
        functions.logger.error("Dispute creation trigger failed", {
            disputeId,
            error,
        });
        throw error;
    }
});
// ============================================================================
// onDisputeUpdate - Trigger when a dispute is updated
// ============================================================================
exports.onDisputeUpdate = functions.firestore
    .document("disputes/{disputeId}")
    .onUpdate(async (change, context) => {
    const disputeId = context.params.disputeId;
    const before = change.before.data();
    const after = change.after.data();
    try {
        const statusChanged = before.status !== after.status;
        // Only process meaningful changes
        if (!statusChanged) {
            return null;
        }
        functions.logger.info("Dispute update trigger fired", {
            disputeId,
            statusChanged,
            previousStatus: before.status,
            newStatus: after.status,
        });
        // Handle status change
        const previousStatus = before.status;
        const newStatus = after.status;
        // Log status change
        await (0, audit_1.logAuditEvent)({
            tenantId: after.tenantId,
            actor: {
                userId: "system",
                role: "operator",
            },
            entity: "dispute",
            entityId: disputeId,
            action: "status_change",
            previousState: { status: previousStatus },
            newState: { status: newStatus },
            metadata: { source: "trigger" },
        });
        // Update tenant statistics based on status change
        if (newStatus === "resolved" || newStatus === "closed") {
            await updateTenantStats(after.tenantId, "activeDisputes", -1);
            if (newStatus === "resolved") {
                await updateTenantStats(after.tenantId, "resolvedDisputes", 1);
                // Calculate resolution time
                const createdAt = before.timestamps?.createdAt?.toDate();
                const resolvedAt = new Date();
                if (createdAt) {
                    const resolutionDays = Math.ceil((resolvedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
                    // Update with resolution metrics
                    await change.after.ref.update({
                        "metrics.resolutionDays": resolutionDays,
                        "timestamps.closedAt": firestore_1.FieldValue.serverTimestamp(),
                    });
                }
            }
        }
        // Check if dispute is overdue and update SLA status
        if (newStatus === "resolved" || newStatus === "closed") {
            const dueAt = after.timestamps?.dueAt?.toDate();
            const now = new Date();
            const completedOnTime = dueAt && now <= dueAt;
            await change.after.ref.update({
                "metrics.completedOnTime": completedOnTime,
            });
        }
        // Send notification for important status changes
        const notifiableStatuses = [
            "approved",
            "mailed",
            "delivered",
            "bureau_investigating",
            "resolved",
        ];
        if (notifiableStatuses.includes(newStatus)) {
            await createNotification(after.tenantId, "dispute_status_changed", "Dispute Status Updated", `Dispute ${disputeId} status changed from ${previousStatus} to ${newStatus}`, {
                disputeId,
                consumerId: after.consumerId,
                previousStatus,
                newStatus,
            });
        }
        functions.logger.info("Dispute update trigger completed", {
            disputeId,
            statusChanged,
        });
        return { success: true, disputeId };
    }
    catch (error) {
        functions.logger.error("Dispute update trigger failed", {
            disputeId,
            error,
        });
        throw error;
    }
});
// ============================================================================
// onLetterStatusChange - Trigger when a letter status changes
// ============================================================================
exports.onLetterStatusChange = functions.firestore
    .document("letters/{letterId}")
    .onUpdate(async (change, context) => {
    const letterId = context.params.letterId;
    const before = change.before.data();
    const after = change.after.data();
    const statusChanged = before.status !== after.status;
    if (!statusChanged) {
        return null;
    }
    try {
        const previousStatus = before.status;
        const newStatus = after.status;
        functions.logger.info("Letter status change trigger fired", {
            letterId,
            previousStatus,
            newStatus,
        });
        // Log status change
        await (0, audit_1.logAuditEvent)({
            tenantId: after.tenantId,
            actor: {
                userId: "system",
                role: "operator",
            },
            entity: "letter",
            entityId: letterId,
            action: "status_change",
            previousState: { status: previousStatus },
            newState: { status: newStatus },
            metadata: { source: "trigger" },
        });
        // Update associated dispute based on letter status
        if (after.disputeId) {
            const disputeRef = admin_1.db.collection("disputes").doc(after.disputeId);
            // Update dispute status based on letter status
            const letterToDisputeStatusMap = {
                sent: "mailed",
                in_transit: "mailed",
                delivered: "delivered",
            };
            const mappedDisputeStatus = letterToDisputeStatusMap[newStatus];
            if (mappedDisputeStatus) {
                // Get current dispute to check if we should update
                const disputeDoc = await disputeRef.get();
                if (disputeDoc.exists) {
                    const dispute = disputeDoc.data();
                    // Only update if the dispute isn't already in a later stage
                    const disputeStatusOrder = [
                        "draft",
                        "pending_review",
                        "approved",
                        "rejected",
                        "mailed",
                        "delivered",
                        "bureau_investigating",
                        "resolved",
                        "closed",
                    ];
                    const currentIndex = disputeStatusOrder.indexOf(dispute.status);
                    const newIndex = disputeStatusOrder.indexOf(mappedDisputeStatus);
                    if (newIndex > currentIndex) {
                        await disputeRef.update({
                            status: mappedDisputeStatus,
                            updatedAt: firestore_1.FieldValue.serverTimestamp(),
                        });
                        functions.logger.info("Updated dispute status from letter", {
                            letterId,
                            disputeId: after.disputeId,
                            newDisputeStatus: mappedDisputeStatus,
                        });
                    }
                }
            }
            // Track delivery date for SLA calculations
            if (newStatus === "delivered") {
                await disputeRef.update({
                    "timestamps.deliveredAt": firestore_1.FieldValue.serverTimestamp(),
                });
            }
            // Handle returned letters
            if (newStatus === "returned_to_sender") {
                // Get dispute to find bureau
                const disputeDoc = await disputeRef.get();
                const dispute = disputeDoc.exists ? disputeDoc.data() : null;
                await createNotification(after.tenantId, "letter_returned", "Letter Returned", `Letter was returned to sender - please check the address`, {
                    letterId,
                    disputeId: after.disputeId,
                    bureau: dispute?.bureau,
                    returnReason: after.returnReason,
                });
            }
        }
        // Send notifications for important letter status changes
        const notifiableStatuses = ["sent", "delivered", "returned_to_sender"];
        if (notifiableStatuses.includes(newStatus)) {
            const messageMap = {
                sent: "has been sent and is in transit",
                delivered: "has been delivered successfully",
                returned_to_sender: "was returned - please check the address",
            };
            // Get dispute info for notification
            let bureau = "bureau";
            if (after.disputeId) {
                const disputeDoc = await admin_1.db.collection("disputes").doc(after.disputeId).get();
                if (disputeDoc.exists) {
                    bureau = disputeDoc.data().bureau;
                }
            }
            await createNotification(after.tenantId, "letter_status_changed", `Letter ${newStatus.charAt(0).toUpperCase() + newStatus.slice(1).replace("_", " ")}`, `Letter to ${bureau} ${messageMap[newStatus]}`, {
                letterId,
                disputeId: after.disputeId,
                previousStatus,
                newStatus,
                lobId: after.lobId,
            });
        }
        // Update tenant letter statistics
        if (newStatus === "delivered") {
            await updateTenantStats(after.tenantId, "lettersDelivered", 1);
        }
        else if (newStatus === "returned_to_sender") {
            await updateTenantStats(after.tenantId, "lettersReturned", 1);
        }
        functions.logger.info("Letter status change trigger completed", {
            letterId,
            newStatus,
        });
        return { success: true, letterId, newStatus };
    }
    catch (error) {
        functions.logger.error("Letter status change trigger failed", {
            letterId,
            error,
        });
        throw error;
    }
});
// ============================================================================
// onConsumerCreate - Trigger when a new consumer is created
// ============================================================================
exports.onConsumerCreate = functions.firestore
    .document("consumers/{consumerId}")
    .onCreate(async (snapshot, context) => {
    const consumerId = context.params.consumerId;
    const consumerData = snapshot.data();
    try {
        functions.logger.info("Consumer created trigger fired", { consumerId });
        // Initialize consumer statistics
        await snapshot.ref.update({
            "stats.totalDisputes": 0,
            "stats.activeDisputes": 0,
            "stats.resolvedDisputes": 0,
            "stats.totalLetters": 0,
        });
        // Create audit log for consumer creation
        await (0, audit_1.logAuditEvent)({
            tenantId: consumerData.tenantId,
            actor: {
                userId: consumerData.createdBy || "system",
                role: "operator",
            },
            entity: "consumer",
            entityId: consumerId,
            action: "create",
            newState: {
                kycStatus: consumerData.kycStatus,
                hasSmartCredit: !!consumerData.smartCreditConnectionId,
            },
            metadata: { source: "trigger" },
        });
        // Update tenant consumer count
        await updateTenantStats(consumerData.tenantId, "totalConsumers", 1);
        await updateTenantStats(consumerData.tenantId, "activeConsumers", 1);
        // Send welcome notification
        await createNotification(consumerData.tenantId, "consumer_created", "New Consumer Added", "A new consumer has been added to your account", {
            consumerId,
            kycStatus: consumerData.kycStatus,
        });
        functions.logger.info("Consumer creation trigger completed", {
            consumerId,
        });
        return { success: true, consumerId };
    }
    catch (error) {
        functions.logger.error("Consumer creation trigger failed", {
            consumerId,
            error,
        });
        throw error;
    }
});
// ============================================================================
// onEvidenceUpload - Trigger when evidence is uploaded
// ============================================================================
exports.onEvidenceUpload = functions.firestore
    .document("evidence/{evidenceId}")
    .onCreate(async (snapshot, context) => {
    const evidenceId = context.params.evidenceId;
    const evidenceData = snapshot.data();
    try {
        functions.logger.info("Evidence upload trigger fired", { evidenceId });
        // Update consumer evidence count
        if (evidenceData.consumerId) {
            await admin_1.db
                .collection("consumers")
                .doc(evidenceData.consumerId)
                .update({
                "stats.totalEvidence": firestore_1.FieldValue.increment(1),
            });
        }
        // Update dispute evidence count if linked
        if (evidenceData.disputeId) {
            await admin_1.db
                .collection("disputes")
                .doc(evidenceData.disputeId)
                .update({
                evidenceIds: firestore_1.FieldValue.arrayUnion(evidenceId),
            });
        }
        // Create audit log
        await (0, audit_1.logAuditEvent)({
            tenantId: evidenceData.tenantId,
            actor: {
                userId: evidenceData.uploadedBy || "system",
                role: "operator",
            },
            entity: "evidence",
            entityId: evidenceId,
            action: "upload",
            newState: {
                category: evidenceData.category,
                fileSize: evidenceData.fileSize,
                mimeType: evidenceData.mimeType,
            },
            metadata: { source: "trigger" },
        });
        functions.logger.info("Evidence upload trigger completed", {
            evidenceId,
        });
        return { success: true, evidenceId };
    }
    catch (error) {
        functions.logger.error("Evidence upload trigger failed", {
            evidenceId,
            error,
        });
        throw error;
    }
});
// ============================================================================
// onSmartCreditConnectionChange - Track SmartCredit connection status
// ============================================================================
exports.onSmartCreditConnectionChange = functions.firestore
    .document("smartCreditConnections/{connectionId}")
    .onUpdate(async (change, context) => {
    const connectionId = context.params.connectionId;
    const before = change.before.data();
    const after = change.after.data();
    const statusChanged = before.status !== after.status;
    if (!statusChanged) {
        return null;
    }
    try {
        functions.logger.info("SmartCredit connection status change", {
            connectionId,
            previousStatus: before.status,
            newStatus: after.status,
        });
        // Log the status change
        await (0, audit_1.logAuditEvent)({
            tenantId: after.tenantId,
            actor: {
                userId: "system",
                role: "operator",
            },
            entity: "smartcredit_connection",
            entityId: connectionId,
            action: "status_change",
            previousState: { status: before.status },
            newState: { status: after.status },
            metadata: { source: "trigger" },
        });
        // Notify if connection becomes expired or revoked
        if (after.status === "expired" || after.status === "revoked") {
            await createNotification(after.tenantId, "smartcredit_disconnected", "SmartCredit Connection Lost", `SmartCredit connection for consumer ${after.consumerId} is ${after.status}`, {
                connectionId,
                consumerId: after.consumerId,
                status: after.status,
            });
        }
        return { success: true, connectionId };
    }
    catch (error) {
        functions.logger.error("SmartCredit connection change trigger failed", {
            connectionId,
            error,
        });
        throw error;
    }
});
//# sourceMappingURL=index.js.map