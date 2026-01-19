/**
 * USTAXX Credit Dispute System - Cloud Functions Entry Point
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
  authRequestPasswordReset,
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

// ============================================================================
// Temporary Test Function (REMOVE AFTER TESTING)
// ============================================================================
import * as functions from "firebase-functions";
import { lobService } from "./services/lobService";

export const testLobIntegration = functions.https.onRequest(async (req, res) => {
  try {
    const results: Record<string, unknown> = {
      timestamp: new Date().toISOString(),
      configured: lobService.isConfigured(),
      testMode: lobService.isTestMode(),
    };

    // Test 1: Cost estimation (no API call)
    results.costEstimate = lobService.estimateCost(2, "usps_first_class");

    // Test 2: Address verification
    try {
      const verification = await lobService.verifyAddress({
        name: "Test",
        addressLine1: "185 Berry St Ste 6100",
        city: "San Francisco",
        state: "CA",
        zipCode: "94107",
      });
      results.addressVerification = {
        success: true,
        deliverability: verification.deliverability,
        primaryLine: verification.primary_line,
      };
    } catch (e: unknown) {
      results.addressVerification = { success: false, error: e instanceof Error ? e.message : String(e) };
    }

    // Test 3: Letter creation (test mode)
    try {
      const letter = await lobService.createLetter({
        description: "Integration Test Letter",
        to: {
          name: "Test Recipient",
          addressLine1: "185 Berry St Ste 6100",
          city: "San Francisco",
          state: "CA",
          zipCode: "94107",
        },
        from: {
          name: "USTAXX Test",
          addressLine1: "185 Berry St Ste 6100",
          city: "San Francisco",
          state: "CA",
          zipCode: "94107",
        },
        file: "<html><body><h1>Test Letter</h1><p>This is a test.</p></body></html>",
        color: false,
        mailType: "usps_first_class",
      });
      results.letterCreation = {
        success: true,
        letterId: letter.id,
        expectedDelivery: letter.expected_delivery_date,
        dashboardUrl: `https://dashboard.lob.com/letters/${letter.id}`,
      };
    } catch (e: unknown) {
      results.letterCreation = { success: false, error: e instanceof Error ? e.message : String(e) };
    }

    res.json(results);
  } catch (error: unknown) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});
