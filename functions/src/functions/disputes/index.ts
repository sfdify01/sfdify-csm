/**
 * Dispute Management Cloud Functions
 *
 * Handles dispute lifecycle: creation, updates, approval, submission, and closure.
 * Implements FCRA 30/45 day SLA tracking and status transitions.
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
  createDisputeSchema,
  updateDisputeSchema,
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
  Dispute,
  DisputeStatus,
  DisputeType,
  DisputeTimestamps,
  DisputeSla,
  DisputeOutcome,
  DisputeOutcomeDetails,
  Bureau,
  Tradeline,
  Consumer,
  ApiResponse,
  PaginatedResponse,
} from "../../types";
import { slaConfig } from "../../config";
import Joi from "joi";

// ============================================================================
// Constants
// ============================================================================

/**
 * Valid status transitions for disputes
 */
const STATUS_TRANSITIONS: Record<DisputeStatus, DisputeStatus[]> = {
  draft: ["pending_review"],
  pending_review: ["approved", "rejected", "draft"],
  approved: ["mailed"],
  rejected: ["draft"],
  mailed: ["delivered", "bureau_investigating"],
  delivered: ["bureau_investigating"],
  bureau_investigating: ["resolved", "closed"],
  resolved: ["closed"],
  closed: [],
};

/**
 * Statuses that can still be edited
 */
const EDITABLE_STATUSES: DisputeStatus[] = ["draft", "pending_review", "rejected"];

// ============================================================================
// Type Definitions
// ============================================================================

interface CreateDisputeInput {
  consumerId: string;
  tradelineId: string;
  bureau: Bureau;
  type: DisputeType;
  reasonCodes: string[];
  reasonDetails?: Record<string, {
    reportedValue?: string | number;
    actualValue?: string | number;
    explanation: string;
  }>;
  narrative?: string;
  evidenceIds?: string[];
  priority?: "low" | "normal" | "high" | "urgent";
  aiDraftAssist?: boolean;
}

interface UpdateDisputeInput {
  disputeId: string;
  narrative?: string;
  priority?: "low" | "normal" | "high" | "urgent";
  assignedTo?: string | null;
  reasonCodes?: string[];
  reasonDetails?: Record<string, unknown>;
  internalNotes?: string;
  tags?: string[];
}

interface ListDisputesInput {
  consumerId?: string;
  status?: DisputeStatus | DisputeStatus[];
  bureau?: Bureau;
  assignedTo?: string;
  priority?: "low" | "normal" | "high" | "urgent";
  limit?: number;
  cursor?: string;
}

interface GetDisputeInput {
  disputeId: string;
}

interface SubmitDisputeInput {
  disputeId: string;
}

interface ApproveDisputeInput {
  disputeId: string;
  comments?: string;
}

interface CloseDisputeInput {
  disputeId: string;
  outcome: DisputeOutcome;
  outcomeDetails?: DisputeOutcomeDetails;
  internalNotes?: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Validate status transition is allowed
 */
function validateStatusTransition(
  currentStatus: DisputeStatus,
  newStatus: DisputeStatus
): void {
  const allowedTransitions = STATUS_TRANSITIONS[currentStatus];
  if (!allowedTransitions.includes(newStatus)) {
    throw new AppError(
      ErrorCode.INVALID_DISPUTE_STATUS,
      `Cannot transition from '${currentStatus}' to '${newStatus}'. Allowed transitions: ${allowedTransitions.join(", ") || "none"}`,
      400
    );
  }
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
 * Verify tradeline exists and belongs to tenant
 */
async function verifyTradelineAccess(
  tradelineId: string,
  tenantId: string
): Promise<Tradeline> {
  const tradelineDoc = await db.collection("tradelines").doc(tradelineId).get();
  assertExists(tradelineDoc.exists ? tradelineDoc.data() : null, "Tradeline", tradelineId);

  const tradeline = { id: tradelineDoc.id, ...tradelineDoc.data() } as Tradeline;

  if (tradeline.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this tradeline");
  }

  return tradeline;
}

/**
 * Verify consumer exists and belongs to tenant
 */
async function verifyConsumerAccess(
  consumerId: string,
  tenantId: string
): Promise<Consumer> {
  const consumerDoc = await db.collection("consumers").doc(consumerId).get();
  assertExists(consumerDoc.exists ? consumerDoc.data() : null, "Consumer", consumerId);

  const consumer = { id: consumerDoc.id, ...consumerDoc.data() } as Consumer;

  if (consumer.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this consumer");
  }

  return consumer;
}

// ============================================================================
// disputesCreate - Create a new dispute
// ============================================================================

async function createDisputeHandler(
  data: CreateDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;

  // Validate input
  const validatedData = validate(createDisputeSchema, data);

  // Check tenant dispute limits
  const currentMonth = new Date();
  currentMonth.setDate(1);
  currentMonth.setHours(0, 0, 0, 0);

  const disputesThisMonth = await db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .where("timestamps.createdAt", ">=", Timestamp.fromDate(currentMonth))
    .count()
    .get();

  const maxDisputes = tenant.features?.maxDisputesPerMonth || 500;
  if (disputesThisMonth.data().count >= maxDisputes) {
    throw new AppError(
      ErrorCode.TENANT_LIMIT_EXCEEDED,
      `Monthly dispute limit reached. Maximum ${maxDisputes} disputes per month allowed.`,
      400
    );
  }

  // Verify consumer and tradeline access
  await verifyConsumerAccess(validatedData.consumerId, tenantId);
  const tradeline = await verifyTradelineAccess(validatedData.tradelineId, tenantId);

  // Verify tradeline belongs to the consumer
  if (tradeline.consumerId !== validatedData.consumerId) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Tradeline does not belong to the specified consumer",
      400
    );
  }

