/**
 * Audit Logging Utilities
 *
 * Provides comprehensive audit logging for FCRA/GLBA compliance.
 * All actions that affect consumer data or disputes are logged
 * with full state tracking for 7-year retention.
 */

import { db } from "../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { auditConfig } from "../config";
import { AuditLog, UserRole, DocumentId } from "../types";

/**
 * Action types for audit logging
 */
export type AuditAction =
  | "create"
  | "read"
  | "update"
  | "delete"
  | "auto_close"
  | "status_change"
  | "login"
  | "logout"
  | "export"
  | "send"
  | "approve"
  | "reject"
  | "upload"
  | "download"
  | "connect"
  | "disconnect"
  | "refresh";

/**
 * Entity types that can be audited
 */
export type AuditEntity =
  | "consumer"
  | "dispute"
  | "letter"
  | "evidence"
  | "tradeline"
  | "credit_report"
  | "user"
  | "tenant"
  | "smartcredit_connection"
  | "webhook"
  | "template"
  | "export";

/**
 * Actor context for audit logs
 */
export interface AuditActor {
  userId: DocumentId;
  email?: string;
  role: UserRole;
  ip?: string;
  userAgent?: string;
}

/**
 * Options for creating an audit log entry
 */
export interface AuditLogOptions {
  tenantId: DocumentId;
  actor: AuditActor;
  entity: AuditEntity;
  entityId: DocumentId;
  action: AuditAction;
  actionDetail?: string;
  previousState?: Record<string, unknown>;
  newState?: Record<string, unknown>;
  metadata?: {
    source?: string;
    sessionId?: string;
    requestId?: string;
    [key: string]: unknown;
  };
}

/**
 * Redact sensitive fields from an object for audit logging
 * PII and secrets should not be stored in plain text in audit logs
 */
