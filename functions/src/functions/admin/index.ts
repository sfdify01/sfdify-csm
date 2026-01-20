/**
 * Admin & Analytics Cloud Functions
 *
 * Handles analytics, billing, audit logs, and data export.
 * Provides dashboard metrics and compliance reporting.
 *
 * @version 2.0.0 - Fixed Twilio initialization issue
 */

import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";
import { db } from "../../admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  withAuth,
  RequestContext,
  requireRole,
} from "../../middleware/auth";
import {
  validate,
  paginationSchema,
  schemas,
} from "../../utils/validation";
import {
  withErrorHandling,
  AppError,
  ErrorCode,
} from "../../utils/errors";
import { logAuditEvent } from "../../utils/audit";
import {
  ApiResponse,
  PaginatedResponse,
  AuditLog,
  DisputeStatus,
  LetterStatus,
  Bureau,
} from "../../types";
import Joi from "joi";

// ============================================================================
// Type Definitions
// ============================================================================

interface DisputeAnalytics {
  overview: {
    total: number;
    active: number;
    resolved: number;
    closed: number;
  };
  byStatus: Record<DisputeStatus, number>;
  byBureau: Record<Bureau, number>;
  byType: Record<string, number>;
  resolution: {
    successRate: number;
    averageResolutionDays: number;
    pendingOverSla: number;
  };
  trends: {
    period: string;
    created: number;
    resolved: number;
  }[];
}

interface LetterAnalytics {
  overview: {
    total: number;
    sent: number;
    delivered: number;
    returned: number;
  };
  byStatus: Record<LetterStatus, number>;
  byMailType: Record<string, number>;
  costs: {
    totalSpent: number;
    averageCost: number;
    currency: string;
  };
  deliveryMetrics: {
    deliveryRate: number;
    averageDeliveryDays: number;
    returnedRate: number;
  };
}

interface AuditLogFilters {
  entity?: string;
  entityId?: string;
  action?: string;
  actorId?: string;
  startDate?: string;
  endDate?: string;
  limit?: number;
  cursor?: string;
}

interface ExportDataInput {
  type: "disputes" | "letters" | "consumers" | "audit_logs";
  format: "json" | "csv";
  startDate?: string;
  endDate?: string;
  filters?: Record<string, unknown>;
}

interface ExportResult {
  exportId: string;
  type: string;
  format: string;
  status: "pending" | "processing" | "completed" | "failed";
  downloadUrl?: string;
  recordCount?: number;
  createdAt: Timestamp | FieldValue;
  completedAt?: Timestamp;
  expiresAt?: Timestamp;
}

// ============================================================================
// Validation Schemas
// ============================================================================

const analyticsDateRangeSchema = Joi.object({
  startDate: schemas.date,
  endDate: schemas.date,
  granularity: Joi.string().valid("day", "week", "month").default("day"),
}).and("startDate", "endDate");

const auditLogFilterSchema = Joi.object({
  entity: Joi.string().valid(
    "user", "tenant", "consumer", "dispute", "letter", "evidence", "template"
  ),
  entityId: schemas.documentId,
  action: Joi.string().valid(
    "create", "read", "update", "delete", "auto_close", "status_change",
    "login", "logout", "export", "send", "approve", "reject",
    "upload", "download", "connect", "disconnect", "refresh"
  ),
  actorId: schemas.documentId,
  startDate: schemas.date,
  endDate: schemas.date,
});

const exportDataSchema = Joi.object({
  type: Joi.string().valid("disputes", "letters", "consumers", "audit_logs").required(),
  format: Joi.string().valid("json", "csv").default("json"),
  startDate: schemas.date,
  endDate: schemas.date,
  filters: Joi.object(),
});

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Calculate date range for analytics queries
 */
