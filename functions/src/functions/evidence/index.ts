/**
 * Evidence Management Cloud Functions
 *
 * Handles evidence file upload, retrieval, and management.
 * Supports virus scanning and secure file storage.
 */

import * as functions from "firebase-functions";
import * as crypto from "crypto";
import { db, storage } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  withAuth,
  RequestContext,
} from "../../middleware/auth";
import {
  validate,
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
  Evidence,
  Dispute,
  VirusScan,
  ApiResponse,
  PaginatedResponse,
} from "../../types";
import { uploadConfig } from "../../config";
import Joi from "joi";

// ============================================================================
// Constants
// ============================================================================

/**
 * Evidence categories for organization
 */
const EVIDENCE_CATEGORIES = [
  "credit_report",
  "identity_document",
  "payment_proof",
  "correspondence",
  "court_document",
  "police_report",
  "ftc_report",
  "bank_statement",
  "other",
] as const;

type EvidenceCategory = typeof EVIDENCE_CATEGORIES[number];

// ============================================================================
// Validation Schemas
// ============================================================================

const evidenceUploadSchema = Joi.object({
  disputeId: schemas.documentId.required(),
  filename: Joi.string().min(1).max(255).required(),
  mimeType: Joi.string()
    .valid(...uploadConfig.allowedMimeTypes)
    .required(),
  fileSize: Joi.number()
    .integer()
    .min(1)
    .max(uploadConfig.maxFileSizeBytes)
    .required(),
  fileBase64: Joi.string().base64().required(),
  description: Joi.string().max(500),
  category: Joi.string().valid(...EVIDENCE_CATEGORIES).default("other"),
  source: Joi.string()
    .valid("consumer_upload", "operator_upload", "smartcredit", "system")
    .default("operator_upload"),
});

const evidenceUpdateSchema = Joi.object({
  description: Joi.string().max(500),
  category: Joi.string().valid(...EVIDENCE_CATEGORIES),
}).min(1);

// ============================================================================
// Type Definitions
// ============================================================================

interface UploadEvidenceInput {
  disputeId: string;
  filename: string;
  mimeType: string;
  fileSize: number;
  fileBase64: string;
  description?: string;
  category?: EvidenceCategory;
  source?: Evidence["source"];
}

interface GetEvidenceInput {
  evidenceId: string;
}

interface DeleteEvidenceInput {
  evidenceId: string;
}

interface UpdateEvidenceInput {
  evidenceId: string;
  description?: string;
  category?: EvidenceCategory;
}

