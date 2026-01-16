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

import * as functions from "firebase-functions";
import { db } from "../../admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logAuditEvent } from "../../utils/audit";
import { slaConfig } from "../../config";
import { Dispute, Letter, Consumer, DisputeStatus, LetterStatus } from "../../types";
import { v4 as uuidv4 } from "uuid";

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Calculate the FCRA-compliant SLA due date
 * Standard: baseDays (30 days)
 * Extended: baseDays + extensionDays (45 days total)
 */
function calculateSlaDueDate(createdAt: Date, isExtended: boolean): Date {
  const dueDate = new Date(createdAt);
  const days = isExtended
    ? slaConfig.baseDays + slaConfig.extensionDays
    : slaConfig.baseDays;
  dueDate.setDate(dueDate.getDate() + days);
  return dueDate;
}

/**
 * Create a notification record
 */
async function createNotification(
  tenantId: string,
  type: string,
  title: string,
  message: string,
  data: Record<string, unknown>
): Promise<void> {
  const notificationId = uuidv4();
  await db.collection("notifications").doc(notificationId).set({
    id: notificationId,
    tenantId,
    type,
    title,
    message,
    data,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    channels: ["email"],
  });
}

/**
 * Update tenant statistics
 */
async function updateTenantStats(
  tenantId: string,
  field: string,
  increment: number
): Promise<void> {
  await db.collection("tenants").doc(tenantId).update({
    [`stats.${field}`]: FieldValue.increment(increment),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

// ============================================================================
// onDisputeCreate - Trigger when a new dispute is created
// ============================================================================

export const onDisputeCreate = functions.firestore
  .document("disputes/{disputeId}")
  .onCreate(async (snapshot, context) => {
    const disputeId = context.params.disputeId;
    const disputeData = snapshot.data() as Omit<Dispute, "id">;

    try {
      functions.logger.info("Dispute created trigger fired", { disputeId });

      const createdAt = (disputeData.timestamps?.createdAt as Timestamp)?.toDate() || new Date();

      // Determine if this is an extended SLA case based on dispute type
      const extendedTypes = ["reinvestigation", "605b_identity_theft"];
      const isExtended = extendedTypes.includes(disputeData.type);

      // Calculate SLA deadline
      const dueAt = calculateSlaDueDate(createdAt, isExtended);
      const warningAt = new Date(dueAt);
      warningAt.setDate(warningAt.getDate() - slaConfig.reminderDays[0]);

      // Update dispute with SLA information
      await snapshot.ref.update({
        "timestamps.dueAt": Timestamp.fromDate(dueAt),
        "sla.baseDays": slaConfig.baseDays,
        "sla.extendedDays": isExtended ? slaConfig.extensionDays : 0,
        "sla.isExtended": isExtended,
      });

      // Create audit log for dispute creation
      await logAuditEvent({
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
          slaBaseDays: slaConfig.baseDays,
        },
      });

      // Update tenant dispute count
      await updateTenantStats(disputeData.tenantId, "totalDisputes", 1);
      await updateTenantStats(disputeData.tenantId, "activeDisputes", 1);

      // Send notification about new dispute
      await createNotification(
        disputeData.tenantId,
        "dispute_created",
        "New Dispute Created",
        `A new dispute has been created for consumer ${disputeData.consumerId}`,
        {
          disputeId,
          consumerId: disputeData.consumerId,
          bureau: disputeData.bureau,
          dueAt: dueAt.toISOString(),
        }
      );

      functions.logger.info("Dispute creation trigger completed", {
        disputeId,
        dueAt: dueAt.toISOString(),
        isExtended,
      });

      return { success: true, disputeId, dueAt };
    } catch (error) {
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

export const onDisputeUpdate = functions.firestore
  .document("disputes/{disputeId}")
  .onUpdate(async (change, context) => {
    const disputeId = context.params.disputeId;
    const before = change.before.data() as Dispute;
    const after = change.after.data() as Dispute;

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
      const previousStatus = before.status as DisputeStatus;
      const newStatus = after.status as DisputeStatus;

      // Log status change
      await logAuditEvent({
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
          const createdAt = (before.timestamps?.createdAt as Timestamp)?.toDate();
          const resolvedAt = new Date();
          if (createdAt) {
            const resolutionDays = Math.ceil(
              (resolvedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24)
            );

            // Update with resolution metrics
            await change.after.ref.update({
              "metrics.resolutionDays": resolutionDays,
              "timestamps.closedAt": FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Check if dispute is overdue and update SLA status
      if (newStatus === "resolved" || newStatus === "closed") {
        const dueAt = (after.timestamps?.dueAt as Timestamp)?.toDate();
        const now = new Date();

        const completedOnTime = dueAt && now <= dueAt;

        await change.after.ref.update({
          "metrics.completedOnTime": completedOnTime,
        });
      }

      // Send notification for important status changes
      const notifiableStatuses: DisputeStatus[] = [
        "approved",
        "mailed",
        "delivered",
        "bureau_investigating",
        "resolved",
      ];

      if (notifiableStatuses.includes(newStatus)) {
        await createNotification(
          after.tenantId,
          "dispute_status_changed",
          "Dispute Status Updated",
          `Dispute ${disputeId} status changed from ${previousStatus} to ${newStatus}`,
          {
            disputeId,
            consumerId: after.consumerId,
            previousStatus,
            newStatus,
          }
        );
      }

      functions.logger.info("Dispute update trigger completed", {
        disputeId,
        statusChanged,
      });

      return { success: true, disputeId };
    } catch (error) {
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

export const onLetterStatusChange = functions.firestore
  .document("letters/{letterId}")
  .onUpdate(async (change, context) => {
    const letterId = context.params.letterId;
    const before = change.before.data() as Letter;
    const after = change.after.data() as Letter;

    const statusChanged = before.status !== after.status;

    if (!statusChanged) {
      return null;
    }

    try {
      const previousStatus = before.status as LetterStatus;
      const newStatus = after.status as LetterStatus;

      functions.logger.info("Letter status change trigger fired", {
        letterId,
        previousStatus,
        newStatus,
      });

      // Log status change
      await logAuditEvent({
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
        const disputeRef = db.collection("disputes").doc(after.disputeId);

        // Update dispute status based on letter status
        const letterToDisputeStatusMap: Partial<Record<LetterStatus, DisputeStatus>> = {
          sent: "mailed",
          in_transit: "mailed",
          delivered: "delivered",
        };

        const mappedDisputeStatus = letterToDisputeStatusMap[newStatus];
        if (mappedDisputeStatus) {
          // Get current dispute to check if we should update
          const disputeDoc = await disputeRef.get();
          if (disputeDoc.exists) {
            const dispute = disputeDoc.data() as Dispute;

            // Only update if the dispute isn't already in a later stage
            const disputeStatusOrder: DisputeStatus[] = [
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
                updatedAt: FieldValue.serverTimestamp(),
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
            "timestamps.deliveredAt": FieldValue.serverTimestamp(),
          });
        }

        // Handle returned letters
        if (newStatus === "returned_to_sender") {
          // Get dispute to find bureau
          const disputeDoc = await disputeRef.get();
          const dispute = disputeDoc.exists ? (disputeDoc.data() as Dispute) : null;

          await createNotification(
            after.tenantId,
            "letter_returned",
            "Letter Returned",
            `Letter was returned to sender - please check the address`,
            {
              letterId,
              disputeId: after.disputeId,
              bureau: dispute?.bureau,
              returnReason: after.returnReason,
            }
          );
        }
      }

      // Send notifications for important letter status changes
      const notifiableStatuses: LetterStatus[] = ["sent", "delivered", "returned_to_sender"];

      if (notifiableStatuses.includes(newStatus)) {
        const messageMap: Partial<Record<LetterStatus, string>> = {
          sent: "has been sent and is in transit",
          delivered: "has been delivered successfully",
          returned_to_sender: "was returned - please check the address",
        };

        // Get dispute info for notification
        let bureau = "bureau";
        if (after.disputeId) {
          const disputeDoc = await db.collection("disputes").doc(after.disputeId).get();
          if (disputeDoc.exists) {
            bureau = (disputeDoc.data() as Dispute).bureau;
          }
        }

        await createNotification(
          after.tenantId,
          "letter_status_changed",
          `Letter ${newStatus.charAt(0).toUpperCase() + newStatus.slice(1).replace("_", " ")}`,
          `Letter to ${bureau} ${messageMap[newStatus]}`,
          {
            letterId,
            disputeId: after.disputeId,
            previousStatus,
            newStatus,
            lobId: after.lobId,
          }
        );
      }

      // Update tenant letter statistics
      if (newStatus === "delivered") {
        await updateTenantStats(after.tenantId, "lettersDelivered", 1);
      } else if (newStatus === "returned_to_sender") {
        await updateTenantStats(after.tenantId, "lettersReturned", 1);
      }

      functions.logger.info("Letter status change trigger completed", {
        letterId,
        newStatus,
      });

      return { success: true, letterId, newStatus };
    } catch (error) {
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

export const onConsumerCreate = functions.firestore
  .document("consumers/{consumerId}")
  .onCreate(async (snapshot, context) => {
    const consumerId = context.params.consumerId;
    const consumerData = snapshot.data() as Omit<Consumer, "id">;

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
      await logAuditEvent({
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
      await createNotification(
        consumerData.tenantId,
        "consumer_created",
        "New Consumer Added",
        "A new consumer has been added to your account",
        {
          consumerId,
          kycStatus: consumerData.kycStatus,
        }
      );

      functions.logger.info("Consumer creation trigger completed", {
        consumerId,
      });

      return { success: true, consumerId };
    } catch (error) {
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

export const onEvidenceUpload = functions.firestore
  .document("evidence/{evidenceId}")
  .onCreate(async (snapshot, context) => {
    const evidenceId = context.params.evidenceId;
    const evidenceData = snapshot.data();

    try {
      functions.logger.info("Evidence upload trigger fired", { evidenceId });

      // Update consumer evidence count
      if (evidenceData.consumerId) {
        await db
          .collection("consumers")
          .doc(evidenceData.consumerId)
          .update({
            "stats.totalEvidence": FieldValue.increment(1),
          });
      }

      // Update dispute evidence count if linked
      if (evidenceData.disputeId) {
        await db
          .collection("disputes")
          .doc(evidenceData.disputeId)
          .update({
            evidenceIds: FieldValue.arrayUnion(evidenceId),
          });
      }

      // Create audit log
      await logAuditEvent({
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
    } catch (error) {
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

export const onSmartCreditConnectionChange = functions.firestore
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
      await logAuditEvent({
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
        await createNotification(
          after.tenantId,
          "smartcredit_disconnected",
          "SmartCredit Connection Lost",
          `SmartCredit connection for consumer ${after.consumerId} is ${after.status}`,
          {
            connectionId,
            consumerId: after.consumerId,
            status: after.status,
          }
        );
      }

      return { success: true, connectionId };
    } catch (error) {
      functions.logger.error("SmartCredit connection change trigger failed", {
        connectionId,
        error,
      });
      throw error;
    }
  });