export function sanitizeForAudit(data: Record<string, unknown> | null | undefined): Record<string, unknown> | null {
  if (!data) return null;

  const sanitized: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(data)) {
    if (auditConfig.sensitiveFieldsToRedact.includes(key)) {
      sanitized[key] = "[REDACTED]";
    } else if (typeof value === "object" && value !== null && !Array.isArray(value)) {
      // Recursively sanitize nested objects
      sanitized[key] = sanitizeForAudit(value as Record<string, unknown>);
    } else if (Array.isArray(value)) {
      // Sanitize arrays
      sanitized[key] = value.map((item) =>
        typeof item === "object" && item !== null
          ? sanitizeForAudit(item as Record<string, unknown>)
          : item
      );
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}

/**
 * Generate a diff between previous and new state
 */
export function generateDiff(
  previousState: Record<string, unknown> | null | undefined,
  newState: Record<string, unknown> | null | undefined
): Record<string, { from: unknown; to: unknown }> | null {
  if (!previousState && !newState) return null;

  const diff: Record<string, { from: unknown; to: unknown }> = {};
  const allKeys = new Set([
    ...Object.keys(previousState || {}),
    ...Object.keys(newState || {}),
  ]);

  for (const key of allKeys) {
    const prevValue = previousState?.[key];
    const newValue = newState?.[key];

    // Simple comparison - could be enhanced for deep object comparison
    if (JSON.stringify(prevValue) !== JSON.stringify(newValue)) {
      diff[key] = { from: prevValue, to: newValue };
    }
  }

  return Object.keys(diff).length > 0 ? diff : null;
}

/**
 * Calculate the retention date (7 years from now)
 */
function getRetentionDate(): Timestamp {
  const date = new Date();
  date.setFullYear(date.getFullYear() + auditConfig.retentionYears);
  return Timestamp.fromDate(date);
}

/**
 * Create an audit log entry
 */
export async function logAuditEvent(options: AuditLogOptions): Promise<DocumentId> {
  const {
    tenantId,
    actor,
    entity,
    entityId,
    action,
    actionDetail,
    previousState,
    newState,
    metadata,
  } = options;

  const auditId = uuidv4();
  const sanitizedPrevious = sanitizeForAudit(previousState);
  const sanitizedNew = sanitizeForAudit(newState);
  const diff = generateDiff(sanitizedPrevious, sanitizedNew);

  const auditLog: Omit<AuditLog, "id"> & { id: string } = {
    id: auditId,
    tenantId,
    actorId: actor.userId,
    actorEmail: actor.email || undefined,
    actorRole: actor.role,
    actorIp: actor.ip || undefined,
    userAgent: actor.userAgent || undefined,
    entity,
    entityId,
    entityPath: `${entity}/${entityId}`,
    action,
    actionDetail: actionDetail || undefined,
    previousState: sanitizedPrevious ?? undefined,
    newState: sanitizedNew ?? undefined,
    diffJson: diff ?? undefined,
    metadata: {
      source: metadata?.source || "api",
      sessionId: metadata?.sessionId || undefined,
      requestId: metadata?.requestId || undefined,
    },
    timestamp: FieldValue.serverTimestamp(),
    retentionUntil: getRetentionDate(),
  };

  await db.collection("auditLogs").doc(auditId).set(auditLog);

  return auditId;
}

/**
 * Log a login event
 */
export async function logLoginEvent(
  tenantId: DocumentId,
  userId: DocumentId,
  email: string,
  role: UserRole,
  ip: string,
  userAgent: string,
  success: boolean
): Promise<void> {
  await logAuditEvent({
    tenantId,
    actor: { userId, email, role, ip, userAgent },
    entity: "user",
    entityId: userId,
    action: "login",
    actionDetail: success ? "successful" : "failed",
    metadata: { source: "auth", success },
  });
}

/**
 * Log a logout event
 */
export async function logLogoutEvent(
  tenantId: DocumentId,
  userId: DocumentId,
  email: string,
  role: UserRole
): Promise<void> {
  await logAuditEvent({
    tenantId,
    actor: { userId, email, role },
    entity: "user",
    entityId: userId,
    action: "logout",
    metadata: { source: "auth" },
  });
}

/**
 * Create a batch audit logger for multiple operations
 */
export function createBatchAuditLogger(
  tenantId: DocumentId,
  actor: AuditActor,
  requestId: string
) {
  const logs: AuditLogOptions[] = [];

  return {
    /**
     * Queue an audit log entry
     */
    log(
      entity: AuditEntity,
      entityId: DocumentId,
      action: AuditAction,
      options?: {
        actionDetail?: string;
        previousState?: Record<string, unknown>;
        newState?: Record<string, unknown>;
      }
    ) {
      logs.push({
        tenantId,
        actor,
        entity,
        entityId,
        action,
        actionDetail: options?.actionDetail,
        previousState: options?.previousState,
        newState: options?.newState,
        metadata: { requestId },
      });
    },

    /**
     * Commit all queued audit logs
     */
    async commit(): Promise<string[]> {
      const auditIds: string[] = [];

      // Use batched writes for efficiency
      const batch = db.batch();
      const auditCollection = db.collection("auditLogs");

      for (const logOptions of logs) {
        const auditId = uuidv4();
        const sanitizedPrevious = sanitizeForAudit(logOptions.previousState);
        const sanitizedNew = sanitizeForAudit(logOptions.newState);
        const diff = generateDiff(sanitizedPrevious, sanitizedNew);

        const auditLog = {
          id: auditId,
          tenantId: logOptions.tenantId,
          actorId: logOptions.actor.userId,
          actorEmail: logOptions.actor.email,
          actorRole: logOptions.actor.role,
          actorIp: logOptions.actor.ip,
          userAgent: logOptions.actor.userAgent,
          entity: logOptions.entity,
          entityId: logOptions.entityId,
          entityPath: `${logOptions.entity}/${logOptions.entityId}`,
          action: logOptions.action,
          actionDetail: logOptions.actionDetail,
          previousState: sanitizedPrevious,
          newState: sanitizedNew,
          diffJson: diff,
          metadata: logOptions.metadata,
          timestamp: FieldValue.serverTimestamp(),
          retentionUntil: getRetentionDate(),
        };

        batch.set(auditCollection.doc(auditId), auditLog);
        auditIds.push(auditId);
      }

      await batch.commit();
      return auditIds;
    },

    /**
     * Get the number of queued logs
     */
    get count(): number {
      return logs.length;
    },
  };
}

/**
 * Query audit logs for an entity
 */
export async function getAuditLogsForEntity(
  tenantId: DocumentId,
  entity: AuditEntity,
  entityId: DocumentId,
  limit = 100
): Promise<AuditLog[]> {
  const snapshot = await db
    .collection("auditLogs")
    .where("tenantId", "==", tenantId)
    .where("entity", "==", entity)
    .where("entityId", "==", entityId)
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as AuditLog);
}

/**
 * Query audit logs by actor
 */
export async function getAuditLogsByActor(
  tenantId: DocumentId,
  actorId: DocumentId,
  startDate?: Date,
  endDate?: Date,
  limit = 100
): Promise<AuditLog[]> {
  let query = db
    .collection("auditLogs")
    .where("tenantId", "==", tenantId)
    .where("actorId", "==", actorId);

  if (startDate) {
    query = query.where("timestamp", ">=", Timestamp.fromDate(startDate));
  }

  if (endDate) {
    query = query.where("timestamp", "<=", Timestamp.fromDate(endDate));
  }

  const snapshot = await query.orderBy("timestamp", "desc").limit(limit).get();

  return snapshot.docs.map((doc) => doc.data() as AuditLog);
}
