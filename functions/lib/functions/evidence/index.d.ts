/**
 * Evidence Management Cloud Functions
 *
 * Handles evidence file upload, retrieval, and management.
 * Supports virus scanning and secure file storage.
 */
import * as functions from "firebase-functions";
export declare const evidenceUpload: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceUpdate: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceDelete: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceList: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceLinkToLetter: functions.HttpsFunction & functions.Runnable<any>;
export declare const evidenceUnlinkFromLetter: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map