  // Check if there's already an active dispute for this tradeline+bureau
  const existingDispute = await db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .where("tradelineId", "==", validatedData.tradelineId)
    .where("bureau", "==", validatedData.bureau)
    .where("status", "not-in", ["closed", "resolved"])
    .limit(1)
    .get();

  if (!existingDispute.empty) {
    throw new AppError(
      ErrorCode.ALREADY_EXISTS,
      "An active dispute already exists for this tradeline and bureau",
      409
    );
  }

  // Create dispute
  const disputeId = uuidv4();
  const now = FieldValue.serverTimestamp() as unknown as Timestamp;

  const timestamps: DisputeTimestamps = {
    createdAt: now,
  };

  const sla: DisputeSla = {
    baseDays: slaConfig.baseDays,
    extendedDays: slaConfig.extensionDays,
    isExtended: false,
  };

  const dispute: Dispute = {
    id: disputeId,
    consumerId: validatedData.consumerId,
    tradelineId: validatedData.tradelineId,
    tenantId,
    bureau: validatedData.bureau,
    type: validatedData.type,
    reasonCodes: validatedData.reasonCodes,
    reasonDetails: validatedData.reasonDetails || {},
    narrative: validatedData.narrative || "",
    status: "draft",
    priority: validatedData.priority || "normal",
    assignedTo: actorId, // Assign to creator by default
    timestamps,
    sla,
    letterIds: [],
    evidenceIds: validatedData.evidenceIds || [],
    tags: [],
    createdBy: actorId,
    updatedAt: now,
  };

  await db.collection("disputes").doc(disputeId).set(dispute);

  // Update tradeline dispute status
  await db.collection("tradelines").doc(validatedData.tradelineId).update({
    disputeStatus: "in_dispute",
    disputeFlag: true,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "dispute",
    entityId: disputeId,
    action: "create",
    newState: dispute as unknown as Record<string, unknown>,
    metadata: {
      source: "dispute_management",
      consumerId: validatedData.consumerId,
      tradelineId: validatedData.tradelineId,
    },
  });

  return {
    success: true,
    data: dispute,
  };
}

export const disputesCreate = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:write"], createDisputeHandler)
  )
);

// ============================================================================
// disputesGet - Get dispute details
// ============================================================================

async function getDisputeHandler(
  data: GetDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ disputeId: schemas.documentId.required() }),
    data
  );

  const dispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  return {
    success: true,
    data: dispute,
  };
}

export const disputesGet = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:read"], getDisputeHandler)
  )
);

// ============================================================================
// disputesUpdate - Update dispute details
// ============================================================================

