/**
 * Lob API Service
 *
 * Handles all interactions with the Lob print-and-mail API.
 * Provides address verification, letter creation, status tracking, and webhook processing.
 *
 * @see https://docs.lob.com/
 */

import axios, { AxiosInstance, AxiosError } from "axios";
import { lobConfig, isEmulator } from "../config";
import * as logger from "firebase-functions/logger";
import { MailingAddress, MailType } from "../types";

// ============================================================================
// Types
// ============================================================================

export interface LobAddress {
  name: string;
  address_line1: string;
  address_line2?: string;
  address_city: string;
  address_state: string;
  address_zip: string;
  address_country?: string;
}

export interface LobAddressVerification {
  id: string;
  recipient: string;
  primary_line: string;
  secondary_line?: string;
  urbanization?: string;
  last_line: string;
  deliverability: "deliverable" | "deliverable_missing_unit" | "deliverable_incorrect_unit" | "deliverable_unnecessary_unit" | "undeliverable";
  components: {
    primary_number: string;
    street_predirection: string;
    street_name: string;
    street_suffix: string;
    street_postdirection: string;
    secondary_designator: string;
    secondary_number: string;
    pmb_designator: string;
    pmb_number: string;
    extra_secondary_designator: string;
    extra_secondary_number: string;
    city: string;
    state: string;
    zip_code: string;
    zip_code_plus_4: string;
    zip_code_type: string;
    delivery_point_barcode: string;
    address_type: string;
    record_type: string;
    default_building_address: boolean;
    county: string;
    county_fips: string;
    carrier_route: string;
    carrier_route_type: string;
    latitude: number;
    longitude: number;
  };
  object: "us_verification";
}

export interface LobLetter {
  id: string;
  description?: string;
  metadata?: Record<string, string>;
  mail_type: "usps_first_class" | "usps_standard";
  expected_delivery_date: string;
  date_created: string;
  date_modified: string;
  send_date: string;
  to: LobAddress;
  from: LobAddress;
  color: boolean;
  double_sided: boolean;
  address_placement: string;
  return_envelope: boolean;
  perforated_page?: number;
  custom_envelope?: string;
  extra_service?: "certified" | "certified_return_receipt" | "registered";
  carrier: string;
  tracking_number?: string;
  tracking_events: LobTrackingEvent[];
  url: string;
  thumbnails: { small: string; medium: string; large: string }[];
  object: "letter";
}

export interface LobTrackingEvent {
  id: string;
  type: string;
  name: string;
  location?: string;
  time: string;
  date_created: string;
  date_modified: string;
  object: "tracking_event";
}

export interface CreateLetterOptions {
  to: MailingAddress;
  from: MailingAddress;
  file: string | Buffer;
  fileType?: "pdf" | "html";
  description?: string;
  mailType: MailType;
  color?: boolean;
  doubleSided?: boolean;
  sendDate?: string;
  metadata?: Record<string, string>;
  idempotencyKey?: string;
}

export interface CostEstimate {
  printing: number;
  postage: number;
  certifiedFee?: number;
  returnReceiptFee?: number;
  total: number;
  currency: string;
  mailType: MailType;
  pageCount: number;
}

export interface LobWebhookPayload {
  id: string;
  reference_id?: string;
  event_type: {
    id: string;
    enabled_for_test: boolean;
    resource: string;
    object: "event_type";
  };
  date_created: string;
  object: "event";
  body: LobLetter | LobAddressVerification;
}

// ============================================================================
// Error Types
// ============================================================================

export class LobApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public lobErrorCode?: string,
    public lobErrorMessage?: string
  ) {
    super(message);
    this.name = "LobApiError";
  }
}

// ============================================================================
// Lob Client
// ============================================================================

class LobService {
  private client: AxiosInstance;
  private testMode: boolean;

