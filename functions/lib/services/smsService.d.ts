/**
 * SMS Service
 *
 * Handles SMS notifications using Twilio.
 * Provides SMS sending for alerts and notifications.
 */
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
export declare const SMS_TEMPLATES: {
    readonly SLA_REMINDER: (daysRemaining: number, bureau: string) => string;
    readonly LETTER_SENT: (bureau: string) => string;
    readonly LETTER_DELIVERED: (bureau: string) => string;
    readonly LETTER_RETURNED: (bureau: string) => string;
    readonly DISPUTE_RESOLVED: (bureau: string, outcome: string) => string;
    readonly CREDIT_ALERT: (alertType: string) => string;
    readonly VERIFICATION_CODE: (code: string) => string;
    readonly PASSWORD_RESET: () => string;
};
declare class SmsService {
    private client;
    private fromNumber;
    constructor();
    /**
     * Initialize Twilio client
     */
    private initialize;
    /**
     * Check if service is configured
     */
    isConfigured(): boolean;
    /**
     * Normalize phone number to E.164 format
     */
    private normalizePhoneNumber;
    /**
     * Send a single SMS
     */
    send(options: SmsOptions): Promise<SmsResult>;
    /**
     * Send bulk SMS messages
     */
    sendBulk(messages: SmsOptions[]): Promise<BulkSmsResult>;
    /**
     * Mock send for development/testing
     */
    private mockSend;
    /**
     * Send SLA reminder SMS
     */
    sendSlaReminder(to: string, daysRemaining: number, bureau: string): Promise<SmsResult>;
    /**
     * Send letter status SMS
     */
    sendLetterStatus(to: string, status: "sent" | "delivered" | "returned", bureau: string): Promise<SmsResult>;
    /**
     * Send dispute resolved SMS
     */
    sendDisputeResolved(to: string, bureau: string, outcome: string): Promise<SmsResult>;
    /**
     * Send credit alert SMS
     */
    sendCreditAlert(to: string, alertType: string): Promise<SmsResult>;
    /**
     * Send verification code SMS
     */
    sendVerificationCode(to: string, code: string): Promise<SmsResult>;
    /**
     * Send password reset notification SMS
     */
    sendPasswordResetNotification(to: string): Promise<SmsResult>;
    /**
     * Get message status by SID
     */
    getMessageStatus(messageSid: string): Promise<{
        status: string;
        errorCode?: number;
        errorMessage?: string;
    } | null>;
    /**
     * Check if phone number is valid and can receive SMS
     */
    validatePhoneNumber(phone: string): Promise<{
        valid: boolean;
        carrier?: string;
        type?: string;
        error?: string;
    }>;
}
export declare const smsService: SmsService;
export { SmsService };
//# sourceMappingURL=smsService.d.ts.map