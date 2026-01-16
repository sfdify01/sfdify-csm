"use strict";
/**
 * Evidence Management Cloud Functions
 *
 * Handles evidence file upload, retrieval, and management.
 * Supports virus scanning and secure file storage.
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
exports.evidenceUnlinkFromLetter = exports.evidenceLinkToLetter = exports.evidenceList = exports.evidenceDelete = exports.evidenceUpdate = exports.evidenceGet = exports.evidenceUpload = void 0;
const functions = __importStar(require("firebase-functions"));
const crypto = __importStar(require("crypto"));
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
];
// ============================================================================
// Validation Schemas
// ============================================================================
const evidenceUploadSchema = joi_1.default.object({
    disputeId: validation_1.schemas.documentId.required(),
    filename: joi_1.default.string().min(1).max(255).required(),
    mimeType: joi_1.default.string()
        .valid(...config_1.uploadConfig.allowedMimeTypes)
        .required(),
    fileSize: joi_1.default.number()
        .integer()
        .min(1)
        .max(config_1.uploadConfig.maxFileSizeBytes)
        .required(),
    fileBase64: joi_1.default.string().base64().required(),
    description: joi_1.default.string().max(500),
    category: joi_1.default.string().valid(...EVIDENCE_CATEGORIES).default("other"),
    source: joi_1.default.string()
        .valid("consumer_upload", "operator_upload", "smartcredit", "system")
        .default("operator_upload"),
});
const evidenceUpdateSchema = joi_1.default.object({
    description: joi_1.default.string().max(500),
    category: joi_1.default.string().valid(...EVIDENCE_CATEGORIES),
}).min(1);
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Verify dispute exists and user has access
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
 * Verify evidence exists and user has access
 */
async function verifyEvidenceAccess(evidenceId, tenantId) {
    const evidenceDoc = await admin_1.db.collection("evidence").doc(evidenceId).get();
    (0, errors_1.assertExists)(evidenceDoc.exists ? evidenceDoc.data() : null, "Evidence", evidenceId);
    const evidence = { id: evidenceDoc.id, ...evidenceDoc.data() };
    if (evidence.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this evidence");
    }
    return evidence;
}
/**
 * Calculate SHA-256 checksum of file data
 */
function calculateChecksum(data) {
    return crypto.createHash("sha256").update(data).digest("hex");
}
/**
 * Generate storage path for evidence file
 */
function getStoragePath(tenantId, disputeId, evidenceId, filename) {
    // Sanitize filename
    const sanitizedFilename = filename.replace(/[^a-zA-Z0-9._-]/g, "_");
    return `tenants/${tenantId}/disputes/${disputeId}/evidence/${evidenceId}/${sanitizedFilename}`;
}
/**
 * Perform basic virus scan check (placeholder - integrate with real scanner)
 * In production, this should use Cloud Run or a service like VirusTotal
 */
async function performVirusScan(_fileBuffer, _mimeType) {
    // TODO: Integrate with actual virus scanning service
    // For now, return a pending scan that will be processed asynchronously
    return {
        status: "pending",
        scannedAt: firestore_1.FieldValue.serverTimestamp(),
        engine: "placeholder",
        engineVersion: "1.0.0",
    };
}
/**
 * Check total evidence size for a dispute
 */
