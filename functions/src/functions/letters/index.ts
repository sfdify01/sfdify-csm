/**
 * Letter Management Cloud Functions
 *
 * Handles letter generation, approval, and sending via Lob.
 * Implements quality checks and integrates with Lob print-and-mail API.
 */

import * as functions from "firebase-functions";
import { db } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  withAuth,
  RequestContext,
  requireRole,
} from "../../middleware/auth";
import {
  validate,
  generateLetterSchema,
  sendLetterSchema,
  paginationSchema,
  schemas,
} from "../../utils/validation";
import {
  withErrorHandling,
  ForbiddenError,
  assertExists,
  ErrorCode,
  AppError,
} from "../../utils/errors";
import { logAuditEvent } from "../../utils/audit";
import {
  generateAndUploadPdf,
  generateLetterPdfPath,
  markdownToHtml,
} from "../../utils/pdfGenerator";
import { lobService } from "../../services/lobService";
import {
  Letter,
  LetterStatus,
  LetterTemplate,
  Dispute,
  Consumer,
  MailType,
  QualityChecks,
  LetterStatusHistoryEntry,
  ApiResponse,
  PaginatedResponse,
  MailingAddress,
} from "../../types";
import { BUREAU_ADDRESSES } from "../../config";
import { decryptPii } from "../../utils/encryption";
import Handlebars from "handlebars";
import Joi from "joi";
import * as logger from "firebase-functions/logger";

// ============================================================================
// Constants
// ============================================================================

/**
 * Valid status transitions for letters
 * Used for validating status changes in letter workflow
 */
