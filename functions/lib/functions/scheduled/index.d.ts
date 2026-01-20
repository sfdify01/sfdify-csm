/**
 * Scheduled Cloud Functions
 *
 * Handles periodic background tasks like SLA monitoring, report refresh,
 * reconciliation, and billing aggregation.
 */
import * as functions from "firebase-functions";
export declare const scheduledSlaChecker: functions.CloudFunction<unknown>;
export declare const scheduledReportRefresh: functions.CloudFunction<unknown>;
export declare const scheduledReconciliation: functions.CloudFunction<unknown>;
export declare const scheduledCleanup: functions.CloudFunction<unknown>;
//# sourceMappingURL=index.d.ts.map