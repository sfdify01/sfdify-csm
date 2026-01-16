/**
 * Firestore Trigger Cloud Functions
 *
 * Handles automatic actions on document changes including:
 * - SLA deadline calculations
 * - Audit logging
 * - Status synchronization
 * - Notifications
 * - Statistics aggregation
 */
import * as functions from "firebase-functions";
export declare const onDisputeCreate: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
export declare const onDisputeUpdate: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
export declare const onLetterStatusChange: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
export declare const onConsumerCreate: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
export declare const onEvidenceUpload: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
export declare const onSmartCreditConnectionChange: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
//# sourceMappingURL=index.d.ts.map