/**
 * User Management Cloud Functions
 *
 * Handles user creation, updates, role assignment, and listing.
 * Implements role-based access control (RBAC) for multi-tenant security.
 */
import * as functions from "firebase-functions";
export declare const usersCreate: functions.HttpsFunction & functions.Runnable<any>;
export declare const usersGet: functions.HttpsFunction & functions.Runnable<any>;
export declare const usersUpdate: functions.HttpsFunction & functions.Runnable<any>;
export declare const usersDelete: functions.HttpsFunction & functions.Runnable<any>;
export declare const usersList: functions.HttpsFunction & functions.Runnable<any>;
export declare const usersSetRole: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map