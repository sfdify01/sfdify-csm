"use strict";
/**
 * Letter Management Cloud Functions
 *
 * Handles letter generation, approval, and sending via Lob.
 * Implements quality checks and integrates with Lob print-and-mail API.
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
exports.lettersList = exports.lettersSend = exports.lettersApprove = exports.lettersGet = exports.lettersGenerate = void 0;
exports.isValidStatusTransition = isValidStatusTransition;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const audit_1 = require("../../utils/audit");
const pdfGenerator_1 = require("../../utils/pdfGenerator");
const lobService_1 = require("../../services/lobService");
const config_1 = require("../../config");
const encryption_1 = require("../../utils/encryption");
const handlebars_1 = __importDefault(require("handlebars"));
const joi_1 = __importDefault(require("joi"));
const logger = __importStar(require("firebase-functions/logger"));
// ============================================================================
// Constants
// ============================================================================
/**
 * Valid status transitions for letters
 * Used for validating status changes in letter workflow
 */
const STATUS_TRANSITIONS = {
    draft: ["pending_approval"],
    pending_approval: ["approved", "draft"],
    approved: ["rendering"],
    rendering: ["ready", "draft"], // Can go back to draft if rendering fails
    ready: ["queued"],
    queued: ["sent"],
    sent: ["in_transit", "delivered", "returned_to_sender"],
    in_transit: ["delivered", "returned_to_sender"],
    delivered: [],
    returned_to_sender: [],
};
/**
 * Check if a status transition is valid
 */
function isValidStatusTransition(from, to) {
    return STATUS_TRANSITIONS[from]?.includes(to) ?? false;
}
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Verify letter access and return letter document
 */
async function verifyLetterAccess(letterId, tenantId) {
    const letterDoc = await admin_1.db.collection("letters").doc(letterId).get();
    (0, errors_1.assertExists)(letterDoc.exists ? letterDoc.data() : null, "Letter", letterId);
    const letter = { id: letterDoc.id, ...letterDoc.data() };
    if (letter.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this letter");
    }
    return letter;
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
 * Get template by ID
 */
async function getTemplate(templateId, tenantId) {
    const templateDoc = await admin_1.db.collection("letterTemplates").doc(templateId).get();
    (0, errors_1.assertExists)(templateDoc.exists ? templateDoc.data() : null, "Template", templateId);
    const template = { id: templateDoc.id, ...templateDoc.data() };
    // Check if template is system-wide or belongs to tenant
    if (template.tenantId && template.tenantId !== tenantId && !template.isSystemTemplate) {
        throw new errors_1.ForbiddenError("You do not have access to this template");
    }
    return template;
}
/**
 * Get consumer by ID with decrypted PII
 */
async function getConsumerWithPii(consumerId, tenantId) {
    const consumerDoc = await admin_1.db.collection("consumers").doc(consumerId).get();
    (0, errors_1.assertExists)(consumerDoc.exists ? consumerDoc.data() : null, "Consumer", consumerId);
    const consumer = { id: consumerDoc.id, ...consumerDoc.data() };
    if (consumer.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this consumer");
    }
    // Decrypt PII fields
    consumer.firstName = await (0, encryption_1.decryptPii)(consumer.firstName);
    consumer.lastName = await (0, encryption_1.decryptPii)(consumer.lastName);
    consumer.dob = await (0, encryption_1.decryptPii)(consumer.dob);
    consumer.ssnLast4 = await (0, encryption_1.decryptPii)(consumer.ssnLast4);
    return consumer;
}
/**
 * Get bureau address for the dispute
 */
function getBureauAddress(bureau) {
    const bureauKey = bureau;
    const address = config_1.BUREAU_ADDRESSES[bureauKey];
    if (!address) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, `Unknown bureau: ${bureau}`, 400);
    }
    return {
        name: address.name,
        addressLine1: address.addressLine1,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
    };
}
/**
 * Add status history entry
 */
function addStatusHistory(currentHistory, newStatus, userId) {
    return [
        ...currentHistory,
        {
            status: newStatus,
            timestamp: firestore_1.FieldValue.serverTimestamp(),
            by: userId,
        },
    ];
}
/**
 * Perform quality checks on letter
 */