interface ListEvidenceInput {
  disputeId: string;
  category?: EvidenceCategory;
  limit?: number;
  cursor?: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Verify dispute exists and user has access
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
 * Verify evidence exists and user has access
 */
async function verifyEvidenceAccess(
  evidenceId: string,
  tenantId: string
): Promise<Evidence> {
  const evidenceDoc = await db.collection("evidence").doc(evidenceId).get();
  assertExists(evidenceDoc.exists ? evidenceDoc.data() : null, "Evidence", evidenceId);

  const evidence = { id: evidenceDoc.id, ...evidenceDoc.data() } as Evidence;

  if (evidence.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this evidence");
  }

  return evidence;
}

/**
 * Calculate SHA-256 checksum of file data
 */
function calculateChecksum(data: Buffer): string {
  return crypto.createHash("sha256").update(data).digest("hex");
}

/**
 * Generate storage path for evidence file
 */
function getStoragePath(tenantId: string, disputeId: string, evidenceId: string, filename: string): string {
  // Sanitize filename
  const sanitizedFilename = filename.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `tenants/${tenantId}/disputes/${disputeId}/evidence/${evidenceId}/${sanitizedFilename}`;
}

/**
 * Perform basic virus scan check (placeholder - integrate with real scanner)
 * In production, this should use Cloud Run or a service like VirusTotal
 */
async function performVirusScan(
  _fileBuffer: Buffer,
  _mimeType: string
): Promise<VirusScan> {
  // TODO: Integrate with actual virus scanning service
  // For now, return a pending scan that will be processed asynchronously

  return {
    status: "pending",
    scannedAt: FieldValue.serverTimestamp() as unknown as Timestamp,
    engine: "placeholder",
    engineVersion: "1.0.0",
  };
}

/**
 * Check total evidence size for a dispute
 */
async function getTotalEvidenceSize(disputeId: string): Promise<number> {
  const evidenceSnapshot = await db
    .collection("evidence")
    .where("disputeId", "==", disputeId)
    .get();

  return evidenceSnapshot.docs.reduce((total, doc) => {
    const data = doc.data();
    return total + (data.fileSize || 0);
  }, 0);
}

/**
 * Get file extension from filename
 */
function getFileExtension(filename: string): string {
  const parts = filename.split(".");
  return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : "";
}

// ============================================================================
// evidenceUpload - Upload evidence file
// ============================================================================

async function uploadEvidenceHandler(
  data: UploadEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<Evidence>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(evidenceUploadSchema, data);

  // Verify dispute access
  const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  // Check if dispute is in a state that allows evidence upload
  const allowedStatuses = ["draft", "pending_review"];
  if (!allowedStatuses.includes(dispute.status)) {
    throw new AppError(
      ErrorCode.INVALID_DISPUTE_STATUS,
      `Cannot add evidence to dispute in '${dispute.status}' status. Must be draft or pending_review.`,
      400
    );
  }

  // Decode file from base64
  const fileBuffer = Buffer.from(validatedData.fileBase64, "base64");

  // Verify file size matches
  if (fileBuffer.length !== validatedData.fileSize) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      `File size mismatch. Expected ${validatedData.fileSize} bytes, got ${fileBuffer.length} bytes.`,
      400
    );
  }

  // Check total evidence size for dispute
  const currentTotalSize = await getTotalEvidenceSize(validatedData.disputeId);
  if (currentTotalSize + fileBuffer.length > uploadConfig.maxTotalSizePerDispute) {
    throw new AppError(
      ErrorCode.FILE_TOO_LARGE,
      `Total evidence size would exceed limit. Current: ${Math.round(currentTotalSize / 1024 / 1024)}MB, Limit: ${Math.round(uploadConfig.maxTotalSizePerDispute / 1024 / 1024)}MB`,
      400
    );
  }

  // Calculate checksum
  const checksum = calculateChecksum(fileBuffer);

  // Check for duplicate evidence by checksum
  const existingEvidence = await db
    .collection("evidence")
    .where("disputeId", "==", validatedData.disputeId)
    .where("checksum", "==", checksum)
    .limit(1)
    .get();

  if (!existingEvidence.empty) {
    throw new AppError(
      ErrorCode.ALREADY_EXISTS,
      "This file has already been uploaded as evidence for this dispute",
      409
    );
  }

  // Generate evidence ID and storage path
  const evidenceId = uuidv4();
  const storagePath = getStoragePath(
    tenantId,
    validatedData.disputeId,
    evidenceId,
    validatedData.filename
  );

  // Upload to Cloud Storage
  const bucket = storage.bucket();
  const file = bucket.file(storagePath);

  await file.save(fileBuffer, {
    metadata: {
      contentType: validatedData.mimeType,
      metadata: {
        tenantId,
        disputeId: validatedData.disputeId,
        evidenceId,
        uploadedBy: actorId,
        originalFilename: validatedData.filename,
      },
    },
  });

  // Perform virus scan (async - will update status later)
  const virusScan = await performVirusScan(fileBuffer, validatedData.mimeType);

  // Create evidence document
  const now = FieldValue.serverTimestamp() as unknown as Timestamp;
  const evidence: Evidence = {
    id: evidenceId,
    disputeId: validatedData.disputeId,
    tenantId,
    filename: `${evidenceId}.${getFileExtension(validatedData.filename)}`,
    originalFilename: validatedData.filename,
    fileUrl: storagePath,
    mimeType: validatedData.mimeType,
    fileSize: fileBuffer.length,
    checksum,
    source: validatedData.source || "operator_upload",
    description: validatedData.description,
    category: validatedData.category,
    virusScan,
    redactions: [],
    linkedToLetters: [],
    uploadedAt: now,
    uploadedBy: actorId,
  };

  await db.collection("evidence").doc(evidenceId).set(evidence);

  // Update dispute's evidence list
  await db.collection("disputes").doc(validatedData.disputeId).update({
    evidenceIds: FieldValue.arrayUnion(evidenceId),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "evidence",
    entityId: evidenceId,
    action: "upload",
    newState: {
      ...evidence,
      fileBase64: "[REDACTED]",
    } as unknown as Record<string, unknown>,
    metadata: {
      disputeId: validatedData.disputeId,
      filename: validatedData.filename,
      fileSize: fileBuffer.length,
      mimeType: validatedData.mimeType,
    },
  });

  return {
    success: true,
    data: evidence,
  };
}

export const evidenceUpload = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:write"], uploadEvidenceHandler)
  )
);

