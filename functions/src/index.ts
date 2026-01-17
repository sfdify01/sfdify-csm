/**
 * SFDIFY Credit Dispute System - Cloud Functions Entry Point
 *
 * This file exports all Cloud Functions for Firebase deployment.
 * Functions are organized by domain for better maintainability.
 *
 * Note: Firebase Admin SDK (db, auth, storage) is initialized in admin.ts
 * and should be imported directly from there by function modules.
 */

// ============================================================================
// Consumer Functions
// ============================================================================
export {
  consumersCreate,
  consumersGet,
  consumersUpdate,
  consumersList,
  consumersSmartCreditConnect,
  consumersSmartCreditDisconnect,
  consumersReportsRefresh,
  consumersTradelinesList,
} from "./functions/consumers";

// ============================================================================
// Dispute Functions
// ============================================================================
export {
  disputesCreate,
  disputesGet,
  disputesUpdate,
  disputesList,
  disputesSubmit,
  disputesApprove,
  disputesClose,
} from "./functions/disputes";

// ============================================================================
// Letter Functions
// ============================================================================
export {
  lettersGenerate,
  lettersGet,
  lettersApprove,
  lettersSend,
  lettersList,
} from "./functions/letters";

// ============================================================================
// Evidence Functions
// ============================================================================
export {
  evidenceUpload,
  evidenceGet,
  evidenceUpdate,
  evidenceDelete,
  evidenceList,
  evidenceLinkToLetter,
  evidenceUnlinkFromLetter,
} from "./functions/evidence";

// ============================================================================
// Admin Functions
// ============================================================================
export {
  adminAnalyticsDisputes,
  adminAnalyticsLetters,
  adminBillingUsage,
  adminAuditLogs,
  adminExportData,
  adminGetExportStatus,
  adminSystemHealth,
} from "./functions/admin";

// ============================================================================
// User Management Functions
// ============================================================================
export {
  usersCreate,
  usersGet,
  usersUpdate,
  usersDelete,
  usersList,
  usersSetRole,
} from "./functions/users";

// ============================================================================
// Tenant Management Functions
// ============================================================================
export {
  tenantsCreate,
  tenantsGet,
  tenantsUpdate,
  tenantsList,
} from "./functions/tenants";

// ============================================================================
// Public Auth Functions (Self-Service Signup)
// ============================================================================
export {
  authSignUp,
} from "./functions/auth";

// ============================================================================
// Webhook Handlers
// ============================================================================
export {
  webhooksLob,
  webhooksSmartCredit,
  webhooksRetry,
  webhooksList,
} from "./functions/webhooks";

// ============================================================================
// Scheduled Functions
// ============================================================================
export {
  scheduledSlaChecker,
  scheduledReportRefresh,
  scheduledReconciliation,
  scheduledBillingAggregator,
  scheduledCleanup,
} from "./functions/scheduled";

// ============================================================================
// Firestore Triggers
// ============================================================================
export {
  onDisputeCreate,
  onDisputeUpdate,
  onLetterStatusChange,
  onConsumerCreate,
  onEvidenceUpload,
  onSmartCreditConnectionChange,
} from "./functions/triggers";