async function getTotalEvidenceSize(disputeId) {
    const evidenceSnapshot = await admin_1.db
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
function getFileExtension(filename) {
    const parts = filename.split(".");
    return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : "";
}
// ============================================================================
// evidenceUpload - Upload evidence file
// ============================================================================
async function uploadEvidenceHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(evidenceUploadSchema, data);
    // Verify dispute access
    const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);
    // Check if dispute is in a state that allows evidence upload
    const allowedStatuses = ["draft", "pending_review"];
    if (!allowedStatuses.includes(dispute.status)) {
        throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot add evidence to dispute in '${dispute.status}' status. Must be draft or pending_review.`, 400);
    }
    // Decode file from base64
    const fileBuffer = Buffer.from(validatedData.fileBase64, "base64");
    // Verify file size matches
    if (fileBuffer.length !== validatedData.fileSize) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, `File size mismatch. Expected ${validatedData.fileSize} bytes, got ${fileBuffer.length} bytes.`, 400);
    }
    // Check total evidence size for dispute
    const currentTotalSize = await getTotalEvidenceSize(validatedData.disputeId);
    if (currentTotalSize + fileBuffer.length > config_1.uploadConfig.maxTotalSizePerDispute) {
        throw new errors_1.AppError(errors_1.ErrorCode.FILE_TOO_LARGE, `Total evidence size would exceed limit. Current: ${Math.round(currentTotalSize / 1024 / 1024)}MB, Limit: ${Math.round(config_1.uploadConfig.maxTotalSizePerDispute / 1024 / 1024)}MB`, 400);
    }
    // Calculate checksum
    const checksum = calculateChecksum(fileBuffer);
    // Check for duplicate evidence by checksum
    const existingEvidence = await admin_1.db
        .collection("evidence")
        .where("disputeId", "==", validatedData.disputeId)
        .where("checksum", "==", checksum)
        .limit(1)
        .get();
    if (!existingEvidence.empty) {
        throw new errors_1.AppError(errors_1.ErrorCode.ALREADY_EXISTS, "This file has already been uploaded as evidence for this dispute", 409);
    }
    // Generate evidence ID and storage path
    const evidenceId = (0, uuid_1.v4)();
    const storagePath = getStoragePath(tenantId, validatedData.disputeId, evidenceId, validatedData.filename);
    // Upload to Cloud Storage
    const bucket = admin_1.storage.bucket();
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
    const now = firestore_1.FieldValue.serverTimestamp();
    const evidence = {
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
    await admin_1.db.collection("evidence").doc(evidenceId).set(evidence);
    // Update dispute's evidence list
    await admin_1.db.collection("disputes").doc(validatedData.disputeId).update({
        evidenceIds: firestore_1.FieldValue.arrayUnion(evidenceId),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "evidence",
        entityId: evidenceId,
        action: "upload",
        newState: {
            ...evidence,
            fileBase64: "[REDACTED]",
        },
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
exports.evidenceUpload = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:write"], uploadEvidenceHandler)));
// ============================================================================
// evidenceGet - Get evidence details
// ============================================================================
async function getEvidenceHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ evidenceId: validation_1.schemas.documentId.required() }), data);
    // Get evidence and verify access
    const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);
    // Generate signed download URL (valid for 1 hour)
    let downloadUrl;
    try {
        const bucket = admin_1.storage.bucket();
        const file = bucket.file(evidence.fileUrl);
        const [url] = await file.getSignedUrl({
            action: "read",
            expires: Date.now() + 60 * 60 * 1000, // 1 hour
        });
        downloadUrl = url;
    }
    catch {
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
exports.evidenceGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:read"], getEvidenceHandler)));
// ============================================================================
// evidenceUpdate - Update evidence metadata
// ============================================================================
async function updateEvidenceHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate evidence ID
    const validatedEvidenceId = (0, validation_1.validate)(joi_1.default.object({ evidenceId: validation_1.schemas.documentId.required() }), { evidenceId: data.evidenceId });
    // Validate update data
    const validatedData = (0, validation_1.validate)(evidenceUpdateSchema, data);
    // Get evidence and verify access
    const currentEvidence = await verifyEvidenceAccess(validatedEvidenceId.evidenceId, tenantId);
    // Build update object
    const updates = {
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (validatedData.description !== undefined) {
        updates.description = validatedData.description;
    }
    if (validatedData.category !== undefined) {
        updates.category = validatedData.category;
    }
    // Update evidence document
    const evidenceRef = admin_1.db.collection("evidence").doc(validatedEvidenceId.evidenceId);
    await evidenceRef.update(updates);
    // Get updated evidence
    const updatedDoc = await evidenceRef.get();
    const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "evidence",
        entityId: validatedEvidenceId.evidenceId,
        action: "update",
        previousState: currentEvidence,
        newState: updatedEvidence,
    });
    return {
        success: true,
        data: updatedEvidence,
    };
}
exports.evidenceUpdate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:write"], updateEvidenceHandler)));
// ============================================================================
// evidenceDelete - Delete evidence
// ============================================================================
async function deleteEvidenceHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ evidenceId: validation_1.schemas.documentId.required() }), data);
    // Get evidence and verify access
    const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);
    // Check if evidence is linked to any letters
    if (evidence.linkedToLetters && evidence.linkedToLetters.length > 0) {
        throw new errors_1.AppError(errors_1.ErrorCode.FORBIDDEN, "Cannot delete evidence that is linked to letters. Unlink from letters first.", 400);
    }
    // Get the dispute to verify its state
    const disputeDoc = await admin_1.db.collection("disputes").doc(evidence.disputeId).get();
    if (disputeDoc.exists) {
        const dispute = disputeDoc.data();
        const allowedStatuses = ["draft", "pending_review"];
        if (!allowedStatuses.includes(dispute.status)) {
            throw new errors_1.AppError(errors_1.ErrorCode.INVALID_DISPUTE_STATUS, `Cannot delete evidence from dispute in '${dispute.status}' status.`, 400);
        }
    }
    // Delete from Cloud Storage
    try {
        const bucket = admin_1.storage.bucket();
        const file = bucket.file(evidence.fileUrl);
        await file.delete();
    }
    catch {
        // File might already be deleted - continue with document deletion
    }
    // Remove evidence reference from dispute
    if (disputeDoc.exists) {
        await admin_1.db.collection("disputes").doc(evidence.disputeId).update({
            evidenceIds: firestore_1.FieldValue.arrayRemove(validatedData.evidenceId),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    // Delete evidence document
    await admin_1.db.collection("evidence").doc(validatedData.evidenceId).delete();
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "evidence",
        entityId: validatedData.evidenceId,
        action: "delete",
        previousState: evidence,
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
exports.evidenceDelete = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:delete"], deleteEvidenceHandler)));
// ============================================================================
// evidenceList - List evidence for a dispute
// ============================================================================
async function listEvidenceHandler(data, context) {
    const { tenantId } = context;
    // Validate pagination
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    // Validate dispute ID
    const validatedDisputeId = (0, validation_1.validate)(joi_1.default.object({ disputeId: validation_1.schemas.documentId.required() }), { disputeId: data.disputeId });
    // Verify dispute access
    await verifyDisputeAccess(validatedDisputeId.disputeId, tenantId);
    // Build query
    let query = admin_1.db
        .collection("evidence")
        .where("disputeId", "==", validatedDisputeId.disputeId)
        .where("tenantId", "==", tenantId)
        .orderBy("uploadedAt", "desc");
    // Filter by category if specified
    if (data.category) {
        const validCategory = (0, validation_1.validate)(joi_1.default.string().valid(...EVIDENCE_CATEGORIES), data.category);
        query = query.where("category", "==", validCategory);
    }
    // Apply cursor if provided
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("evidence").doc(pagination.cursor).get();
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
    }));
    // Get total count for this dispute
    const countSnapshot = await admin_1.db
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
exports.evidenceList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:read"], listEvidenceHandler)));
async function linkEvidenceHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        evidenceId: validation_1.schemas.documentId.required(),
        letterId: validation_1.schemas.documentId.required(),
    }), data);
    // Verify evidence access
    const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);
    // Verify letter exists and belongs to same tenant
    const letterDoc = await admin_1.db.collection("letters").doc(validatedData.letterId).get();
    (0, errors_1.assertExists)(letterDoc.exists ? letterDoc.data() : null, "Letter", validatedData.letterId);
    const letter = letterDoc.data();
    if (letter?.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this letter");
    }
    // Verify evidence and letter are for the same dispute
    if (evidence.disputeId !== letter.disputeId) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, "Evidence and letter must belong to the same dispute", 400);
    }
    // Update evidence to include letter reference
    const evidenceRef = admin_1.db.collection("evidence").doc(validatedData.evidenceId);
    await evidenceRef.update({
        linkedToLetters: firestore_1.FieldValue.arrayUnion(validatedData.letterId),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Get updated evidence
    const updatedDoc = await evidenceRef.get();
    const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "evidence",
        entityId: validatedData.evidenceId,
        action: "update",
        previousState: evidence,
        newState: updatedEvidence,
        metadata: {
            linkedLetterId: validatedData.letterId,
        },
    });
    return {
        success: true,
        data: updatedEvidence,
    };
}
exports.evidenceLinkToLetter = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:write", "letters:write"], linkEvidenceHandler)));
async function unlinkEvidenceHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({
        evidenceId: validation_1.schemas.documentId.required(),
        letterId: validation_1.schemas.documentId.required(),
    }), data);
    // Verify evidence access
    const evidence = await verifyEvidenceAccess(validatedData.evidenceId, tenantId);
    // Update evidence to remove letter reference
    const evidenceRef = admin_1.db.collection("evidence").doc(validatedData.evidenceId);
    await evidenceRef.update({
        linkedToLetters: firestore_1.FieldValue.arrayRemove(validatedData.letterId),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Get updated evidence
    const updatedDoc = await evidenceRef.get();
    const updatedEvidence = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "evidence",
        entityId: validatedData.evidenceId,
        action: "update",
        previousState: evidence,
        newState: updatedEvidence,
        metadata: {
            unlinkedLetterId: validatedData.letterId,
        },
    });
    return {
        success: true,
        data: updatedEvidence,
    };
}
exports.evidenceUnlinkFromLetter = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["evidence:write", "letters:write"], unlinkEvidenceHandler)));
//# sourceMappingURL=index.js.map