// ============================================================================
// evidenceGet - Get evidence details
// ============================================================================

async function getEvidenceHandler(
  data: GetEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<Evidence & { downloadUrl?: string }>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ evidenceId: schemas.documentId.required() }),
    data
  );

  // Get evidence and verify access
  const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);

  // Generate signed download URL (valid for 1 hour)
  let downloadUrl: string | undefined;
  try {
    const bucket = storage.bucket();
    const file = bucket.file(evidence.fileUrl);

    const [url] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });
    downloadUrl = url;
  } catch {
    // File might not exist in storage
    downloadUrl = undefined;
  }

  return {
    success: true,
    data: {
      ...evidence,
      downloadUrl,
    },
  };
}

export const evidenceGet = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:read"], getEvidenceHandler)
  )
);

// ============================================================================
// evidenceUpdate - Update evidence metadata
// ============================================================================

async function updateEvidenceHandler(
  data: UpdateEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<Evidence>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate evidence ID
  const validatedEvidenceId = validate(
    Joi.object({ evidenceId: schemas.documentId.required() }),
    { evidenceId: data.evidenceId }
  );

  // Validate update data
  const validatedData = validate(evidenceUpdateSchema, data);

  // Get evidence and verify access
  const currentEvidence = await verifyEvidenceAccess(validatedEvidenceId.evidenceId, tenantId);

  // Build update object
  const updates: Record<string, unknown> = {
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (validatedData.description !== undefined) {
    updates.description = validatedData.description;
  }

  if (validatedData.category !== undefined) {
    updates.category = validatedData.category;
  }

  // Update evidence document
  const evidenceRef = db.collection("evidence").doc(validatedEvidenceId.evidenceId);
  await evidenceRef.update(updates);

  // Get updated evidence
  const updatedDoc = await evidenceRef.get();
  const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() } as Evidence;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "evidence",
    entityId: validatedEvidenceId.evidenceId,
    action: "update",
    previousState: currentEvidence as unknown as Record<string, unknown>,
    newState: updatedEvidence as unknown as Record<string, unknown>,
  });

  return {
    success: true,
    data: updatedEvidence,
  };
}

export const evidenceUpdate = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:write"], updateEvidenceHandler)
  )
);

// ============================================================================
// evidenceDelete - Delete evidence
// ============================================================================

async function deleteEvidenceHandler(
  data: DeleteEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<{ deleted: boolean }>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ evidenceId: schemas.documentId.required() }),
    data
  );

  // Get evidence and verify access
  const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);

  // Check if evidence is linked to any letters
  if (evidence.linkedToLetters && evidence.linkedToLetters.length > 0) {
    throw new AppError(
      ErrorCode.FORBIDDEN,
      "Cannot delete evidence that is linked to letters. Unlink from letters first.",
      400
    );
  }

  // Get the dispute to verify its state
  const disputeDoc = await db.collection("disputes").doc(evidence.disputeId).get();
  if (disputeDoc.exists) {
    const dispute = disputeDoc.data() as Dispute;
    const allowedStatuses = ["draft", "pending_review"];
    if (!allowedStatuses.includes(dispute.status)) {
      throw new AppError(
        ErrorCode.INVALID_DISPUTE_STATUS,
        `Cannot delete evidence from dispute in '${dispute.status}' status.`,
        400
      );
    }
  }

  // Delete from Cloud Storage
  try {
    const bucket = storage.bucket();
    const file = bucket.file(evidence.fileUrl);
    await file.delete();
  } catch {
    // File might already be deleted - continue with document deletion
  }

  // Remove evidence reference from dispute
  if (disputeDoc.exists) {
    await db.collection("disputes").doc(evidence.disputeId).update({
      evidenceIds: FieldValue.arrayRemove(validatedData.evidenceId),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Delete evidence document
  await db.collection("evidence").doc(validatedData.evidenceId).delete();

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "evidence",
    entityId: validatedData.evidenceId,
    action: "delete",
    previousState: evidence as unknown as Record<string, unknown>,
    metadata: {
      disputeId: evidence.disputeId,
      filename: evidence.originalFilename,
    },
  });

  return {
    success: true,
    data: { deleted: true },
  };
}

export const evidenceDelete = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:delete"], deleteEvidenceHandler)
  )
);

// ============================================================================
// evidenceList - List evidence for a dispute
// ============================================================================

