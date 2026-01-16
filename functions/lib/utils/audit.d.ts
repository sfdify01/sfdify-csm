/**
 * Audit Logging Utilities
 *
 * Provides comprehensive audit logging for FCRA/GLBA compliance.
 * All actions that affect consumer data or disputes are logged
 * with full state tracking for 7-year retention.
 */
import { AuditLog, UserRole, DocumentId } from "../types";
/**
 * Action types for audit logging
 */
export type AuditAction = "create" | "read" | "update" | "delete" | "auto_close" | "status_change" | "login" | "logout" | "export" | "send" | "approve" | "reject" | "upload" | "download" | "connect" | "disconnect" | "refresh";
/**
 * Entity types that can be audited
 */
export type AuditEntity = "consumer" | "dispute" | "letter" | "evidence" | "tradeline" | "credit_report" | "user" | "tenant" | "smartcredit_connection" | "webhook" | "template" | "export";
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
export declare function sanitizeForAudit(data: Record<string, unknown> | null | undefined): Record<string, unknown> | null;
/**
 * Generate a diff between previous and new state
 */
export declare function generateDiff(previousState: Record<string, unknown> | null | undefined, newState: Record<string, unknown> | null | undefined): Record<string, {
    from: unknown;
    to: unknown;
}> | null;
/**
 * Create an audit log entry
 */
export declare function logAuditEvent(options: AuditLogOptions): Promise<DocumentId>;
/**
 * Log a login event
 */
export declare function logLoginEvent(tenantId: DocumentId, userId: DocumentId, email: string, role: UserRole, ip: string, userAgent: string, success: boolean): Promise<void>;
/**
 * Log a logout event
 */
export declare function logLogoutEvent(tenantId: DocumentId, userId: DocumentId, email: string, role: UserRole): Promise<void>;
/**
 * Create a batch audit logger for multiple operations
 */
export declare function createBatchAuditLogger(tenantId: DocumentId, actor: AuditActor, requestId: string): {
    /**
     * Queue an audit log entry
     */
    log(entity: AuditEntity, entityId: DocumentId, action: AuditAction, options?: {
        actionDetail?: string;
        previousState?: Record<string, unknown>;
        newState?: Record<string, unknown>;
    }): void;
    /**
     * Commit all queued audit logs
     */
    commit(): Promise<string[]>;
    /**
     * Get the number of queued logs
     */
    readonly count: number;
};
/**
 * Query audit logs for an entity
 */
export declare function getAuditLogsForEntity(tenantId: DocumentId, entity: AuditEntity, entityId: DocumentId, limit?: number): Promise<AuditLog[]>;
/**
 * Query audit logs by actor
 */
export declare function getAuditLogsByActor(tenantId: DocumentId, actorId: DocumentId, startDate?: Date, endDate?: Date, limit?: number): Promise<AuditLog[]>;
//# sourceMappingURL=audit.d.ts.map