  constructor() {
    this.testMode = !lobConfig.apiKey.startsWith("live_");

    this.client = axios.create({
      baseURL: lobConfig.baseUrl,
      auth: {
        username: lobConfig.apiKey,
        password: "", // Lob uses API key as username with empty password
      },
      headers: {
        "Content-Type": "application/json",
        "Lob-Version": "2024-01-01",
      },
      timeout: 30000,
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
   * Handle API errors and convert to LobApiError
   */
  private handleApiError(error: AxiosError): never {
    const status = error.response?.status || 500;
    const data = error.response?.data as Record<string, unknown> | undefined;

    let message = "Lob API request failed";
    let lobErrorCode: string | undefined;
    let lobErrorMessage: string | undefined;

    if (data?.error) {
      const lobError = data.error as Record<string, unknown>;
      lobErrorCode = lobError.code as string;
      lobErrorMessage = lobError.message as string;
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
  isConfigured(): boolean {
    return !!lobConfig.apiKey && lobConfig.apiKey.length > 0;
  }

  /**
   * Check if in test mode
   */
  isTestMode(): boolean {
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
  async verifyAddress(address: MailingAddress): Promise<LobAddressVerification> {
    if (!this.isConfigured()) {
      logger.warn("[Lob Service] API not configured, returning mock verification");
      return this.mockAddressVerification(address);
    }

    const response = await this.client.post<LobAddressVerification>("/us_verifications", {
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
  private mockAddressVerification(address: MailingAddress): LobAddressVerification {
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
  async createLetter(options: CreateLetterOptions): Promise<LobLetter> {
    if (!this.isConfigured()) {
      logger.warn("[Lob Service] API not configured, returning mock letter");
      return this.mockLetter(options);
    }

    // Convert MailType to Lob format
    const mailType = options.mailType === "usps_first_class" ? "usps_first_class" : "usps_standard";
    let extraService: "certified" | "certified_return_receipt" | undefined;

    if (options.mailType === "usps_certified") {
      extraService = "certified";
    } else if (options.mailType === "usps_certified_return_receipt") {
      extraService = "certified_return_receipt";
    }

    // Build request data
    const requestData: Record<string, unknown> = {
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
      } else {
        // Assume it's HTML content
        requestData.file = options.file;
      }
    } else {
      // Buffer - need to upload as multipart
      const formData = new FormData();
      const blob = new Blob([options.file], { type: "application/pdf" });
      formData.append("file", blob, "letter.pdf");

      // For multipart, we need different handling
      requestData.file = options.file.toString("base64");
    }

    if (extraService) {
      requestData.extra_service = extraService;
    }

    if (options.sendDate) {
      requestData.send_date = options.sendDate;
    }

    // Set idempotency key in header if provided
    const headers: Record<string, string> = {};
    if (options.idempotencyKey) {
      headers["Idempotency-Key"] = options.idempotencyKey;
    }

    const response = await this.client.post<LobLetter>("/letters", requestData, { headers });

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
  private convertAddress(address: MailingAddress): LobAddress {
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
  async getLetter(lobId: string): Promise<LobLetter> {
    if (!this.isConfigured()) {
      throw new LobApiError("Lob API not configured", 500);
    }

    const response = await this.client.get<LobLetter>(`/letters/${lobId}`);
    return response.data;
  }

  /**
   * Cancel a letter (only if not yet sent)
   */
  async cancelLetter(lobId: string): Promise<void> {
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
  async listLetters(options: {
    limit?: number;
    afterId?: string;
    beforeId?: string;
    dateCreated?: { gt?: string; gte?: string; lt?: string; lte?: string };
    metadata?: Record<string, string>;
  } = {}): Promise<{ data: LobLetter[]; total_count: number }> {
    if (!this.isConfigured()) {
      return { data: [], total_count: 0 };
    }

    const params = new URLSearchParams();
    if (options.limit) params.set("limit", String(options.limit));
    if (options.afterId) params.set("after", options.afterId);
    if (options.beforeId) params.set("before", options.beforeId);
    if (options.metadata) {
      for (const [key, value] of Object.entries(options.metadata)) {
        params.set(`metadata[${key}]`, value);
      }
    }

    const response = await this.client.get<{ data: LobLetter[]; total_count: number }>(
      `/letters?${params.toString()}`
    );
    return response.data;
  }

  /**
   * Mock letter for development/testing
   */
  private mockLetter(options: CreateLetterOptions): LobLetter {
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
  estimateCost(pageCount: number, mailType: MailType): CostEstimate {
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
    let certifiedFee: number | undefined;
    let returnReceiptFee: number | undefined;

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
  verifyWebhookSignature(payload: string, signature: string): boolean {
    if (!lobConfig.webhookSecret) {
      logger.warn("[Lob Service] Webhook secret not configured, skipping verification");
      return true;
    }

    const crypto = require("crypto");
    const expectedSignature = crypto
      .createHmac("sha256", lobConfig.webhookSecret)
      .update(payload)
      .digest("hex");

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  }

  /**
   * Parse webhook event type
   */
  parseWebhookEvent(eventType: string): {
    resource: "letter" | "postcard" | "check" | "address";
    action: string;
  } {
    const parts = eventType.split(".");
    return {
      resource: parts[0] as "letter" | "postcard" | "check" | "address",
      action: parts.slice(1).join("."),
    };
  }

  /**
   * Map Lob event to internal letter status
   */
  mapEventToLetterStatus(eventType: string): string | null {
    const eventMap: Record<string, string> = {
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

// Export singleton instance
export const lobService = new LobService();

// Export class for testing
export { LobService };