async function updateDisputeHandler(
  data: UpdateDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedDisputeId = validate(
    Joi.object({ disputeId: schemas.documentId.required() }),
    { disputeId: data.disputeId }
  );
  const validatedData = validate(updateDisputeSchema, data);

  // Get current dispute
  const disputeRef = db.collection("disputes").doc(validatedDisputeId.disputeId);
  const currentDispute = await verifyDisputeAccess(validatedDisputeId.disputeId, tenantId);

  // Check if dispute is editable
  if (!EDITABLE_STATUSES.includes(currentDispute.status)) {
    throw new AppError(
      ErrorCode.INVALID_DISPUTE_STATUS,
      `Cannot edit dispute in '${currentDispute.status}' status. Editable statuses: ${EDITABLE_STATUSES.join(", ")}`,
      400
    );
  }

  // Build update object
  const updates: Record<string, unknown> = {
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (validatedData.narrative !== undefined) {
    updates.narrative = validatedData.narrative;
  }

  if (validatedData.priority !== undefined) {
    updates.priority = validatedData.priority;
  }

  if (validatedData.assignedTo !== undefined) {
    updates.assignedTo = validatedData.assignedTo;
  }

  if (validatedData.reasonCodes !== undefined) {
    updates.reasonCodes = validatedData.reasonCodes;
  }

  if (validatedData.reasonDetails !== undefined) {
    updates.reasonDetails = validatedData.reasonDetails;
  }

  if (validatedData.internalNotes !== undefined) {
    updates.internalNotes = validatedData.internalNotes;
  }

  if (validatedData.tags !== undefined) {
    updates.tags = validatedData.tags;
  }

  // Update dispute
  await disputeRef.update(updates);

  // Get updated dispute
  const updatedDoc = await disputeRef.get();
  const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() } as Dispute;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "dispute",
    entityId: validatedDisputeId.disputeId,
    action: "update",
    previousState: currentDispute as unknown as Record<string, unknown>,
    newState: updatedDispute as unknown as Record<string, unknown>,
  });

  return {
    success: true,
    data: updatedDispute,
  };
}

export const disputesUpdate = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:write"], updateDisputeHandler)
  )
);

// ============================================================================
// disputesList - List disputes with filters
// ============================================================================

async function listDisputesHandler(
  data: ListDisputesInput,
  context: RequestContext
): Promise<PaginatedResponse<Dispute>> {
  const { tenantId } = context;

  // Validate input
  const pagination = validate(paginationSchema, data);

  const filters = validate(
    Joi.object({
      consumerId: schemas.documentId,
      status: Joi.alternatives().try(
        Joi.string().valid("draft", "pending_review", "approved", "rejected", "mailed", "delivered", "bureau_investigating", "resolved", "closed"),
        Joi.array().items(Joi.string().valid("draft", "pending_review", "approved", "rejected", "mailed", "delivered", "bureau_investigating", "resolved", "closed"))
      ),
      bureau: schemas.bureau,
      assignedTo: schemas.documentId,
      priority: schemas.priority,
    }),
    data
  );

  // Build query
  let query = db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .orderBy("timestamps.createdAt", "desc");

  // Apply filters
  if (filters.consumerId) {
    query = query.where("consumerId", "==", filters.consumerId);
  }

  if (filters.status) {
    if (Array.isArray(filters.status)) {
      query = query.where("status", "in", filters.status);
    } else {
      query = query.where("status", "==", filters.status);
    }
  }

  if (filters.bureau) {
    query = query.where("bureau", "==", filters.bureau);
  }

  if (filters.assignedTo) {
    query = query.where("assignedTo", "==", filters.assignedTo);
  }

  if (filters.priority) {
    query = query.where("priority", "==", filters.priority);
  }

  // Apply cursor if provided
  if (pagination.cursor) {
    const cursorDoc = await db.collection("disputes").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  const snapshot = await query.limit(pagination.limit + 1).get();

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const disputes = docs.map((doc) => ({ id: doc.id, ...doc.data() } as Dispute));

  // Get total count
  let countQuery = db.collection("disputes").where("tenantId", "==", tenantId);
  if (filters.consumerId) {
    countQuery = countQuery.where("consumerId", "==", filters.consumerId);
  }
  if (filters.status && !Array.isArray(filters.status)) {
    countQuery = countQuery.where("status", "==", filters.status);
  }
  const countSnapshot = await countQuery.count().get();
  const totalCount = countSnapshot.data().count;

  return {
    success: true,
    data: {
      items: disputes,
      pagination: {
        total: totalCount,
        limit: pagination.limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const disputesList = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:read"], listDisputesHandler)
  )
);

// ============================================================================
// disputesSubmit - Submit dispute for review
// ============================================================================

async function submitDisputeHandler(
  data: SubmitDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ disputeId: schemas.documentId.required() }),
    data
  );

  // Get current dispute
  const disputeRef = db.collection("disputes").doc(validatedData.disputeId);
  const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  // Validate status transition
  validateStatusTransition(currentDispute.status, "pending_review");

  // Validate dispute is ready for submission
  if (!currentDispute.narrative || currentDispute.narrative.length < 50) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Dispute narrative must be at least 50 characters",
      400
    );
  }

  if (!currentDispute.reasonCodes || currentDispute.reasonCodes.length === 0) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "At least one reason code is required",
      400
    );
  }

  // Update status
  await disputeRef.update({
    status: "pending_review",
    "timestamps.submittedAt": FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Get updated dispute
  const updatedDoc = await disputeRef.get();
  const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() } as Dispute;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "dispute",
    entityId: validatedData.disputeId,
    action: "status_change",
    actionDetail: "Submitted for review",
    previousState: { status: currentDispute.status },
    newState: { status: "pending_review" },
  });

  return {
    success: true,
    data: updatedDispute,
  };
}

