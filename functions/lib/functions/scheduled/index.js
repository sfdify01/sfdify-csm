"use strict";
/**
 * Scheduled Cloud Functions
 *
 * Handles periodic background tasks like SLA monitoring, report refresh,
 * reconciliation, and billing aggregation.
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
exports.scheduledCleanup = exports.scheduledBillingAggregator = exports.scheduledReconciliation = exports.scheduledReportRefresh = exports.scheduledSlaChecker = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const firestore_1 = require("firebase-admin/firestore");
const config_1 = require("../../config");
const audit_1 = require("../../utils/audit");
const emailService_1 = require("../../services/emailService");
const smsService_1 = require("../../services/smsService");
const uuid_1 = require("uuid");
// ============================================================================
// Constants
// ============================================================================
const BATCH_SIZE = 100;
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Get tenant notification recipients (owners and operators)
 */
async function getTenantNotifyUsers(tenantId) {
    const usersSnapshot = await admin_1.db
        .collection("users")
        .where("tenantId", "==", tenantId)
        .where("role", "in", ["owner", "operator"])
        .where("disabled", "==", false)
        .get();
    return usersSnapshot.docs.map((doc) => {
        const user = doc.data();
        return {
            email: user.email,
            phone: undefined, // Would get from user profile
            role: user.role,
        };
    });
}
/**
 * Get consumer name and info for notifications
 */
async function getConsumerInfo(consumerId) {
    const consumerDoc = await admin_1.db.collection("consumers").doc(consumerId).get();
    if (!consumerDoc.exists) {
        return { name: "Consumer" };
    }
    const consumer = consumerDoc.data();
    const primaryEmail = consumer.emails?.find((e) => e.isPrimary);
    const primaryPhone = consumer.phones?.find((p) => p.isPrimary);
    return {
        name: "Consumer", // PII is encrypted, would need to decrypt for display
        email: primaryEmail?.address,
        phone: primaryPhone?.number,
    };
}
/**
 * Send notification to users via email and SMS
 */