async function listEvidenceHandler(
  data: ListEvidenceInput,
  context: RequestContext
): Promise<PaginatedResponse<Evidence>> {
  const { tenantId } = context;

  // Validate pagination
  const pagination = validate(paginationSchema, data);

  // Validate dispute ID
  const validatedDisputeId = validate(
    Joi.object({ disputeId: schemas.documentId.required() }),
    { disputeId: data.disputeId }
  );

  // Verify dispute access
  await verifyDisputeAccess(validatedDisputeId.disputeId, tenantId);

  // Build query
  let query = db
    .collection("evidence")
    .where("disputeId", "==", validatedDisputeId.disputeId)
    .where("tenantId", "==", tenantId)
    .orderBy("uploadedAt", "desc");

  // Filter by category if specified
  if (data.category) {
    const validCategory = validate(
      Joi.string().valid(...EVIDENCE_CATEGORIES),
      data.category
    );
    query = query.where("category", "==", validCategory);
  }

  // Apply cursor if provided
  if (pagination.cursor) {
    const cursorDoc = await db.collection("evidence").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  const snapshot = await query.limit(pagination.limit + 1).get();

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const evidenceItems = docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  } as Evidence));

  // Get total count for this dispute
  const countSnapshot = await db
    .collection("evidence")
    .where("disputeId", "==", validatedDisputeId.disputeId)
    .where("tenantId", "==", tenantId)
    .count()
    .get();

  return {
    success: true,
    data: {
      items: evidenceItems,
      pagination: {
        total: countSnapshot.data().count,
        limit: pagination.limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const evidenceList = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:read"], listEvidenceHandler)
  )
);

// ============================================================================
// evidenceLinkToLetter - Link evidence to a letter
// ============================================================================

interface LinkEvidenceInput {
  evidenceId: string;
  letterId: string;
}

async function linkEvidenceHandler(
  data: LinkEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<Evidence>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      evidenceId: schemas.documentId.required(),
      letterId: schemas.documentId.required(),
    }),
    data
  );

  // Verify evidence access
  const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);

  // Verify letter exists and belongs to same tenant
  const letterDoc = await db.collection("letters").doc(validatedData.letterId).get();
  assertExists(letterDoc.exists ? letterDoc.data() : null, "Letter", validatedData.letterId);

  const letter = letterDoc.data();
  if (letter?.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this letter");
  }

  // Verify evidence and letter are for the same dispute
  if (evidence.disputeId !== letter.disputeId) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Evidence and letter must belong to the same dispute",
      400
    );
  }

  // Update evidence to include letter reference
  const evidenceRef = db.collection("evidence").doc(validatedData.evidenceId);
  await evidenceRef.update({
    linkedToLetters: FieldValue.arrayUnion(validatedData.letterId),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Get updated evidence
  const updatedDoc = await evidenceRef.get();
  const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() } as Evidence;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "evidence",
    entityId: validatedData.evidenceId,
    action: "update",
    previousState: evidence as unknown as Record<string, unknown>,
    newState: updatedEvidence as unknown as Record<string, unknown>,
    metadata: {
      linkedLetterId: validatedData.letterId,
    },
  });

  return {
    success: true,
    data: updatedEvidence,
  };
}

export const evidenceLinkToLetter = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:write", "letters:write"], linkEvidenceHandler)
  )
);

// ============================================================================
// evidenceUnlinkFromLetter - Unlink evidence from a letter
// ============================================================================

interface UnlinkEvidenceInput {
  evidenceId: string;
  letterId: string;
}

async function unlinkEvidenceHandler(
  data: UnlinkEvidenceInput,
  context: RequestContext
): Promise<ApiResponse<Evidence>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      evidenceId: schemas.documentId.required(),
      letterId: schemas.documentId.required(),
    }),
    data
  );

  // Verify evidence access
  const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);

  // Update evidence to remove letter reference
  const evidenceRef = db.collection("evidence").doc(validatedData.evidenceId);
  await evidenceRef.update({
    linkedToLetters: FieldValue.arrayRemove(validatedData.letterId),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Get updated evidence
  const updatedDoc = await evidenceRef.get();
  const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() } as Evidence;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "evidence",
    entityId: validatedData.evidenceId,
    action: "update",
    previousState: evidence as unknown as Record<string, unknown>,
    newState: updatedEvidence as unknown as Record<string, unknown>,
    metadata: {
      unlinkedLetterId: validatedData.letterId,
    },
  });

  return {
    success: true,
    data: updatedEvidence,
  };
}

export const evidenceUnlinkFromLetter = functions.https.onCall(
  withErrorHandling(
    withAuth(["evidence:write", "letters:write"], unlinkEvidenceHandler)
  )
);
