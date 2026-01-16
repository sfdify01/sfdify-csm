"use strict";
/**
 * Webhook Handler Cloud Functions
 *
 * Handles incoming webhooks from external services (Lob, SmartCredit).
 * Implements signature verification and event processing.
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
exports.webhooksList = exports.webhooksRetry = exports.webhooksSmartCredit = exports.webhooksLob = exports.LOB_EVENT_TYPES = void 0;
const functions = __importStar(require("firebase-functions"));
const crypto = __importStar(require("crypto"));
const admin_1 = require("../../admin");
const firestore_1 = require("firebase-admin/firestore");
const audit_1 = require("../../utils/audit");
const config_1 = require("../../config");
const uuid_1 = require("uuid");
// ============================================================================
// Lob Webhook Event Types
// ============================================================================
// Export for reference/documentation
exports.LOB_EVENT_TYPES = {
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
};
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Verify Lob webhook signature
 * Lob uses a timestamp + payload signature scheme
 */
function verifyLobSignature(payload, signature, timestamp) {
    if (!config_1.lobConfig.webhookSecret) {
        return false;
    }
    const expectedSignature = crypto
        .createHmac("sha256", config_1.lobConfig.webhookSecret)
        .update(`${timestamp}.${payload}`)
        .digest("hex");
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
}
/**
 * Verify SmartCredit webhook signature
 */
function verifySmartCreditSignature(payload, signature) {
    if (!config_1.smartCreditConfig.webhookSecret) {
        return false;
    }
    const expectedSignature = crypto
        .createHmac("sha256", config_1.smartCreditConfig.webhookSecret)
        .update(payload)
        .digest("hex");
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
}
/**
 * Map Lob event type to internal letter status
 */
