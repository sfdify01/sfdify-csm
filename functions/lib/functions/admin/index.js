"use strict";
/**
 * Admin & Analytics Cloud Functions
 *
 * Handles analytics, billing, audit logs, and data export.
 * Provides dashboard metrics and compliance reporting.
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
exports.adminSystemHealth = exports.adminGetExportStatus = exports.adminExportData = exports.adminAuditLogs = exports.adminBillingUsage = exports.adminAnalyticsLetters = exports.adminAnalyticsDisputes = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const audit_1 = require("../../utils/audit");
const joi_1 = __importDefault(require("joi"));
// ============================================================================
// Validation Schemas
// ============================================================================
const analyticsDateRangeSchema = joi_1.default.object({
    startDate: validation_1.schemas.date,
    endDate: validation_1.schemas.date,
    granularity: joi_1.default.string().valid("day", "week", "month").default("day"),
}).and("startDate", "endDate");
const auditLogFilterSchema = joi_1.default.object({
    entity: joi_1.default.string().valid("user", "tenant", "consumer", "dispute", "letter", "evidence", "template"),
    entityId: validation_1.schemas.documentId,
    action: joi_1.default.string().valid("create", "read", "update", "delete", "auto_close", "status_change", "login", "logout", "export", "send", "approve", "reject", "upload", "download", "connect", "disconnect", "refresh"),
    actorId: validation_1.schemas.documentId,
    startDate: validation_1.schemas.date,
    endDate: validation_1.schemas.date,
});
const exportDataSchema = joi_1.default.object({
    type: joi_1.default.string().valid("disputes", "letters", "consumers", "audit_logs").required(),
    format: joi_1.default.string().valid("json", "csv").default("json"),
    startDate: validation_1.schemas.date,
    endDate: validation_1.schemas.date,
    filters: joi_1.default.object(),
});
// ============================================================================
// Helper Functions
// ============================================================================
/**
 * Calculate date range for analytics queries
 */
function getDateRange(startDate, endDate) {
    const end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);
    const start = startDate ? new Date(startDate) : new Date(end);
    if (!startDate) {
        start.setDate(start.getDate() - 30); // Default to last 30 days
    }
    start.setHours(0, 0, 0, 0);
    return { start, end };
}
/**
 * Generate trend data by grouping counts per period
 */
