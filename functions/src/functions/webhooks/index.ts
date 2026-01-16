/**
 * Webhook Handler Cloud Functions
 *
 * Handles incoming webhooks from external services (Lob, SmartCredit).
 * Implements signature verification and event processing.
 */

import * as functions from "firebase-functions";
import * as crypto from "crypto";
import { db } from "../../admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logAuditEvent } from "../../utils/audit";
import { lobConfig, smartCreditConfig } from "../../config";
import { WebhookEvent, Letter, LetterStatus, Consumer } from "../../types";
import { v4 as uuidv4 } from "uuid";

// ============================================================================
// Types
// ============================================================================

interface LobWebhookPayload {
  id: string;
  event_type: {
    id: string;
    enabled_for_test: boolean;
    resource: string;
    object: string;
  };
  date_created: string;
  object: string;
  body: {
    id: string;
    description?: string;
    metadata?: Record<string, string>;
    mail_type?: string;
    tracking_events?: Array<{
      id: string;
      type: string;
      name: string;
      time: string;
      location?: string;
    }>;
    expected_delivery_date?: string;
    status?: string;
    url?: string;
    carrier?: string;
    tracking_number?: string;
  };
}

interface SmartCreditWebhookPayload {
  event_type: string;
  timestamp: string;
  customer_id: string;
  data: {
    report_id?: string;
    bureau?: string;
    status?: string;
    changes?: Array<{
      field: string;
      old_value: unknown;
      new_value: unknown;
    }>;
  };
  signature: string;
}

// ============================================================================
// Lob Webhook Event Types
// ============================================================================

// Export for reference/documentation
export const LOB_EVENT_TYPES = {
  // Letter events
  "letter.created": "Letter created",
  "letter.rendered_pdf": "Letter PDF rendered",
  "letter.rendered_thumbnails": "Letter thumbnails rendered",
  "letter.deleted": "Letter deleted",
  "letter.delivered": "Letter delivered",
  "letter.failed": "Letter failed",
  "letter.re-routed": "Letter re-routed",
  "letter.returned_to_sender": "Letter returned to sender",
  "letter.certified.mailed": "Certified letter mailed",
  "letter.certified.in_transit": "Certified letter in transit",
  "letter.certified.in_local_area": "Certified letter in local area",
  "letter.certified.processed_for_delivery": "Certified letter processed for delivery",
  "letter.certified.re-routed": "Certified letter re-routed",
  "letter.certified.returned_to_sender": "Certified letter returned to sender",
  "letter.certified.delivered": "Certified letter delivered",
  "letter.certified.pickup_available": "Certified letter pickup available",
  "letter.certified.issue": "Certified letter issue",
} as const;

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Verify Lob webhook signature
 * Lob uses a timestamp + payload signature scheme
 */
