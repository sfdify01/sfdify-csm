/**
 * Letter Management Cloud Functions
 *
 * Handles letter generation, approval, and sending via Lob.
 * Implements quality checks and integrates with Lob print-and-mail API.
 */
import * as functions from "firebase-functions";
import { LetterStatus } from "../../types";
/**
 * Check if a status transition is valid
 */
declare function isValidStatusTransition(from: LetterStatus, to: LetterStatus): boolean;
export { isValidStatusTransition };
export declare const lettersGenerate: functions.HttpsFunction & functions.Runnable<any>;
export declare const lettersGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const lettersApprove: functions.HttpsFunction & functions.Runnable<any>;
export declare const lettersSend: functions.HttpsFunction & functions.Runnable<any>;
export declare const lettersList: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map