function generateTrends(docs, dateField, granularity = "day") {
    const counts = {};
    docs.forEach((doc) => {
        const data = doc.data();
        const timestamp = data[dateField];
        if (!timestamp)
            return;
        const date = timestamp.toDate();
        let key;
        if (granularity === "month") {
            key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
        }
        else if (granularity === "week") {
            const weekStart = new Date(date);
            weekStart.setDate(date.getDate() - date.getDay());
            key = weekStart.toISOString().split("T")[0];
        }
        else {
            key = date.toISOString().split("T")[0];
        }
        counts[key] = (counts[key] || 0) + 1;
    });
    return Object.entries(counts)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([period, count]) => ({ period, count }));
}
// ============================================================================
// adminAnalyticsDisputes - Get dispute analytics
// ============================================================================
async function analyticsDisputesHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(analyticsDateRangeSchema, data);
    const { start, end } = getDateRange(validatedData.startDate, validatedData.endDate);
    // Get all disputes for the tenant within date range
    const disputesSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("timestamps.createdAt", ">=", firestore_1.Timestamp.fromDate(start))
        .where("timestamps.createdAt", "<=", firestore_1.Timestamp.fromDate(end))
        .get();
    // Initialize counters
    const byStatus = {};
    const byBureau = {};
    const byType = {};
    let totalResolutionDays = 0;
    let resolvedCount = 0;
    // Process disputes
    disputesSnapshot.docs.forEach((doc) => {
        const dispute = doc.data();
        // Count by status
        byStatus[dispute.status] = (byStatus[dispute.status] || 0) + 1;
        // Count by bureau
        byBureau[dispute.bureau] = (byBureau[dispute.bureau] || 0) + 1;
        // Count by type
        byType[dispute.type] = (byType[dispute.type] || 0) + 1;
        // Calculate resolution time for resolved disputes
        if (dispute.status === "resolved" && dispute.timestamps?.resolvedAt) {
            const createdAt = dispute.timestamps.createdAt.toDate();
            const resolvedAt = dispute.timestamps.resolvedAt.toDate();
            const days = Math.ceil((resolvedAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
            totalResolutionDays += days;
            resolvedCount++;
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
        if (data.status === "resolved" || data.status === "closed")
            return false;
        const dueAt = data.timestamps?.dueAt;
        return dueAt && dueAt.toDate() < now;
    }).length;
    // Generate trends
    const createdTrends = generateTrends(disputesSnapshot.docs, "timestamps.createdAt", validatedData.granularity);
    // Get resolved disputes for trends
    const resolvedSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("timestamps.resolvedAt", ">=", firestore_1.Timestamp.fromDate(start))
        .where("timestamps.resolvedAt", "<=", firestore_1.Timestamp.fromDate(end))
        .get();
    const resolvedTrends = generateTrends(resolvedSnapshot.docs, "timestamps.resolvedAt", validatedData.granularity);
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
            byStatus: byStatus,
            byBureau: byBureau,
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
exports.adminAnalyticsDisputes = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["analytics:read"], analyticsDisputesHandler)));
// ============================================================================
// adminAnalyticsLetters - Get letter analytics
// ============================================================================
async function analyticsLettersHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(analyticsDateRangeSchema, data);
    const { start, end } = getDateRange(validatedData.startDate, validatedData.endDate);
    // Get all letters for the tenant within date range
    const lettersSnapshot = await admin_1.db
        .collection("letters")
        .where("tenantId", "==", tenantId)
        .where("createdAt", ">=", firestore_1.Timestamp.fromDate(start))
        .where("createdAt", "<=", firestore_1.Timestamp.fromDate(end))
        .get();
    // Initialize counters
    const byStatus = {};
    const byMailType = {};
    let totalCost = 0;
    let deliveredCount = 0;
    let totalDeliveryDays = 0;
    // Process letters
    lettersSnapshot.docs.forEach((doc) => {
        const letter = doc.data();
        // Count by status
        byStatus[letter.status] = (byStatus[letter.status] || 0) + 1;
        // Count by mail type
        byMailType[letter.mailType] = (byMailType[letter.mailType] || 0) + 1;
        // Sum costs
        if (letter.cost?.total) {
            totalCost += letter.cost.total;
        }
        // Calculate delivery time
        if (letter.status === "delivered" && letter.sentAt && letter.deliveredAt) {
            const sentAt = letter.sentAt.toDate();
            const deliveredAt = letter.deliveredAt.toDate();
            const days = Math.ceil((deliveredAt.getTime() - sentAt.getTime()) / (1000 * 60 * 60 * 24));
            totalDeliveryDays += days;
            deliveredCount++;
        }
    });
    // Calculate overview counts
    const total = lettersSnapshot.size;
    const sent = lettersSnapshot.docs.filter((d) => ["sent", "in_transit", "delivered", "returned_to_sender"].includes(d.data().status)).length;
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
            byStatus: byStatus,
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
exports.adminAnalyticsLetters = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["analytics:read"], analyticsLettersHandler)));
// ============================================================================
// adminBillingUsage - Get billing usage for tenant
// ============================================================================
async function billingUsageHandler(data, context) {
    const { tenantId, tenant } = context;
    // Determine billing period
    const now = new Date();
    let periodStart;
    let periodEnd;
    if (data.month) {
        const [year, month] = data.month.split("-").map(Number);
        periodStart = new Date(year, month - 1, 1);
        periodEnd = new Date(year, month, 0, 23, 59, 59, 999);
    }
    else {
        // Current month
        periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
        periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }
    // Get letter counts by mail type
    const lettersSnapshot = await admin_1.db
        .collection("letters")
        .where("tenantId", "==", tenantId)
        .where("sentAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
        .where("sentAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
        .get();
    const letterCounts = {
        uspsFirstClass: 0,
        uspsCertified: 0,
        uspsCertifiedReturnReceipt: 0,
        total: lettersSnapshot.size,
    };
    let letterCosts = 0;
    lettersSnapshot.docs.forEach((doc) => {
        const letter = doc.data();
        if (letter.mailType === "usps_first_class")
            letterCounts.uspsFirstClass++;
        else if (letter.mailType === "usps_certified")
            letterCounts.uspsCertified++;
        else if (letter.mailType === "usps_certified_return_receipt")
            letterCounts.uspsCertifiedReturnReceipt++;
        if (letter.cost?.total)
            letterCosts += letter.cost.total;
    });
    // Get dispute counts
    const disputesCreatedSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("timestamps.createdAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
        .where("timestamps.createdAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
        .count()
        .get();
    const disputesResolvedSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("timestamps.resolvedAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
        .where("timestamps.resolvedAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
        .count()
        .get();
    // Get consumer counts
    const activeConsumersSnapshot = await admin_1.db
        .collection("consumers")
        .where("tenantId", "==", tenantId)
        .where("disabled", "==", false)
        .count()
        .get();
    const newConsumersSnapshot = await admin_1.db
        .collection("consumers")
        .where("tenantId", "==", tenantId)
        .where("createdAt", ">=", firestore_1.Timestamp.fromDate(periodStart))
        .where("createdAt", "<=", firestore_1.Timestamp.fromDate(periodEnd))
        .count()
        .get();
    // Get storage usage (sum of evidence file sizes)
    const evidenceSnapshot = await admin_1.db
        .collection("evidence")
        .where("tenantId", "==", tenantId)
        .get();
    const storageUsed = evidenceSnapshot.docs.reduce((total, doc) => {
        return total + (doc.data().fileSize || 0);
    }, 0);
    // Calculate subscription cost based on plan
    const planPricing = {
        starter: 99,
        professional: 299,
        enterprise: 999,
    };
    const storageLimits = {
        starter: 5 * 1024 * 1024 * 1024, // 5GB
        professional: 25 * 1024 * 1024 * 1024, // 25GB
        enterprise: 100 * 1024 * 1024 * 1024, // 100GB
    };
    const subscriptionCost = planPricing[tenant.plan] || 99;
    const storageLimit = storageLimits[tenant.plan] || storageLimits.starter;
    // Calculate overage costs
    let overageCost = 0;
    if (storageUsed > storageLimit) {
        const overageGB = (storageUsed - storageLimit) / (1024 * 1024 * 1024);
        overageCost = Math.ceil(overageGB) * 5; // $5 per GB overage
    }
    return {
        success: true,
        data: {
            period: {
                start: periodStart.toISOString().split("T")[0],
                end: periodEnd.toISOString().split("T")[0],
            },
            usage: {
                letters: letterCounts,
                disputes: {
                    created: disputesCreatedSnapshot.data().count,
                    resolved: disputesResolvedSnapshot.data().count,
                },
                consumers: {
                    active: activeConsumersSnapshot.data().count,
                    new: newConsumersSnapshot.data().count,
                },
                storage: {
                    usedBytes: storageUsed,
                    limitBytes: storageLimit,
                },
                apiCalls: 0, // Would need request logging to track this
            },
            costs: {
                letters: letterCosts,
                subscription: subscriptionCost,
                overage: overageCost,
                total: letterCosts + subscriptionCost + overageCost,
                currency: "USD",
            },
            plan: tenant.plan,
        },
    };
}
exports.adminBillingUsage = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["billing:read"], billingUsageHandler)));
// ============================================================================
// adminAuditLogs - List audit logs
// ============================================================================
async function auditLogsHandler(data, context) {
    const { tenantId } = context;
    // Validate pagination and filters
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    const filters = (0, validation_1.validate)(auditLogFilterSchema, data);
    // Build query
    let query = admin_1.db
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
            .where("timestamp", ">=", firestore_1.Timestamp.fromDate(start))
            .where("timestamp", "<=", firestore_1.Timestamp.fromDate(end));
    }
    // Apply cursor
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("auditLogs").doc(pagination.cursor).get();
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
    }));
    // Get total count
    let countQuery = admin_1.db
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
exports.adminAuditLogs = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["audit:read"], auditLogsHandler)));
// ============================================================================
// adminExportData - Export data for FCRA compliance
// ============================================================================
async function exportDataHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Only owners and auditors can export data
    (0, auth_1.requireRole)(context, ["owner", "auditor"]);
    // Validate input
    const validatedData = (0, validation_1.validate)(exportDataSchema, data);
    // Create export record
    const exportId = `export_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const now = firestore_1.FieldValue.serverTimestamp();
    const exportRecord = {
        exportId,
        type: validatedData.type,
        format: validatedData.format,
        status: "pending",
        createdAt: now,
    };
    await admin_1.db.collection("exports").doc(exportId).set({
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
    await (0, audit_1.logAuditEvent)({
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
exports.adminExportData = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["data:export"], exportDataHandler)));
async function getExportStatusHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ exportId: joi_1.default.string().required() }), data);
    // Get export record
    const exportDoc = await admin_1.db.collection("exports").doc(validatedData.exportId).get();
    if (!exportDoc.exists) {
        throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, `Export ${validatedData.exportId} not found`, 404);
    }
    const exportData = exportDoc.data();
    // Verify tenant access
    if (exportData.tenantId !== tenantId) {
        throw new errors_1.AppError(errors_1.ErrorCode.NOT_FOUND, `Export ${validatedData.exportId} not found`, 404);
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
exports.adminGetExportStatus = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["data:export"], getExportStatusHandler)));
async function systemHealthHandler(_data, context) {
    const { tenantId } = context;
    // Only owners can view system health
    (0, auth_1.requireRole)(context, ["owner"]);
    // Check various health metrics
    const now = new Date();
    // Active disputes count
    const activeDisputesSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("status", "in", ["draft", "pending_review", "approved", "mailed", "delivered", "bureau_investigating"])
        .count()
        .get();
    // Pending letters count
    const pendingLettersSnapshot = await admin_1.db
        .collection("letters")
        .where("tenantId", "==", tenantId)
        .where("status", "in", ["draft", "pending_approval", "approved", "rendering", "ready", "queued"])
        .count()
        .get();
    // Overdue SLA count
    const overdueSnapshot = await admin_1.db
        .collection("disputes")
        .where("tenantId", "==", tenantId)
        .where("status", "not-in", ["resolved", "closed"])
        .where("timestamps.dueAt", "<", firestore_1.Timestamp.fromDate(now))
        .count()
        .get();
    // Failed webhooks in last 24 hours
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const failedWebhooksSnapshot = await admin_1.db
        .collection("webhookEvents")
        .where("tenantId", "==", tenantId)
        .where("status", "==", "failed")
        .where("receivedAt", ">=", firestore_1.Timestamp.fromDate(yesterday))
        .count()
        .get();
    // Determine overall health status
    let status = "healthy";
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
            lastChecked: firestore_1.FieldValue.serverTimestamp(),
        },
    };
}
exports.adminSystemHealth = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["analytics:read"], systemHealthHandler)));
//# sourceMappingURL=index.js.map