function verifyLobSignature(
  payload: string,
  signature: string,
  timestamp: string
): boolean {
  if (!lobConfig.webhookSecret) {
    return false;
  }

  const expectedSignature = crypto
    .createHmac("sha256", lobConfig.webhookSecret)
    .update(`${timestamp}.${payload}`)
    .digest("hex");

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

/**
 * Verify SmartCredit webhook signature
 */
function verifySmartCreditSignature(
  payload: string,
  signature: string
): boolean {
  if (!smartCreditConfig.webhookSecret) {
    return false;
  }

  const expectedSignature = crypto
    .createHmac("sha256", smartCreditConfig.webhookSecret)
    .update(payload)
    .digest("hex");

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

/**
 * Map Lob event type to internal letter status
 */
function mapLobEventToStatus(eventType: string): LetterStatus | null {
  const statusMap: Record<string, LetterStatus> = {
    "letter.created": "queued",
    "letter.rendered_pdf": "ready",
    "letter.certified.mailed": "sent",
    "letter.certified.in_transit": "in_transit",
    "letter.certified.delivered": "delivered",
    "letter.delivered": "delivered",
    "letter.returned_to_sender": "returned_to_sender",
    "letter.certified.returned_to_sender": "returned_to_sender",
    "letter.failed": "returned_to_sender",
    "letter.certified.issue": "returned_to_sender",
  };

  return statusMap[eventType] || null;
}

/**
 * Store webhook event for processing and audit
 */
async function storeWebhookEvent(
  provider: "lob" | "smartcredit",
  eventType: string,
  resourceType: string,
  resourceId: string,
  payload: unknown,
  signature: string,
  signatureValid: boolean,
  tenantId?: string,
  internalResourceId?: string
): Promise<string> {
  const eventId = uuidv4();
  const now = FieldValue.serverTimestamp();

  const webhookEvent: Partial<WebhookEvent> = {
    id: eventId,
    tenantId: tenantId || "unknown",
    provider,
    eventType,
    resourceType,
    resourceId,
    internalResourceId,
    payload,
    signature,
    signatureValid,
    receivedAt: now as unknown as Timestamp,
  };

  await db.collection("webhookEvents").doc(eventId).set({
    ...webhookEvent,
    status: signatureValid ? "pending" : "invalid_signature",
    processedAt: null,
    error: null,
  });

  return eventId;
}

// ============================================================================
// webhooksLob - Lob webhook handler for letter status updates
// ============================================================================

export const webhooksLob = functions.https.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    // Get signature headers
    const lobSignature = req.headers["lob-signature"] as string;
    const lobTimestamp = req.headers["lob-signature-timestamp"] as string;

    const rawBody = JSON.stringify(req.body);
    const payload = req.body as LobWebhookPayload;

    // Verify signature if webhook secret is configured
    let signatureValid = true;
    if (lobConfig.webhookSecret && lobSignature && lobTimestamp) {
      signatureValid = verifyLobSignature(rawBody, lobSignature, lobTimestamp);
    }

    // Extract event information
    const eventType = payload.event_type?.id || "unknown";
    const resourceType = payload.event_type?.resource || "letter";
    const resourceId = payload.body?.id || "unknown";

    // Look up internal letter by Lob ID
    let tenantId: string | undefined;
    let internalLetterId: string | undefined;
    let letter: Letter | undefined;

    if (resourceType === "letter" && resourceId !== "unknown") {
      const letterQuery = await db
        .collection("letters")
        .where("lobId", "==", resourceId)
        .limit(1)
        .get();

      if (!letterQuery.empty) {
        const letterDoc = letterQuery.docs[0];
        letter = { id: letterDoc.id, ...letterDoc.data() } as Letter;
        internalLetterId = letter.id;
        tenantId = letter.tenantId;
      }
    }

    // Store webhook event
    const webhookEventId = await storeWebhookEvent(
      "lob",
      eventType,
      resourceType,
      resourceId,
      payload,
      lobSignature || "",
      signatureValid,
      tenantId,
      internalLetterId
    );

    // If signature is invalid, stop processing
    if (!signatureValid) {
      functions.logger.warn("Invalid Lob webhook signature", {
        eventType,
        resourceId,
        webhookEventId
      });
      res.status(401).json({ error: "Invalid signature" });
      return;
    }

    // Process the event if we found the letter
    if (letter && internalLetterId && tenantId) {
      const newStatus = mapLobEventToStatus(eventType);

      if (newStatus && newStatus !== letter.status) {
        // Update letter status
        const updates: Record<string, unknown> = {
          status: newStatus,
          updatedAt: FieldValue.serverTimestamp(),
        };

        // Add tracking information if available
        if (payload.body?.tracking_number) {
          updates.trackingCode = payload.body.tracking_number;
        }
        if (payload.body?.url) {
          updates.trackingUrl = payload.body.url;
        }

        // Add delivery event
        const deliveryEvent = {
          event: eventType,
          timestamp: FieldValue.serverTimestamp(),
          location: payload.body?.tracking_events?.[0]?.location,
        };

        updates.deliveryEvents = FieldValue.arrayUnion(deliveryEvent);

        // Update specific timestamps
        if (newStatus === "sent") {
          updates.sentAt = FieldValue.serverTimestamp();
        } else if (newStatus === "delivered") {
          updates.deliveredAt = FieldValue.serverTimestamp();
        }

        // Add to status history
        updates.statusHistory = FieldValue.arrayUnion({
          status: newStatus,
          timestamp: FieldValue.serverTimestamp(),
          by: "system",
        });

        await db.collection("letters").doc(internalLetterId).update(updates);

        // Update webhook event as processed
        await db.collection("webhookEvents").doc(webhookEventId).update({
          status: "processed",
          processedAt: FieldValue.serverTimestamp(),
        });

        // Audit log
        await logAuditEvent({
          tenantId,
          actor: {
            userId: "system",
            email: "webhook@lob.com",
            role: "owner", // System actions use owner role
          },
          entity: "letter",
          entityId: internalLetterId,
          action: "status_change",
          previousState: { status: letter.status },
          newState: { status: newStatus },
          metadata: {
            source: "lob_webhook",
            eventType,
            lobId: resourceId,
            webhookEventId,
          },
        });

        // Update associated dispute status if letter is delivered
        if (newStatus === "delivered" && letter.disputeId) {
          const disputeRef = db.collection("disputes").doc(letter.disputeId);
          const disputeDoc = await disputeRef.get();

          if (disputeDoc.exists) {
            const dispute = disputeDoc.data()!;
            if (dispute.status === "mailed") {
              await disputeRef.update({
                status: "delivered",
                "timestamps.deliveredAt": FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
              });
            }
          }
        }

        functions.logger.info("Processed Lob webhook", {
          eventType,
          letterId: internalLetterId,
          newStatus,
          webhookEventId,
        });
      }
    } else {
      // Letter not found - mark webhook for manual review
      await db.collection("webhookEvents").doc(webhookEventId).update({
        status: "unmatched",
        error: "No matching letter found for Lob ID",
      });

      functions.logger.warn("Lob webhook - letter not found", {
        eventType,
        lobId: resourceId,
        webhookEventId,
      });
    }

    res.status(200).json({
      success: true,
      eventId: webhookEventId,
      processed: !!letter,
    });
  } catch (error) {
    functions.logger.error("Error processing Lob webhook", { error });
    res.status(500).json({ error: "Internal server error" });
  }
});