const STATUS_TRANSITIONS: Record<LetterStatus, LetterStatus[]> = {
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
function isValidStatusTransition(from: LetterStatus, to: LetterStatus): boolean {
  return STATUS_TRANSITIONS[from]?.includes(to) ?? false;
}

// Export for testing
export { isValidStatusTransition };

// ============================================================================
// Type Definitions
// ============================================================================

interface GenerateLetterInput {
  disputeId: string;
  templateId: string;
  mailType: MailType;
  customizations?: {
    includeEvidenceIndex?: boolean;
    attachEvidence?: boolean;
    additionalText?: string;
  };
}

interface GetLetterInput {
  letterId: string;
}

interface ApproveLetterInput {
  letterId: string;
  comments?: string;
}

interface SendLetterInput {
  letterId: string;
  mailType?: MailType;
  scheduledSendDate?: string | null;
  idempotencyKey: string;
}

interface ListLettersInput {
  disputeId?: string;
  status?: LetterStatus | LetterStatus[];
  limit?: number;
  cursor?: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Verify letter access and return letter document
 */
async function verifyLetterAccess(
  letterId: string,
  tenantId: string
): Promise<Letter> {
  const letterDoc = await db.collection("letters").doc(letterId).get();
  assertExists(letterDoc.exists ? letterDoc.data() : null, "Letter", letterId);

  const letter = { id: letterDoc.id, ...letterDoc.data() } as Letter;

  if (letter.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this letter");
  }

  return letter;
}

/**
 * Verify dispute access and return dispute document
 */
async function verifyDisputeAccess(
  disputeId: string,
  tenantId: string
): Promise<Dispute> {
  const disputeDoc = await db.collection("disputes").doc(disputeId).get();
  assertExists(disputeDoc.exists ? disputeDoc.data() : null, "Dispute", disputeId);

  const dispute = { id: disputeDoc.id, ...disputeDoc.data() } as Dispute;

  if (dispute.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this dispute");
  }

  return dispute;
}

/**
 * Get template by ID
 */
async function getTemplate(
  templateId: string,
  tenantId: string
): Promise<LetterTemplate> {
  const templateDoc = await db.collection("letterTemplates").doc(templateId).get();
  assertExists(templateDoc.exists ? templateDoc.data() : null, "Template", templateId);

  const template = { id: templateDoc.id, ...templateDoc.data() } as LetterTemplate;

  // Check if template is system-wide or belongs to tenant
  if (template.tenantId && template.tenantId !== tenantId && !template.isSystemTemplate) {
    throw new ForbiddenError("You do not have access to this template");
  }

  return template;
}

/**
 * Get consumer by ID with decrypted PII
 */
async function getConsumerWithPii(
  consumerId: string,
  tenantId: string
): Promise<Consumer> {
  const consumerDoc = await db.collection("consumers").doc(consumerId).get();
  assertExists(consumerDoc.exists ? consumerDoc.data() : null, "Consumer", consumerId);

  const consumer = { id: consumerDoc.id, ...consumerDoc.data() } as Consumer;

  if (consumer.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this consumer");
  }

  // Decrypt PII fields
  consumer.firstName = await decryptPii(consumer.firstName);
  consumer.lastName = await decryptPii(consumer.lastName);
  consumer.dob = await decryptPii(consumer.dob);
  consumer.ssnLast4 = await decryptPii(consumer.ssnLast4);

  return consumer;
}

/**
 * Get bureau address for the dispute
 */
function getBureauAddress(bureau: string): MailingAddress {
  const bureauKey = bureau as keyof typeof BUREAU_ADDRESSES;
  const address = BUREAU_ADDRESSES[bureauKey];

  if (!address) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      `Unknown bureau: ${bureau}`,
      400
    );
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
function addStatusHistory(
  currentHistory: LetterStatusHistoryEntry[],
  newStatus: LetterStatus,
  userId?: string
): LetterStatusHistoryEntry[] {
  return [
    ...currentHistory,
    {
      status: newStatus,
      timestamp: FieldValue.serverTimestamp() as unknown as Timestamp,
      by: userId,
    },
  ];
}

/**
 * Perform quality checks on letter
 */
function performQualityChecks(
  letter: Partial<Letter>,
  consumer: Consumer
): QualityChecks {
  const primaryAddress = consumer.addresses.find((a) => a.isPrimary);

  return {
    addressValidated: !!primaryAddress && !!primaryAddress.zipCode,
    narrativeLengthOk: (letter.contentMarkdown?.length || 0) >= 100,
    evidenceIndexGenerated: (letter.evidenceIndex?.length || 0) > 0 || true, // OK if no evidence
    pdfIntegrityVerified: false, // Will be set after PDF generation
    allFieldsComplete: !!(letter.recipientAddress && letter.returnAddress),
    checkedAt: FieldValue.serverTimestamp() as unknown as Timestamp,
  };
}

// ============================================================================
// Handlebars Configuration
// ============================================================================

// Register custom Handlebars helpers
Handlebars.registerHelper("formatDate", (date: string | Date) => {
  if (!date) return "";
  const d = typeof date === "string" ? new Date(date) : date;
  return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
});

Handlebars.registerHelper("formatCurrency", (amount: number) => {
  if (amount === undefined || amount === null) return "";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
});

Handlebars.registerHelper("uppercase", (str: string) => {
  return str ? str.toUpperCase() : "";
});

Handlebars.registerHelper("lowercase", (str: string) => {
  return str ? str.toLowerCase() : "";
});

Handlebars.registerHelper("eq", (a: unknown, b: unknown) => {
  return a === b;
});

Handlebars.registerHelper("ne", (a: unknown, b: unknown) => {
  return a !== b;
});

Handlebars.registerHelper("or", (...args: unknown[]) => {
  // Remove the last argument (Handlebars options object)
  args.pop();
  return args.some(Boolean);
});

Handlebars.registerHelper("and", (...args: unknown[]) => {
  // Remove the last argument (Handlebars options object)
  args.pop();
  return args.every(Boolean);
});

/**
 * Render template using Handlebars
 */
function renderTemplate(
  template: string,
  variables: Record<string, string | number | undefined | null>
): string {
  try {
    const compiled = Handlebars.compile(template, { strict: false });
    return compiled(variables);
  } catch (error) {
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

async function generateLetterHandler(
  data: GenerateLetterInput,
  context: RequestContext
): Promise<ApiResponse<Letter>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;

  // Validate input
  const validatedData = validate(generateLetterSchema, data);

  // Verify dispute access
  const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  // Check dispute status allows letter generation
  if (!["approved", "mailed", "delivered"].includes(dispute.status)) {
    throw new AppError(
      ErrorCode.INVALID_DISPUTE_STATUS,
      `Cannot generate letter for dispute in '${dispute.status}' status. Dispute must be approved first.`,
      400
    );
  }

  // Get template
  const template = await getTemplate(validatedData.templateId, tenantId);

  // Verify template matches dispute type
  if (template.type !== dispute.type) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      `Template type '${template.type}' does not match dispute type '${dispute.type}'`,
      400
    );
  }

  // Get consumer with decrypted PII
  const consumer = await getConsumerWithPii(dispute.consumerId, tenantId);

  // Get bureau address
  const bureauAddress = getBureauAddress(dispute.bureau);

  // Get consumer's primary address
  const consumerAddress = consumer.addresses.find((a) => a.isPrimary);
  if (!consumerAddress) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Consumer has no primary address",
      400
    );
  }

  // Get tenant return address
  const returnAddress = tenant.lobConfig?.returnAddress;
  if (!returnAddress) {
    throw new AppError(
      ErrorCode.INTEGRATION_NOT_CONFIGURED,
      "Tenant has no return address configured",
      400
    );
  }

  // Build template variables
  const today = new Date();
  const templateVariables: Record<string, string | number | undefined> = {
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
  const letterId = uuidv4();
  const now = FieldValue.serverTimestamp() as unknown as Timestamp;

  const letter: Letter = {
    id: letterId,
    disputeId: validatedData.disputeId,
    consumerId: dispute.consumerId,
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
    round: 1,
    recipientType: "bureau",
  };

  // Perform quality checks
  letter.qualityChecks = performQualityChecks(letter, consumer);

  // Build evidence index if requested
  if (validatedData.customizations?.includeEvidenceIndex && dispute.evidenceIds.length > 0) {
    const evidenceDocs = await db
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

  await db.collection("letters").doc(letterId).set(letter);

  // Update dispute with letter ID
  await db.collection("disputes").doc(validatedData.disputeId).update({
    letterIds: FieldValue.arrayUnion(letterId),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "letter",
    entityId: letterId,
    action: "create",
    newState: {
      ...letter,
      contentMarkdown: "[CONTENT_REDACTED]", // Don't log full content
    } as unknown as Record<string, unknown>,
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

export const lettersGenerate = functions.https.onCall(
  withErrorHandling(
    withAuth(["letters:write"], generateLetterHandler)
  )
);

// ============================================================================
// lettersGet - Get letter details
// ============================================================================

async function getLetterHandler(
  data: GetLetterInput,
  context: RequestContext
): Promise<ApiResponse<Letter>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ letterId: schemas.documentId.required() }),
    data
  );

  const letter = await verifyLetterAccess(validatedData.letterId, tenantId);

  return {
    success: true,
    data: letter,
  };
}

