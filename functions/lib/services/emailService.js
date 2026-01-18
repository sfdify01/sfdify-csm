"use strict";
/**
 * Email Service
 *
 * Handles email notifications using SendGrid.
 * Provides template-based email sending for various notification types.
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
exports.EmailService = exports.emailService = exports.EMAIL_TEMPLATES = void 0;
const mail_1 = __importDefault(require("@sendgrid/mail"));
const config_1 = require("../config");
const logger = __importStar(require("firebase-functions/logger"));
// Email template IDs (to be configured in SendGrid)
exports.EMAIL_TEMPLATES = {
    // SLA and Dispute Notifications
    SLA_REMINDER_5_DAYS: "d-sla-reminder-5-days",
    SLA_REMINDER_3_DAYS: "d-sla-reminder-3-days",
    SLA_REMINDER_1_DAY: "d-sla-reminder-1-day",
    SLA_OVERDUE: "d-sla-overdue",
    // Letter Notifications
    LETTER_GENERATED: "d-letter-generated",
    LETTER_SENT: "d-letter-sent",
    LETTER_DELIVERED: "d-letter-delivered",
    LETTER_RETURNED: "d-letter-returned",
    // Dispute Status Notifications
    DISPUTE_CREATED: "d-dispute-created",
    DISPUTE_APPROVED: "d-dispute-approved",
    DISPUTE_REJECTED: "d-dispute-rejected",
    DISPUTE_RESOLVED: "d-dispute-resolved",
    // Account Notifications
    WELCOME: "d-welcome",
    PASSWORD_RESET: "d-password-reset",
    ACCOUNT_LOCKED: "d-account-locked",
    // Report Notifications
    CREDIT_REPORT_READY: "d-credit-report-ready",
    CREDIT_ALERT: "d-credit-alert",
    // Billing
    INVOICE_READY: "d-invoice-ready",
    PAYMENT_RECEIVED: "d-payment-received",
    PAYMENT_FAILED: "d-payment-failed",
};
// ============================================================================
// Email Service Class
// ============================================================================
class EmailService {
    initialized = false;
    constructor() {
        this.initialize();
    }
    /**
     * Initialize SendGrid with API key
     */
    initialize() {
        if (config_1.sendgridConfig.apiKey) {
            mail_1.default.setApiKey(config_1.sendgridConfig.apiKey);
            this.initialized = true;
        }
        else {
            logger.warn("[Email Service] SendGrid API key not configured");
        }
    }
    /**
     * Check if service is configured
     */
    isConfigured() {
        return this.initialized && !!config_1.sendgridConfig.apiKey;
    }
    /**
     * Send a single email
     */
    async send(options) {
        if (!this.isConfigured()) {
            logger.warn("[Email Service] Not configured, skipping email send");
            return this.mockSend(options);
        }
        try {
            // Build message object - use type assertion since SendGrid's types are overly strict
            // When using templateId, content is not required
            const msg = {
                to: options.to,
                from: options.from || {
                    email: config_1.sendgridConfig.fromEmail,
                    name: config_1.sendgridConfig.fromName,
                },
                subject: options.subject,
                ...(options.templateId && { templateId: options.templateId }),
                ...(options.templateId && options.templateData && { dynamicTemplateData: options.templateData }),
                ...(!options.templateId && options.html && { html: options.html }),
                ...(!options.templateId && options.text && { text: options.text }),
                ...(options.replyTo && { replyTo: options.replyTo }),
                ...(options.attachments && { attachments: options.attachments }),
                ...(options.categories && { categories: options.categories }),
                ...(options.sendAt && { sendAt: options.sendAt }),
            };
            const [response] = await mail_1.default.send(msg);
            logger.info("[Email Service] Email sent", {
                to: Array.isArray(options.to) ? options.to.length : 1,
                subject: options.subject,
                templateId: options.templateId,
                statusCode: response.statusCode,
            });
            return {
                success: true,
                messageId: response.headers["x-message-id"],
            };
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : "Unknown error";
            logger.error("[Email Service] Failed to send email", {
                error: errorMessage,
                to: options.to,
                subject: options.subject,
            });
            return {
                success: false,
                error: errorMessage,
            };
        }
    }
    /**
     * Send bulk emails
     */
    async sendBulk(emails) {
        const results = await Promise.all(emails.map((email) => this.send(email)));
        const successful = results.filter((r) => r.success).length;
        const failed = results.filter((r) => !r.success).length;
        return {
            total: emails.length,
            successful,
            failed,
            results,
        };
    }
    /**
     * Mock send for development/testing
     */
    mockSend(options) {
        logger.info("[Email Service] Mock email sent", {
            to: options.to,
            subject: options.subject,
            templateId: options.templateId,
        });
        return {
            success: true,
            messageId: `mock_${Date.now()}`,
        };
    }
    // ==========================================================================
    // Pre-built Email Methods
    // ==========================================================================
    /**
     * Send SLA reminder email
     */
    async sendSlaReminder(to, data) {
        const templateId = data.daysRemaining <= 1
            ? exports.EMAIL_TEMPLATES.SLA_REMINDER_1_DAY
            : data.daysRemaining <= 3
                ? exports.EMAIL_TEMPLATES.SLA_REMINDER_3_DAYS
                : exports.EMAIL_TEMPLATES.SLA_REMINDER_5_DAYS;
        return this.send({
            to,
            subject: `SLA Reminder: ${data.daysRemaining} day(s) remaining for ${data.consumerName}'s dispute`,
            templateId,
            templateData: data,
            categories: ["sla-reminder", "dispute"],
        });
    }
    /**
     * Send letter status notification
     */
    async sendLetterNotification(to, type, data) {
        const templates = {
            sent: exports.EMAIL_TEMPLATES.LETTER_SENT,
            delivered: exports.EMAIL_TEMPLATES.LETTER_DELIVERED,
            returned: exports.EMAIL_TEMPLATES.LETTER_RETURNED,
        };
        const subjects = {
            sent: `Letter Sent: ${data.consumerName}'s dispute letter to ${data.bureau}`,
            delivered: `Letter Delivered: ${data.consumerName}'s dispute letter reached ${data.bureau}`,
            returned: `Letter Returned: ${data.consumerName}'s dispute letter was returned`,
        };
        return this.send({
            to,
            subject: subjects[type],
            templateId: templates[type],
            templateData: data,
            categories: ["letter-notification", type],
        });
    }
    /**
     * Send dispute status update
     */
    async sendDisputeStatusUpdate(to, data) {
        const templateMap = {
            approved: exports.EMAIL_TEMPLATES.DISPUTE_APPROVED,
            rejected: exports.EMAIL_TEMPLATES.DISPUTE_REJECTED,
            resolved: exports.EMAIL_TEMPLATES.DISPUTE_RESOLVED,
        };
        const templateId = templateMap[data.newStatus] || exports.EMAIL_TEMPLATES.DISPUTE_CREATED;
        return this.send({
            to,
            subject: `Dispute ${data.newStatus}: ${data.consumerName}'s ${data.bureau} dispute`,
            templateId,
            templateData: data,
            categories: ["dispute-status", data.newStatus],
        });
    }
    /**
     * Send credit alert notification
     */
    async sendCreditAlert(to, data) {
        return this.send({
            to,
            subject: `Credit Alert: ${data.alertTitle}`,
            templateId: exports.EMAIL_TEMPLATES.CREDIT_ALERT,
            templateData: data,
            categories: ["credit-alert", data.severity],
        });
    }
    /**
     * Send welcome email to new user
     */
    async sendWelcomeEmail(to, data) {
        return this.send({
            to,
            subject: `Welcome to ${data.companyName}`,
            templateId: exports.EMAIL_TEMPLATES.WELCOME,
            templateData: data,
            categories: ["onboarding", "welcome"],
        });
    }
    /**
     * Send password reset email
     */
    async sendPasswordReset(to, data) {
        return this.send({
            to,
            subject: "Password Reset Request",
            templateId: exports.EMAIL_TEMPLATES.PASSWORD_RESET,
            templateData: data,
            categories: ["account", "password-reset"],
        });
    }
}
exports.EmailService = EmailService;
// Export singleton instance
exports.emailService = new EmailService();
//# sourceMappingURL=emailService.js.map