// ============================================================================
// webhooksSmartCredit - SmartCredit webhook handler for report updates
// ============================================================================

export const webhooksSmartCredit = functions.https.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    const rawBody = JSON.stringify(req.body);
    const payload = req.body as SmartCreditWebhookPayload;

    // Verify signature
    let signatureValid = true;
    if (smartCreditConfig.webhookSecret && payload.signature) {
      signatureValid = verifySmartCreditSignature(rawBody, payload.signature);
    }

    // Extract event information
    const eventType = payload.event_type || "unknown";
    const customerId = payload.customer_id || "unknown";
    const resourceType = "consumer";

    // Look up internal consumer by SmartCredit customer ID
    let tenantId: string | undefined;
    let internalConsumerId: string | undefined;
    let consumer: Consumer | undefined;

    if (customerId !== "unknown") {
      // Query consumers with SmartCredit connection
      const consumersQuery = await db
        .collection("consumers")
        .where("smartCredit.memberId", "==", customerId)
        .limit(1)
        .get();

      if (!consumersQuery.empty) {
        const consumerDoc = consumersQuery.docs[0];
        consumer = { id: consumerDoc.id, ...consumerDoc.data() } as Consumer;
        internalConsumerId = consumer.id;
        tenantId = consumer.tenantId;
      }
    }

    // Store webhook event
    const webhookEventId = await storeWebhookEvent(
      "smartcredit",
      eventType,
      resourceType,
      customerId,
      payload,
      payload.signature || "",
      signatureValid,
      tenantId,
      internalConsumerId
    );

    // If signature is invalid, stop processing
    if (!signatureValid) {
      functions.logger.warn("Invalid SmartCredit webhook signature", {
        eventType,
        customerId,
        webhookEventId,
      });
      res.status(401).json({ error: "Invalid signature" });
      return;
    }

    // Process the event if we found the consumer
    if (consumer && internalConsumerId && tenantId) {
      switch (eventType) {
        case "report.available":
        case "report.refreshed": {
          // Update consumer's SmartCredit status
          await db.collection("consumers").doc(internalConsumerId).update({
            "smartCredit.lastRefreshed": FieldValue.serverTimestamp(),
            "smartCredit.reportAvailable": true,
            updatedAt: FieldValue.serverTimestamp(),
          });

          // Create a credit report record if report data is provided
          if (payload.data?.report_id) {
            const reportId = uuidv4();
            await db.collection("creditReports").doc(reportId).set({
              id: reportId,
              tenantId,
              consumerId: internalConsumerId,
              smartCreditReportId: payload.data.report_id,
              bureau: payload.data.bureau || "all",
              pulledAt: FieldValue.serverTimestamp(),
              status: "available",
              source: "webhook",
            });
          }

          functions.logger.info("Processed SmartCredit report webhook", {
            eventType,
            consumerId: internalConsumerId,
            webhookEventId,
          });
          break;
        }

        case "score.changed": {
          // Log score change for analytics
          await db.collection("consumers").doc(internalConsumerId).update({
            "smartCredit.lastScoreChange": FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });

          functions.logger.info("Processed SmartCredit score change", {
            consumerId: internalConsumerId,
            changes: payload.data?.changes,
            webhookEventId,
          });
          break;
        }

        case "connection.disconnected": {
          // Mark SmartCredit as disconnected
          await db.collection("consumers").doc(internalConsumerId).update({
            "smartCredit.status": "disconnected",
            "smartCredit.disconnectedAt": FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });

          // Audit log
          await logAuditEvent({
            tenantId,
            actor: {
              userId: "system",
              email: "webhook@smartcredit.com",
              role: "owner",
            },
            entity: "smartcredit_connection",
            entityId: internalConsumerId,
            action: "disconnect",
            metadata: {
              source: "smartcredit_webhook",
              eventType,
              webhookEventId,
            },
          });

          functions.logger.info("Processed SmartCredit disconnection", {
            consumerId: internalConsumerId,
            webhookEventId,
          });
          break;
        }

        default: {
          // Unknown event type - store for review
          await db.collection("webhookEvents").doc(webhookEventId).update({
            status: "unknown_event",
            error: `Unknown SmartCredit event type: ${eventType}`,
          });

          functions.logger.warn("Unknown SmartCredit event type", {
            eventType,
            consumerId: internalConsumerId,
            webhookEventId,
          });
        }
      }

      // Mark webhook as processed
      await db.collection("webhookEvents").doc(webhookEventId).update({
        status: "processed",
        processedAt: FieldValue.serverTimestamp(),
      });

      // Audit log for report events
      if (eventType === "report.available" || eventType === "report.refreshed") {
        await logAuditEvent({
          tenantId,
          actor: {
            userId: "system",
            email: "webhook@smartcredit.com",
            role: "owner",
          },
          entity: "credit_report",
          entityId: internalConsumerId,
          action: "refresh",
          metadata: {
            source: "smartcredit_webhook",
            eventType,
            reportId: payload.data?.report_id,
            webhookEventId,
          },
        });
      }
    } else {
      // Consumer not found - mark webhook for manual review
      await db.collection("webhookEvents").doc(webhookEventId).update({
        status: "unmatched",
        error: "No matching consumer found for SmartCredit customer ID",
      });

      functions.logger.warn("SmartCredit webhook - consumer not found", {
        eventType,
        customerId,
        webhookEventId,
      });
    }

    res.status(200).json({
      success: true,
      eventId: webhookEventId,
      processed: !!consumer,
    });
  } catch (error) {
    functions.logger.error("Error processing SmartCredit webhook", { error });
    res.status(500).json({ error: "Internal server error" });
  }
});

