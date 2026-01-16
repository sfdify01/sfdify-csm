"use strict";
/**
 * Audit Logging Utilities
 *
 * Provides comprehensive audit logging for FCRA/GLBA compliance.
 * All actions that affect consumer data or disputes are logged
 * with full state tracking for 7-year retention.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.sanitizeForAudit = sanitizeForAudit;
exports.generateDiff = generateDiff;
exports.logAuditEvent = logAuditEvent;
exports.logLoginEvent = logLoginEvent;
exports.logLogoutEvent = logLogoutEvent;
exports.createBatchAuditLogger = createBatchAuditLogger;
exports.getAuditLogsForEntity = getAuditLogsForEntity;
exports.getAuditLogsByActor = getAuditLogsByActor;
const admin_1 = require("../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const config_1 = require("../config");
/**
 * Redact sensitive fields from an object for audit logging
 * PII and secrets should not be stored in plain text in audit logs
 */
function sanitizeForAudit(data) {
    if (!data)
        return null;
    const sanitized = {};
    for (const [key, value] of Object.entries(data)) {
        if (config_1.auditConfig.sensitiveFieldsToRedact.includes(key)) {
            sanitized[key] = "[REDACTED]";
        }
        else if (typeof value === "object" && value !== null && !Array.isArray(value)) {
            // Recursively sanitize nested objects
            sanitized[key] = sanitizeForAudit(value);
        }
        else if (Array.isArray(value)) {
            // Sanitize arrays
            sanitized[key] = value.map((item) => typeof item === "object" && item !== null
                ? sanitizeForAudit(item)
                : item);
        }
        else {
            sanitized[key] = value;
        }
    }
    return sanitized;
}
/**
 * Generate a diff between previous and new state
 */
function generateDiff(previousState, newState) {
    if (!previousState && !newState)
        return null;
    const diff = {};
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
function getRetentionDate() {
    const date = new Date();
    date.setFullYear(date.getFullYear() + config_1.auditConfig.retentionYears);
    return firestore_1.Timestamp.fromDate(date);
}
/**
 * Create an audit log entry
 */
async function logAuditEvent(options) {
    const { tenantId, actor, entity, entityId, action, actionDetail, previousState, newState, metadata, } = options;
    const auditId = (0, uuid_1.v4)();
    const sanitizedPrevious = sanitizeForAudit(previousState);
    const sanitizedNew = sanitizeForAudit(newState);
    const diff = generateDiff(sanitizedPrevious, sanitizedNew);
    const auditLog = {
        id: auditId,
        tenantId,
        actorId: actor.userId,
        actorEmail: actor.email,
        actorRole: actor.role,
        actorIp: actor.ip,
        userAgent: actor.userAgent,
        entity,
        entityId,
        entityPath: `${entity}/${entityId}`,
        action,
        actionDetail,
        previousState: sanitizedPrevious ?? undefined,
        newState: sanitizedNew ?? undefined,
        diffJson: diff ?? undefined,
        metadata: {
            source: metadata?.source || "api",
            sessionId: metadata?.sessionId,
            requestId: metadata?.requestId,
        },
        timestamp: firestore_1.FieldValue.serverTimestamp(),
        retentionUntil: getRetentionDate(),
    };
    await admin_1.db.collection("auditLogs").doc(auditId).set(auditLog);
    return auditId;
}
/**
 * Log a login event
 */
async function logLoginEvent(tenantId, userId, email, role, ip, userAgent, success) {
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
async function logLogoutEvent(tenantId, userId, email, role) {
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
function createBatchAuditLogger(tenantId, actor, requestId) {
    const logs = [];
    return {
        /**
         * Queue an audit log entry
         */
        log(entity, entityId, action, options) {
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
        async commit() {
            const auditIds = [];
            // Use batched writes for efficiency
            const batch = admin_1.db.batch();
            const auditCollection = admin_1.db.collection("auditLogs");
            for (const logOptions of logs) {
                const auditId = (0, uuid_1.v4)();
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
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
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
        get count() {
            return logs.length;
        },
    };
}
/**
 * Query audit logs for an entity
 */
async function getAuditLogsForEntity(tenantId, entity, entityId, limit = 100) {
    const snapshot = await admin_1.db
        .collection("auditLogs")
        .where("tenantId", "==", tenantId)
        .where("entity", "==", entity)
        .where("entityId", "==", entityId)
        .orderBy("timestamp", "desc")
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data());
}
/**
 * Query audit logs by actor
 */
async function getAuditLogsByActor(tenantId, actorId, startDate, endDate, limit = 100) {
    let query = admin_1.db
        .collection("auditLogs")
        .where("tenantId", "==", tenantId)
        .where("actorId", "==", actorId);
    if (startDate) {
        query = query.where("timestamp", ">=", firestore_1.Timestamp.fromDate(startDate));
    }
    if (endDate) {
        query = query.where("timestamp", "<=", firestore_1.Timestamp.fromDate(endDate));
    }
    const snapshot = await query.orderBy("timestamp", "desc").limit(limit).get();
    return snapshot.docs.map((doc) => doc.data());
}
//# sourceMappingURL=audit.js.map