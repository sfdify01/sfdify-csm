/**
 * Tenant Management Cloud Functions
 *
 * Handles tenant creation, updates, and retrieval.
 * Tenants represent credit repair companies using the system.
 */
import * as functions from "firebase-functions";
export declare const tenantsCreate: functions.HttpsFunction & functions.Runnable<any>;
export declare const tenantsGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const tenantsUpdate: functions.HttpsFunction & functions.Runnable<any>;
export declare const tenantsList: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map