export const disputesSubmit = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:write"], submitDisputeHandler)
  )
);

// ============================================================================
// disputesApprove - Approve a dispute (owner/operator only)
// ============================================================================

async function approveDisputeHandler(
  data: ApproveDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Only owner and operator can approve
  requireRole(context, ["owner", "operator"]);

  // Validate input
  const validatedData = validate(
    Joi.object({
      disputeId: schemas.documentId.required(),
      comments: Joi.string().max(1000),
    }),
    data
  );

  // Get current dispute
  const disputeRef = db.collection("disputes").doc(validatedData.disputeId);
  const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  // Validate status transition
  validateStatusTransition(currentDispute.status, "approved");

  // Update status
  await disputeRef.update({
    status: "approved",
    "timestamps.approvedAt": FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    internalNotes: validatedData.comments
      ? `${currentDispute.internalNotes || ""}\n[Approved] ${validatedData.comments}`.trim()
      : currentDispute.internalNotes,
  });

  // Get updated dispute
  const updatedDoc = await disputeRef.get();
  const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() } as Dispute;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "dispute",
    entityId: validatedData.disputeId,
    action: "approve",
    actionDetail: validatedData.comments || "Approved",
    previousState: { status: currentDispute.status },
    newState: { status: "approved" },
  });

  return {
    success: true,
    data: updatedDispute,
  };
}

export const disputesApprove = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:approve"], approveDisputeHandler)
  )
);

// ============================================================================
// disputesClose - Close a dispute with outcome
// ============================================================================

async function closeDisputeHandler(
  data: CloseDisputeInput,
  context: RequestContext
): Promise<ApiResponse<Dispute>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      disputeId: schemas.documentId.required(),
      outcome: Joi.string().valid(
        "corrected",
        "verified_accurate",
        "deleted",
        "pending",
        "no_response",
        "frivolous"
      ).required(),
      outcomeDetails: Joi.object({
        balanceCorrected: Joi.boolean(),
        statusCorrected: Joi.boolean(),
        accountDeleted: Joi.boolean(),
        noChange: Joi.boolean(),
        bureauResponse: Joi.string().max(2000),
        responseDate: Joi.date().iso(),
      }),
      internalNotes: Joi.string().max(2000),
    }),
    data
  );

  // Get current dispute
  const disputeRef = db.collection("disputes").doc(validatedData.disputeId);
  const currentDispute = await verifyDisputeAccess(validatedData.disputeId, tenantId);

  // Can only close disputes that are in valid closing states
  const closableStatuses: DisputeStatus[] = ["bureau_investigating", "resolved", "delivered"];
  if (!closableStatuses.includes(currentDispute.status)) {
    throw new AppError(
      ErrorCode.INVALID_DISPUTE_STATUS,
      `Cannot close dispute in '${currentDispute.status}' status. Must be in: ${closableStatuses.join(", ")}`,
      400
    );
  }

  // Update dispute
  const updates: Record<string, unknown> = {
    status: "closed",
    outcome: validatedData.outcome,
    "timestamps.closedAt": FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (validatedData.outcomeDetails) {
    updates.outcomeDetails = {
      ...validatedData.outcomeDetails,
      responseDate: validatedData.outcomeDetails.responseDate
        ? Timestamp.fromDate(new Date(validatedData.outcomeDetails.responseDate as unknown as string))
        : undefined,
    };
  }

  if (validatedData.internalNotes) {
    updates.internalNotes = `${currentDispute.internalNotes || ""}\n[Closed] ${validatedData.internalNotes}`.trim();
  }

  await disputeRef.update(updates);

  // Update tradeline dispute status based on outcome
  const tradelineUpdate: Record<string, unknown> = {
    disputeStatus: "resolved",
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (validatedData.outcome === "deleted") {
    tradelineUpdate.disputeFlag = false;
  }

  await db.collection("tradelines").doc(currentDispute.tradelineId).update(tradelineUpdate);

  // Get updated dispute
  const updatedDoc = await disputeRef.get();
  const updatedDispute = { id: updatedDoc.id, ...updatedDoc.data() } as Dispute;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "dispute",
    entityId: validatedData.disputeId,
    action: "status_change",
    actionDetail: `Closed with outcome: ${validatedData.outcome}`,
    previousState: { status: currentDispute.status },
    newState: { status: "closed", outcome: validatedData.outcome },
  });

  return {
    success: true,
    data: updatedDispute,
  };
}

export const disputesClose = functions.https.onCall(
  withErrorHandling(
    withAuth(["disputes:write"], closeDisputeHandler)
  )
);
