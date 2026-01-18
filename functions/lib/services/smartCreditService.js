"use strict";
/**
 * SmartCredit API Service
 *
 * Handles OAuth authentication and credit report data retrieval from SmartCredit.
 * Provides methods for token exchange, report fetching, and tradeline parsing.
 *
 * @see https://www.smartcredit.com/api-documentation
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
exports.SmartCreditService = exports.smartCreditService = exports.SmartCreditApiError = void 0;
const axios_1 = __importDefault(require("axios"));
const config_1 = require("../config");
const admin_1 = require("../admin");
const encryption_1 = require("../utils/encryption");
const logger = __importStar(require("firebase-functions/logger"));
const firestore_1 = require("firebase-admin/firestore");
// ============================================================================
// Error Types
// ============================================================================
class SmartCreditApiError extends Error {
    statusCode;
    errorCode;
    errorDetails;
    constructor(message, statusCode, errorCode, errorDetails) {
        super(message);
        this.statusCode = statusCode;
        this.errorCode = errorCode;
        this.errorDetails = errorDetails;
        this.name = "SmartCreditApiError";
    }
}
exports.SmartCreditApiError = SmartCreditApiError;
// ============================================================================
// SmartCredit Client
// ============================================================================
class SmartCreditService {
    client;
    constructor() {
        this.client = axios_1.default.create({
            baseURL: config_1.smartCreditConfig.baseUrl,
            headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
            },
            timeout: 60000, // Credit report pulls can be slow
        });
        // Add response interceptor for error handling
        this.client.interceptors.response.use((response) => response, (error) => {
            return this.handleApiError(error);
        });
    }
    /**
     * Handle API errors
     */
    handleApiError(error) {
        const status = error.response?.status || 500;
        const data = error.response?.data;
        let message = "SmartCredit API request failed";
        let errorCode;
        let errorDetails;
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
    isConfigured() {
        return !!(config_1.smartCreditConfig.clientId && config_1.smartCreditConfig.clientSecret);
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
    async exchangeAuthCode(code, redirectUri) {
        if (!this.isConfigured()) {
            logger.warn("[SmartCredit Service] Not configured, returning mock tokens");
            return this.mockTokenResponse();
        }
        const response = await this.client.post("/oauth/token", {
            grant_type: "authorization_code",
            code,
            redirect_uri: redirectUri,
            client_id: config_1.smartCreditConfig.clientId,
            client_secret: config_1.smartCreditConfig.clientSecret,
        });
        logger.info("[SmartCredit Service] Token exchange successful");
        return response.data;
    }
    /**
     * Refresh access token
     *
     * @param refreshToken - Refresh token (encrypted)
     * @returns New token response
     */
    async refreshToken(refreshToken) {
        if (!this.isConfigured()) {
            return this.mockTokenResponse();
        }
        // Decrypt refresh token
        const decryptedToken = await (0, encryption_1.decryptPii)(refreshToken);
        const response = await this.client.post("/oauth/token", {
            grant_type: "refresh_token",
            refresh_token: decryptedToken,
            client_id: config_1.smartCreditConfig.clientId,
            client_secret: config_1.smartCreditConfig.clientSecret,
        });
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
    getAuthorizationUrl(redirectUri, state, scopes = ["credit_report", "credit_score", "alerts"]) {
        const params = new URLSearchParams({
            response_type: "code",
            client_id: config_1.smartCreditConfig.clientId,
            redirect_uri: redirectUri,
            scope: scopes.join(" "),
            state,
        });
        return `${config_1.smartCreditConfig.baseUrl}/oauth/authorize?${params.toString()}`;
    }
    /**
     * Mock token response for development
     */
    mockTokenResponse() {
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
    async storeConnection(consumerId, tenantId, tokenResponse) {
        const now = firestore_1.Timestamp.now();
        const expiresAt = firestore_1.Timestamp.fromMillis(Date.now() + tokenResponse.expires_in * 1000);
        // Encrypt tokens before storing
        const encryptedAccess = await (0, encryption_1.encryptPii)(tokenResponse.access_token);
        const encryptedRefresh = await (0, encryption_1.encryptPii)(tokenResponse.refresh_token);
        const connectionId = `sc_${consumerId}`;
        const connection = {
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
        await admin_1.db
            .collection("smartCreditConnections")
            .doc(connectionId)
            .set({ id: connectionId, ...connection });
        // Update consumer with connection ID
        await admin_1.db.collection("consumers").doc(consumerId).update({
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
    async getActiveConnection(connectionId) {
        const doc = await admin_1.db
            .collection("smartCreditConnections")
            .doc(connectionId)
            .get();
        if (!doc.exists) {
            return null;
        }
        const connection = { id: doc.id, ...doc.data() };
        // Check if token is expired
        const expiresAt = connection.tokenExpiresAt.toMillis();
        const bufferTime = config_1.smartCreditConfig.tokenExpiryBuffer;
        if (Date.now() + bufferTime > expiresAt) {
            // Token expired or expiring soon, refresh it
            try {
                const newTokens = await this.refreshToken(connection.refreshToken);
                await this.storeConnection(connection.consumerId, connection.tenantId, newTokens);
                return {
                    connection,
                    accessToken: newTokens.access_token,
                };
            }
            catch (error) {
                // Refresh failed, mark connection as expired
                await doc.ref.update({
                    status: "expired",
                    errorMessage: "Token refresh failed",
                });
                return null;
            }
        }
        // Token is valid, decrypt and return
        const accessToken = await (0, encryption_1.decryptPii)(connection.accessToken);
        return { connection, accessToken };
    }
    /**
     * Revoke a SmartCredit connection
     */
    async revokeConnection(connectionId) {
        const doc = await admin_1.db
            .collection("smartCreditConnections")
            .doc(connectionId)
            .get();
        if (!doc.exists) {
            return;
        }
        const connection = doc.data();
        // Update consumer to remove connection
        await admin_1.db.collection("consumers").doc(connection.consumerId).update({
            smartCreditConnectionId: null,
        });
        // Mark connection as revoked
        await doc.ref.update({
            status: "revoked",
            revokedAt: firestore_1.Timestamp.now(),
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
    async getCreditReport(accessToken, bureau) {
        if (!this.isConfigured()) {
            logger.warn("[SmartCredit Service] Not configured, returning mock report");
            return this.mockCreditReport(bureau);
        }
        const bureauCode = this.bureauToCode(bureau);
        const response = await this.client.get(`/credit-report/${bureauCode}`, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
        });
        logger.info("[SmartCredit Service] Credit report retrieved", {
            bureau,
            tradelineCount: response.data.tradelines.length,
        });
        return response.data;
    }
    /**
     * Fetch all three bureau reports
     */
    async getAllCreditReports(accessToken) {
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
    bureauToCode(bureau) {
        const map = {
            equifax: "EQ",
            experian: "EX",
            transunion: "TU",
        };
        return map[bureau];
    }
    /**
     * Convert SmartCredit bureau code to bureau name
     */
    codeToBureau(code) {
        const map = {
            EQ: "equifax",
            EX: "experian",
            TU: "transunion",
        };
        return map[code];
    }
    /**
     * Mock credit report for development
     */
    mockCreditReport(bureau) {
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
    convertTradeline(scTradeline, reportId, consumerId, tenantId, bureau) {
        const ownershipMap = {
            I: "individual",
            J: "joint",
            A: "authorized_user",
            U: "individual",
        };
        const statusMap = {
            Open: "open",
            Closed: "closed",
            "Paid Closed": "paid",
            Collection: "collection",
            "Charge Off": "charge_off",
        };
        const paymentHistory = scTradeline.paymentHistory.map((entry) => ({
            month: entry.month,
            status: this.mapPaymentStatus(entry.status),
        }));
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
    mapPaymentStatus(status) {
        const statusMap = {
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
    async getAlerts(accessToken, since) {
        if (!this.isConfigured()) {
            return [];
        }
        const params = new URLSearchParams();
        if (since) {
            params.set("since", since.toISOString());
        }
        const response = await this.client.get(`/alerts?${params.toString()}`, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
        });
        return response.data.alerts;
    }
    // ==========================================================================
    // Webhook Processing
    // ==========================================================================
    /**
     * Verify webhook signature
     */
    verifyWebhookSignature(payload, signature) {
        if (!config_1.smartCreditConfig.webhookSecret) {
            logger.warn("[SmartCredit Service] Webhook secret not configured, skipping verification");
            return true;
        }
        const crypto = require("crypto");
        const expectedSignature = crypto
            .createHmac("sha256", config_1.smartCreditConfig.webhookSecret)
            .update(payload)
            .digest("hex");
        return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
    }
    /**
     * Parse SmartCredit webhook event type
     */
    parseWebhookEventType(eventType) {
        const parts = eventType.split(".");
        return {
            category: parts[0],
            action: parts.slice(1).join("."),
        };
    }
}
exports.SmartCreditService = SmartCreditService;
// Export singleton instance
exports.smartCreditService = new SmartCreditService();
//# sourceMappingURL=smartCreditService.js.map