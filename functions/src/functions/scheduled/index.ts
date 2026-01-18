/**
 * Scheduled Cloud Functions
 *
 * Handles periodic background tasks like SLA monitoring, report refresh,
 * reconciliation, and billing aggregation.
 */

import * as functions from "firebase-functions";
import { db } from "../../admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { slaConfig } from "../../config";
import { logAuditEvent } from "../../utils/audit";
import { emailService } from "../../services/emailService";
import { smsService } from "../../services/smsService";
import { Dispute, Consumer, Letter, Tenant, SmartCreditConnection, User } from "../../types";
import { v4 as uuidv4 } from "uuid";

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
async function getTenantNotifyUsers(
  tenantId: string
): Promise<Array<{ email: string; phone?: string; role: string }>> {
  const usersSnapshot = await db
    .collection("users")
    .where("tenantId", "==", tenantId)
    .where("role", "in", ["owner", "operator"])
    .where("disabled", "==", false)
    .get();

  return usersSnapshot.docs.map((doc) => {
    const user = doc.data() as User;
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
async function getConsumerInfo(
  consumerId: string
): Promise<{ name: string; email?: string; phone?: string }> {
  const consumerDoc = await db.collection("consumers").doc(consumerId).get();
  if (!consumerDoc.exists) {
    return { name: "Consumer" };
  }
  const consumer = consumerDoc.data() as Consumer;
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
async function sendNotification(
  tenantId: string,
  type: "sla_warning" | "sla_breach" | "report_available" | "billing_due",
  data: Record<string, unknown>
): Promise<void> {
  // Create notification record
  const notificationId = uuidv4();
  const notificationRecord = {
    id: notificationId,
    tenantId,
    type,
    data,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    channels: ["email"],
    deliveryResults: [] as Array<{ channel: string; success: boolean; error?: string }>,
  };

  await db.collection("notifications").doc(notificationId).set(notificationRecord);

  // Get recipients
  const recipients = await getTenantNotifyUsers(tenantId);
  const deliveryResults: Array<{ channel: string; success: boolean; error?: string }> = [];

  // Get consumer info if available
  let consumerName = "Consumer";
  if (data.consumerId) {
    const consumerInfo = await getConsumerInfo(data.consumerId as string);
    consumerName = consumerInfo.name;
  }

  // Send emails based on notification type
  for (const recipient of recipients) {
    try {
      switch (type) {
        case "sla_warning":
          const slaResult = await emailService.sendSlaReminder(recipient.email, {
            consumerName,
            disputeId: data.disputeId as string,
            bureau: data.bureau as string || "Bureau",
            daysRemaining: data.daysUntilDue as number,
            dueDate: data.dueAt as string,
            disputeUrl: `https://app.ustaxx.com/disputes/${data.disputeId}`,
          });
          deliveryResults.push({
            channel: "email",
            success: slaResult.success,
            error: slaResult.error,
          });

          // Also send SMS for urgent SLA reminders (1 day or less)
          if ((data.daysUntilDue as number) <= 1 && recipient.phone) {
            const smsResult = await smsService.sendSlaReminder(
              recipient.phone,
              data.daysUntilDue as number,
              data.bureau as string || "Bureau"
            );
            deliveryResults.push({
              channel: "sms",
              success: smsResult.success,
              error: smsResult.error,
            });
          }
          break;

        case "sla_breach":
          const breachResult = await emailService.send({
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
          const reportResult = await emailService.send({
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
          const billingResult = await emailService.send({
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
    } catch (error) {
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
  await db.collection("notifications").doc(notificationId).update({
    status: allSuccessful ? "sent" : "partial",
    deliveryResults,
    sentAt: FieldValue.serverTimestamp(),
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

export const scheduledSlaChecker = functions.pubsub
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
      warningThreshold.setDate(now.getDate() + slaConfig.reminderDays[0]);

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
      const upcomingDeadlineQuery = await db
        .collection("disputes")
        .where("status", "in", activeStatuses)
        .where("timestamps.dueAt", "<=", Timestamp.fromDate(warningThreshold))
        .where("timestamps.dueAt", ">=", Timestamp.fromDate(now))
        .limit(BATCH_SIZE)
        .get();

      // Process upcoming deadlines
      for (const doc of upcomingDeadlineQuery.docs) {
        try {
          const dispute = { id: doc.id, ...doc.data() } as Dispute;
          const dueAt = (dispute.timestamps?.dueAt as Timestamp).toDate();
          const daysUntilDue = Math.ceil(
            (dueAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          );

          // Check if we should send reminder (at 5, 3, and 1 days)
          if (slaConfig.reminderDays.includes(daysUntilDue)) {
            // Check if reminder already sent
            const reminderKey = `sla_warning_${daysUntilDue}_days`;
            const existingNotification = await db
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
        } catch (error) {
          functions.logger.error("Error processing dispute for SLA warning", {
            disputeId: doc.id,
            error,
          });
          stats.errors++;
        }
      }

      // Query overdue disputes
      const overdueQuery = await db
        .collection("disputes")
        .where("status", "in", activeStatuses)
        .where("timestamps.dueAt", "<", Timestamp.fromDate(now))
        .limit(BATCH_SIZE)
        .get();

      // Process overdue disputes
      for (const doc of overdueQuery.docs) {
        try {
          const dispute = { id: doc.id, ...doc.data() } as Dispute;
          const dueAt = (dispute.timestamps?.dueAt as Timestamp).toDate();
          const daysOverdue = Math.ceil(
            (now.getTime() - dueAt.getTime()) / (1000 * 60 * 60 * 24)
          );

          // Send breach notification if not already sent
          const breachNotification = await db
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
          if (daysOverdue > slaConfig.followUpGraceDays + 30) {
            // 30+ days overdue
            await db.collection("disputes").doc(doc.id).update({
              status: "closed",
              "resolution.outcome": "unresolved",
              "resolution.reason": "SLA timeout - auto-closed",
              "timestamps.closedAt": FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });

            // Audit log
            await logAuditEvent({
              tenantId: dispute.tenantId,
              actor: {
                userId: "system",
                email: "scheduler@ustaxx.com",
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
        } catch (error) {
          functions.logger.error("Error processing overdue dispute", {
            disputeId: doc.id,
            error,
          });
          stats.errors++;
        }
      }

      functions.logger.info("SLA checker completed", stats);
      return stats;
    } catch (error) {
      functions.logger.error("SLA checker failed", { error });
      throw error;
    }
  });

// ============================================================================
// scheduledReportRefresh - Refresh credit reports periodically
// ============================================================================

export const scheduledReportRefresh = functions.pubsub
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
      const connectionsQuery = await db
        .collection("smartCreditConnections")
        .where("status", "==", "connected")
        .limit(BATCH_SIZE)
        .get();

      for (const doc of connectionsQuery.docs) {
        try {
          const connection = { id: doc.id, ...doc.data() } as SmartCreditConnection;
          stats.checked++;

          // Check if refresh is needed based on lastRefreshedAt
          const lastRefreshed = connection.lastRefreshedAt as Timestamp;
          if (!lastRefreshed || lastRefreshed.toDate() < refreshThreshold) {
            // Get the consumer for tenant info
            const consumerDoc = await db
              .collection("consumers")
              .doc(connection.consumerId as string)
              .get();

            if (!consumerDoc.exists) {
              functions.logger.warn("Consumer not found for connection", {
                connectionId: connection.id,
                consumerId: connection.consumerId,
              });
              continue;
            }

            const consumer = { id: consumerDoc.id, ...consumerDoc.data() } as Consumer;

            // Queue refresh request
            const requestId = uuidv4();
            await db.collection("scheduledTasks").doc(requestId).set({
              id: requestId,
              type: "report_refresh",
              tenantId: consumer.tenantId,
              entityType: "consumer",
              entityId: consumer.id,
              status: "pending",
              scheduledFor: FieldValue.serverTimestamp(),
              createdAt: FieldValue.serverTimestamp(),
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
        } catch (error) {
          functions.logger.error("Error queuing report refresh", {
            connectionId: doc.id,
            error,
          });
          stats.errors++;
        }
      }

      functions.logger.info("Report refresh scheduler completed", stats);
      return stats;
    } catch (error) {
      functions.logger.error("Report refresh scheduler failed", { error });
      throw error;
    }
  });

// ============================================================================
// scheduledReconciliation - Reconcile letter statuses with Lob
// ============================================================================

export const scheduledReconciliation = functions.pubsub
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

      const staleLettersQuery = await db
        .collection("letters")
        .where("status", "in", ["sent", "in_transit", "queued"])
        .where("sentAt", "<", Timestamp.fromDate(staleThreshold))
        .limit(BATCH_SIZE)
        .get();

      for (const doc of staleLettersQuery.docs) {
        try {
          const letter = { id: doc.id, ...doc.data() } as Letter;
          stats.checked++;

          // Log stale letter for review
          if (letter.lobId) {
            // Create reconciliation task to check Lob status
            const taskId = uuidv4();
            await db.collection("scheduledTasks").doc(taskId).set({
              id: taskId,
              type: "lob_reconciliation",
              tenantId: letter.tenantId,
              entityType: "letter",
              entityId: letter.id,
              status: "pending",
              scheduledFor: FieldValue.serverTimestamp(),
              createdAt: FieldValue.serverTimestamp(),
              data: {
                letterId: letter.id,
                lobId: letter.lobId,
                currentStatus: letter.status,
                sentAt: letter.sentAt,
              },
            });

            stats.discrepancies++;
          }
        } catch (error) {
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

      const stuckLettersQuery = await db
        .collection("letters")
        .where("status", "in", ["rendering", "ready", "queued"])
        .where("createdAt", "<", Timestamp.fromDate(stuckThreshold))
        .limit(BATCH_SIZE)
        .get();

      for (const doc of stuckLettersQuery.docs) {
        try {
          const letter = { id: doc.id, ...doc.data() } as Letter;

          // Create task to investigate stuck letter
          const taskId = uuidv4();
          await db.collection("scheduledTasks").doc(taskId).set({
            id: taskId,
            type: "stuck_letter_investigation",
            tenantId: letter.tenantId,
            entityType: "letter",
            entityId: letter.id,
            status: "pending",
            scheduledFor: FieldValue.serverTimestamp(),
            createdAt: FieldValue.serverTimestamp(),
            data: {
              letterId: letter.id,
              currentStatus: letter.status,
              createdAt: letter.createdAt,
            },
          });

          stats.discrepancies++;
        } catch (error) {
          functions.logger.error("Error checking stuck letter", {
            letterId: doc.id,
            error,
          });
          stats.errors++;
        }
      }

      functions.logger.info("Reconciliation scheduler completed", stats);
      return stats;
    } catch (error) {
      functions.logger.error("Reconciliation scheduler failed", { error });
      throw error;
    }
  });

// ============================================================================
// scheduledBillingAggregator - Monthly billing aggregation
// ============================================================================

export const scheduledBillingAggregator = functions.pubsub
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
      const tenantsQuery = await db
        .collection("tenants")
        .where("status", "==", "active")
        .get();

      for (const tenantDoc of tenantsQuery.docs) {
        try {
          const tenant = { id: tenantDoc.id, ...tenantDoc.data() } as Tenant;
          stats.tenantsProcessed++;

          // Count letters sent
          const lettersQuery = await db
            .collection("letters")
            .where("tenantId", "==", tenant.id)
            .where("sentAt", ">=", Timestamp.fromDate(periodStart))
            .where("sentAt", "<=", Timestamp.fromDate(periodEnd))
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
            if (letter.mailType === "usps_first_class") letterCounts.uspsFirstClass++;
            else if (letter.mailType === "usps_certified") letterCounts.uspsCertified++;
            else if (letter.mailType === "usps_certified_return_receipt")
              letterCounts.uspsCertifiedReturnReceipt++;

            if (letter.cost?.total) totalLetterCost += letter.cost.total;
          });

          // Count disputes
          const disputesCreatedQuery = await db
            .collection("disputes")
            .where("tenantId", "==", tenant.id)
            .where("timestamps.createdAt", ">=", Timestamp.fromDate(periodStart))
            .where("timestamps.createdAt", "<=", Timestamp.fromDate(periodEnd))
            .count()
            .get();

          const disputesResolvedQuery = await db
            .collection("disputes")
            .where("tenantId", "==", tenant.id)
            .where("timestamps.resolvedAt", ">=", Timestamp.fromDate(periodStart))
            .where("timestamps.resolvedAt", "<=", Timestamp.fromDate(periodEnd))
            .count()
            .get();

          // Count consumers
          const activeConsumersQuery = await db
            .collection("consumers")
            .where("tenantId", "==", tenant.id)
            .where("disabled", "==", false)
            .count()
            .get();

          // Calculate storage usage
          const evidenceQuery = await db
            .collection("evidence")
            .where("tenantId", "==", tenant.id)
            .get();

          const storageUsed = evidenceQuery.docs.reduce(
            (total, doc) => total + (doc.data().fileSize || 0),
            0
          );

          // Calculate costs
          const planPricing: Record<string, number> = {
            starter: 99,
            professional: 299,
            enterprise: 999,
          };

          const storageLimits: Record<string, number> = {
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
          const recordId = uuidv4();
          await db.collection("billingRecords").doc(recordId).set({
            id: recordId,
            tenantId: tenant.id,
            period: {
              start: Timestamp.fromDate(periodStart),
              end: Timestamp.fromDate(periodEnd),
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
            createdAt: FieldValue.serverTimestamp(),
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
        } catch (error) {
          functions.logger.error("Error processing tenant billing", {
            tenantId: tenantDoc.id,
            error,
          });
          stats.errors++;
        }
      }

      functions.logger.info("Billing aggregator completed", stats);
      return stats;
    } catch (error) {
      functions.logger.error("Billing aggregator failed", { error });
      throw error;
    }
  });

// ============================================================================
// scheduledCleanup - Clean up old data (runs weekly)
// ============================================================================

export const scheduledCleanup = functions.pubsub
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

      const oldWebhooksQuery = await db
        .collection("webhookEvents")
        .where("status", "in", ["processed", "invalid_signature"])
        .where("receivedAt", "<", Timestamp.fromDate(webhookThreshold))
        .limit(BATCH_SIZE)
        .get();

      const batch1 = db.batch();
      oldWebhooksQuery.docs.forEach((doc) => {
        batch1.delete(doc.ref);
        stats.webhooksDeleted++;
      });
      await batch1.commit();

      // Delete old notifications (sent more than 30 days ago)
      const notificationThreshold = new Date();
      notificationThreshold.setDate(notificationThreshold.getDate() - 30);

      const oldNotificationsQuery = await db
        .collection("notifications")
        .where("status", "==", "sent")
        .where("createdAt", "<", Timestamp.fromDate(notificationThreshold))
        .limit(BATCH_SIZE)
        .get();

      const batch2 = db.batch();
      oldNotificationsQuery.docs.forEach((doc) => {
        batch2.delete(doc.ref);
        stats.notificationsDeleted++;
      });
      await batch2.commit();

      // Delete completed scheduled tasks older than 30 days
      const taskThreshold = new Date();
      taskThreshold.setDate(taskThreshold.getDate() - 30);

      const oldTasksQuery = await db
        .collection("scheduledTasks")
        .where("status", "in", ["completed", "cancelled"])
        .where("createdAt", "<", Timestamp.fromDate(taskThreshold))
        .limit(BATCH_SIZE)
        .get();

      const batch3 = db.batch();
      oldTasksQuery.docs.forEach((doc) => {
        batch3.delete(doc.ref);
        stats.tasksDeleted++;
      });
      await batch3.commit();

      functions.logger.info("Cleanup scheduler completed", stats);
      return stats;
    } catch (error) {
      functions.logger.error("Cleanup scheduler failed", { error });
      throw error;
    }
  });