function mapLobEventToStatus(eventType) {
    const statusMap = {
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
async function storeWebhookEvent(provider, eventType, resourceType, resourceId, payload, signature, signatureValid, tenantId, internalResourceId) {
    const eventId = (0, uuid_1.v4)();
    const now = firestore_1.FieldValue.serverTimestamp();
    const webhookEvent = {
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
        receivedAt: now,
    };
    await admin_1.db.collection("webhookEvents").doc(eventId).set({
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
exports.webhooksLob = functions.https.onRequest(async (req, res) => {
    // Only accept POST requests
    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }
    try {
        // Get signature headers
        const lobSignature = req.headers["lob-signature"];
        const lobTimestamp = req.headers["lob-signature-timestamp"];
        const rawBody = JSON.stringify(req.body);
        const payload = req.body;
        // Verify signature if webhook secret is configured
        let signatureValid = true;
        if (config_1.lobConfig.webhookSecret && lobSignature && lobTimestamp) {
            signatureValid = verifyLobSignature(rawBody, lobSignature, lobTimestamp);
        }
        // Extract event information
        const eventType = payload.event_type?.id || "unknown";
        const resourceType = payload.event_type?.resource || "letter";
        const resourceId = payload.body?.id || "unknown";
        // Look up internal letter by Lob ID
        let tenantId;
        let internalLetterId;
        let letter;
        if (resourceType === "letter" && resourceId !== "unknown") {
            const letterQuery = await admin_1.db
                .collection("letters")
                .where("lobId", "==", resourceId)
                .limit(1)
                .get();
            if (!letterQuery.empty) {
                const letterDoc = letterQuery.docs[0];
                letter = { id: letterDoc.id, ...letterDoc.data() };
                internalLetterId = letter.id;
                tenantId = letter.tenantId;
            }
        }
        // Store webhook event
        const webhookEventId = await storeWebhookEvent("lob", eventType, resourceType, resourceId, payload, lobSignature || "", signatureValid, tenantId, internalLetterId);
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
                const updates = {
                    status: newStatus,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                    location: payload.body?.tracking_events?.[0]?.location,
                };
                updates.deliveryEvents = firestore_1.FieldValue.arrayUnion(deliveryEvent);
                // Update specific timestamps
                if (newStatus === "sent") {
                    updates.sentAt = firestore_1.FieldValue.serverTimestamp();
                }
                else if (newStatus === "delivered") {
                    updates.deliveredAt = firestore_1.FieldValue.serverTimestamp();
                }
                // Add to status history
                updates.statusHistory = firestore_1.FieldValue.arrayUnion({
                    status: newStatus,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                    by: "system",
                });
                await admin_1.db.collection("letters").doc(internalLetterId).update(updates);
                // Update webhook event as processed
                await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
                    status: "processed",
                    processedAt: firestore_1.FieldValue.serverTimestamp(),
                });
                // Audit log
                await (0, audit_1.logAuditEvent)({
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
                    const disputeRef = admin_1.db.collection("disputes").doc(letter.disputeId);
                    const disputeDoc = await disputeRef.get();
                    if (disputeDoc.exists) {
                        const dispute = disputeDoc.data();
                        if (dispute.status === "mailed") {
                            await disputeRef.update({
                                status: "delivered",
                                "timestamps.deliveredAt": firestore_1.FieldValue.serverTimestamp(),
                                updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
        }
        else {
            // Letter not found - mark webhook for manual review
            await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
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
    }
    catch (error) {
        functions.logger.error("Error processing Lob webhook", { error });
        res.status(500).json({ error: "Internal server error" });
    }
});
// ============================================================================
// webhooksSmartCredit - SmartCredit webhook handler for report updates
// ============================================================================
exports.webhooksSmartCredit = functions.https.onRequest(async (req, res) => {
    // Only accept POST requests
    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }
    try {
        const rawBody = JSON.stringify(req.body);
        const payload = req.body;
        // Verify signature
        let signatureValid = true;
        if (config_1.smartCreditConfig.webhookSecret && payload.signature) {
            signatureValid = verifySmartCreditSignature(rawBody, payload.signature);
        }
        // Extract event information
        const eventType = payload.event_type || "unknown";
        const customerId = payload.customer_id || "unknown";
        const resourceType = "consumer";
        // Look up internal consumer by SmartCredit customer ID
        let tenantId;
        let internalConsumerId;
        let consumer;
        if (customerId !== "unknown") {
            // Query consumers with SmartCredit connection
            const consumersQuery = await admin_1.db
                .collection("consumers")
                .where("smartCredit.memberId", "==", customerId)
                .limit(1)
                .get();
            if (!consumersQuery.empty) {
                const consumerDoc = consumersQuery.docs[0];
                consumer = { id: consumerDoc.id, ...consumerDoc.data() };
                internalConsumerId = consumer.id;
                tenantId = consumer.tenantId;
            }
        }
        // Store webhook event
        const webhookEventId = await storeWebhookEvent("smartcredit", eventType, resourceType, customerId, payload, payload.signature || "", signatureValid, tenantId, internalConsumerId);
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
                    await admin_1.db.collection("consumers").doc(internalConsumerId).update({
                        "smartCredit.lastRefreshed": firestore_1.FieldValue.serverTimestamp(),
                        "smartCredit.reportAvailable": true,
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    // Create a credit report record if report data is provided
                    if (payload.data?.report_id) {
                        const reportId = (0, uuid_1.v4)();
                        await admin_1.db.collection("creditReports").doc(reportId).set({
                            id: reportId,
                            tenantId,
                            consumerId: internalConsumerId,
                            smartCreditReportId: payload.data.report_id,
                            bureau: payload.data.bureau || "all",
                            pulledAt: firestore_1.FieldValue.serverTimestamp(),
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
                    await admin_1.db.collection("consumers").doc(internalConsumerId).update({
                        "smartCredit.lastScoreChange": firestore_1.FieldValue.serverTimestamp(),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
                    await admin_1.db.collection("consumers").doc(internalConsumerId).update({
                        "smartCredit.status": "disconnected",
                        "smartCredit.disconnectedAt": firestore_1.FieldValue.serverTimestamp(),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    // Audit log
                    await (0, audit_1.logAuditEvent)({
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
                    await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
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
            await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
                status: "processed",
                processedAt: firestore_1.FieldValue.serverTimestamp(),
            });
            // Audit log for report events
            if (eventType === "report.available" || eventType === "report.refreshed") {
                await (0, audit_1.logAuditEvent)({
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
        }
        else {
            // Consumer not found - mark webhook for manual review
            await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
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
    }
    catch (error) {
        functions.logger.error("Error processing SmartCredit webhook", { error });
        res.status(500).json({ error: "Internal server error" });
    }
});
// ============================================================================
// webhooksRetry - Retry a failed webhook event (admin function)
// ============================================================================
exports.webhooksRetry = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const { webhookEventId } = data;
    if (!webhookEventId) {
        throw new functions.https.HttpsError("invalid-argument", "webhookEventId is required");
    }
    // Get webhook event
    const eventDoc = await admin_1.db.collection("webhookEvents").doc(webhookEventId).get();
    if (!eventDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Webhook event not found");
    }
    const event = eventDoc.data();
    // Verify tenant access
    const userClaims = context.auth.token;
    if (event.tenantId !== userClaims.tenantId) {
        throw new functions.https.HttpsError("permission-denied", "Access denied");
    }
    // Mark for retry
    await admin_1.db.collection("webhookEvents").doc(webhookEventId).update({
        status: "retry_pending",
        retryCount: firestore_1.FieldValue.increment(1),
        lastRetryAt: firestore_1.FieldValue.serverTimestamp(),
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
exports.webhooksList = functions.https.onCall(async (data, context) => {
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
    let query = admin_1.db
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
        const cursorDoc = await admin_1.db.collection("webhookEvents").doc(cursor).get();
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
//# sourceMappingURL=index.js.map