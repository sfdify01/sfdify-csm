/**
 * Email Service
 *
 * Handles email notifications using SendGrid.
 * Provides template-based email sending for various notification types.
 */
export interface EmailOptions {
    to: string | string[];
    subject: string;
    templateId?: string;
    templateData?: Record<string, unknown>;
    text?: string;
    html?: string;
    from?: {
        email: string;
        name: string;
    };
    replyTo?: string;
    attachments?: Array<{
        content: string;
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
export declare const EMAIL_TEMPLATES: {
    readonly SLA_REMINDER_5_DAYS: "d-sla-reminder-5-days";
    readonly SLA_REMINDER_3_DAYS: "d-sla-reminder-3-days";
    readonly SLA_REMINDER_1_DAY: "d-sla-reminder-1-day";
    readonly SLA_OVERDUE: "d-sla-overdue";
    readonly LETTER_GENERATED: "d-letter-generated";
    readonly LETTER_SENT: "d-letter-sent";
    readonly LETTER_DELIVERED: "d-letter-delivered";
    readonly LETTER_RETURNED: "d-letter-returned";
    readonly DISPUTE_CREATED: "d-dispute-created";
    readonly DISPUTE_APPROVED: "d-dispute-approved";
    readonly DISPUTE_REJECTED: "d-dispute-rejected";
    readonly DISPUTE_RESOLVED: "d-dispute-resolved";
    readonly WELCOME: "d-welcome";
    readonly PASSWORD_RESET: "d-password-reset";
    readonly ACCOUNT_LOCKED: "d-account-locked";
    readonly CREDIT_REPORT_READY: "d-credit-report-ready";
    readonly CREDIT_ALERT: "d-credit-alert";
    readonly INVOICE_READY: "d-invoice-ready";
    readonly PAYMENT_RECEIVED: "d-payment-received";
    readonly PAYMENT_FAILED: "d-payment-failed";
};
export type EmailTemplate = typeof EMAIL_TEMPLATES[keyof typeof EMAIL_TEMPLATES];
declare class EmailService {
    private initialized;
    constructor();
    /**
     * Initialize SendGrid with API key
     */
    private initialize;
    /**
     * Check if service is configured
     */
    isConfigured(): boolean;
    /**
     * Send a single email
     */
    send(options: EmailOptions): Promise<EmailResult>;
    /**
     * Send bulk emails
     */
    sendBulk(emails: EmailOptions[]): Promise<BulkEmailResult>;
    /**
     * Mock send for development/testing
     */
    private mockSend;
    /**
     * Send SLA reminder email
     */
    sendSlaReminder(to: string, data: {
        consumerName: string;
        disputeId: string;
        bureau: string;
        daysRemaining: number;
        dueDate: string;
        disputeUrl: string;
    }): Promise<EmailResult>;
    /**
     * Send letter status notification
     */
    sendLetterNotification(to: string, type: "sent" | "delivered" | "returned", data: {
        consumerName: string;
        letterId: string;
        bureau: string;
        trackingNumber?: string;
        letterUrl?: string;
        returnReason?: string;
    }): Promise<EmailResult>;
    /**
     * Send dispute status update
     */
    sendDisputeStatusUpdate(to: string, data: {
        consumerName: string;
        disputeId: string;
        bureau: string;
        oldStatus: string;
        newStatus: string;
        disputeUrl: string;
        outcome?: string;
        outcomeDetails?: string;
    }): Promise<EmailResult>;
    /**
     * Send credit alert notification
     */
    sendCreditAlert(to: string, data: {
        consumerName: string;
        alertType: string;
        alertTitle: string;
        alertDescription: string;
        bureau: string;
        severity: "info" | "warning" | "critical";
        alertUrl?: string;
    }): Promise<EmailResult>;
    /**
     * Send welcome email to new user
     */
    sendWelcomeEmail(to: string, data: {
        userName: string;
        companyName: string;
        loginUrl: string;
    }): Promise<EmailResult>;
    /**
     * Send password reset email
     */
    sendPasswordReset(to: string, data: {
        userName: string;
        resetUrl: string;
        expiresIn: string;
    }): Promise<EmailResult>;
}
export declare const emailService: EmailService;
export { EmailService };
//# sourceMappingURL=emailService.d.ts.map