/**
 * SmartCredit API Service
 *
 * Handles OAuth authentication and credit report data retrieval from SmartCredit.
 * Provides methods for token exchange, report fetching, and tradeline parsing.
 *
 * @see https://www.smartcredit.com/api-documentation
 */

import axios, { AxiosInstance, AxiosError } from "axios";
import { smartCreditConfig, isEmulator } from "../config";
import { db } from "../admin";
import { encryptPii, decryptPii } from "../utils/encryption";
import * as logger from "firebase-functions/logger";
import { Timestamp } from "firebase-admin/firestore";
import {
  SmartCreditConnection,
  CreditReport,
  Tradeline,
  Bureau,
  ScoreFactor,
  Inquiry,
  ReportSummary,
  PaymentHistoryEntry,
} from "../types";

// ============================================================================
// Types
// ============================================================================

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
  scoreFactors?: Array<{ code: string; description: string }>;
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
  paymentHistory: Array<{ month: string; status: string }>;
  remarks: string[];
  disputeFlag: boolean;
  consumerStatement?: string;
}

export interface SmartCreditInquiry {
  creditorName: string;
  date: string;
  type: "H" | "S"; // Hard or Soft
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

// ============================================================================
// Error Types
// ============================================================================

export class SmartCreditApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public errorCode?: string,
    public errorDetails?: string
  ) {
    super(message);
    this.name = "SmartCreditApiError";
  }
}

// ============================================================================
// SmartCredit Client
// ============================================================================

