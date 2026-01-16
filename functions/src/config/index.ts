/**
 * Application Configuration
 *
 * Central configuration for all Cloud Functions.
 * Uses Firebase Functions config() for secrets in production.
 */

import * as functions from "firebase-functions";

// Environment detection
export const isProduction = process.env.NODE_ENV === "production";
export const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

/**
 * Firebase project configuration
 */
export const firebaseConfig = {
  projectId: process.env.GCLOUD_PROJECT || "ustaxx-csm",
  region: "us-central1",
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "ustaxx-csm.firebasestorage.app",
};

/**
 * Cloud KMS configuration for PII encryption
 */
export const kmsConfig = {
  projectId: firebaseConfig.projectId,
  location: "global",
  keyRing: "sfdify-pii",
  cryptoKey: "pii-encryption-key",
  get keyName() {
    return `projects/${this.projectId}/locations/${this.location}/keyRings/${this.keyRing}/cryptoKeys/${this.cryptoKey}`;
  },
};

/**
 * SmartCredit API configuration
 */
export const smartCreditConfig = {
  baseUrl: isProduction
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
export const lobConfig = {
  baseUrl: "https://api.lob.com/v1",
  apiKey: isProduction
    ? (functions.config().lob?.api_key_live || process.env.LOB_API_KEY_LIVE || "")
    : (functions.config().lob?.api_key_test || process.env.LOB_API_KEY_TEST || ""),
  webhookSecret: functions.config().lob?.webhook_secret || process.env.LOB_WEBHOOK_SECRET || "",
  rateLimitPerMinute: 150,
};

/**
 * SendGrid configuration for email notifications
 */
export const sendgridConfig = {
  apiKey: functions.config().sendgrid?.api_key || process.env.SENDGRID_API_KEY || "",
  fromEmail: "notifications@sfdify.com",
  fromName: "SFDIFY Credit Services",
};

/**
 * Twilio configuration for SMS notifications
 */
export const twilioConfig = {
  accountSid: functions.config().twilio?.account_sid || process.env.TWILIO_ACCOUNT_SID || "",
  authToken: functions.config().twilio?.auth_token || process.env.TWILIO_AUTH_TOKEN || "",
  fromNumber: functions.config().twilio?.from_number || process.env.TWILIO_FROM_NUMBER || "",
};

/**
 * SLA configuration for dispute timelines
 */
export const slaConfig = {
  baseDays: 30, // FCRA requires 30 days
  extensionDays: 15, // Can extend to 45 days total
  reminderDays: [5, 3, 1], // Days before due date to send reminders
  followUpGraceDays: 5, // Days after due date before escalation
};

/**
 * File upload configuration
 */
export const uploadConfig = {
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
export const rateLimitConfig = {
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
export const auditConfig = {
  retentionYears: 7, // FCRA/GLBA requirement
  sensitiveFieldsToRedact: ["ssnLast4", "dob", "firstName", "lastName", "accessToken", "refreshToken"],
};

/**
 * Bureau addresses for dispute letters
 */
export const BUREAU_ADDRESSES = {
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
} as const;

export type Bureau = keyof typeof BUREAU_ADDRESSES;
