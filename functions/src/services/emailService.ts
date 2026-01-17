/**
 * Email Service
 *
 * Handles email notifications using SendGrid.
 * Provides template-based email sending for various notification types.
 */

import sgMail, { MailDataRequired } from "@sendgrid/mail";
import { sendgridConfig, isEmulator } from "../config";
import * as logger from "firebase-functions/logger";

// ============================================================================
// Types
// ============================================================================

export interface EmailOptions {
  to: string | string[];
  subject: string;
  templateId?: string;
  templateData?: Record<string, unknown>;
  text?: string;
  html?: string;
  from?: { email: string; name: string };
  replyTo?: string;
  attachments?: Array<{
    content: string; // Base64 encoded
    filename: string;
    type: string;
    disposition?: "attachment" | "inline";
  }>;
  categories?: string[];
  sendAt?: number;
}

export interface EmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface BulkEmailResult {
  total: number;
  successful: number;
  failed: number;
  results: EmailResult[];
}

// Email template IDs (to be configured in SendGrid)
export const EMAIL_TEMPLATES = {
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
} as const;

export type EmailTemplate = typeof EMAIL_TEMPLATES[keyof typeof EMAIL_TEMPLATES];

// ============================================================================
// Email Service Class
// ============================================================================

class EmailService {
  private initialized = false;

  constructor() {
    this.initialize();
  }

  /**
   * Initialize SendGrid with API key
   */
  private initialize(): void {
    if (sendgridConfig.apiKey) {
      sgMail.setApiKey(sendgridConfig.apiKey);
      this.initialized = true;
    } else {
      logger.warn("[Email Service] SendGrid API key not configured");
    }
  }

  /**
   * Check if service is configured
   */
  isConfigured(): boolean {
    return this.initialized && !!sendgridConfig.apiKey;
  }

  /**
   * Send a single email
   */
  async send(options: EmailOptions): Promise<EmailResult> {
    if (!this.isConfigured()) {
      logger.warn("[Email Service] Not configured, skipping email send");
      return this.mockSend(options);
    }

    try {
      const msg: MailDataRequired = {
        to: options.to,
        from: options.from || {
          email: sendgridConfig.fromEmail,
          name: sendgridConfig.fromName,
        },
        subject: options.subject,
      };

      // Add content - template or direct content
      if (options.templateId) {
        msg.templateId = options.templateId;
        if (options.templateData) {
          msg.dynamicTemplateData = options.templateData;
        }
      } else if (options.html) {
        msg.html = options.html;
        if (options.text) {
          msg.text = options.text;
        }
      } else if (options.text) {
        msg.text = options.text;
      }

      // Add optional fields
      if (options.replyTo) {
        msg.replyTo = options.replyTo;
      }
      if (options.attachments) {
        msg.attachments = options.attachments;
      }
      if (options.categories) {
        msg.categories = options.categories;
      }
      if (options.sendAt) {
        msg.sendAt = options.sendAt;
      }

      const [response] = await sgMail.send(msg);

      logger.info("[Email Service] Email sent", {
        to: Array.isArray(options.to) ? options.to.length : 1,
        subject: options.subject,
        templateId: options.templateId,
        statusCode: response.statusCode,
      });

      return {
        success: true,
        messageId: response.headers["x-message-id"] as string,
      };
    } catch (error) {
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
  async sendBulk(emails: EmailOptions[]): Promise<BulkEmailResult> {
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
  private mockSend(options: EmailOptions): EmailResult {
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
  async sendSlaReminder(
    to: string,
    data: {
      consumerName: string;
      disputeId: string;
      bureau: string;
      daysRemaining: number;
      dueDate: string;
      disputeUrl: string;
    }
  ): Promise<EmailResult> {
    const templateId = data.daysRemaining <= 1
      ? EMAIL_TEMPLATES.SLA_REMINDER_1_DAY
      : data.daysRemaining <= 3
        ? EMAIL_TEMPLATES.SLA_REMINDER_3_DAYS
        : EMAIL_TEMPLATES.SLA_REMINDER_5_DAYS;

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
  async sendLetterNotification(
    to: string,
    type: "sent" | "delivered" | "returned",
    data: {
      consumerName: string;
      letterId: string;
      bureau: string;
      trackingNumber?: string;
      letterUrl?: string;
      returnReason?: string;
    }
  ): Promise<EmailResult> {
    const templates = {
      sent: EMAIL_TEMPLATES.LETTER_SENT,
      delivered: EMAIL_TEMPLATES.LETTER_DELIVERED,
      returned: EMAIL_TEMPLATES.LETTER_RETURNED,
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
  async sendDisputeStatusUpdate(
    to: string,
    data: {
      consumerName: string;
      disputeId: string;
      bureau: string;
      oldStatus: string;
      newStatus: string;
      disputeUrl: string;
      outcome?: string;
      outcomeDetails?: string;
    }
  ): Promise<EmailResult> {
    const templateMap: Record<string, EmailTemplate> = {
      approved: EMAIL_TEMPLATES.DISPUTE_APPROVED,
      rejected: EMAIL_TEMPLATES.DISPUTE_REJECTED,
      resolved: EMAIL_TEMPLATES.DISPUTE_RESOLVED,
    };

    const templateId = templateMap[data.newStatus] || EMAIL_TEMPLATES.DISPUTE_CREATED;

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
  async sendCreditAlert(
    to: string,
    data: {
      consumerName: string;
      alertType: string;
      alertTitle: string;
      alertDescription: string;
      bureau: string;
      severity: "info" | "warning" | "critical";
      alertUrl?: string;
    }
  ): Promise<EmailResult> {
    return this.send({
      to,
      subject: `Credit Alert: ${data.alertTitle}`,
      templateId: EMAIL_TEMPLATES.CREDIT_ALERT,
      templateData: data,
      categories: ["credit-alert", data.severity],
    });
  }

  /**
   * Send welcome email to new user
   */
  async sendWelcomeEmail(
    to: string,
    data: {
      userName: string;
      companyName: string;
      loginUrl: string;
    }
  ): Promise<EmailResult> {
    return this.send({
      to,
      subject: `Welcome to ${data.companyName}`,
      templateId: EMAIL_TEMPLATES.WELCOME,
      templateData: data,
      categories: ["onboarding", "welcome"],
    });
  }

  /**
   * Send password reset email
   */
  async sendPasswordReset(
    to: string,
    data: {
      userName: string;
      resetUrl: string;
      expiresIn: string;
    }
  ): Promise<EmailResult> {
    return this.send({
      to,
      subject: "Password Reset Request",
      templateId: EMAIL_TEMPLATES.PASSWORD_RESET,
      templateData: data,
      categories: ["account", "password-reset"],
    });
  }
}

// Export singleton instance
export const emailService = new EmailService();

// Export class for testing
export { EmailService };
