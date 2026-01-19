"use strict";
/**
 * Lob API Service
 *
 * Handles all interactions with the Lob print-and-mail API.
 * Provides address verification, letter creation, status tracking, and webhook processing.
 *
 * Uses the official Lob TypeScript SDK with retry logic and rate limiting.
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
const lob_typescript_sdk_1 = require("@lob/lob-typescript-sdk");
const bottleneck_1 = __importDefault(require("bottleneck"));
const p_retry_1 = __importStar(require("p-retry"));
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
    /**
     * Check if this error is retryable
     */
    isRetryable() {
        // Retry on server errors or rate limiting
        return this.statusCode >= 500 || this.statusCode === 429;
    }
}
exports.LobApiError = LobApiError;
// ============================================================================
// Lob Client
// ============================================================================
class LobService {
    lettersApi = null;
    verificationsApi = null;
    testMode;
    limiter;
    constructor() {
        this.testMode = !config_1.lobConfig.apiKey || !config_1.lobConfig.apiKey.startsWith("live_");
        // Initialize rate limiter
        // Lob allows 150 requests per minute
        this.limiter = new bottleneck_1.default({
            maxConcurrent: 10,
            minTime: 400, // 150 requests/min = ~400ms between requests
            reservoir: 150,
            reservoirRefreshAmount: 150,
            reservoirRefreshInterval: 60 * 1000, // 1 minute
        });
        // Initialize SDK if configured
        if (this.isConfigured()) {
            const config = new lob_typescript_sdk_1.Configuration({
                username: config_1.lobConfig.apiKey,
            });
            this.lettersApi = new lob_typescript_sdk_1.LettersApi(config);
            this.verificationsApi = new lob_typescript_sdk_1.UsVerificationsApi(config);
            logger.info("[Lob Service] Initialized with SDK", {
                testMode: this.testMode,
            });
        }
        else {
            logger.warn("[Lob Service] API key not configured, running in mock mode");
        }
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
    /**
     * Handle SDK errors and convert to LobApiError
     */
    handleSdkError(error, operation) {
        let statusCode = 500;
        let lobErrorCode;
        let lobErrorMessage;
        let message = `Lob API ${operation} failed`;
        if (error instanceof Error) {
            // Check if it's an Axios error from the SDK
            const axiosError = error;
            if (axiosError.response) {
                statusCode = axiosError.response.status || 500;
                if (axiosError.response.data?.error) {
                    lobErrorCode = axiosError.response.data.error.code;
                    lobErrorMessage = axiosError.response.data.error.message;
                    message = lobErrorMessage || message;
                }
            }
        }
        logger.error(`[Lob Service] ${operation} Error`, {
            statusCode,
            code: lobErrorCode,
            message: lobErrorMessage,
        });
        throw new LobApiError(message, statusCode, lobErrorCode, lobErrorMessage);
    }
    /**
     * Wrap an operation with retry logic
     */
    async withRetry(operation, operationName) {
        return (0, p_retry_1.default)(async () => {
            try {
                return await operation();
            }
            catch (error) {
                // Convert to our error type for proper retry checking
                if (error instanceof LobApiError) {
                    if (!error.isRetryable()) {
                        throw new p_retry_1.AbortError(error.message);
                    }
                    throw error;
                }
                throw error;
            }
        }, {
            retries: 3,
            minTimeout: 1000,
            maxTimeout: 10000,
            factor: 2,
            onFailedAttempt: (attemptError) => {
                logger.warn(`[Lob Service] ${operationName} attempt ${attemptError.attemptNumber} failed`, {
                    retriesLeft: attemptError.retriesLeft,
                });
            },
        });
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
        if (!this.isConfigured() || !this.verificationsApi) {
            logger.warn("[Lob Service] API not configured, returning mock verification");
            return this.mockAddressVerification(address);
        }
        return this.limiter.schedule(() => this.withRetry(async () => {
            try {
                // Build verification request - use any to bypass SDK's strict type requirements
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const verificationRequest = {
                    primary_line: address.addressLine1,
                    secondary_line: address.addressLine2 || "",
                    city: address.city,
                    state: address.state,
                    zip_code: address.zipCode,
                };
                const response = await this.verificationsApi.verifySingle(verificationRequest);
                logger.info("[Lob Service] Address verified", {
                    deliverability: response.deliverability,
                    city: response.components?.city,
                    state: response.components?.state,
                });
                // Convert SDK response to our interface
                return this.convertVerificationResponse(response, address);
            }
            catch (error) {
                this.handleSdkError(error, "verifyAddress");
            }
        }, "verifyAddress"));
    }
    /**
     * Convert SDK verification response to our interface
     */
    convertVerificationResponse(sdkResponse, originalAddress) {
        const components = sdkResponse.components;
        return {
            id: sdkResponse.id || `us_ver_${Date.now()}`,
            recipient: originalAddress.name,
            primary_line: sdkResponse.primary_line || originalAddress.addressLine1,
            secondary_line: sdkResponse.secondary_line || undefined,
            last_line: sdkResponse.last_line || `${originalAddress.city}, ${originalAddress.state} ${originalAddress.zipCode}`,
            deliverability: sdkResponse.deliverability || "undeliverable",
            components: {
                primary_number: components?.primary_number || "",
                street_predirection: components?.street_predirection || "",
                street_name: components?.street_name || "",
                street_suffix: components?.street_suffix || "",
                street_postdirection: components?.street_postdirection || "",
                secondary_designator: components?.secondary_designator || "",
                secondary_number: components?.secondary_number || "",
                pmb_designator: components?.pmb_designator || "",
                pmb_number: components?.pmb_number || "",
                extra_secondary_designator: components?.extra_secondary_designator || "",
                extra_secondary_number: components?.extra_secondary_number || "",
                city: components?.city || originalAddress.city,
                state: components?.state || originalAddress.state,
                zip_code: components?.zip_code || originalAddress.zipCode.substring(0, 5),
                zip_code_plus_4: components?.zip_code_plus_4 || "",
                zip_code_type: components?.zip_code_type || "standard",
                delivery_point_barcode: components?.delivery_point_barcode || "",
                address_type: components?.address_type || "residential",
                record_type: components?.record_type || "street",
                default_building_address: components?.default_building_address || false,
                county: components?.county || "",
                county_fips: components?.county_fips || "",
                carrier_route: components?.carrier_route || "",
                carrier_route_type: components?.carrier_route_type || "",
                latitude: components?.latitude || 0,
                longitude: components?.longitude || 0,
            },
            object: "us_verification",
        };
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
        if (!this.isConfigured() || !this.lettersApi) {
            logger.warn("[Lob Service] API not configured, returning mock letter");
            return this.mockLetter(options);
        }
        return this.limiter.schedule(() => this.withRetry(async () => {
            try {
                // Convert MailType to Lob format
                const mailType = options.mailType === "usps_first_class" ? "usps_first_class" : "usps_standard";
                let extraService;
                if (options.mailType === "usps_certified") {
                    extraService = "certified";
                }
                else if (options.mailType === "usps_certified_return_receipt") {
                    extraService = "certified_return_receipt";
                }
                // Build address objects - use any to bypass SDK's strict toJSON requirement
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const toAddress = {
                    name: options.to.name,
                    address_line1: options.to.addressLine1,
                    address_line2: options.to.addressLine2,
                    address_city: options.to.city,
                    address_state: options.to.state,
                    address_zip: options.to.zipCode,
                    address_country: "US",
                };
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const fromAddress = {
                    name: options.from.name,
                    address_line1: options.from.addressLine1,
                    address_line2: options.from.addressLine2,
                    address_city: options.from.city,
                    address_state: options.from.state,
                    address_zip: options.from.zipCode,
                    address_country: "US",
                };
                // Build request data - use any to bypass SDK's strict toJSON requirement
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const letterEditable = {
                    description: options.description || "Credit Dispute Letter",
                    to: toAddress,
                    from: fromAddress,
                    mail_type: mailType,
                    color: options.color ?? false,
                    double_sided: options.doubleSided ?? false,
                    use_type: "operational", // Required by Lob - "operational" for transactional mail
                    metadata: options.metadata || {},
                    file: typeof options.file === "string" ? options.file : options.file.toString("base64"),
                };
                if (extraService) {
                    letterEditable.extra_service = extraService;
                }
                if (options.sendDate) {
                    letterEditable.send_date = options.sendDate;
                }
                // Create letter using SDK
                const response = await this.lettersApi.create(letterEditable, options.idempotencyKey);
                logger.info("[Lob Service] Letter created", {
                    letterId: response.id,
                    expectedDelivery: response.expected_delivery_date,
                    carrier: response.carrier,
                });
                return this.convertLetterResponse(response, options);
            }
            catch (error) {
                this.handleSdkError(error, "createLetter");
            }
        }, "createLetter"));
    }
    /**
     * Convert MailingAddress to Lob format (for internal use)
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
     * Convert SDK letter response to our interface
     */
    convertLetterResponse(sdkLetter, options) {
        const tracking_events = [];
        if (sdkLetter.tracking_events) {
            for (const event of sdkLetter.tracking_events) {
                // Type assertion needed because SDK types may be incomplete
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const eventAny = event;
                const formatEventDate = (val) => {
                    if (!val)
                        return "";
                    if (typeof val === "string")
                        return val;
                    if (val instanceof Date)
                        return val.toISOString();
                    return String(val);
                };
                tracking_events.push({
                    id: eventAny.id || "",
                    type: eventAny.type || "",
                    name: eventAny.name || "",
                    location: eventAny.location || undefined,
                    time: formatEventDate(eventAny.time),
                    date_created: formatEventDate(eventAny.date_created),
                    date_modified: formatEventDate(eventAny.date_modified),
                    object: "tracking_event",
                });
            }
        }
        // Handle date fields - they may be strings or Date objects
        const formatDate = (val) => {
            if (!val)
                return "";
            if (typeof val === "string")
                return val.split("T")[0];
            return val.toISOString().split("T")[0];
        };
        const formatDateTime = (val) => {
            if (!val)
                return "";
            if (typeof val === "string")
                return val;
            return val.toISOString();
        };
        return {
            id: sdkLetter.id || "",
            description: sdkLetter.description || undefined,
            metadata: sdkLetter.metadata || {},
            mail_type: sdkLetter.mail_type || "usps_first_class",
            expected_delivery_date: formatDate(sdkLetter.expected_delivery_date),
            date_created: formatDateTime(sdkLetter.date_created),
            date_modified: formatDateTime(sdkLetter.date_modified),
            send_date: formatDate(sdkLetter.send_date),
            to: this.convertAddress(options.to),
            from: this.convertAddress(options.from),
            color: sdkLetter.color || false,
            double_sided: sdkLetter.double_sided || false,
            address_placement: sdkLetter.address_placement || "top_first_page",
            return_envelope: typeof sdkLetter.return_envelope === "boolean" ? sdkLetter.return_envelope : false,
            perforated_page: sdkLetter.perforated_page ?? undefined,
            custom_envelope: sdkLetter.custom_envelope?.id || undefined,
            extra_service: sdkLetter.extra_service,
            carrier: sdkLetter.carrier || "USPS",
            tracking_number: sdkLetter.tracking_number || undefined,
            tracking_events,
            url: sdkLetter.url || "",
            thumbnails: sdkLetter.thumbnails
                ? {
                    small: sdkLetter.thumbnails[0]?.small || "",
                    medium: sdkLetter.thumbnails[0]?.medium || "",
                    large: sdkLetter.thumbnails[0]?.large || "",
                }
                : { small: "", medium: "", large: "" },
            object: "letter",
        };
    }
    /**
     * Get letter details by Lob ID
     */
    async getLetter(lobId) {
        if (!this.isConfigured() || !this.lettersApi) {
            throw new LobApiError("Lob API not configured", 500);
        }
        return this.limiter.schedule(() => this.withRetry(async () => {
            try {
                const response = await this.lettersApi.get(lobId);
                // We need to construct the options for the converter from the response
                const toAddr = response.to;
                const fromAddr = response.from;
                const options = {
                    to: {
                        name: toAddr?.name || "",
                        addressLine1: toAddr?.address_line1 || "",
                        addressLine2: toAddr?.address_line2,
                        city: toAddr?.address_city || "",
                        state: toAddr?.address_state || "",
                        zipCode: toAddr?.address_zip || "",
                    },
                    from: {
                        name: fromAddr?.name || "",
                        addressLine1: fromAddr?.address_line1 || "",
                        addressLine2: fromAddr?.address_line2,
                        city: fromAddr?.address_city || "",
                        state: fromAddr?.address_state || "",
                        zipCode: fromAddr?.address_zip || "",
                    },
                    file: "",
                    mailType: response.mail_type,
                };
                return this.convertLetterResponse(response, options);
            }
            catch (error) {
                this.handleSdkError(error, "getLetter");
            }
        }, "getLetter"));
    }
    /**
     * Cancel a letter (only if not yet sent)
     */
    async cancelLetter(lobId) {
        if (!this.isConfigured() || !this.lettersApi) {
            logger.warn("[Lob Service] API not configured, skipping cancel");
            return;
        }
        await this.limiter.schedule(() => this.withRetry(async () => {
            try {
                await this.lettersApi.cancel(lobId);
                logger.info("[Lob Service] Letter cancelled", { lobId });
            }
            catch (error) {
                this.handleSdkError(error, "cancelLetter");
            }
        }, "cancelLetter"));
    }
    /**
     * List letters with optional filters
     */
    async listLetters(options = {}) {
        if (!this.isConfigured() || !this.lettersApi) {
            return { data: [], total_count: 0 };
        }
        return this.limiter.schedule(() => this.withRetry(async () => {
            try {
                const response = await this.lettersApi.list(options.limit, options.beforeId, options.afterId, undefined, // include
                options.dateCreated, options.metadata);
                const listResponse = response;
                // Convert each letter
                const letters = [];
                if (listResponse.data) {
                    for (const letter of listResponse.data) {
                        const toAddr = letter.to;
                        const fromAddr = letter.from;
                        const convertedOptions = {
                            to: {
                                name: toAddr?.name || "",
                                addressLine1: toAddr?.address_line1 || "",
                                addressLine2: toAddr?.address_line2,
                                city: toAddr?.address_city || "",
                                state: toAddr?.address_state || "",
                                zipCode: toAddr?.address_zip || "",
                            },
                            from: {
                                name: fromAddr?.name || "",
                                addressLine1: fromAddr?.address_line1 || "",
                                addressLine2: fromAddr?.address_line2,
                                city: fromAddr?.address_city || "",
                                state: fromAddr?.address_state || "",
                                zipCode: fromAddr?.address_zip || "",
                            },
                            file: "",
                            mailType: letter.mail_type,
                        };
                        letters.push(this.convertLetterResponse(letter, convertedOptions));
                    }
                }
                return {
                    data: letters,
                    total_count: listResponse.total_count || 0,
                };
            }
            catch (error) {
                this.handleSdkError(error, "listLetters");
            }
        }, "listLetters"));
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
     * Verify webhook signature using Lob's format
     *
     * Lob signature header format: "t=timestamp,v1=signature"
     * Signed payload format: "{timestamp}.{rawBody}"
     *
     * @param payload - Raw webhook payload (body as string)
     * @param signatureHeader - Full lob-signature header value
     * @returns Object with valid flag and parsed timestamp
     */
    verifyWebhookSignature(payload, signatureHeader) {
        if (!config_1.lobConfig.webhookSecret) {
            logger.warn("[Lob Service] Webhook secret not configured, skipping verification");
            return { valid: true };
        }
        try {
            // Parse header: "t=1234567890,v1=abc123def456..."
            const parts = signatureHeader.split(",");
            const timestampPart = parts.find((p) => p.startsWith("t="));
            const signaturePart = parts.find((p) => p.startsWith("v1="));
            if (!timestampPart || !signaturePart) {
                logger.warn("[Lob Service] Invalid signature header format", {
                    hasTimestamp: !!timestampPart,
                    hasSignature: !!signaturePart,
                });
                return { valid: false };
            }
            const timestamp = timestampPart.substring(2);
            const signature = signaturePart.substring(3);
            // Compute expected signature
            const crypto = require("crypto");
            const signedPayload = `${timestamp}.${payload}`;
            const expectedSignature = crypto
                .createHmac("sha256", config_1.lobConfig.webhookSecret)
                .update(signedPayload)
                .digest("hex");
            // Timing-safe comparison
            const signatureBuffer = Buffer.from(signature);
            const expectedBuffer = Buffer.from(expectedSignature);
            // Buffers must be same length for timingSafeEqual
            if (signatureBuffer.length !== expectedBuffer.length) {
                return { valid: false, timestamp };
            }
            const signatureValid = crypto.timingSafeEqual(signatureBuffer, expectedBuffer);
            // Check timestamp freshness (prevent replay attacks)
            const timestampMs = parseInt(timestamp) * 1000;
            const age = Date.now() - timestampMs;
            const maxAge = 5 * 60 * 1000; // 5 minutes
            const isFresh = age >= 0 && age < maxAge;
            if (!isFresh) {
                logger.warn("[Lob Service] Webhook signature timestamp too old or in future", {
                    timestamp,
                    ageMs: age,
                    maxAgeMs: maxAge,
                });
            }
            return {
                valid: signatureValid && isFresh,
                timestamp,
            };
        }
        catch (error) {
            logger.error("[Lob Service] Error verifying webhook signature", { error });
            return { valid: false };
        }
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
     * Includes all standard and certified mail events
     */
    mapEventToLetterStatus(eventType) {
        const eventMap = {
            // Standard letter events
            "letter.created": "queued",
            "letter.rendered_pdf": "ready",
            "letter.rendered_thumbnails": "ready",
            "letter.deleted": "cancelled",
            "letter.mailed": "sent",
            "letter.in_transit": "in_transit",
            "letter.in_local_area": "in_transit",
            "letter.processed_for_delivery": "in_transit",
            "letter.re-routed": "in_transit",
            "letter.returned_to_sender": "returned_to_sender",
            "letter.delivered": "delivered",
            "letter.failed": "returned_to_sender",
            // Certified mail events
            "letter.certified.mailed": "sent",
            "letter.certified.in_transit": "in_transit",
            "letter.certified.in_local_area": "in_transit",
            "letter.certified.processed_for_delivery": "in_transit",
            "letter.certified.re-routed": "in_transit",
            "letter.certified.returned_to_sender": "returned_to_sender",
            "letter.certified.delivered": "delivered",
            "letter.certified.pickup_available": "in_transit",
            "letter.certified.issue": "returned_to_sender",
        };
        return eventMap[eventType] || null;
    }
}
exports.LobService = LobService;
// Export singleton instance
exports.lobService = new LobService();
//# sourceMappingURL=lobService.js.map