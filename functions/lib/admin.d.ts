/**
 * Firebase Admin SDK Initialization
 *
 * This file initializes the Firebase Admin SDK and exports
 * the Firestore, Auth, and Storage instances for use throughout the app.
 *
 * Separated from index.ts to avoid circular dependencies.
 */
import * as admin from "firebase-admin";
export declare const db: admin.firestore.Firestore;
export declare const auth: import("firebase-admin/auth").Auth;
export declare const storage: import("firebase-admin/lib/storage/storage").Storage;
//# sourceMappingURL=admin.d.ts.map