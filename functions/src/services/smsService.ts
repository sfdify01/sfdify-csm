/**
 * SMS Service
 *
 * Handles SMS notifications using Twilio.
 * Provides SMS sending for alerts and notifications.
 */

import twilio from "twilio";
import { twilioConfig } from "../config";
import * as logger from "firebase-functions/logger";

// ============================================================================
// Types
// ============================================================================

export interface SmsOptions {
  to: string;
  body: string;
  from?: string;
  mediaUrl?: string[];
  statusCallback?: string;
}

export interface SmsResult {
  success: boolean;
  messageId?: string;
  status?: string;
  error?: string;
}

export interface BulkSmsResult {
  total: number;
  successful: number;
  failed: number;
  results: SmsResult[];
}

// SMS message templates
export const SMS_TEMPLATES = {
  SLA_REMINDER: (daysRemaining: number, bureau: string) =>
    `SFDIFY Alert: Your ${bureau} dispute has ${daysRemaining} day(s) until SLA deadline. Login to take action.`,

  LETTER_SENT: (bureau: string) =>
    `SFDIFY: Your dispute letter to ${bureau} has been sent! You'll receive tracking info soon.`,

  LETTER_DELIVERED: (bureau: string) =>
    `SFDIFY: Great news! Your dispute letter to ${bureau} was delivered successfully.`,

  LETTER_RETURNED: (bureau: string) =>
    `SFDIFY Alert: Your letter to ${bureau} was returned. Please login to review and resend.`,

  DISPUTE_RESOLVED: (bureau: string, outcome: string) =>
    `SFDIFY: Your ${bureau} dispute has been resolved with outcome: ${outcome}. Login for details.`,

  CREDIT_ALERT: (alertType: string) =>
    `SFDIFY Credit Alert: ${alertType}. Login to your account for more details.`,

  VERIFICATION_CODE: (code: string) =>
    `Your SFDIFY verification code is: ${code}. This code expires in 10 minutes.`,

  PASSWORD_RESET: () =>
    `SFDIFY: A password reset was requested for your account. If this wasn't you, please contact support.`,
} as const;

// ============================================================================
// SMS Service Class
// ============================================================================

class SmsService {
  private client: twilio.Twilio | null = null;
  private fromNumber: string;

  constructor() {
    this.fromNumber = twilioConfig.fromNumber;
    this.initialize();
  }

  /**
   * Initialize Twilio client
   */
  private initialize(): void {
    if (twilioConfig.accountSid && twilioConfig.authToken) {
      this.client = twilio(twilioConfig.accountSid, twilioConfig.authToken);
    } else {
      logger.warn("[SMS Service] Twilio credentials not configured");
    }
  }

  /**
   * Check if service is configured
   */
  isConfigured(): boolean {
    return this.client !== null && !!this.fromNumber;
  }

  /**
   * Normalize phone number to E.164 format
   */
  private normalizePhoneNumber(phone: string): string {
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
  async send(options: SmsOptions): Promise<SmsResult> {
    if (!this.isConfigured()) {
      logger.warn("[SMS Service] Not configured, skipping SMS send");
      return this.mockSend(options);
    }

    try {
      const normalizedTo = this.normalizePhoneNumber(options.to);

      const message = await this.client!.messages.create({
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
    } catch (error) {
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
  async sendBulk(messages: SmsOptions[]): Promise<BulkSmsResult> {
    // Twilio has rate limits, so we process in batches with delay
    const batchSize = 10;
    const delayMs = 1000;
    const results: SmsResult[] = [];

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
  private mockSend(options: SmsOptions): SmsResult {
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
  async sendSlaReminder(
    to: string,
    daysRemaining: number,
    bureau: string
  ): Promise<SmsResult> {
    return this.send({
      to,
      body: SMS_TEMPLATES.SLA_REMINDER(daysRemaining, bureau),
    });
  }

  /**
   * Send letter status SMS
   */
  async sendLetterStatus(
    to: string,
    status: "sent" | "delivered" | "returned",
    bureau: string
  ): Promise<SmsResult> {
    const templates = {
      sent: SMS_TEMPLATES.LETTER_SENT,
      delivered: SMS_TEMPLATES.LETTER_DELIVERED,
      returned: SMS_TEMPLATES.LETTER_RETURNED,
    };

    return this.send({
      to,
      body: templates[status](bureau),
    });
  }

  /**
   * Send dispute resolved SMS
   */
  async sendDisputeResolved(
    to: string,
    bureau: string,
    outcome: string
  ): Promise<SmsResult> {
    return this.send({
      to,
      body: SMS_TEMPLATES.DISPUTE_RESOLVED(bureau, outcome),
    });
  }

  /**
   * Send credit alert SMS
   */
  async sendCreditAlert(to: string, alertType: string): Promise<SmsResult> {
    return this.send({
      to,
      body: SMS_TEMPLATES.CREDIT_ALERT(alertType),
    });
  }

  /**
   * Send verification code SMS
   */
  async sendVerificationCode(to: string, code: string): Promise<SmsResult> {
    return this.send({
      to,
      body: SMS_TEMPLATES.VERIFICATION_CODE(code),
    });
  }

  /**
   * Send password reset notification SMS
   */
  async sendPasswordResetNotification(to: string): Promise<SmsResult> {
    return this.send({
      to,
      body: SMS_TEMPLATES.PASSWORD_RESET(),
    });
  }

  // ==========================================================================
  // Message Status
  // ==========================================================================

  /**
   * Get message status by SID
   */
  async getMessageStatus(messageSid: string): Promise<{
    status: string;
    errorCode?: number;
    errorMessage?: string;
  } | null> {
    if (!this.isConfigured()) {
      return null;
    }

    try {
      const message = await this.client!.messages(messageSid).fetch();

      return {
        status: message.status,
        errorCode: message.errorCode || undefined,
        errorMessage: message.errorMessage || undefined,
      };
    } catch (error) {
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
  async validatePhoneNumber(phone: string): Promise<{
    valid: boolean;
    carrier?: string;
    type?: string;
    error?: string;
  }> {
    if (!this.isConfigured()) {
      return { valid: true }; // Assume valid in dev mode
    }

    try {
      const normalizedPhone = this.normalizePhoneNumber(phone);
      const lookup = await this.client!.lookups.v2.phoneNumbers(normalizedPhone).fetch({
        fields: "line_type_intelligence",
      });

      return {
        valid: lookup.valid,
        carrier: lookup.callerName?.caller_name,
        type: lookup.lineTypeIntelligence?.type,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      return {
        valid: false,
        error: errorMessage,
      };
    }
  }
}

// Export singleton instance
export const smsService = new SmsService();

// Export class for testing
export { SmsService };
