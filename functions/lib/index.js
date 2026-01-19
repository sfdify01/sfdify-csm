"use strict";
/**
 * USTAXX Credit Dispute System - Cloud Functions Entry Point
 *
 * This file exports all Cloud Functions for Firebase deployment.
 * Functions are organized by domain for better maintainability.
 *
 * Note: Firebase Admin SDK (db, auth, storage) is initialized in admin.ts
 * and should be imported directly from there by function modules.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.webhooksList = exports.webhooksRetry = exports.webhooksSmartCredit = exports.webhooksLob = exports.authRequestPasswordReset = exports.authSignUp = exports.tenantsList = exports.tenantsUpdate = exports.tenantsGet = exports.tenantsCreate = exports.usersSetRole = exports.usersList = exports.usersDelete = exports.usersUpdate = exports.usersGet = exports.usersCreate = exports.adminSystemHealth = exports.adminGetExportStatus = exports.adminExportData = exports.adminAuditLogs = exports.adminBillingUsage = exports.adminAnalyticsLetters = exports.adminAnalyticsDisputes = exports.evidenceUnlinkFromLetter = exports.evidenceLinkToLetter = exports.evidenceList = exports.evidenceDelete = exports.evidenceUpdate = exports.evidenceGet = exports.evidenceUpload = exports.lettersList = exports.lettersSend = exports.lettersApprove = exports.lettersGet = exports.lettersGenerate = exports.disputesClose = exports.disputesApprove = exports.disputesSubmit = exports.disputesList = exports.disputesUpdate = exports.disputesGet = exports.disputesCreate = exports.consumersTradelinesList = exports.consumersReportsRefresh = exports.consumersSmartCreditDisconnect = exports.consumersSmartCreditConnect = exports.consumersList = exports.consumersUpdate = exports.consumersGet = exports.consumersCreate = void 0;
exports.testLobIntegration = exports.onSmartCreditConnectionChange = exports.onEvidenceUpload = exports.onConsumerCreate = exports.onLetterStatusChange = exports.onDisputeUpdate = exports.onDisputeCreate = exports.scheduledCleanup = exports.scheduledBillingAggregator = exports.scheduledReconciliation = exports.scheduledReportRefresh = exports.scheduledSlaChecker = void 0;
// ============================================================================
// Consumer Functions
// ============================================================================
var consumers_1 = require("./functions/consumers");
Object.defineProperty(exports, "consumersCreate", { enumerable: true, get: function () { return consumers_1.consumersCreate; } });
Object.defineProperty(exports, "consumersGet", { enumerable: true, get: function () { return consumers_1.consumersGet; } });
Object.defineProperty(exports, "consumersUpdate", { enumerable: true, get: function () { return consumers_1.consumersUpdate; } });
Object.defineProperty(exports, "consumersList", { enumerable: true, get: function () { return consumers_1.consumersList; } });
Object.defineProperty(exports, "consumersSmartCreditConnect", { enumerable: true, get: function () { return consumers_1.consumersSmartCreditConnect; } });
Object.defineProperty(exports, "consumersSmartCreditDisconnect", { enumerable: true, get: function () { return consumers_1.consumersSmartCreditDisconnect; } });
Object.defineProperty(exports, "consumersReportsRefresh", { enumerable: true, get: function () { return consumers_1.consumersReportsRefresh; } });
Object.defineProperty(exports, "consumersTradelinesList", { enumerable: true, get: function () { return consumers_1.consumersTradelinesList; } });
// ============================================================================
// Dispute Functions
// ============================================================================
var disputes_1 = require("./functions/disputes");
Object.defineProperty(exports, "disputesCreate", { enumerable: true, get: function () { return disputes_1.disputesCreate; } });
Object.defineProperty(exports, "disputesGet", { enumerable: true, get: function () { return disputes_1.disputesGet; } });
Object.defineProperty(exports, "disputesUpdate", { enumerable: true, get: function () { return disputes_1.disputesUpdate; } });
Object.defineProperty(exports, "disputesList", { enumerable: true, get: function () { return disputes_1.disputesList; } });
Object.defineProperty(exports, "disputesSubmit", { enumerable: true, get: function () { return disputes_1.disputesSubmit; } });
Object.defineProperty(exports, "disputesApprove", { enumerable: true, get: function () { return disputes_1.disputesApprove; } });
Object.defineProperty(exports, "disputesClose", { enumerable: true, get: function () { return disputes_1.disputesClose; } });
// ============================================================================
// Letter Functions
// ============================================================================
var letters_1 = require("./functions/letters");
Object.defineProperty(exports, "lettersGenerate", { enumerable: true, get: function () { return letters_1.lettersGenerate; } });
Object.defineProperty(exports, "lettersGet", { enumerable: true, get: function () { return letters_1.lettersGet; } });
Object.defineProperty(exports, "lettersApprove", { enumerable: true, get: function () { return letters_1.lettersApprove; } });
Object.defineProperty(exports, "lettersSend", { enumerable: true, get: function () { return letters_1.lettersSend; } });
Object.defineProperty(exports, "lettersList", { enumerable: true, get: function () { return letters_1.lettersList; } });
// ============================================================================
// Evidence Functions
// ============================================================================
var evidence_1 = require("./functions/evidence");
Object.defineProperty(exports, "evidenceUpload", { enumerable: true, get: function () { return evidence_1.evidenceUpload; } });
Object.defineProperty(exports, "evidenceGet", { enumerable: true, get: function () { return evidence_1.evidenceGet; } });
Object.defineProperty(exports, "evidenceUpdate", { enumerable: true, get: function () { return evidence_1.evidenceUpdate; } });
Object.defineProperty(exports, "evidenceDelete", { enumerable: true, get: function () { return evidence_1.evidenceDelete; } });
Object.defineProperty(exports, "evidenceList", { enumerable: true, get: function () { return evidence_1.evidenceList; } });
Object.defineProperty(exports, "evidenceLinkToLetter", { enumerable: true, get: function () { return evidence_1.evidenceLinkToLetter; } });
Object.defineProperty(exports, "evidenceUnlinkFromLetter", { enumerable: true, get: function () { return evidence_1.evidenceUnlinkFromLetter; } });
// ============================================================================
// Admin Functions
// ============================================================================
var admin_1 = require("./functions/admin");
Object.defineProperty(exports, "adminAnalyticsDisputes", { enumerable: true, get: function () { return admin_1.adminAnalyticsDisputes; } });
Object.defineProperty(exports, "adminAnalyticsLetters", { enumerable: true, get: function () { return admin_1.adminAnalyticsLetters; } });
Object.defineProperty(exports, "adminBillingUsage", { enumerable: true, get: function () { return admin_1.adminBillingUsage; } });
Object.defineProperty(exports, "adminAuditLogs", { enumerable: true, get: function () { return admin_1.adminAuditLogs; } });
Object.defineProperty(exports, "adminExportData", { enumerable: true, get: function () { return admin_1.adminExportData; } });
Object.defineProperty(exports, "adminGetExportStatus", { enumerable: true, get: function () { return admin_1.adminGetExportStatus; } });
Object.defineProperty(exports, "adminSystemHealth", { enumerable: true, get: function () { return admin_1.adminSystemHealth; } });
// ============================================================================
// User Management Functions
// ============================================================================
var users_1 = require("./functions/users");
Object.defineProperty(exports, "usersCreate", { enumerable: true, get: function () { return users_1.usersCreate; } });
Object.defineProperty(exports, "usersGet", { enumerable: true, get: function () { return users_1.usersGet; } });
Object.defineProperty(exports, "usersUpdate", { enumerable: true, get: function () { return users_1.usersUpdate; } });
Object.defineProperty(exports, "usersDelete", { enumerable: true, get: function () { return users_1.usersDelete; } });
Object.defineProperty(exports, "usersList", { enumerable: true, get: function () { return users_1.usersList; } });
Object.defineProperty(exports, "usersSetRole", { enumerable: true, get: function () { return users_1.usersSetRole; } });
// ============================================================================
// Tenant Management Functions
// ============================================================================
var tenants_1 = require("./functions/tenants");
Object.defineProperty(exports, "tenantsCreate", { enumerable: true, get: function () { return tenants_1.tenantsCreate; } });
Object.defineProperty(exports, "tenantsGet", { enumerable: true, get: function () { return tenants_1.tenantsGet; } });
Object.defineProperty(exports, "tenantsUpdate", { enumerable: true, get: function () { return tenants_1.tenantsUpdate; } });
Object.defineProperty(exports, "tenantsList", { enumerable: true, get: function () { return tenants_1.tenantsList; } });
// ============================================================================
// Public Auth Functions (Self-Service Signup)
// ============================================================================
var auth_1 = require("./functions/auth");
Object.defineProperty(exports, "authSignUp", { enumerable: true, get: function () { return auth_1.authSignUp; } });
Object.defineProperty(exports, "authRequestPasswordReset", { enumerable: true, get: function () { return auth_1.authRequestPasswordReset; } });
// ============================================================================
// Webhook Handlers
// ============================================================================
var webhooks_1 = require("./functions/webhooks");
Object.defineProperty(exports, "webhooksLob", { enumerable: true, get: function () { return webhooks_1.webhooksLob; } });
Object.defineProperty(exports, "webhooksSmartCredit", { enumerable: true, get: function () { return webhooks_1.webhooksSmartCredit; } });
Object.defineProperty(exports, "webhooksRetry", { enumerable: true, get: function () { return webhooks_1.webhooksRetry; } });
Object.defineProperty(exports, "webhooksList", { enumerable: true, get: function () { return webhooks_1.webhooksList; } });
// ============================================================================
// Scheduled Functions
// ============================================================================
var scheduled_1 = require("./functions/scheduled");
Object.defineProperty(exports, "scheduledSlaChecker", { enumerable: true, get: function () { return scheduled_1.scheduledSlaChecker; } });
Object.defineProperty(exports, "scheduledReportRefresh", { enumerable: true, get: function () { return scheduled_1.scheduledReportRefresh; } });
Object.defineProperty(exports, "scheduledReconciliation", { enumerable: true, get: function () { return scheduled_1.scheduledReconciliation; } });
Object.defineProperty(exports, "scheduledBillingAggregator", { enumerable: true, get: function () { return scheduled_1.scheduledBillingAggregator; } });
Object.defineProperty(exports, "scheduledCleanup", { enumerable: true, get: function () { return scheduled_1.scheduledCleanup; } });
// ============================================================================
// Firestore Triggers
// ============================================================================
var triggers_1 = require("./functions/triggers");
Object.defineProperty(exports, "onDisputeCreate", { enumerable: true, get: function () { return triggers_1.onDisputeCreate; } });
Object.defineProperty(exports, "onDisputeUpdate", { enumerable: true, get: function () { return triggers_1.onDisputeUpdate; } });
Object.defineProperty(exports, "onLetterStatusChange", { enumerable: true, get: function () { return triggers_1.onLetterStatusChange; } });
Object.defineProperty(exports, "onConsumerCreate", { enumerable: true, get: function () { return triggers_1.onConsumerCreate; } });
Object.defineProperty(exports, "onEvidenceUpload", { enumerable: true, get: function () { return triggers_1.onEvidenceUpload; } });
Object.defineProperty(exports, "onSmartCreditConnectionChange", { enumerable: true, get: function () { return triggers_1.onSmartCreditConnectionChange; } });
// ============================================================================
// Temporary Test Function (REMOVE AFTER TESTING)
// ============================================================================
const functions = __importStar(require("firebase-functions"));
const lobService_1 = require("./services/lobService");
exports.testLobIntegration = functions.https.onRequest(async (req, res) => {
    try {
        const results = {
            timestamp: new Date().toISOString(),
            configured: lobService_1.lobService.isConfigured(),
            testMode: lobService_1.lobService.isTestMode(),
        };
        // Test 1: Cost estimation (no API call)
        results.costEstimate = lobService_1.lobService.estimateCost(2, "usps_first_class");
        // Test 2: Address verification
        try {
            const verification = await lobService_1.lobService.verifyAddress({
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
        }
        catch (e) {
            results.addressVerification = { success: false, error: e instanceof Error ? e.message : String(e) };
        }
        // Test 3: Letter creation (test mode)
        try {
            const letter = await lobService_1.lobService.createLetter({
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
        }
        catch (e) {
            results.letterCreation = { success: false, error: e instanceof Error ? e.message : String(e) };
        }
        res.json(results);
    }
    catch (error) {
        res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
    }
});
//# sourceMappingURL=index.js.map