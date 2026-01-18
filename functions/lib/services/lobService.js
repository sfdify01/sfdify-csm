"use strict";
/**
 * Lob API Service
 *
 * Handles all interactions with the Lob print-and-mail API.
 * Provides address verification, letter creation, status tracking, and webhook processing.
 *
 * @see https://docs.lob.com/
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
exports.LobService = exports.lobService = exports.LobApiError = void 0;
const axios_1 = __importDefault(require("axios"));
const config_1 = require("../config");
const logger = __importStar(require("firebase-functions/logger"));
// ============================================================================
// Error Types
// ============================================================================
class LobApiError extends Error {
    statusCode;
    lobErrorCode;
    lobErrorMessage;
    constructor(message, statusCode, lobErrorCode, lobErrorMessage) {
        super(message);
        this.statusCode = statusCode;
        this.lobErrorCode = lobErrorCode;
        this.lobErrorMessage = lobErrorMessage;
        this.name = "LobApiError";
    }
}
exports.LobApiError = LobApiError;
// ============================================================================
// Lob Client
// ============================================================================
class LobService {
    client;
    testMode;
    constructor() {
        this.testMode = !config_1.lobConfig.apiKey.startsWith("live_");
        this.client = axios_1.default.create({
            baseURL: config_1.lobConfig.baseUrl,
            auth: {
                username: config_1.lobConfig.apiKey,
                password: "", // Lob uses API key as username with empty password
            },
            headers: {
                "Content-Type": "application/json",
                "Lob-Version": "2024-01-01",
            },
            timeout: 30000,
        });
        // Add response interceptor for error handling
        this.client.interceptors.response.use((response) => response, (error) => {
            return this.handleApiError(error);
        });
    }
    /**
     * Handle API errors and convert to LobApiError
     */
    handleApiError(error) {
        const status = error.response?.status || 500;
        const data = error.response?.data;
        let message = "Lob API request failed";
        let lobErrorCode;
        let lobErrorMessage;
        if (data?.error) {
            const lobError = data.error;
            lobErrorCode = lobError.code;
            lobErrorMessage = lobError.message;
            message = lobErrorMessage || message;
        }
        logger.error("[Lob Service] API Error", {
            status,
            code: lobErrorCode,
            message: lobErrorMessage,
            url: error.config?.url,
        });
        throw new LobApiError(message, status, lobErrorCode, lobErrorMessage);
    }
    /**
     * Check if service is configured
     */
    isConfigured() {
        return !!config_1.lobConfig.apiKey && config_1.lobConfig.apiKey.length > 0;
    }
    /**
     * Check if in test mode
     */
    isTestMode() {
        return this.testMode;
    }
    // ==========================================================================
    // Address Verification
    // ==========================================================================
    /**
     * Verify a US address with Lob
     *
     * @param address - Address to verify
     * @returns Verification result with deliverability status
     */
    async verifyAddress(address) {
        if (!this.isConfigured()) {
            logger.warn("[Lob Service] API not configured, returning mock verification");
            return this.mockAddressVerification(address);
        }
        const response = await this.client.post("/us_verifications", {
            primary_line: address.addressLine1,
            secondary_line: address.addressLine2 || "",
            city: address.city,
            state: address.state,
            zip_code: address.zipCode,
        });
        logger.info("[Lob Service] Address verified", {
            deliverability: response.data.deliverability,
            city: response.data.components.city,
            state: response.data.components.state,
        });
        return response.data;
    }
    /**
     * Mock address verification for development/testing
     */
    mockAddressVerification(address) {
        return {
            id: `us_ver_${Date.now()}`,
            recipient: address.name,
            primary_line: address.addressLine1,
            secondary_line: address.addressLine2,
            last_line: `${address.city}, ${address.state} ${address.zipCode}`,
            deliverability: "deliverable",
            components: {
                primary_number: "",
                street_predirection: "",
                street_name: "",
                street_suffix: "",
                street_postdirection: "",
                secondary_designator: "",
                secondary_number: "",
                pmb_designator: "",
                pmb_number: "",
                extra_secondary_designator: "",
                extra_secondary_number: "",
                city: address.city,
                state: address.state,
                zip_code: address.zipCode.substring(0, 5),
                zip_code_plus_4: address.zipCode.length > 5 ? address.zipCode.substring(6) : "",
                zip_code_type: "standard",
                delivery_point_barcode: "",
                address_type: "residential",
                record_type: "street",
                default_building_address: false,
                county: "",
                county_fips: "",
                carrier_route: "",
                carrier_route_type: "",
                latitude: 0,
                longitude: 0,
            },
            object: "us_verification",
        };
    }
    // ==========================================================================
    // Letter Operations
    // ==========================================================================
    /**
     * Create and send a letter via Lob
     *
     * @param options - Letter creation options
     * @returns Created letter object
     */
    async createLetter(options) {
        if (!this.isConfigured()) {
            logger.warn("[Lob Service] API not configured, returning mock letter");
            return this.mockLetter(options);
        }
        // Convert MailType to Lob format
        const mailType = options.mailType === "usps_first_class" ? "usps_first_class" : "usps_standard";
        let extraService;
        if (options.mailType === "usps_certified") {
            extraService = "certified";
        }
        else if (options.mailType === "usps_certified_return_receipt") {
            extraService = "certified_return_receipt";
        }
        // Build request data
        const requestData = {
            description: options.description || "Credit Dispute Letter",
            to: this.convertAddress(options.to),
            from: this.convertAddress(options.from),
            mail_type: mailType,
            color: options.color ?? false,
            double_sided: options.doubleSided ?? false,
            metadata: options.metadata || {},
        };
        // Handle file - either URL or inline content
        if (typeof options.file === "string") {
            if (options.file.startsWith("http") || options.file.startsWith("https")) {
                requestData.file = options.file;
            }
            else {
                // Assume it's HTML content
                requestData.file = options.file;
            }
        }
        else {
            // Buffer - convert to base64 for Lob API
            requestData.file = options.file.toString("base64");
        }
        if (extraService) {
            requestData.extra_service = extraService;
        }
        if (options.sendDate) {
            requestData.send_date = options.sendDate;
        }
        // Set idempotency key in header if provided
        const headers = {};
        if (options.idempotencyKey) {
            headers["Idempotency-Key"] = options.idempotencyKey;
        }
        const response = await this.client.post("/letters", requestData, { headers });
        logger.info("[Lob Service] Letter created", {
            letterId: response.data.id,
            expectedDelivery: response.data.expected_delivery_date,
            carrier: response.data.carrier,
        });
        return response.data;
    }
    /**
     * Convert MailingAddress to Lob format
     */
    convertAddress(address) {
        return {
            name: address.name,
            address_line1: address.addressLine1,
            address_line2: address.addressLine2,
            address_city: address.city,
            address_state: address.state,
            address_zip: address.zipCode,
            address_country: "US",
        };
    }
    /**
     * Get letter details by Lob ID
     */
    async getLetter(lobId) {
        if (!this.isConfigured()) {
            throw new LobApiError("Lob API not configured", 500);
        }
        const response = await this.client.get(`/letters/${lobId}`);
        return response.data;
    }
    /**
     * Cancel a letter (only if not yet sent)
     */
    async cancelLetter(lobId) {
        if (!this.isConfigured()) {
            logger.warn("[Lob Service] API not configured, skipping cancel");
            return;
        }
        await this.client.delete(`/letters/${lobId}`);
        logger.info("[Lob Service] Letter cancelled", { lobId });
    }
    /**
     * List letters with optional filters
     */
    async listLetters(options = {}) {
        if (!this.isConfigured()) {
            return { data: [], total_count: 0 };
        }
        const params = new URLSearchParams();
        if (options.limit)
            params.set("limit", String(options.limit));
        if (options.afterId)
            params.set("after", options.afterId);
        if (options.beforeId)
            params.set("before", options.beforeId);
        if (options.metadata) {
            for (const [key, value] of Object.entries(options.metadata)) {
                params.set(`metadata[${key}]`, value);
            }
        }
        const response = await this.client.get(`/letters?${params.toString()}`);
        return response.data;
    }
    /**
     * Mock letter for development/testing
     */
    mockLetter(options) {
        const now = new Date();
        const expectedDelivery = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000); // 5 days
        return {
            id: `ltr_${Date.now()}_mock`,
            description: options.description || "Credit Dispute Letter",
            metadata: options.metadata || {},
            mail_type: options.mailType === "usps_first_class" ? "usps_first_class" : "usps_standard",
            expected_delivery_date: expectedDelivery.toISOString().split("T")[0],
            date_created: now.toISOString(),
            date_modified: now.toISOString(),
            send_date: now.toISOString().split("T")[0],
            to: this.convertAddress(options.to),
            from: this.convertAddress(options.from),
            color: options.color ?? false,
            double_sided: options.doubleSided ?? false,
            address_placement: "top_first_page",
            return_envelope: false,
            extra_service: options.mailType.includes("certified") ? "certified" : undefined,
            carrier: "USPS",
            tracking_number: this.testMode ? `TEST${Date.now()}` : undefined,
            tracking_events: [],
            url: "https://lob-assets.com/mock-letter.pdf",
            thumbnails: {
                small: "https://lob-assets.com/mock-thumb-small.png",
                medium: "https://lob-assets.com/mock-thumb-medium.png",
                large: "https://lob-assets.com/mock-thumb-large.png",
            },
            object: "letter",
        };
    }
    // ==========================================================================
    // Cost Estimation
    // ==========================================================================
    /**
     * Estimate cost for sending a letter
     *
     * @param pageCount - Number of pages
     * @param mailType - Type of mailing service
     * @returns Cost breakdown
     */
    estimateCost(pageCount, mailType) {
        // Lob pricing (approximate, subject to change)
        // Base letter (1-6 pages, B&W): $0.80
        // Additional pages: $0.06 each
        // Color: +$0.50 per page
        // First Class: +$0.00 (included)
        // Certified: +$3.75
        // Certified Return Receipt: +$6.65
        const basePrice = 0.80;
        const additionalPagePrice = pageCount > 6 ? (pageCount - 6) * 0.06 : 0;
        const printing = basePrice + additionalPagePrice;
        // Postage costs
        let postage = 0.55; // First class stamp rate
        let certifiedFee;
        let returnReceiptFee;
        switch (mailType) {
            case "usps_first_class":
                postage = 0.55 + Math.max(0, pageCount - 1) * 0.24; // Additional ounce rate
                break;
            case "usps_certified":
                postage = 0.55;
                certifiedFee = 3.75;
                break;
            case "usps_certified_return_receipt":
                postage = 0.55;
                certifiedFee = 3.75;
                returnReceiptFee = 2.90;
                break;
        }
        const total = printing + postage + (certifiedFee || 0) + (returnReceiptFee || 0);
        return {
            printing: Math.round(printing * 100) / 100,
            postage: Math.round(postage * 100) / 100,
            certifiedFee,
            returnReceiptFee,
            total: Math.round(total * 100) / 100,
            currency: "USD",
            mailType,
            pageCount,
        };
    }
    // ==========================================================================
    // Webhook Processing
    // ==========================================================================
    /**
     * Verify webhook signature
     *
     * @param payload - Raw webhook payload
     * @param signature - Lob signature header
     * @returns true if signature is valid
     */
    verifyWebhookSignature(payload, signature) {
        if (!config_1.lobConfig.webhookSecret) {
            logger.warn("[Lob Service] Webhook secret not configured, skipping verification");
            return true;
        }
        const crypto = require("crypto");
        const expectedSignature = crypto
            .createHmac("sha256", config_1.lobConfig.webhookSecret)
            .update(payload)
            .digest("hex");
        return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
    }
    /**
     * Parse webhook event type
     */
    parseWebhookEvent(eventType) {
        const parts = eventType.split(".");
        return {
            resource: parts[0],
            action: parts.slice(1).join("."),
        };
    }
    /**
     * Map Lob event to internal letter status
     */
    mapEventToLetterStatus(eventType) {
        const eventMap = {
            "letter.created": "queued",
            "letter.rendered_pdf": "ready",
            "letter.rendered_thumbnails": "ready",
            "letter.deleted": "cancelled",
            "letter.mailed": "sent",
            "letter.in_transit": "in_transit",
            "letter.in_local_area": "in_transit",
            "letter.processed_for_delivery": "in_transit",
            "letter.delivered": "delivered",
            "letter.re-routed": "in_transit",
            "letter.returned_to_sender": "returned_to_sender",
        };
        return eventMap[eventType] || null;
    }
}
exports.LobService = LobService;
// Export singleton instance
exports.lobService = new LobService();
//# sourceMappingURL=lobService.js.map