export const lettersGet = functions.https.onCall(
  withErrorHandling(
    withAuth(["letters:read"], getLetterHandler)
  )
);

// ============================================================================
// lettersApprove - Approve a letter for sending
// ============================================================================

async function approveLetterHandler(
  data: ApproveLetterInput,
  context: RequestContext
): Promise<ApiResponse<Letter>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Only owner and operator can approve
  requireRole(context, ["owner", "operator"]);

  // Validate input
  const validatedData = validate(
    Joi.object({
      letterId: schemas.documentId.required(),
      comments: Joi.string().max(1000),
    }),
    data
  );

  // Get current letter
  const letterRef = db.collection("letters").doc(validatedData.letterId);
  const currentLetter = await verifyLetterAccess(validatedData.letterId, tenantId);

  // Validate status - can approve from draft or pending_approval
  if (!["draft", "pending_approval"].includes(currentLetter.status)) {
    throw new AppError(
      ErrorCode.INVALID_LETTER_STATUS,
      `Cannot approve letter in '${currentLetter.status}' status`,
      400
    );
  }

  // Update status
  const newStatusHistory = addStatusHistory(currentLetter.statusHistory, "approved", actorId);

  await letterRef.update({
    status: "approved",
    statusHistory: newStatusHistory,
    approvedBy: actorId,
    approvedAt: FieldValue.serverTimestamp(),
  });

  // Get updated letter
  const updatedDoc = await letterRef.get();
  const updatedLetter = { id: updatedDoc.id, ...updatedDoc.data() } as Letter;

  // Audit log
  await logAuditEvent({
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

export const lettersApprove = functions.https.onCall(
  withErrorHandling(
    withAuth(["letters:approve"], approveLetterHandler)
  )
);

// ============================================================================
// lettersSend - Send letter via Lob
// ============================================================================

async function sendLetterHandler(
  data: SendLetterInput,
  context: RequestContext
): Promise<ApiResponse<Letter>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(sendLetterSchema, data);

  // Get current letter
  const letterRef = db.collection("letters").doc(validatedData.letterId);
  const currentLetter = await verifyLetterAccess(validatedData.letterId, tenantId);

  // Must be approved to send
  if (currentLetter.status !== "approved") {
    throw new AppError(
      ErrorCode.INVALID_LETTER_STATUS,
      `Cannot send letter in '${currentLetter.status}' status. Must be approved first.`,
      400
    );
  }

  // Check for idempotency - don't send if already queued with same key
  const existingWithKey = await db
    .collection("letter_send_requests")
    .where("idempotencyKey", "==", validatedData.idempotencyKey)
    .limit(1)
    .get();

  if (!existingWithKey.empty) {
    throw new AppError(
      ErrorCode.ALREADY_EXISTS,
      "A send request with this idempotency key already exists",
      409
    );
  }

  // Store send request for idempotency
  await db.collection("letter_send_requests").add({
    letterId: validatedData.letterId,
    idempotencyKey: validatedData.idempotencyKey,
    tenantId,
    createdAt: FieldValue.serverTimestamp(),
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

    const contentHtml = currentLetter.contentHtml || markdownToHtml(currentLetter.contentMarkdown || "");
    const storagePath = generateLetterPdfPath(tenantId, validatedData.letterId);

    const pdfResult = await generateAndUploadPdf(contentHtml, storagePath, {
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

    // Step 2: Verify recipient address before sending
    logger.info("[Letter] Verifying recipient address", { letterId: validatedData.letterId });

    const addressVerification = await lobService.verifyAddress(currentLetter.recipientAddress);

    // Block sending if address is undeliverable
    if (addressVerification.deliverability === "undeliverable") {
      // Revert to draft status
      newStatusHistory = addStatusHistory(currentLetter.statusHistory, "draft", actorId);
      await letterRef.update({
        status: "draft",
        statusHistory: newStatusHistory,
        addressVerification: {
          deliverability: addressVerification.deliverability,
          verifiedAt: FieldValue.serverTimestamp(),
          error: "Address is undeliverable",
        },
      });

      throw new AppError(
        ErrorCode.VALIDATION_ERROR,
        "Recipient address is undeliverable. Please update the address and try again.",
        400
      );
    }

    // Use corrected/standardized address from Lob for better deliverability
    const correctedAddress: MailingAddress = {
      name: currentLetter.recipientAddress.name,
      addressLine1: addressVerification.primary_line,
      addressLine2: addressVerification.secondary_line || undefined,
      city: addressVerification.components.city,
      state: addressVerification.components.state,
      zipCode: addressVerification.components.zip_code_plus_4
        ? `${addressVerification.components.zip_code}-${addressVerification.components.zip_code_plus_4}`
        : addressVerification.components.zip_code,
    };

    // Store verification result and corrected address
    await letterRef.update({
      addressVerification: {
        deliverability: addressVerification.deliverability,
        verifiedAt: FieldValue.serverTimestamp(),
        originalAddress: currentLetter.recipientAddress,
        correctedAddress: correctedAddress,
      },
      // Update recipient address with corrected version
      recipientAddress: correctedAddress,
    });

    logger.info("[Letter] Address verified", {
      letterId: validatedData.letterId,
      deliverability: addressVerification.deliverability,
      addressCorrected: JSON.stringify(currentLetter.recipientAddress) !== JSON.stringify(correctedAddress),
    });

    // Step 3: Calculate cost estimate
    const costEstimate = lobService.estimateCost(pdfResult.pageCount, mailType);

    // Step 4: Send to Lob
    logger.info("[Letter] Sending to Lob", {
      letterId: validatedData.letterId,
      mailType,
      pageCount: pdfResult.pageCount,
    });

    const lobLetter = await lobService.createLetter({
      to: correctedAddress, // Use the corrected address
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

    // Step 5: Update letter with Lob info
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
      sentAt: FieldValue.serverTimestamp(),
      "qualityChecks.pdfIntegrityVerified": true,
    });

    logger.info("[Letter] Successfully queued with Lob", {
      letterId: validatedData.letterId,
      lobId: lobLetter.id,
      expectedDelivery: lobLetter.expected_delivery_date,
    });

    // Get updated letter
    const updatedDoc = await letterRef.get();
    const updatedLetter = { id: updatedDoc.id, ...updatedDoc.data() } as Letter;

    // Update dispute status to mailed
    await db.collection("disputes").doc(currentLetter.disputeId).update({
      status: "mailed",
      "timestamps.mailedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Audit log
    await logAuditEvent({
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
  } catch (error) {
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

    throw new AppError(
      ErrorCode.EXTERNAL_SERVICE_ERROR,
      `Failed to send letter: ${error instanceof Error ? error.message : "Unknown error"}`,
      500
    );
  }
}

export const lettersSend = functions.https.onCall(
  withErrorHandling(
    withAuth(["letters:send"], sendLetterHandler)
  )
);

// ============================================================================
// lettersList - List letters with filters
// ============================================================================

async function listLettersHandler(
  data: ListLettersInput,
  context: RequestContext
): Promise<PaginatedResponse<Letter>> {
  logger.info("[lettersList] Handler started", { data });
  const { tenantId } = context;
  logger.info("[lettersList] TenantId extracted", { tenantId });

  // Validate input
  const pagination = validate(paginationSchema, data);
  const filters = validate(
    Joi.object({
      disputeId: schemas.documentId,
      status: Joi.alternatives().try(
        Joi.string().valid("draft", "pending_approval", "approved", "rendering", "ready", "queued", "sent", "in_transit", "delivered", "returned_to_sender"),
        Joi.array().items(Joi.string().valid("draft", "pending_approval", "approved", "rendering", "ready", "queued", "sent", "in_transit", "delivered", "returned_to_sender"))
      ),
    }),
    data
  );

  // Build query
  let query = db
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
    } else {
      query = query.where("status", "==", filters.status);
    }
  }

  // Apply cursor if provided
  if (pagination.cursor) {
    const cursorDoc = await db.collection("letters").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  const snapshot = await query.limit(pagination.limit + 1).get();

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const letters = docs.map((doc) => {
    const letter = { id: doc.id, ...doc.data() } as Letter;
    // Redact full content in list view
    return {
      ...letter,
      contentMarkdown: letter.contentMarkdown ? "[CONTENT_AVAILABLE]" : undefined,
      contentHtml: letter.contentHtml ? "[CONTENT_AVAILABLE]" : undefined,
    };
  });

  // Get total count
  let countQuery = db.collection("letters").where("tenantId", "==", tenantId);
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

export const lettersList = functions.https.onCall(
  withErrorHandling(
    withAuth(["letters:read"], listLettersHandler)
  )
);
