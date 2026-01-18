"use strict";
/**
 * Application Configuration
 *
 * Central configuration for all Cloud Functions.
 * Uses Firebase Functions config() for secrets in production.
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
exports.BUREAU_ADDRESSES = exports.auditConfig = exports.rateLimitConfig = exports.uploadConfig = exports.slaConfig = exports.twilioConfig = exports.sendgridConfig = exports.lobConfig = exports.smartCreditConfig = exports.kmsConfig = exports.firebaseConfig = exports.isEmulator = exports.isProduction = void 0;
const functions = __importStar(require("firebase-functions"));
// Environment detection
exports.isProduction = process.env.NODE_ENV === "production";
exports.isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
/**
 * Firebase project configuration
 */
exports.firebaseConfig = {
    projectId: process.env.GCLOUD_PROJECT || "ustaxx-csm",
    region: "us-central1",
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "ustaxx-csm.firebasestorage.app",
};
/**
 * Cloud KMS configuration for PII encryption
 */
exports.kmsConfig = {
    projectId: exports.firebaseConfig.projectId,
    location: "global",
    keyRing: "ustaxx-pii",
    cryptoKey: "pii-encryption-key",
    get keyName() {
        return `projects/${this.projectId}/locations/${this.location}/keyRings/${this.keyRing}/cryptoKeys/${this.cryptoKey}`;
    },
};
/**
 * SmartCredit API configuration
 */
exports.smartCreditConfig = {
    baseUrl: exports.isProduction
        ? "https://api.smartcredit.com/v1"
        : "https://sandbox.smartcredit.com/api/v1",
    clientId: functions.config().smartcredit?.client_id || process.env.SMARTCREDIT_CLIENT_ID || "",
    clientSecret: functions.config().smartcredit?.client_secret || process.env.SMARTCREDIT_CLIENT_SECRET || "",
    webhookSecret: functions.config().smartcredit?.webhook_secret || process.env.SMARTCREDIT_WEBHOOK_SECRET || "",
    tokenExpiryBuffer: 5 * 60 * 1000, // 5 minutes before expiry
    rateLimitPerMinute: 60,
};
/**
 * Lob API configuration for mail services
 */
exports.lobConfig = {
    baseUrl: "https://api.lob.com/v1",
    apiKey: exports.isProduction
        ? (functions.config().lob?.api_key_live || process.env.LOB_API_KEY_LIVE || "")
        : (functions.config().lob?.api_key_test || process.env.LOB_API_KEY_TEST || ""),
    webhookSecret: functions.config().lob?.webhook_secret || process.env.LOB_WEBHOOK_SECRET || "",
    rateLimitPerMinute: 150,
};
/**
 * SendGrid configuration for email notifications
 */
exports.sendgridConfig = {
    apiKey: functions.config().sendgrid?.api_key || process.env.SENDGRID_API_KEY || "",
    fromEmail: "notifications@ustaxx.com",
    fromName: "USTAXX Credit Services",
};
/**
 * Twilio configuration for SMS notifications
 */
exports.twilioConfig = {
    accountSid: functions.config().twilio?.account_sid || process.env.TWILIO_ACCOUNT_SID || "",
    authToken: functions.config().twilio?.auth_token || process.env.TWILIO_AUTH_TOKEN || "",
    fromNumber: functions.config().twilio?.from_number || process.env.TWILIO_FROM_NUMBER || "",
};
/**
 * SLA configuration for dispute timelines
 */
exports.slaConfig = {
    baseDays: 30, // FCRA requires 30 days
    extensionDays: 15, // Can extend to 45 days total
    reminderDays: [5, 3, 1], // Days before due date to send reminders
    followUpGraceDays: 5, // Days after due date before escalation
};
/**
 * File upload configuration
 */
exports.uploadConfig = {
    maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
    maxTotalSizePerDispute: 50 * 1024 * 1024, // 50MB
    allowedMimeTypes: [
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/gif",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ],
    virusScanEnabled: true,
};
/**
 * Rate limiting configuration
 */
exports.rateLimitConfig = {
    perUser: {
        requestsPerMinute: 100,
        burstSize: 20,
    },
    perTenant: {
        requestsPerMinute: 1000,
        burstSize: 200,
    },
};
/**
 * Audit log retention configuration
 */
exports.auditConfig = {
    retentionYears: 7, // FCRA/GLBA requirement
    sensitiveFieldsToRedact: ["ssnLast4", "dob", "firstName", "lastName", "accessToken", "refreshToken"],
};
/**
 * Bureau addresses for dispute letters
 */
exports.BUREAU_ADDRESSES = {
    equifax: {
        name: "Equifax Information Services LLC",
        addressLine1: "P.O. Box 740256",
        city: "Atlanta",
        state: "GA",
        zipCode: "30374-0256",
    },
    experian: {
        name: "Experian",
        addressLine1: "P.O. Box 4500",
        city: "Allen",
        state: "TX",
        zipCode: "75013",
    },
    transunion: {
        name: "TransUnion LLC",
        addressLine1: "P.O. Box 2000",
        city: "Chester",
        state: "PA",
        zipCode: "19016",
    },
};
//# sourceMappingURL=index.js.map