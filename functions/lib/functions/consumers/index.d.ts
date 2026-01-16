/**
 * Consumer Management Cloud Functions
 *
 * Handles consumer CRUD, SmartCredit connection, and report management.
 * PII fields (firstName, lastName, dob, ssnLast4) are encrypted at rest.
 */
import * as functions from "firebase-functions";
export declare const consumersCreate: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersUpdate: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersList: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersSmartCreditConnect: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersSmartCreditDisconnect: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersReportsRefresh: functions.HttpsFunction & functions.Runnable<any>;
export declare const consumersTradelinesList: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map