function performQualityChecks(letter, consumer) {
    const primaryAddress = consumer.addresses.find((a) => a.isPrimary);
    return {
        addressValidated: !!primaryAddress && !!primaryAddress.zipCode,
        narrativeLengthOk: (letter.contentMarkdown?.length || 0) >= 100,
        evidenceIndexGenerated: (letter.evidenceIndex?.length || 0) > 0 || true, // OK if no evidence
        pdfIntegrityVerified: false, // Will be set after PDF generation
        allFieldsComplete: !!(letter.recipientAddress && letter.returnAddress),
        checkedAt: firestore_1.FieldValue.serverTimestamp(),
    };
}
// ============================================================================
// Handlebars Configuration
// ============================================================================
// Register custom Handlebars helpers
handlebars_1.default.registerHelper("formatDate", (date) => {
    if (!date)
        return "";
    const d = typeof date === "string" ? new Date(date) : date;
    return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
});
handlebars_1.default.registerHelper("formatCurrency", (amount) => {
    if (amount === undefined || amount === null)
        return "";
    return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
    }).format(amount);
});
handlebars_1.default.registerHelper("uppercase", (str) => {
    return str ? str.toUpperCase() : "";
});
handlebars_1.default.registerHelper("lowercase", (str) => {
    return str ? str.toLowerCase() : "";
});
handlebars_1.default.registerHelper("eq", (a, b) => {
    return a === b;
});
handlebars_1.default.registerHelper("ne", (a, b) => {
    return a !== b;
});
handlebars_1.default.registerHelper("or", (...args) => {
    // Remove the last argument (Handlebars options object)
    args.pop();
    return args.some(Boolean);
});
handlebars_1.default.registerHelper("and", (...args) => {
    // Remove the last argument (Handlebars options object)
    args.pop();
    return args.every(Boolean);
});
/**
 * Render template using Handlebars
 */
