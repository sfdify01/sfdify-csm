"use strict";
/**
 * SMS Service
 *
 * Handles SMS notifications using Twilio.
 * Provides SMS sending for alerts and notifications.
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SmsService = exports.smsService = exports.SMS_TEMPLATES = void 0;
const twilio_1 = __importDefault(require("twilio"));
const config_1 = require("../config");
const logger = __importStar(require("firebase-functions/logger"));
// SMS message templates
exports.SMS_TEMPLATES = {
    SLA_REMINDER: (daysRemaining, bureau) => `USTAXX Alert: Your ${bureau} dispute has ${daysRemaining} day(s) until SLA deadline. Login to take action.`,
    LETTER_SENT: (bureau) => `USTAXX: Your dispute letter to ${bureau} has been sent! You'll receive tracking info soon.`,
    LETTER_DELIVERED: (bureau) => `USTAXX: Great news! Your dispute letter to ${bureau} was delivered successfully.`,
    LETTER_RETURNED: (bureau) => `USTAXX Alert: Your letter to ${bureau} was returned. Please login to review and resend.`,
    DISPUTE_RESOLVED: (bureau, outcome) => `USTAXX: Your ${bureau} dispute has been resolved with outcome: ${outcome}. Login for details.`,
    CREDIT_ALERT: (alertType) => `USTAXX Credit Alert: ${alertType}. Login to your account for more details.`,
    VERIFICATION_CODE: (code) => `Your USTAXX verification code is: ${code}. This code expires in 10 minutes.`,
    PASSWORD_RESET: () => `USTAXX: A password reset was requested for your account. If this wasn't you, please contact support.`,
};
// ============================================================================
// SMS Service Class
// ============================================================================
class SmsService {
    client = null;
    fromNumber;
    constructor() {
        this.fromNumber = config_1.twilioConfig.fromNumber;
        this.initialize();
    }
    /**
     * Initialize Twilio client
     */
    initialize() {
        if (config_1.twilioConfig.accountSid && config_1.twilioConfig.authToken) {
            this.client = (0, twilio_1.default)(config_1.twilioConfig.accountSid, config_1.twilioConfig.authToken);
        }
        else {
            logger.warn("[SMS Service] Twilio credentials not configured");
        }
    }
    /**
     * Check if service is configured
     */
    isConfigured() {
        return this.client !== null && !!this.fromNumber;
    }
    /**
     * Normalize phone number to E.164 format
     */
    normalizePhoneNumber(phone) {
        // Remove all non-numeric characters
        let cleaned = phone.replace(/\D/g, "");
        // Add US country code if not present
        if (cleaned.length === 10) {
            cleaned = "1" + cleaned;
        }
        // Add + prefix
        if (!cleaned.startsWith("+")) {
            cleaned = "+" + cleaned;
        }
        return cleaned;
    }
    /**
     * Send a single SMS
     */
    async send(options) {
        if (!this.isConfigured()) {
            logger.warn("[SMS Service] Not configured, skipping SMS send");
            return this.mockSend(options);
        }
        try {
            const normalizedTo = this.normalizePhoneNumber(options.to);
            const message = await this.client.messages.create({
                to: normalizedTo,
                from: options.from || this.fromNumber,
                body: options.body,
                mediaUrl: options.mediaUrl,
                statusCallback: options.statusCallback,
            });
            logger.info("[SMS Service] SMS sent", {
                to: normalizedTo.substring(0, 5) + "****",
                sid: message.sid,
                status: message.status,
            });
            return {
                success: true,
                messageId: message.sid,
                status: message.status,
            };
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : "Unknown error";
            logger.error("[SMS Service] Failed to send SMS", {
                error: errorMessage,
                to: options.to.substring(0, 5) + "****",
            });
            return {
                success: false,
                error: errorMessage,
            };
        }
    }
    /**
     * Send bulk SMS messages
     */
    async sendBulk(messages) {
        // Twilio has rate limits, so we process in batches with delay
        const batchSize = 10;
        const delayMs = 1000;
        const results = [];
        for (let i = 0; i < messages.length; i += batchSize) {
            const batch = messages.slice(i, i + batchSize);
            const batchResults = await Promise.all(batch.map((msg) => this.send(msg)));
            results.push(...batchResults);
            // Add delay between batches to avoid rate limiting
            if (i + batchSize < messages.length) {
                await new Promise((resolve) => setTimeout(resolve, delayMs));
            }
        }
        const successful = results.filter((r) => r.success).length;
        const failed = results.filter((r) => !r.success).length;
        return {
            total: messages.length,
            successful,
            failed,
            results,
        };
    }
    /**
     * Mock send for development/testing
     */
    mockSend(options) {
        logger.info("[SMS Service] Mock SMS sent", {
            to: options.to.substring(0, 5) + "****",
            body: options.body.substring(0, 50) + "...",
        });
        return {
            success: true,
            messageId: `mock_${Date.now()}`,
            status: "sent",
        };
    }
    // ==========================================================================
    // Pre-built SMS Methods
    // ==========================================================================
    /**
     * Send SLA reminder SMS
     */
    async sendSlaReminder(to, daysRemaining, bureau) {
        return this.send({
            to,
            body: exports.SMS_TEMPLATES.SLA_REMINDER(daysRemaining, bureau),
        });
    }
    /**
     * Send letter status SMS
     */
    async sendLetterStatus(to, status, bureau) {
        const templates = {
            sent: exports.SMS_TEMPLATES.LETTER_SENT,
            delivered: exports.SMS_TEMPLATES.LETTER_DELIVERED,
            returned: exports.SMS_TEMPLATES.LETTER_RETURNED,
        };
        return this.send({
            to,
            body: templates[status](bureau),
        });
    }
    /**
     * Send dispute resolved SMS
     */
    async sendDisputeResolved(to, bureau, outcome) {
        return this.send({
            to,
            body: exports.SMS_TEMPLATES.DISPUTE_RESOLVED(bureau, outcome),
        });
    }
    /**
     * Send credit alert SMS
     */
    async sendCreditAlert(to, alertType) {
        return this.send({
            to,
            body: exports.SMS_TEMPLATES.CREDIT_ALERT(alertType),
        });
    }
    /**
     * Send verification code SMS
     */
    async sendVerificationCode(to, code) {
        return this.send({
            to,
            body: exports.SMS_TEMPLATES.VERIFICATION_CODE(code),
        });
    }
    /**
     * Send password reset notification SMS
     */
    async sendPasswordResetNotification(to) {
        return this.send({
            to,
            body: exports.SMS_TEMPLATES.PASSWORD_RESET(),
        });
    }
    // ==========================================================================
    // Message Status
    // ==========================================================================
    /**
     * Get message status by SID
     */
    async getMessageStatus(messageSid) {
        if (!this.isConfigured()) {
            return null;
        }
        try {
            const message = await this.client.messages(messageSid).fetch();
            return {
                status: message.status,
                errorCode: message.errorCode || undefined,
                errorMessage: message.errorMessage || undefined,
            };
        }
        catch (error) {
            logger.error("[SMS Service] Failed to get message status", {
                messageSid,
                error,
            });
            return null;
        }
    }
    /**
     * Check if phone number is valid and can receive SMS
     */
    async validatePhoneNumber(phone) {
        if (!this.isConfigured()) {
            return { valid: true }; // Assume valid in dev mode
        }
        try {
            const normalizedPhone = this.normalizePhoneNumber(phone);
            const lookup = await this.client.lookups.v2.phoneNumbers(normalizedPhone).fetch({
                fields: "line_type_intelligence",
            });
            return {
                valid: lookup.valid,
                carrier: lookup.callerName?.caller_name,
                type: lookup.lineTypeIntelligence?.type,
            };
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : "Unknown error";
            return {
                valid: false,
                error: errorMessage,
            };
        }
    }
}
exports.SmsService = SmsService;
// Export singleton instance
exports.smsService = new SmsService();
//# sourceMappingURL=smsService.js.map