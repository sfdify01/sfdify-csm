/**
 * Public Authentication Cloud Functions
 *
 * These functions are PUBLIC (no auth required) and handle:
 * - Self-service signup with email/password
 *
 * Unlike other functions, these don't use withAuth middleware
 * since they're called by unauthenticated users.
 */
import * as functions from "firebase-functions";
export declare const authSignUp: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map