function getDateRange(startDate?: string, endDate?: string): { start: Date; end: Date } {
  // Ensure we have valid date strings or use defaults
  const end = endDate ? new Date(endDate) : new Date();
  end.setHours(23, 59, 59, 999);

  const start = startDate ? new Date(startDate) : new Date(end);
  if (!startDate) {
    start.setDate(start.getDate() - 30); // Default to last 30 days
  }
  start.setHours(0, 0, 0, 0);

  // Validate that dates are valid
  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Invalid date format. Dates must be in YYYY-MM-DD format."
    );
  }

  return { start, end };
}

/**
 * Generate trend data by grouping counts per period
 */
function generateTrends(
  docs: FirebaseFirestore.QueryDocumentSnapshot[],
  dateField: string,
  granularity: "day" | "week" | "month" = "day"
): { period: string; count: number }[] {
  const counts: Record<string, number> = {};

  docs.forEach((doc) => {
    try {
      const data = doc.data();
      const timestamp = data[dateField] as Timestamp;
      if (!timestamp) return;

      const date = timestamp.toDate();
      // Check if date is valid
      if (isNaN(date.getTime())) {
        logger.warn("[generateTrends] Invalid date found", {
          docId: doc.id,
          dateField,
          timestampValue: timestamp,
        });
        return;
      }

      let key: string;

      if (granularity === "month") {
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
      } else if (granularity === "week") {
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = weekStart.toISOString().split("T")[0];
      } else {
        key = date.toISOString().split("T")[0];
      }

      counts[key] = (counts[key] || 0) + 1;
    } catch (error) {
      logger.warn("[generateTrends] Error processing document", {
        docId: doc.id,
        dateField,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  return Object.entries(counts)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([period, count]) => ({ period, count }));
}

// ============================================================================
// adminAnalyticsDisputes - Get dispute analytics
// ============================================================================

async function analyticsDisputesHandler(
  data: { startDate?: string; endDate?: string; granularity?: string },
  context: RequestContext
): Promise<ApiResponse<DisputeAnalytics>> {
  logger.info("[analyticsDisputesHandler] Starting", {
    tenantId: context.tenantId,
    userId: context.userId,
    role: context.role,
    data,
  });

  const { tenantId } = context;

  // Validate input - handle empty data case
  logger.info("[analyticsDisputesHandler] Validating input", { rawData: data });

  let validatedData;
  try {
    validatedData = validate(analyticsDateRangeSchema, data || {});
    logger.info("[analyticsDisputesHandler] Validation successful", { validatedData });
  } catch (validationError) {
    logger.error("[analyticsDisputesHandler] Validation failed", {
      error: validationError instanceof Error ? validationError.message : String(validationError),
      data
    });
    throw validationError;
  }

  const { start, end } = getDateRange(validatedData.startDate, validatedData.endDate);
  logger.info("[analyticsDisputesHandler] Date range", { start, end });

  // Get all disputes for the tenant within date range
  logger.info("[analyticsDisputesHandler] Querying disputes", {
    tenantId,
    start: start.toISOString(),
    end: end.toISOString()
  });

  const disputesSnapshot = await db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .where("timestamps.createdAt", ">=", Timestamp.fromDate(start))
    .where("timestamps.createdAt", "<=", Timestamp.fromDate(end))
    .get();

  logger.info("[analyticsDisputesHandler] Disputes query completed", {
    count: disputesSnapshot.size
  });

  // Initialize counters
  const byStatus: Record<string, number> = {};
  const byBureau: Record<string, number> = {};
  const byType: Record<string, number> = {};
  let totalResolutionDays = 0;
  let resolvedCount = 0;

  // Process disputes
  disputesSnapshot.docs.forEach((doc) => {
    const dispute = doc.data();

    // Safely access dispute properties
    const status = dispute.status || "unknown";
    const bureau = dispute.bureau || "unknown";
    const type = dispute.type || "unknown";

    // Count by status
    byStatus[status] = (byStatus[status] || 0) + 1;

    // Count by bureau
    byBureau[bureau] = (byBureau[bureau] || 0) + 1;

    // Count by type
    byType[type] = (byType[type] || 0) + 1;

    // Calculate resolution time for resolved disputes
    if (status === "resolved" && dispute.timestamps?.resolvedAt && dispute.timestamps?.createdAt) {
      try {
        const createdAt = (dispute.timestamps.createdAt as Timestamp).toDate();
        const resolvedAt = (dispute.timestamps.resolvedAt as Timestamp).toDate();

        // Validate that dates are valid
        if (!isNaN(createdAt.getTime()) && !isNaN(resolvedAt.getTime())) {
          const days = Math.ceil((resolvedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
          totalResolutionDays += days;
          resolvedCount++;
        }
      } catch (error) {
        logger.warn("[analyticsDisputesHandler] Error calculating resolution time", {
          disputeId: doc.id,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  });

  // Calculate overview counts
  const total = disputesSnapshot.size;
  const activeStatuses = ["draft", "pending_review", "approved", "mailed", "delivered", "bureau_investigating"];
  const active = disputesSnapshot.docs.filter((d) => activeStatuses.includes(d.data().status)).length;
  const resolved = byStatus["resolved"] || 0;
  const closed = byStatus["closed"] || 0;

  // Count pending over SLA
  const now = new Date();
  const pendingOverSla = disputesSnapshot.docs.filter((doc) => {
    const data = doc.data();
    if (data.status === "resolved" || data.status === "closed") return false;

    try {
      const dueAt = data.timestamps?.dueAt as Timestamp;
      if (!dueAt) return false;

      const dueAtDate = dueAt.toDate();
      if (isNaN(dueAtDate.getTime())) return false;

      return dueAtDate < now;
    } catch (error) {
      logger.warn("[analyticsDisputesHandler] Error checking SLA status", {
        disputeId: doc.id,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }).length;

  // Generate trends
  const createdTrends = generateTrends(
    disputesSnapshot.docs,
    "timestamps.createdAt",
    validatedData.granularity as "day" | "week" | "month"
  );

  // Get resolved disputes for trends
  let resolvedSnapshot;
  try {
    resolvedSnapshot = await db
      .collection("disputes")
      .where("tenantId", "==", tenantId)
      .where("timestamps.resolvedAt", ">=", Timestamp.fromDate(start))
      .where("timestamps.resolvedAt", "<=", Timestamp.fromDate(end))
      .get();
  } catch (error) {
    logger.warn("[analyticsDisputesHandler] Error querying resolved disputes", {
      tenantId,
      start: start.toISOString(),
      end: end.toISOString(),
      error: error instanceof Error ? error.message : String(error),
    });
    // If the query fails, create an empty snapshot
    resolvedSnapshot = { docs: [] };
  }

  const resolvedTrends = generateTrends(
    resolvedSnapshot.docs,
    "timestamps.resolvedAt",
    validatedData.granularity as "day" | "week" | "month"
  );

  // Merge trends
  const allPeriods = new Set([
    ...createdTrends.map((t) => t.period),
    ...resolvedTrends.map((t) => t.period),
  ]);

  const trends = Array.from(allPeriods)
    .sort()
    .map((period) => ({
      period,
      created: createdTrends.find((t) => t.period === period)?.count || 0,
      resolved: resolvedTrends.find((t) => t.period === period)?.count || 0,
    }));

  return {
    success: true,
    data: {
      overview: {
        total,
        active,
        resolved,
        closed,
      },
      byStatus: byStatus as Record<DisputeStatus, number>,
      byBureau: byBureau as Record<Bureau, number>,
      byType,
      resolution: {
        successRate: total > 0 ? (resolved / total) * 100 : 0,
        averageResolutionDays: resolvedCount > 0 ? Math.round(totalResolutionDays / resolvedCount) : 0,
        pendingOverSla,
      },
      trends,
    },
  };
}

export const adminAnalyticsDisputes = functions.https.onCall(
  withErrorHandling(
    withAuth(["analytics:read"], analyticsDisputesHandler)
  )
);

// ============================================================================
// adminAnalyticsLetters - Get letter analytics
// ============================================================================

async function analyticsLettersHandler(
  data: { startDate?: string; endDate?: string; granularity?: string },
  context: RequestContext
): Promise<ApiResponse<LetterAnalytics>> {
  logger.info("[analyticsLettersHandler] Starting", {
    tenantId: context.tenantId,
    userId: context.userId,
    role: context.role,
    data,
  });

  const { tenantId } = context;

  // Validate input - handle empty data case
  logger.info("[analyticsLettersHandler] Validating input", { rawData: data });

  let validatedData;
  try {
    validatedData = validate(analyticsDateRangeSchema, data || {});
    logger.info("[analyticsLettersHandler] Validation successful", { validatedData });
  } catch (validationError) {
    logger.error("[analyticsLettersHandler] Validation failed", {
      error: validationError instanceof Error ? validationError.message : String(validationError),
      data
    });
    throw validationError;
  }

  const { start, end } = getDateRange(validatedData.startDate, validatedData.endDate);

  // Get all letters for the tenant within date range
  logger.info("[analyticsLettersHandler] Querying letters", {
    tenantId,
    start: start.toISOString(),
    end: end.toISOString()
  });

  const lettersSnapshot = await db
    .collection("letters")
    .where("tenantId", "==", tenantId)
    .where("createdAt", ">=", Timestamp.fromDate(start))
    .where("createdAt", "<=", Timestamp.fromDate(end))
    .get();

  logger.info("[analyticsLettersHandler] Letters query completed", {
    count: lettersSnapshot.size
  });

  // Initialize counters
  const byStatus: Record<string, number> = {};
  const byMailType: Record<string, number> = {};
  let totalCost = 0;
  let deliveredCount = 0;
  let totalDeliveryDays = 0;

  // Process letters
  lettersSnapshot.docs.forEach((doc) => {
    const letter = doc.data();

    // Safely access letter properties
    const status = letter.status || "unknown";
    const mailType = letter.mailType || "unknown";

    // Count by status
    byStatus[status] = (byStatus[status] || 0) + 1;

    // Count by mail type
    byMailType[mailType] = (byMailType[mailType] || 0) + 1;

    // Sum costs
    if (letter.cost?.total) {
      totalCost += letter.cost.total;
    }

    // Calculate delivery time
    if (status === "delivered" && letter.sentAt && letter.deliveredAt) {
      try {
        const sentAt = (letter.sentAt as Timestamp).toDate();
        const deliveredAt = (letter.deliveredAt as Timestamp).toDate();

        // Validate that dates are valid
        if (!isNaN(sentAt.getTime()) && !isNaN(deliveredAt.getTime())) {
          const days = Math.ceil((deliveredAt.getTime() - sentAt.getTime()) / (1000 * 60 * 60 * 24));
          totalDeliveryDays += days;
          deliveredCount++;
        }
      } catch (error) {
        logger.warn("[analyticsLettersHandler] Error calculating delivery time", {
          letterId: doc.id,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  });

  // Calculate overview counts
  const total = lettersSnapshot.size;
  const sent = lettersSnapshot.docs.filter((d) =>
    ["sent", "in_transit", "delivered", "returned_to_sender"].includes(d.data().status)
  ).length;
  const delivered = byStatus["delivered"] || 0;
  const returned = byStatus["returned_to_sender"] || 0;

  return {
    success: true,
    data: {
      overview: {
        total,
        sent,
        delivered,
        returned,
      },
      byStatus: byStatus as Record<LetterStatus, number>,
      byMailType,
      costs: {
        totalSpent: totalCost,
        averageCost: total > 0 ? totalCost / total : 0,
        currency: "USD",
      },
      deliveryMetrics: {
        deliveryRate: sent > 0 ? (delivered / sent) * 100 : 0,
        averageDeliveryDays: deliveredCount > 0 ? Math.round(totalDeliveryDays / deliveredCount) : 0,
        returnedRate: sent > 0 ? (returned / sent) * 100 : 0,
      },
    },
  };
}

export const adminAnalyticsLetters = functions.https.onCall(
  withErrorHandling(
    withAuth(["analytics:read"], analyticsLettersHandler)
  )
);

// ============================================================================
// adminAuditLogs - List audit logs
// ============================================================================

async function auditLogsHandler(
  data: AuditLogFilters,
  context: RequestContext
): Promise<PaginatedResponse<AuditLog>> {
  const { tenantId } = context;

  // Validate pagination and filters
  const pagination = validate(paginationSchema, data);
  const filters = validate(auditLogFilterSchema, data);

  // Build query
  let query = db
    .collection("auditLogs")
    .where("tenantId", "==", tenantId)
    .orderBy("timestamp", "desc");

  // Apply filters
  if (filters.entity) {
    query = query.where("entity", "==", filters.entity);
  }

  if (filters.entityId) {
    query = query.where("entityId", "==", filters.entityId);
  }

  if (filters.action) {
    query = query.where("action", "==", filters.action);
  }

  if (filters.actorId) {
    query = query.where("actor.userId", "==", filters.actorId);
  }

  // Date range filter
  if (filters.startDate && filters.endDate) {
    const { start, end } = getDateRange(filters.startDate, filters.endDate);
    query = query
      .where("timestamp", ">=", Timestamp.fromDate(start))
      .where("timestamp", "<=", Timestamp.fromDate(end));
  }

  // Apply cursor
  if (pagination.cursor) {
    const cursorDoc = await db.collection("auditLogs").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query
  const snapshot = await query.limit(pagination.limit + 1).get();

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const logs = docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  } as AuditLog));

  // Get total count
  let countQuery = db
    .collection("auditLogs")
    .where("tenantId", "==", tenantId);

  if (filters.entity) {
    countQuery = countQuery.where("entity", "==", filters.entity);
  }

  const countSnapshot = await countQuery.count().get();

  return {
    success: true,
    data: {
      items: logs,
      pagination: {
        total: countSnapshot.data().count,
        limit: pagination.limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const adminAuditLogs = functions.https.onCall(
  withErrorHandling(
    withAuth(["audit:read"], auditLogsHandler)
  )
);

// ============================================================================
// adminExportData - Export data for FCRA compliance
// ============================================================================

async function exportDataHandler(
  data: ExportDataInput,
  context: RequestContext
): Promise<ApiResponse<ExportResult>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Only owners and auditors can export data
  requireRole(context, ["owner", "auditor"]);

  // Validate input
  const validatedData = validate(exportDataSchema, data);

  // Create export record
  const exportId = `export_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const now = FieldValue.serverTimestamp() as unknown as Timestamp;

  const exportRecord: ExportResult = {
    exportId,
    type: validatedData.type,
    format: validatedData.format,
    status: "pending",
    createdAt: now,
  };

  await db.collection("exports").doc(exportId).set({
    ...exportRecord,
    tenantId,
    requestedBy: actorId,
    filters: validatedData.filters || {},
    startDate: validatedData.startDate,
    endDate: validatedData.endDate,
  });

  // Note: Actual export processing would be handled by a background function
  // triggered by the document creation. Here we just return the pending record.

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "export",
    entityId: exportId,
    action: "export",
    newState: {
      type: validatedData.type,
      format: validatedData.format,
      filters: validatedData.filters,
    },
    metadata: {
      reason: "FCRA compliance export",
    },
  });

  return {
    success: true,
    data: exportRecord,
  };
}

export const adminExportData = functions.https.onCall(
  withErrorHandling(
    withAuth(["data:export"], exportDataHandler)
  )
);

// ============================================================================
// adminGetExportStatus - Check export status
// ============================================================================

interface GetExportStatusInput {
  exportId: string;
}

async function getExportStatusHandler(
  data: GetExportStatusInput,
  context: RequestContext
): Promise<ApiResponse<ExportResult>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ exportId: Joi.string().required() }),
    data
  );

  // Get export record
  const exportDoc = await db.collection("exports").doc(validatedData.exportId).get();

  if (!exportDoc.exists) {
    throw new AppError(
      ErrorCode.NOT_FOUND,
      `Export ${validatedData.exportId} not found`,
      404
    );
  }

  const exportData = exportDoc.data()!;

  // Verify tenant access
  if (exportData.tenantId !== tenantId) {
    throw new AppError(
      ErrorCode.NOT_FOUND,
      `Export ${validatedData.exportId} not found`,
      404
    );
  }

  return {
    success: true,
    data: {
      exportId: exportData.exportId,
      type: exportData.type,
      format: exportData.format,
      status: exportData.status,
      downloadUrl: exportData.downloadUrl,
      recordCount: exportData.recordCount,
      createdAt: exportData.createdAt,
      completedAt: exportData.completedAt,
      expiresAt: exportData.expiresAt,
    },
  };
}

export const adminGetExportStatus = functions.https.onCall(
  withErrorHandling(
    withAuth(["data:export"], getExportStatusHandler)
  )
);

// ============================================================================
// adminSystemHealth - Get system health metrics (internal use)
// ============================================================================

interface SystemHealth {
  status: "healthy" | "degraded" | "unhealthy";
  services: {
    firestore: "up" | "down";
    storage: "up" | "down";
    auth: "up" | "down";
  };
  metrics: {
    activeDisputes: number;
    pendingLetters: number;
    failedWebhooks: number;
    overdueSlaCount: number;
  };
  lastChecked: Timestamp | FieldValue;
}

async function systemHealthHandler(
  _data: unknown,
  context: RequestContext
): Promise<ApiResponse<SystemHealth>> {
  const { tenantId } = context;

  // Only owners can view system health
  requireRole(context, ["owner"]);

  // Check various health metrics
  const now = new Date();

  // Active disputes count
  const activeDisputesSnapshot = await db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .where("status", "in", ["draft", "pending_review", "approved", "mailed", "delivered", "bureau_investigating"])
    .count()
    .get();

  // Pending letters count
  const pendingLettersSnapshot = await db
    .collection("letters")
    .where("tenantId", "==", tenantId)
    .where("status", "in", ["draft", "pending_approval", "approved", "rendering", "ready", "queued"])
    .count()
    .get();

  // Overdue SLA count
  const overdueSnapshot = await db
    .collection("disputes")
    .where("tenantId", "==", tenantId)
    .where("status", "not-in", ["resolved", "closed"])
    .where("timestamps.dueAt", "<", Timestamp.fromDate(now))
    .count()
    .get();

  // Failed webhooks in last 24 hours
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const failedWebhooksSnapshot = await db
    .collection("webhookEvents")
    .where("tenantId", "==", tenantId)
    .where("status", "==", "failed")
    .where("receivedAt", ">=", Timestamp.fromDate(yesterday))
    .count()
    .get();

  // Determine overall health status
  let status: "healthy" | "degraded" | "unhealthy" = "healthy";
  if (overdueSnapshot.data().count > 10 || failedWebhooksSnapshot.data().count > 5) {
    status = "degraded";
  }
  if (failedWebhooksSnapshot.data().count > 20) {
    status = "unhealthy";
  }

  return {
    success: true,
    data: {
      status,
      services: {
        firestore: "up",
        storage: "up",
        auth: "up",
      },
      metrics: {
        activeDisputes: activeDisputesSnapshot.data().count,
        pendingLetters: pendingLettersSnapshot.data().count,
        failedWebhooks: failedWebhooksSnapshot.data().count,
        overdueSlaCount: overdueSnapshot.data().count,
      },
      lastChecked: FieldValue.serverTimestamp(),
    },
  };
}

export const adminSystemHealth = functions.https.onCall(
  withErrorHandling(
    withAuth(["analytics:read"], systemHealthHandler)
  )
);