// ============================================================================
// webhooksRetry - Retry a failed webhook event (admin function)
// ============================================================================

export const webhooksRetry = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const { webhookEventId } = data;
  if (!webhookEventId) {
    throw new functions.https.HttpsError("invalid-argument", "webhookEventId is required");
  }

  // Get webhook event
  const eventDoc = await db.collection("webhookEvents").doc(webhookEventId).get();
  if (!eventDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Webhook event not found");
  }

  const event = eventDoc.data()!;

  // Verify tenant access
  const userClaims = context.auth.token;
  if (event.tenantId !== userClaims.tenantId) {
    throw new functions.https.HttpsError("permission-denied", "Access denied");
  }

  // Mark for retry
  await db.collection("webhookEvents").doc(webhookEventId).update({
    status: "retry_pending",
    retryCount: FieldValue.increment(1),
    lastRetryAt: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    message: "Webhook event queued for retry",
    webhookEventId,
  };
});

// ============================================================================
// webhooksList - List webhook events for debugging
// ============================================================================

export const webhooksList = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const userClaims = context.auth.token;
  const tenantId = userClaims.tenantId;

  if (!tenantId) {
    throw new functions.https.HttpsError("permission-denied", "No tenant assigned");
  }

  const { provider, status, limit = 50, cursor } = data;

  // Build query
  let query = db
    .collection("webhookEvents")
    .where("tenantId", "==", tenantId)
    .orderBy("receivedAt", "desc");

  if (provider) {
    query = query.where("provider", "==", provider);
  }

  if (status) {
    query = query.where("status", "==", status);
  }

  if (cursor) {
    const cursorDoc = await db.collection("webhookEvents").doc(cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  const snapshot = await query.limit(limit + 1).get();

  const hasMore = snapshot.docs.length > limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const events = docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
    // Redact full payload for list view
    payload: undefined,
  }));

  return {
    success: true,
    data: {
      items: events,
      pagination: {
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
});