class SmartCreditService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: smartCreditConfig.baseUrl,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      timeout: 60000, // Credit report pulls can be slow
    });

    // Add response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        return this.handleApiError(error);
      }
    );
  }

  /**
   * Handle API errors
   */
  private handleApiError(error: AxiosError): never {
    const status = error.response?.status || 500;
    const data = error.response?.data as Record<string, unknown> | undefined;

    let message = "SmartCredit API request failed";
    let errorCode: string | undefined;
    let errorDetails: string | undefined;

    if (data?.error) {
      errorCode = String(data.error_code || data.code);
      errorDetails = String(data.error_description || data.message);
      message = errorDetails || message;
    }

    logger.error("[SmartCredit Service] API Error", {
      status,
      code: errorCode,
      details: errorDetails,
      url: error.config?.url,
    });

    throw new SmartCreditApiError(message, status, errorCode, errorDetails);
  }

  /**
   * Check if service is configured
   */
  isConfigured(): boolean {
    return !!(smartCreditConfig.clientId && smartCreditConfig.clientSecret);
  }

  // ==========================================================================
  // OAuth Authentication
  // ==========================================================================

  /**
   * Exchange authorization code for tokens
   *
   * @param code - Authorization code from OAuth callback
   * @param redirectUri - Redirect URI used in the OAuth flow
   * @returns Token response
   */
  async exchangeAuthCode(
    code: string,
    redirectUri: string
  ): Promise<SmartCreditTokenResponse> {
    if (!this.isConfigured()) {
      logger.warn("[SmartCredit Service] Not configured, returning mock tokens");
      return this.mockTokenResponse();
    }

    const response = await this.client.post<SmartCreditTokenResponse>(
      "/oauth/token",
      {
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
        client_id: smartCreditConfig.clientId,
        client_secret: smartCreditConfig.clientSecret,
      }
    );

    logger.info("[SmartCredit Service] Token exchange successful");
    return response.data;
  }

  /**
   * Refresh access token
   *
   * @param refreshToken - Refresh token (encrypted)
   * @returns New token response
   */
  async refreshToken(refreshToken: string): Promise<SmartCreditTokenResponse> {
    if (!this.isConfigured()) {
      return this.mockTokenResponse();
    }

    // Decrypt refresh token
    const decryptedToken = await decryptPii(refreshToken);

    const response = await this.client.post<SmartCreditTokenResponse>(
      "/oauth/token",
      {
        grant_type: "refresh_token",
        refresh_token: decryptedToken,
        client_id: smartCreditConfig.clientId,
        client_secret: smartCreditConfig.clientSecret,
      }
    );

    logger.info("[SmartCredit Service] Token refresh successful");
    return response.data;
  }

  /**
   * Generate OAuth authorization URL
   *
   * @param redirectUri - Callback URL
   * @param state - State parameter for CSRF protection
   * @param scopes - Requested scopes
   * @returns Authorization URL
   */
  getAuthorizationUrl(
    redirectUri: string,
    state: string,
    scopes: string[] = ["credit_report", "credit_score", "alerts"]
  ): string {
    const params = new URLSearchParams({
      response_type: "code",
      client_id: smartCreditConfig.clientId,
      redirect_uri: redirectUri,
      scope: scopes.join(" "),
      state,
    });

    return `${smartCreditConfig.baseUrl}/oauth/authorize?${params.toString()}`;
  }

  /**
   * Mock token response for development
   */
  private mockTokenResponse(): SmartCreditTokenResponse {
    return {
      access_token: `mock_access_${Date.now()}`,
      refresh_token: `mock_refresh_${Date.now()}`,
      token_type: "Bearer",
      expires_in: 3600,
      scope: "credit_report credit_score alerts",
    };
  }

  // ==========================================================================
  // Connection Management
  // ==========================================================================

  /**
   * Store SmartCredit connection
   *
   * @param consumerId - Consumer ID
   * @param tenantId - Tenant ID
   * @param tokenResponse - OAuth token response
   * @returns Connection ID
   */
  async storeConnection(
    consumerId: string,
    tenantId: string,
    tokenResponse: SmartCreditTokenResponse
  ): Promise<string> {
    const now = Timestamp.now();
    const expiresAt = Timestamp.fromMillis(
      Date.now() + tokenResponse.expires_in * 1000
    );

    // Encrypt tokens before storing
    const encryptedAccess = await encryptPii(tokenResponse.access_token);
    const encryptedRefresh = await encryptPii(tokenResponse.refresh_token);

    const connectionId = `sc_${consumerId}`;
    const connection: Omit<SmartCreditConnection, "id"> = {
      consumerId,
      tenantId,
      accessToken: encryptedAccess,
      refreshToken: encryptedRefresh,
      tokenExpiresAt: expiresAt,
      scopes: tokenResponse.scope.split(" "),
      connectedAt: now,
      lastRefreshedAt: now,
      status: "connected",
    };

    await db
      .collection("smartCreditConnections")
      .doc(connectionId)
      .set({ id: connectionId, ...connection });

    // Update consumer with connection ID
    await db.collection("consumers").doc(consumerId).update({
      smartCreditConnectionId: connectionId,
    });

    logger.info("[SmartCredit Service] Connection stored", {
      consumerId,
      connectionId,
    });

    return connectionId;
  }

  /**
   * Get active connection with valid access token
   *
   * @param connectionId - Connection ID
   * @returns Connection with valid token, or null if expired
   */
  async getActiveConnection(
    connectionId: string
  ): Promise<{ connection: SmartCreditConnection; accessToken: string } | null> {
    const doc = await db
      .collection("smartCreditConnections")
      .doc(connectionId)
      .get();

    if (!doc.exists) {
      return null;
    }

    const connection = { id: doc.id, ...doc.data() } as SmartCreditConnection;

    // Check if token is expired
    const expiresAt = connection.tokenExpiresAt.toMillis();
    const bufferTime = smartCreditConfig.tokenExpiryBuffer;

    if (Date.now() + bufferTime > expiresAt) {
      // Token expired or expiring soon, refresh it
      try {
        const newTokens = await this.refreshToken(connection.refreshToken);
        await this.storeConnection(
          connection.consumerId,
          connection.tenantId,
          newTokens
        );

        return {
          connection,
          accessToken: newTokens.access_token,
        };
      } catch (error) {
        // Refresh failed, mark connection as expired
        await doc.ref.update({
          status: "expired",
          errorMessage: "Token refresh failed",
        });
        return null;
      }
    }

    // Token is valid, decrypt and return
    const accessToken = await decryptPii(connection.accessToken);
    return { connection, accessToken };
  }

  /**
   * Revoke a SmartCredit connection
   */
  async revokeConnection(connectionId: string): Promise<void> {
    const doc = await db
      .collection("smartCreditConnections")
      .doc(connectionId)
      .get();

    if (!doc.exists) {
      return;
    }

    const connection = doc.data() as SmartCreditConnection;

    // Update consumer to remove connection
    await db.collection("consumers").doc(connection.consumerId).update({
      smartCreditConnectionId: null,
    });

    // Mark connection as revoked
    await doc.ref.update({
      status: "revoked",
      revokedAt: Timestamp.now(),
    });

    logger.info("[SmartCredit Service] Connection revoked", { connectionId });
  }

  // ==========================================================================
  // Credit Report Retrieval
  // ==========================================================================

  /**
   * Fetch credit report from SmartCredit
   *
   * @param accessToken - Valid access token
   * @param bureau - Credit bureau (equifax, experian, transunion)
   * @returns Parsed credit report
   */
  async getCreditReport(
    accessToken: string,
    bureau: Bureau
  ): Promise<SmartCreditReport> {
    if (!this.isConfigured()) {
      logger.warn("[SmartCredit Service] Not configured, returning mock report");
      return this.mockCreditReport(bureau);
    }

    const bureauCode = this.bureauToCode(bureau);

    const response = await this.client.get<SmartCreditReport>(
      `/credit-report/${bureauCode}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    logger.info("[SmartCredit Service] Credit report retrieved", {
      bureau,
      tradelineCount: response.data.tradelines.length,
    });

    return response.data;
  }

  /**
   * Fetch all three bureau reports
   */
  async getAllCreditReports(
    accessToken: string
  ): Promise<Record<Bureau, SmartCreditReport>> {
    const [equifax, experian, transunion] = await Promise.all([
      this.getCreditReport(accessToken, "equifax"),
      this.getCreditReport(accessToken, "experian"),
      this.getCreditReport(accessToken, "transunion"),
    ]);

    return {
      equifax,
      experian,
      transunion,
    };
  }

  /**
   * Convert bureau name to SmartCredit code
   */
  private bureauToCode(bureau: Bureau): "EQ" | "EX" | "TU" {
    const map: Record<Bureau, "EQ" | "EX" | "TU"> = {
      equifax: "EQ",
      experian: "EX",
      transunion: "TU",
    };
    return map[bureau];
  }

  /**
   * Convert SmartCredit bureau code to bureau name
   */
  codeToBureau(code: "EQ" | "EX" | "TU"): Bureau {
    const map: Record<"EQ" | "EX" | "TU", Bureau> = {
      EQ: "equifax",
      EX: "experian",
      TU: "transunion",
    };
    return map[code];
  }

  /**
   * Mock credit report for development
   */
  private mockCreditReport(bureau: Bureau): SmartCreditReport {
    return {
      id: `report_${bureau}_${Date.now()}`,
      bureau: this.bureauToCode(bureau),
      pullDate: new Date().toISOString(),
      score: 720 + Math.floor(Math.random() * 50),
      scoreModel: "FICO Score 8",
      scoreFactors: [
        { code: "01", description: "Too many accounts with balances" },
        { code: "05", description: "Too many recent inquiries" },
      ],
      tradelines: [
        {
          id: `tl_${Date.now()}_1`,
          accountNumber: "****1234",
          creditorName: "Example Bank",
          accountType: "Credit Card",
          ownershipType: "I",
          dateOpened: "2020-01-15",
          balance: 2500,
          creditLimit: 10000,
          highBalance: 5000,
          pastDueAmount: 0,
          paymentStatus: "Current",
          accountStatus: "Open",
          paymentHistory: [
            { month: "2024-01", status: "OK" },
            { month: "2023-12", status: "OK" },
          ],
          remarks: [],
          disputeFlag: false,
        },
        {
          id: `tl_${Date.now()}_2`,
          accountNumber: "****5678",
          creditorName: "Auto Finance Co",
          accountType: "Auto Loan",
          ownershipType: "I",
          dateOpened: "2022-06-01",
          balance: 15000,
          highBalance: 25000,
          pastDueAmount: 0,
          monthlyPayment: 450,
          paymentStatus: "Current",
          accountStatus: "Open",
          paymentHistory: [
            { month: "2024-01", status: "OK" },
            { month: "2023-12", status: "OK" },
          ],
          remarks: [],
          disputeFlag: false,
        },
      ],
      inquiries: [
        {
          creditorName: "Credit Card Issuer",
          date: "2024-01-10",
          type: "H",
        },
      ],
      publicRecords: [],
      summary: {
        totalAccounts: 2,
        openAccounts: 2,
        closedAccounts: 0,
        delinquentCount: 0,
        derogatoryCount: 0,
        totalBalance: 17500,
        totalCreditLimit: 10000,
        utilizationPercent: 25,
      },
    };
  }

  // ==========================================================================
  // Tradeline Parsing
  // ==========================================================================

  /**
   * Convert SmartCredit tradeline to internal format
   */
  convertTradeline(
    scTradeline: SmartCreditTradeline,
    reportId: string,
    consumerId: string,
    tenantId: string,
    bureau: Bureau
  ): Omit<Tradeline, "createdAt" | "updatedAt"> {
    const ownershipMap: Record<string, Tradeline["ownershipType"]> = {
      I: "individual",
      J: "joint",
      A: "authorized_user",
      U: "individual",
    };

    const statusMap: Record<string, Tradeline["accountStatus"]> = {
      Open: "open",
      Closed: "closed",
      "Paid Closed": "paid",
      Collection: "collection",
      "Charge Off": "charge_off",
    };

    const paymentHistory: PaymentHistoryEntry[] = scTradeline.paymentHistory.map(
      (entry) => ({
        month: entry.month,
        status: this.mapPaymentStatus(entry.status),
      })
    );

    return {
      id: `tl_${consumerId}_${bureau}_${Date.now()}_${Math.random().toString(36).substring(7)}`,
      reportId,
      consumerId,
      tenantId,
      bureau,
      creditorName: scTradeline.creditorName,
      originalCreditor: scTradeline.originalCreditor,
      accountNumberMasked: scTradeline.accountNumber,
      accountType: scTradeline.accountType,
      accountTypeDetail: scTradeline.accountTypeDetail,
      ownershipType: ownershipMap[scTradeline.ownershipType] || "individual",
      openedDate: scTradeline.dateOpened,
      closedDate: scTradeline.dateClosed,
      lastActivityDate: scTradeline.lastActivityDate,
      lastReportedDate: scTradeline.lastReportedDate,
      balance: scTradeline.balance,
      creditLimit: scTradeline.creditLimit,
      highBalance: scTradeline.highBalance,
      pastDueAmount: scTradeline.pastDueAmount,
      monthlyPayment: scTradeline.monthlyPayment,
      paymentStatus: scTradeline.paymentStatus,
      paymentStatusDetail: scTradeline.paymentStatusDetail,
      accountStatus: statusMap[scTradeline.accountStatus] || "open",
      paymentHistory,
      remarks: scTradeline.remarks || [],
      disputeStatus: scTradeline.disputeFlag ? "in_dispute" : "none",
      disputeFlag: scTradeline.disputeFlag,
      consumerStatement: scTradeline.consumerStatement,
      smartCreditTradelineId: scTradeline.id,
    };
  }

  /**
   * Map SmartCredit payment status to internal format
   */
  private mapPaymentStatus(status: string): PaymentHistoryEntry["status"] {
    const statusMap: Record<string, PaymentHistoryEntry["status"]> = {
      OK: "current",
      CUR: "current",
      "30": "30_days_late",
      "60": "60_days_late",
      "90": "90_days_late",
      "120": "120_days_late",
      CO: "charge_off",
    };
    return statusMap[status] || "unknown";
  }

  // ==========================================================================
  // Alerts
  // ==========================================================================

  /**
   * Fetch recent alerts for a consumer
   */
  async getAlerts(
    accessToken: string,
    since?: Date
  ): Promise<SmartCreditAlert[]> {
    if (!this.isConfigured()) {
      return [];
    }

    const params = new URLSearchParams();
    if (since) {
      params.set("since", since.toISOString());
    }

    const response = await this.client.get<{ alerts: SmartCreditAlert[] }>(
      `/alerts?${params.toString()}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    return response.data.alerts;
  }

  // ==========================================================================
  // Webhook Processing
  // ==========================================================================

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(payload: string, signature: string): boolean {
    if (!smartCreditConfig.webhookSecret) {
      logger.warn(
        "[SmartCredit Service] Webhook secret not configured, skipping verification"
      );
      return true;
    }

    const crypto = require("crypto");
    const expectedSignature = crypto
      .createHmac("sha256", smartCreditConfig.webhookSecret)
      .update(payload)
      .digest("hex");

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  }

  /**
   * Parse SmartCredit webhook event type
   */
  parseWebhookEventType(eventType: string): {
    category: "alert" | "report" | "connection";
    action: string;
  } {
    const parts = eventType.split(".");
    return {
      category: parts[0] as "alert" | "report" | "connection",
      action: parts.slice(1).join("."),
    };
  }
}

// Export singleton instance
export const smartCreditService = new SmartCreditService();

// Export class for testing
export { SmartCreditService };