async function sendNotification(tenantId, type, data) {
    // Create notification record
    const notificationId = (0, uuid_1.v4)();
    const notificationRecord = {
        id: notificationId,
        tenantId,
        type,
        data,
        status: "pending",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        channels: ["email"],
        deliveryResults: [],
    };
    await admin_1.db.collection("notifications").doc(notificationId).set(notificationRecord);
    // Get recipients
    const recipients = await getTenantNotifyUsers(tenantId);
    const deliveryResults = [];
    // Get consumer info if available
    let consumerName = "Consumer";
    if (data.consumerId) {
        const consumerInfo = await getConsumerInfo(data.consumerId);
        consumerName = consumerInfo.name;
    }
    // Send emails based on notification type
    for (const recipient of recipients) {
        try {
            switch (type) {
                case "sla_warning":
                    const slaResult = await emailService_1.emailService.sendSlaReminder(recipient.email, {
                        consumerName,
                        disputeId: data.disputeId,
                        bureau: data.bureau || "Bureau",
                        daysRemaining: data.daysUntilDue,
                        dueDate: data.dueAt,
                        disputeUrl: `https://app.sfdify.com/disputes/${data.disputeId}`,
                    });
                    deliveryResults.push({
                        channel: "email",
                        success: slaResult.success,
                        error: slaResult.error,
                    });
                    // Also send SMS for urgent SLA reminders (1 day or less)
                    if (data.daysUntilDue <= 1 && recipient.phone) {
                        const smsResult = await smsService_1.smsService.sendSlaReminder(recipient.phone, data.daysUntilDue, data.bureau || "Bureau");
                        deliveryResults.push({
                            channel: "sms",
                            success: smsResult.success,
                            error: smsResult.error,
                        });
                    }
                    break;
                case "sla_breach":
                    const breachResult = await emailService_1.emailService.send({
                        to: recipient.email,
                        subject: `URGENT: SLA Breach - Dispute ${data.disputeId}`,
                        text: `A dispute for ${consumerName} has breached its SLA deadline. The dispute was due on ${data.dueAt} and is now ${data.daysOverdue} days overdue. Please take immediate action.`,
                        categories: ["sla-breach", "urgent"],
                    });
                    deliveryResults.push({
                        channel: "email",
                        success: breachResult.success,
                        error: breachResult.error,
                    });
                    break;
                case "report_available":
                    const reportResult = await emailService_1.emailService.send({
                        to: recipient.email,
                        subject: `Credit Report Available - ${consumerName}`,
                        text: `A new credit report is available for ${consumerName}. Log in to view the details.`,
                        categories: ["credit-report"],
                    });
                    deliveryResults.push({
                        channel: "email",
                        success: reportResult.success,
                        error: reportResult.error,
                    });
                    break;
                case "billing_due":
                    const billingResult = await emailService_1.emailService.send({
                        to: recipient.email,
                        subject: `Monthly Invoice Ready - ${data.period}`,
                        text: `Your monthly invoice for ${data.period} is ready. Total due: $${data.total}. Log in to view details and pay.`,
                        categories: ["billing"],
                    });
                    deliveryResults.push({
                        channel: "email",
                        success: billingResult.success,
                        error: billingResult.error,
                    });
                    break;
            }
        }
        catch (error) {
            functions.logger.error("Failed to send notification", {
                notificationId,
                recipient: recipient.email,
                type,
                error,
            });
            deliveryResults.push({
                channel: "email",
                success: false,
                error: error instanceof Error ? error.message : "Unknown error",
            });
        }
    }
    // Update notification record with results
    const allSuccessful = deliveryResults.every((r) => r.success);
    await admin_1.db.collection("notifications").doc(notificationId).update({
        status: allSuccessful ? "sent" : "partial",
        deliveryResults,
        sentAt: firestore_1.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Notification processed", {
        notificationId,
        tenantId,
        type,
        recipientCount: recipients.length,
        successCount: deliveryResults.filter((r) => r.success).length,
    });
}
// ============================================================================
// scheduledSlaChecker - Check SLA deadlines
// ============================================================================
exports.scheduledSlaChecker = functions.pubsub
    .schedule("every 1 hours")
    .timeZone("America/New_York")
    .onRun(async () => {
    const now = new Date();
    const stats = {
        checked: 0,
        warningsSent: 0,
        breachesSent: 0,
        autoClosedCount: 0,
        errors: 0,
    };
    try {
        // Calculate warning threshold (5 days before due)
        const warningThreshold = new Date(now);
        warningThreshold.setDate(now.getDate() + config_1.slaConfig.reminderDays[0]);
        // Get all active disputes approaching SLA
        const activeStatuses = [
            "draft",
            "pending_review",
            "approved",
            "mailed",
            "delivered",
            "bureau_investigating",
        ];
        // Query disputes due within warning window
        const upcomingDeadlineQuery = await admin_1.db
            .collection("disputes")
            .where("status", "in", activeStatuses)
            .where("timestamps.dueAt", "<=", firestore_1.Timestamp.fromDate(warningThreshold))
            .where("timestamps.dueAt", ">=", firestore_1.Timestamp.fromDate(now))
            .limit(BATCH_SIZE)
            .get();
        // Process upcoming deadlines
        for (const doc of upcomingDeadlineQuery.docs) {
            try {
                const dispute = { id: doc.id, ...doc.data() };
                const dueAt = (dispute.timestamps?.dueAt).toDate();
                const daysUntilDue = Math.ceil((dueAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
                // Check if we should send reminder (at 5, 3, and 1 days)
                if (config_1.slaConfig.reminderDays.includes(daysUntilDue)) {
                    // Check if reminder already sent
                    const reminderKey = `sla_warning_${daysUntilDue}_days`;
                    const existingNotification = await admin_1.db
                        .collection("notifications")
                        .where("data.disputeId", "==", dispute.id)
                        .where("type", "==", "sla_warning")
                        .where("data.reminderKey", "==", reminderKey)
                        .limit(1)
                        .get();
                    if (existingNotification.empty) {
                        await sendNotification(dispute.tenantId, "sla_warning", {
                            disputeId: dispute.id,
                            consumerId: dispute.consumerId,
                            dueAt: dueAt.toISOString(),
                            daysUntilDue,
                            reminderKey,
                        });
                        stats.warningsSent++;
                    }
                }
                stats.checked++;
            }
            catch (error) {
                functions.logger.error("Error processing dispute for SLA warning", {
                    disputeId: doc.id,
                    error,
                });
                stats.errors++;
            }
        }
        // Query overdue disputes
        const overdueQuery = await admin_1.db
            .collection("disputes")
            .where("status", "in", activeStatuses)
            .where("timestamps.dueAt", "<", firestore_1.Timestamp.fromDate(now))
            .limit(BATCH_SIZE)
            .get();
        // Process overdue disputes
        for (const doc of overdueQuery.docs) {
            try {
                const dispute = { id: doc.id, ...doc.data() };
                const dueAt = (dispute.timestamps?.dueAt).toDate();
                const daysOverdue = Math.ceil((now.getTime() - dueAt.getTime()) / (1000 * 60 * 60 * 24));
                // Send breach notification if not already sent
                const breachNotification = await admin_1.db
                    .collection("notifications")
                    .where("data.disputeId", "==", dispute.id)
                    .where("type", "==", "sla_breach")
                    .limit(1)
                    .get();
                if (breachNotification.empty) {
                    await sendNotification(dispute.tenantId, "sla_breach", {
                        disputeId: dispute.id,
                        consumerId: dispute.consumerId,
                        dueAt: dueAt.toISOString(),
                        daysOverdue,
                    });
                    stats.breachesSent++;
                }
                // Auto-close if significantly overdue (beyond grace period)
                if (daysOverdue > config_1.slaConfig.followUpGraceDays + 30) {
                    // 30+ days overdue
                    await admin_1.db.collection("disputes").doc(doc.id).update({
                        status: "closed",
                        "resolution.outcome": "unresolved",
                        "resolution.reason": "SLA timeout - auto-closed",
                        "timestamps.closedAt": firestore_1.FieldValue.serverTimestamp(),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    // Audit log
                    await (0, audit_1.logAuditEvent)({
                        tenantId: dispute.tenantId,
                        actor: {
                            userId: "system",
                            email: "scheduler@sfdify.com",
                            role: "owner",
                        },
                        entity: "dispute",
                        entityId: doc.id,
                        action: "auto_close",
                        previousState: { status: dispute.status },
                        newState: { status: "closed" },
                        metadata: {
                            reason: "SLA timeout",
                            daysOverdue,
                        },
                    });
                    stats.autoClosedCount++;
                }
                stats.checked++;
            }
            catch (error) {
                functions.logger.error("Error processing overdue dispute", {
                    disputeId: doc.id,
                    error,
                });
                stats.errors++;
            }
        }
        functions.logger.info("SLA checker completed", stats);
        return stats;
    }
    catch (error) {
        functions.logger.error("SLA checker failed", { error });
        throw error;
    }
});
// ============================================================================
// scheduledReportRefresh - Refresh credit reports periodically
// ============================================================================
exports.scheduledReportRefresh = functions.pubsub
    .schedule("every 24 hours")
    .timeZone("America/New_York")
    .onRun(async () => {
    const stats = {
        checked: 0,
        refreshQueued: 0,
        errors: 0,
    };
    try {
        // Calculate refresh threshold (reports older than 7 days)
        const refreshThreshold = new Date();
        refreshThreshold.setDate(refreshThreshold.getDate() - 7);
        // Query active SmartCredit connections that need refresh
        const connectionsQuery = await admin_1.db
            .collection("smartCreditConnections")
            .where("status", "==", "connected")
            .limit(BATCH_SIZE)
            .get();
        for (const doc of connectionsQuery.docs) {
            try {
                const connection = { id: doc.id, ...doc.data() };
                stats.checked++;
                // Check if refresh is needed based on lastRefreshedAt
                const lastRefreshed = connection.lastRefreshedAt;
                if (!lastRefreshed || lastRefreshed.toDate() < refreshThreshold) {
                    // Get the consumer for tenant info
                    const consumerDoc = await admin_1.db
                        .collection("consumers")
                        .doc(connection.consumerId)
                        .get();
                    if (!consumerDoc.exists) {
                        functions.logger.warn("Consumer not found for connection", {
                            connectionId: connection.id,
                            consumerId: connection.consumerId,
                        });
                        continue;
                    }
                    const consumer = { id: consumerDoc.id, ...consumerDoc.data() };
                    // Queue refresh request
                    const requestId = (0, uuid_1.v4)();
                    await admin_1.db.collection("scheduledTasks").doc(requestId).set({
                        id: requestId,
                        type: "report_refresh",
                        tenantId: consumer.tenantId,
                        entityType: "consumer",
                        entityId: consumer.id,
                        status: "pending",
                        scheduledFor: firestore_1.FieldValue.serverTimestamp(),
                        createdAt: firestore_1.FieldValue.serverTimestamp(),
                        data: {
                            consumerId: consumer.id,
                            connectionId: connection.id,
                        },
                    });
                    stats.refreshQueued++;
                    functions.logger.info("Queued report refresh", {
                        consumerId: consumer.id,
                        connectionId: connection.id,
                        lastRefreshed: lastRefreshed?.toDate().toISOString(),
                    });
                }
            }
            catch (error) {
                functions.logger.error("Error queuing report refresh", {
                    connectionId: doc.id,
                    error,
                });
                stats.errors++;
            }
        }
        functions.logger.info("Report refresh scheduler completed", stats);
        return stats;
    }
    catch (error) {
        functions.logger.error("Report refresh scheduler failed", { error });
        throw error;
    }
});
// ============================================================================
// scheduledReconciliation - Reconcile letter statuses with Lob
// ============================================================================
exports.scheduledReconciliation = functions.pubsub
    .schedule("every 6 hours")
    .timeZone("America/New_York")
    .onRun(async () => {
    const stats = {
        checked: 0,
        discrepancies: 0,
        errors: 0,
    };
    try {
        // Query letters in transit or pending status for more than expected time
        const staleThreshold = new Date();
        staleThreshold.setDate(staleThreshold.getDate() - 14); // 14 days
        const staleLettersQuery = await admin_1.db
            .collection("letters")
            .where("status", "in", ["sent", "in_transit", "queued"])
            .where("sentAt", "<", firestore_1.Timestamp.fromDate(staleThreshold))
            .limit(BATCH_SIZE)
            .get();
        for (const doc of staleLettersQuery.docs) {
            try {
                const letter = { id: doc.id, ...doc.data() };
                stats.checked++;
                // Log stale letter for review
                if (letter.lobId) {
                    // Create reconciliation task to check Lob status
                    const taskId = (0, uuid_1.v4)();
                    await admin_1.db.collection("scheduledTasks").doc(taskId).set({
                        id: taskId,
                        type: "lob_reconciliation",
                        tenantId: letter.tenantId,
                        entityType: "letter",
                        entityId: letter.id,
                        status: "pending",
                        scheduledFor: firestore_1.FieldValue.serverTimestamp(),
                        createdAt: firestore_1.FieldValue.serverTimestamp(),
                        data: {
                            letterId: letter.id,
                            lobId: letter.lobId,
                            currentStatus: letter.status,
                            sentAt: letter.sentAt,
                        },
                    });
                    stats.discrepancies++;
                }
            }
            catch (error) {
                functions.logger.error("Error checking letter reconciliation", {
                    letterId: doc.id,
                    error,
                });
                stats.errors++;
            }
        }
        // Also check for letters stuck in rendering/queued state
        const stuckThreshold = new Date();
        stuckThreshold.setHours(stuckThreshold.getHours() - 24); // 24 hours
        const stuckLettersQuery = await admin_1.db
            .collection("letters")
            .where("status", "in", ["rendering", "ready", "queued"])
            .where("createdAt", "<", firestore_1.Timestamp.fromDate(stuckThreshold))
            .limit(BATCH_SIZE)
            .get();
        for (const doc of stuckLettersQuery.docs) {
            try {
                const letter = { id: doc.id, ...doc.data() };
                // Create task to investigate stuck letter
                const taskId = (0, uuid_1.v4)();
                await admin_1.db.collection("scheduledTasks").doc(taskId).set({
                    id: taskId,
                    type: "stuck_letter_investigation",
                    tenantId: letter.tenantId,
                    entityType: "letter",
                    entityId: letter.id,
                    status: "pending",
                    scheduledFor: firestore_1.FieldValue.serverTimestamp(),
                    createdAt: firestore_1.FieldValue.serverTimestamp(),
                    data: {
                        letterId: letter.id,
                        currentStatus: letter.status,
                        createdAt: letter.createdAt,
                    },
                });
                stats.discrepancies++;
            }
            catch (error) {
                functions.logger.error("Error checking stuck letter", {
                    letterId: doc.id,
                    error,
                });
                stats.errors++;
            }
        }
        functions.logger.info("Reconciliation scheduler completed", stats);
        return stats;
    }
    catch (error) {
        functions.logger.error("Reconciliation scheduler failed", { error });
        throw error;
    }
});
// ============================================================================
// scheduledBillingAggregator - Monthly billing aggregation
// ============================================================================
exports.scheduledBillingAggregator = functions.pubsub
    .schedule("0 0 1 * *") // First day of each month at midnight
    .timeZone("America/New_York")
    .onRun(async () => {
    const stats = {
        tenantsProcessed: 0,
        recordsCreated: 0,
        errors: 0,
    };
    try {
        // Get previous month's date range
        const now = new Date();
        const periodEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
        const periodStart = new Date(periodEnd.getFullYear(), periodEnd.getMonth(), 1);
        // Get all active tenants
        const tenantsQuery = await admin_1.db
            .collection("tenants")
            .where("status", "==", "active")
            .get();
        for (const tenantDoc of tenantsQuery.docs) {
            try {
                const tenant = { id: tenantDoc.id, ...tenantDoc.data() };
                stats.tenantsProcessed++;
                // Count letters sent
                const lettersQuery = await admin_1.db
                    .collection("letters")
                    .where("tenantId", "==", tenant.id)
                    .where("sentAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
                    .where("sentAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
                    .get();
                const letterCounts = {
                    uspsFirstClass: 0,
                    uspsCertified: 0,
                    uspsCertifiedReturnReceipt: 0,
                    total: lettersQuery.size,
                };
                let totalLetterCost = 0;
                lettersQuery.docs.forEach((doc) => {
                    const letter = doc.data();
                    if (letter.mailType === "usps_first_class")
                        letterCounts.uspsFirstClass++;
                    else if (letter.mailType === "usps_certified")
                        letterCounts.uspsCertified++;
                    else if (letter.mailType === "usps_certified_return_receipt")
                        letterCounts.uspsCertifiedReturnReceipt++;
                    if (letter.cost?.total)
                        totalLetterCost += letter.cost.total;
                });
                // Count disputes
                const disputesCreatedQuery = await admin_1.db
                    .collection("disputes")
                    .where("tenantId", "==", tenant.id)
                    .where("timestamps.createdAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
                    .where("timestamps.createdAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
                    .count()
                    .get();
                const disputesResolvedQuery = await admin_1.db
                    .collection("disputes")
                    .where("tenantId", "==", tenant.id)
                    .where("timestamps.resolvedAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
                    .where("timestamps.resolvedAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
                    .count()
                    .get();
                // Count consumers
                const activeConsumersQuery = await admin_1.db
                    .collection("consumers")
                    .where("tenantId", "==", tenant.id)
                    .where("disabled", "==", false)
                    .count()
                    .get();
                // Calculate storage usage
                const evidenceQuery = await admin_1.db
                    .collection("evidence")
                    .where("tenantId", "==", tenant.id)
                    .get();
                const storageUsed = evidenceQuery.docs.reduce((total, doc) => total + (doc.data().fileSize || 0), 0);
                // Calculate costs
                const planPricing = {
                    starter: 99,
                    professional: 299,
                    enterprise: 999,
                };
                const storageLimits = {
                    starter: 5 * 1024 * 1024 * 1024,
                    professional: 25 * 1024 * 1024 * 1024,
                    enterprise: 100 * 1024 * 1024 * 1024,
                };
                const subscriptionCost = planPricing[tenant.plan] || 99;
                const storageLimit = storageLimits[tenant.plan] || storageLimits.starter;
                let overageCost = 0;
                if (storageUsed > storageLimit) {
                    const overageGB = (storageUsed - storageLimit) / (1024 * 1024 * 1024);
                    overageCost = Math.ceil(overageGB) * 5;
                }
                // Create billing record
                const recordId = (0, uuid_1.v4)();
                await admin_1.db.collection("billingRecords").doc(recordId).set({
                    id: recordId,
                    tenantId: tenant.id,
                    period: {
                        start: firestore_1.Timestamp.fromDate(periodStart),
                        end: firestore_1.Timestamp.fromDate(periodEnd),
                        month: `${periodEnd.getFullYear()}-${String(periodEnd.getMonth() + 1).padStart(2, "0")}`,
                    },
                    usage: {
                        letters: letterCounts,
                        disputes: {
                            created: disputesCreatedQuery.data().count,
                            resolved: disputesResolvedQuery.data().count,
                        },
                        consumers: {
                            active: activeConsumersQuery.data().count,
                        },
                        storage: {
                            usedBytes: storageUsed,
                            limitBytes: storageLimit,
                        },
                    },
                    costs: {
                        letters: totalLetterCost,
                        subscription: subscriptionCost,
                        overage: overageCost,
                        total: totalLetterCost + subscriptionCost + overageCost,
                        currency: "USD",
                    },
                    plan: tenant.plan,
                    status: "pending",
                    createdAt: firestore_1.FieldValue.serverTimestamp(),
                });
                stats.recordsCreated++;
                // Notify tenant of new bill
                await sendNotification(tenant.id, "billing_due", {
                    billingRecordId: recordId,
                    period: `${periodEnd.getFullYear()}-${String(periodEnd.getMonth() + 1).padStart(2, "0")}`,
                    total: totalLetterCost + subscriptionCost + overageCost,
                });
                functions.logger.info("Created billing record for tenant", {
                    tenantId: tenant.id,
                    recordId,
                    total: totalLetterCost + subscriptionCost + overageCost,
                });
            }
            catch (error) {
                functions.logger.error("Error processing tenant billing", {
                    tenantId: tenantDoc.id,
                    error,
                });
                stats.errors++;
            }
        }
        functions.logger.info("Billing aggregator completed", stats);
        return stats;
    }
    catch (error) {
        functions.logger.error("Billing aggregator failed", { error });
        throw error;
    }
});
// ============================================================================
// scheduledCleanup - Clean up old data (runs weekly)
// ============================================================================
exports.scheduledCleanup = functions.pubsub
    .schedule("every sunday 03:00")
    .timeZone("America/New_York")
    .onRun(async () => {
    const stats = {
        webhooksDeleted: 0,
        notificationsDeleted: 0,
        tasksDeleted: 0,
        errors: 0,
    };
    try {
        // Delete processed webhook events older than 90 days
        const webhookThreshold = new Date();
        webhookThreshold.setDate(webhookThreshold.getDate() - 90);
        const oldWebhooksQuery = await admin_1.db
            .collection("webhookEvents")
            .where("status", "in", ["processed", "invalid_signature"])
            .where("receivedAt", "<", firestore_1.Timestamp.fromDate(webhookThreshold))
            .limit(BATCH_SIZE)
            .get();
        const batch1 = admin_1.db.batch();
        oldWebhooksQuery.docs.forEach((doc) => {
            batch1.delete(doc.ref);
            stats.webhooksDeleted++;
        });
        await batch1.commit();
        // Delete old notifications (sent more than 30 days ago)
        const notificationThreshold = new Date();
        notificationThreshold.setDate(notificationThreshold.getDate() - 30);
        const oldNotificationsQuery = await admin_1.db
            .collection("notifications")
            .where("status", "==", "sent")
            .where("createdAt", "<", firestore_1.Timestamp.fromDate(notificationThreshold))
            .limit(BATCH_SIZE)
            .get();
        const batch2 = admin_1.db.batch();
        oldNotificationsQuery.docs.forEach((doc) => {
            batch2.delete(doc.ref);
            stats.notificationsDeleted++;
        });
        await batch2.commit();
        // Delete completed scheduled tasks older than 30 days
        const taskThreshold = new Date();
        taskThreshold.setDate(taskThreshold.getDate() - 30);
        const oldTasksQuery = await admin_1.db
            .collection("scheduledTasks")
            .where("status", "in", ["completed", "cancelled"])
            .where("createdAt", "<", firestore_1.Timestamp.fromDate(taskThreshold))
            .limit(BATCH_SIZE)
            .get();
        const batch3 = admin_1.db.batch();
        oldTasksQuery.docs.forEach((doc) => {
            batch3.delete(doc.ref);
            stats.tasksDeleted++;
        });
        await batch3.commit();
        functions.logger.info("Cleanup scheduler completed", stats);
        return stats;
    }
    catch (error) {
        functions.logger.error("Cleanup scheduler failed", { error });
        throw error;
    }
});
//# sourceMappingURL=index.js.map