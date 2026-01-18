/**
 * SmartCredit API Service
 *
 * Handles OAuth authentication and credit report data retrieval from SmartCredit.
 * Provides methods for token exchange, report fetching, and tradeline parsing.
 *
 * @see https://www.smartcredit.com/api-documentation
 */
import { SmartCreditConnection, Tradeline, Bureau } from "../types";
export interface SmartCreditTokenResponse {
    access_token: string;
    refresh_token: string;
    token_type: string;
    expires_in: number;
    scope: string;
}
export interface SmartCreditReport {
    id: string;
    bureau: "EQ" | "EX" | "TU";
    pullDate: string;
    score?: number;
    scoreModel?: string;
    scoreFactors?: Array<{
        code: string;
        description: string;
    }>;
    tradelines: SmartCreditTradeline[];
    inquiries: SmartCreditInquiry[];
    publicRecords: SmartCreditPublicRecord[];
    summary: {
        totalAccounts: number;
        openAccounts: number;
        closedAccounts: number;
        delinquentCount: number;
        derogatoryCount: number;
        totalBalance: number;
        totalCreditLimit: number;
        utilizationPercent: number;
    };
}
export interface SmartCreditTradeline {
    id: string;
    accountNumber: string;
    creditorName: string;
    originalCreditor?: string;
    accountType: string;
    accountTypeDetail?: string;
    ownershipType: "I" | "J" | "A" | "U";
    dateOpened?: string;
    dateClosed?: string;
    lastActivityDate?: string;
    lastReportedDate?: string;
    balance: number;
    creditLimit?: number;
    highBalance?: number;
    pastDueAmount: number;
    monthlyPayment?: number;
    paymentStatus: string;
    paymentStatusDetail?: string;
    accountStatus: string;
    paymentHistory: Array<{
        month: string;
        status: string;
    }>;
    remarks: string[];
    disputeFlag: boolean;
    consumerStatement?: string;
}
export interface SmartCreditInquiry {
    creditorName: string;
    date: string;
    type: "H" | "S";
}
export interface SmartCreditPublicRecord {
    type: string;
    status: string;
    filingDate?: string;
    amount?: number;
    court?: string;
    referenceNumber?: string;
}
export interface SmartCreditAlert {
    id: string;
    type: string;
    bureau: "EQ" | "EX" | "TU" | "ALL";
    severity: "info" | "warning" | "critical";
    title: string;
    description: string;
    timestamp: string;
    data?: Record<string, unknown>;
}
export declare class SmartCreditApiError extends Error {
    statusCode: number;
    errorCode?: string | undefined;
    errorDetails?: string | undefined;
    constructor(message: string, statusCode: number, errorCode?: string | undefined, errorDetails?: string | undefined);
}
declare class SmartCreditService {
    private client;
    constructor();
    /**
     * Handle API errors
     */
    private handleApiError;
    /**
     * Check if service is configured
     */
    isConfigured(): boolean;
    /**
     * Exchange authorization code for tokens
     *
     * @param code - Authorization code from OAuth callback
     * @param redirectUri - Redirect URI used in the OAuth flow
     * @returns Token response
     */
    exchangeAuthCode(code: string, redirectUri: string): Promise<SmartCreditTokenResponse>;
    /**
     * Refresh access token
     *
     * @param refreshToken - Refresh token (encrypted)
     * @returns New token response
     */
    refreshToken(refreshToken: string): Promise<SmartCreditTokenResponse>;
    /**
     * Generate OAuth authorization URL
     *
     * @param redirectUri - Callback URL
     * @param state - State parameter for CSRF protection
     * @param scopes - Requested scopes
     * @returns Authorization URL
     */
    getAuthorizationUrl(redirectUri: string, state: string, scopes?: string[]): string;
    /**
     * Mock token response for development
     */
    private mockTokenResponse;
    /**
     * Store SmartCredit connection
     *
     * @param consumerId - Consumer ID
     * @param tenantId - Tenant ID
     * @param tokenResponse - OAuth token response
     * @returns Connection ID
     */
    storeConnection(consumerId: string, tenantId: string, tokenResponse: SmartCreditTokenResponse): Promise<string>;
    /**
     * Get active connection with valid access token
     *
     * @param connectionId - Connection ID
     * @returns Connection with valid token, or null if expired
     */
    getActiveConnection(connectionId: string): Promise<{
        connection: SmartCreditConnection;
        accessToken: string;
    } | null>;
    /**
     * Revoke a SmartCredit connection
     */
    revokeConnection(connectionId: string): Promise<void>;
    /**
     * Fetch credit report from SmartCredit
     *
     * @param accessToken - Valid access token
     * @param bureau - Credit bureau (equifax, experian, transunion)
     * @returns Parsed credit report
     */
    getCreditReport(accessToken: string, bureau: Bureau): Promise<SmartCreditReport>;
    /**
     * Fetch all three bureau reports
     */
    getAllCreditReports(accessToken: string): Promise<Record<Bureau, SmartCreditReport>>;
    /**
     * Convert bureau name to SmartCredit code
     */
    private bureauToCode;
    /**
     * Convert SmartCredit bureau code to bureau name
     */
    codeToBureau(code: "EQ" | "EX" | "TU"): Bureau;
    /**
     * Mock credit report for development
     */
    private mockCreditReport;
    /**
     * Convert SmartCredit tradeline to internal format
     */
    convertTradeline(scTradeline: SmartCreditTradeline, reportId: string, consumerId: string, tenantId: string, bureau: Bureau): Omit<Tradeline, "createdAt" | "updatedAt">;
    /**
     * Map SmartCredit payment status to internal format
     */
    private mapPaymentStatus;
    /**
     * Fetch recent alerts for a consumer
     */
    getAlerts(accessToken: string, since?: Date): Promise<SmartCreditAlert[]>;
    /**
     * Verify webhook signature
     */
    verifyWebhookSignature(payload: string, signature: string): boolean;
    /**
     * Parse SmartCredit webhook event type
     */
    parseWebhookEventType(eventType: string): {
        category: "alert" | "report" | "connection";
        action: string;
    };
}
export declare const smartCreditService: SmartCreditService;
export { SmartCreditService };
//# sourceMappingURL=smartCreditService.d.ts.map