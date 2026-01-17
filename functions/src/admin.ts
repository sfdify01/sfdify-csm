/**
 * Firebase Admin SDK Initialization
 *
 * This file initializes the Firebase Admin SDK and exports
 * the Firestore, Auth, and Storage instances for use throughout the app.
 *
 * Separated from index.ts to avoid circular dependencies.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export Firestore and Auth instances for use throughout the app
export const db = admin.firestore();

// Configure Firestore to ignore undefined values
// This prevents errors when trying to save documents with undefined fields
db.settings({ ignoreUndefinedProperties: true });

export const auth = admin.auth();
export const storage = admin.storage();