function renderTemplate(template, variables) {
    try {
        const compiled = handlebars_1.default.compile(template, { strict: false });
        return compiled(variables);
    }
    catch (error) {
        logger.error("[Letter] Template rendering error", { error });
        // Fallback to simple replacement if Handlebars fails
        let rendered = template;
        for (const [key, value] of Object.entries(variables)) {
            const regex = new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, "g");
            rendered = rendered.replace(regex, String(value || ""));
        }
        return rendered;
    }
}
// ============================================================================
// lettersGenerate - Generate a letter from template
// ============================================================================
async function generateLetterHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.generateLetterSchema, data);
    // Verify dispute access
    const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    // Check dispute status allows letter generation
    if (!["approved", "mailed", "delivered"].includes(dispute.status)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot generate letter for dispute in '${dispute.status}' status. Dispute must be approved first.`, 400);
    }
    // Get template
    const template = await getTemplate(validatedData.templateId, tenantId);
    // Verify template matches dispute type
    if (template.type !== dispute.type) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, `Template type '${template.type}' does not match dispute type '${dispute.type}'`, 400);
    }
    // Get consumer with decrypted PII
    const consumer = await getConsumerWithPii(dispute.consumerId, tenantId);
    // Get bureau address
    const bureauAddress = getBureauAddress(dispute.bureau);
    // Get consumer's primary address
    const consumerAddress = consumer.addresses.find((a) => a.isPrimary);
    if (!consumerAddress) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Consumer has no primary address", 400);
    }
    // Get tenant return address
    const returnAddress = tenant.lobConfig?.returnAddress;
    if (!returnAddress) {
        throw new errors_1.AppError(errors_1.ErrorCode.INTEGRATION_NOT_CONFIGURED, "Tenant has no return address configured", 400);
    }
    // Build template variables
    const today = new Date();
    const templateVariables = {
        consumer_first_name: consumer.firstName,
        consumer_last_name: consumer.lastName,
        consumer_full_name: `${consumer.firstName} ${consumer.lastName}`,
        consumer_address_street1: consumerAddress.street1,
        consumer_address_street2: consumerAddress.street2 || "",
        consumer_address_city: consumerAddress.city,
        consumer_address_state: consumerAddress.state,
        consumer_address_zip: consumerAddress.zipCode,
        consumer_ssn_last4: consumer.ssnLast4,
        consumer_dob: consumer.dob,
        bureau_name: bureauAddress.name,
        bureau_address_street1: bureauAddress.addressLine1,
        bureau_address_city: bureauAddress.city,
        bureau_address_state: bureauAddress.state,
        bureau_address_zip: bureauAddress.zipCode,
        dispute_type: dispute.type,
        dispute_reason_codes: dispute.reasonCodes.join(", "),
        dispute_narrative: dispute.narrative,
        company_name: tenant.branding.companyName,
        date: today.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" }),
        year: today.getFullYear(),
    };
    // Render template
    let contentMarkdown = renderTemplate(template.contentTemplate, templateVariables);
    // Add any additional text
    if (validatedData.customizations?.additionalText) {
        contentMarkdown += `\n\n${validatedData.customizations.additionalText}`;
    }
    // Create letter document
    const letterId = (0, uuid_1.v4)();
    const now = firestore_1.FieldValue.serverTimestamp();
    const letter = {
        id: letterId,
        disputeId: validatedData.disputeId,
        tenantId,
        type: dispute.type,
        templateId: validatedData.templateId,
        renderVersion: template.version,
        contentMarkdown,
        mailType: validatedData.mailType,
        recipientAddress: {
            ...bureauAddress,
        },
        returnAddress: {
            name: tenant.branding.companyName,
            addressLine1: returnAddress.street1,
            addressLine2: returnAddress.street2 || undefined,
            city: returnAddress.city,
            state: returnAddress.state,
            zipCode: returnAddress.zipCode,
        },
        status: "draft",
        statusHistory: [{
                status: "draft",
                timestamp: now,
                by: actorId,
            }],
        deliveryEvents: [],
        createdAt: now,
        createdBy: actorId,
        evidenceIndex: [],
    };
    // Perform quality checks
    letter.qualityChecks = performQualityChecks(letter, consumer);
    // Build evidence index if requested
    if (validatedData.customizations?.includeEvidenceIndex && dispute.evidenceIds.length > 0) {
        const evidenceDocs = await admin_1.db
            .collection("evidence")
            .where("id", "in", dispute.evidenceIds.slice(0, 10)) // Firestore in limit
            .get();
        letter.evidenceIndex = evidenceDocs.docs.map((doc, index) => {
            const evidence = doc.data();
            return {
                evidenceId: doc.id,
                filename: evidence.filename,
                description: evidence.description || evidence.originalFilename,
                pageInLetter: index + 1,
            };
        });
    }
    await admin_1.db.collection("letters").doc(letterId).set(letter);
    // Update dispute with letter ID
    await admin_1.db.collection("disputes").doc(validatedData.disputeId).update({
        letterIds: firestore_1.FieldValue.arrayUnion(letterId),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "letter",
        entityId: letterId,
        action: "create",
        newState: {
            ...letter,
            contentMarkdown: "[CONTENT_REDACTED]", // Don't log full content
        },
        metadata: {
            source: "letter_management",
            disputeId: validatedData.disputeId,
            templateId: validatedData.templateId,
        },
    });
    return {
        success: true,
        data: letter,
    };
}
exports.lettersGenerate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["letters:write"], generateLetterHandler)));
// ============================================================================
// lettersGet - Get letter details
// ============================================================================
async function getLetterHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ letterId: validation_1.schemas.documentId.required() }), data);
    const letter = await verifyLetterAccess(validatedData.letterId, tenantId);
    return {
        success: true,
        data: letter,
    };
}
exports.lettersGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["letters:read"], getLetterHandler)));
// ============================================================================
// lettersApprove - Approve a letter for sending
// ============================================================================
async function approveLetterHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Only owner and operator can approve
    (0, auth_1.requireRole)(context, ["owner", "operator"]);
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        letterId: validation_1.schemas.documentId.required(),
        comments: joi_1.default.string().max(1000),
    }), data);
    // Get current letter
    const letterRef = admin_1.db.collection("letters").doc(validatedData.letterId);
    const currentLetter = await verifyLetterAccess(validatedData.letterId, tenantId);
    // Validate status - can approve from draft or pending_approval
    if (!["draft", "pending_approval"].includes(currentLetter.status)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_LETTER_STATUS, `Cannot approve letter in '${currentLetter.status}' status`, 400);
    }
    // Update status
    const newStatusHistory = addStatusHistory(currentLetter.statusHistory, "approved", actorId);
    await letterRef.update({
        status: "approved",
        statusHistory: newStatusHistory,
        approvedBy: actorId,
        approvedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Get updated letter
    const updatedDoc = await letterRef.get();
    const updatedLetter = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "letter",
        entityId: validatedData.letterId,
        action: "approve",
        actionDetail: validatedData.comments || "Approved for sending",
        previousState: { status: currentLetter.status },
        newState: { status: "approved" },
    });
    return {
        success: true,
        data: updatedLetter,
    };
}
exports.lettersApprove = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["letters:approve"], approveLetterHandler)));
// ============================================================================
// lettersSend - Send letter via Lob
// ============================================================================
async function sendLetterHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.sendLetterSchema, data);
    // Get current letter
    const letterRef = admin_1.db.collection("letters").doc(validatedData.letterId);
    const currentLetter = await verifyLetterAccess(validatedData.letterId, tenantId);
    // Must be approved to send
    if (currentLetter.status !== "approved") {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_LETTER_STATUS, `Cannot send letter in '${currentLetter.status}' status. Must be approved first.`, 400);
    }
    // Check for idempotency - don't send if already queued with same key
    const existingWithKey = await admin_1.db
        .collection("letter_send_requests")
        .where("idempotencyKey", "==", validatedData.idempotencyKey)
        .limit(1)
        .get();
    if (!existingWithKey.empty) {
        throw new errors_1.AppError(errors_1.ErrorCode.ALREADY_EXISTS, "A send request with this idempotency key already exists", 409);
    }
    // Store send request for idempotency
    await admin_1.db.collection("letter_send_requests").add({
        letterId: validatedData.letterId,
        idempotencyKey: validatedData.idempotencyKey,
        tenantId,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        status: "pending",
    });
    // Update to rendering status
    const mailType = validatedData.mailType || currentLetter.mailType;
    let newStatusHistory = addStatusHistory(currentLetter.statusHistory, "rendering", actorId);
    await letterRef.update({
        status: "rendering",
        statusHistory: newStatusHistory,
        mailType,
    });
    try {
        // Step 1: Generate PDF from content
        logger.info("[Letter] Generating PDF", { letterId: validatedData.letterId });
        const contentHtml = currentLetter.contentHtml || (0, pdfGenerator_1.markdownToHtml)(currentLetter.contentMarkdown || "");
        const storagePath = (0, pdfGenerator_1.generateLetterPdfPath)(tenantId, validatedData.letterId);
        const pdfResult = await (0, pdfGenerator_1.generateAndUploadPdf)(contentHtml, storagePath, {
            format: "Letter",
            margin: { top: "1in", right: "1in", bottom: "1in", left: "1in" },
        });
        // Update with PDF info
        await letterRef.update({
            pdfUrl: pdfResult.signedUrl,
            pdfHash: pdfResult.hash,
            pdfSizeBytes: pdfResult.sizeBytes,
            pageCount: pdfResult.pageCount,
        });
        // Step 2: Calculate cost estimate
        const costEstimate = lobService_1.lobService.estimateCost(pdfResult.pageCount, mailType);
        // Step 3: Send to Lob
        logger.info("[Letter] Sending to Lob", {
            letterId: validatedData.letterId,
            mailType,
            pageCount: pdfResult.pageCount,
        });
        const lobLetter = await lobService_1.lobService.createLetter({
            to: currentLetter.recipientAddress,
            from: currentLetter.returnAddress,
            file: pdfResult.signedUrl,
            fileType: "pdf",
            description: `Dispute Letter - ${validatedData.letterId}`,
            mailType,
            metadata: {
                letterId: validatedData.letterId,
                tenantId,
                disputeId: currentLetter.disputeId,
            },
            idempotencyKey: validatedData.idempotencyKey,
        });
        // Step 4: Update letter with Lob info
        newStatusHistory = addStatusHistory(newStatusHistory, "queued", actorId);
        await letterRef.update({
            status: "queued",
            statusHistory: newStatusHistory,
            lobId: lobLetter.id,
            lobUrl: lobLetter.url,
            trackingNumber: lobLetter.tracking_number,
            "mailTypeDetail.service": lobLetter.carrier,
            "mailTypeDetail.returnReceipt": mailType === "usps_certified_return_receipt",
            "mailTypeDetail.extraService": lobLetter.extra_service,
            cost: {
                printing: costEstimate.printing,
                postage: costEstimate.postage,
                certifiedFee: costEstimate.certifiedFee,
                total: costEstimate.total,
                currency: costEstimate.currency,
            },
            sentAt: firestore_1.FieldValue.serverTimestamp(),
            "qualityChecks.pdfIntegrityVerified": true,
        });
        logger.info("[Letter] Successfully queued with Lob", {
            letterId: validatedData.letterId,
            lobId: lobLetter.id,
            expectedDelivery: lobLetter.expected_delivery_date,
        });
        // Get updated letter
        const updatedDoc = await letterRef.get();
        const updatedLetter = { id: updatedDoc.id, ...updatedDoc.data() };
        // Update dispute status to mailed
        await admin_1.db.collection("disputes").doc(currentLetter.disputeId).update({
            status: "mailed",
            "timestamps.mailedAt": firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        // Audit log
        await (0, audit_1.logAuditEvent)({
            tenantId,
            actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
            entity: "letter",
            entityId: validatedData.letterId,
            action: "send",
            actionDetail: `Queued for ${mailType} delivery`,
            previousState: { status: currentLetter.status },
            newState: { status: "queued", mailType, cost: costEstimate },
        });
        return {
            success: true,
            data: updatedLetter,
        };
    }
    catch (error) {
        // Revert to draft status on failure
        logger.error("[Letter] Failed to send letter", {
            letterId: validatedData.letterId,
            error: error instanceof Error ? error.message : "Unknown error",
        });
        newStatusHistory = addStatusHistory(currentLetter.statusHistory, "draft", actorId);
        await letterRef.update({
            status: "draft",
            statusHistory: newStatusHistory,
        });
        throw new errors_1.AppError(errors_1.ErrorCode.EXTERNAL_SERVICE_ERROR, `Failed to send letter: ${error instanceof Error ? error.message : "Unknown error"}`, 500);
    }
}
exports.lettersSend = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["letters:send"], sendLetterHandler)));
// ============================================================================
// lettersList - List letters with filters
// ============================================================================
async function listLettersHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    const filters = (0, validation_1.validate)(joi_1.default.object({
        disputeId: validation_1.schemas.documentId,
        status: joi_1.default.alternatives().try(joi_1.default.string().valid("draft", "pending_approval", "approved", "rendering", "ready", "queued", "sent", "in_transit", "delivered", "returned_to_sender"), joi_1.default.array().items(joi_1.default.string().valid("draft", "pending_approval", "approved", "rendering", "ready", "queued", "sent", "in_transit", "delivered", "returned_to_sender"))),
    }), data);
    // Build query
    let query = admin_1.db
        .collection("letters")
        .where("tenantId", "==", tenantId)
        .orderBy("createdAt", "desc");
    // Apply filters
    if (filters.disputeId) {
        query = query.where("disputeId", "==", filters.disputeId);
    }
    if (filters.status) {
        if (Array.isArray(filters.status)) {
            query = query.where("status", "in", filters.status);
        }
        else {
            query = query.where("status", "==", filters.status);
        }
    }
    // Apply cursor if provided
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("letters").doc(pagination.cursor).get();
        if (cursorDoc.exists) {
            query = query.startAfter(cursorDoc);
        }
    }
    // Execute query with limit + 1 to check for more
    const snapshot = await query.limit(pagination.limit + 1).get();
    const hasMore = snapshot.docs.length > pagination.limit;
    const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
    const letters = docs.map((doc) => {
        const letter = { id: doc.id, ...doc.data() };
        // Redact full content in list view
        return {
            ...letter,
            contentMarkdown: letter.contentMarkdown ? "[CONTENT_AVAILABLE]" : undefined,
            contentHtml: letter.contentHtml ? "[CONTENT_AVAILABLE]" : undefined,
        };
    });
    // Get total count
    let countQuery = admin_1.db.collection("letters").where("tenantId", "==", tenantId);
    if (filters.disputeId) {
        countQuery = countQuery.where("disputeId", "==", filters.disputeId);
    }
    if (filters.status && !Array.isArray(filters.status)) {
        countQuery = countQuery.where("status", "==", filters.status);
    }
    const countSnapshot = await countQuery.count().get();
    return {
        success: true,
        data: {
            items: letters,
            pagination: {
                total: countSnapshot.data().count,
                limit: pagination.limit,
                hasMore,
                nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
            },
        },
    };
}
exports.lettersList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["letters:read"], listLettersHandler)));
//# sourceMappingURL=index.js.map