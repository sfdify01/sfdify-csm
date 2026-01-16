/**
 * Dispute Management Cloud Functions
 *
 * Handles dispute lifecycle: creation, updates, approval, submission, and closure.
 * Implements FCRA 30/45 day SLA tracking and status transitions.
 */
import * as functions from "firebase-functions";
export declare const disputesCreate: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesUpdate: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesList: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesSubmit: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesApprove: functions.HttpsFunction & functions.Runnable<any>;
export declare const disputesClose: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map