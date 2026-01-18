/**
 * Lob API Service
 *
 * Handles all interactions with the Lob print-and-mail API.
 * Provides address verification, letter creation, status tracking, and webhook processing.
 *
 * @see https://docs.lob.com/
 */
import { MailingAddress, MailType } from "../types";
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
    thumbnails: {
        small: string;
        medium: string;
        large: string;
    };
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
export declare class LobApiError extends Error {
    statusCode: number;
    lobErrorCode?: string | undefined;
    lobErrorMessage?: string | undefined;
    constructor(message: string, statusCode: number, lobErrorCode?: string | undefined, lobErrorMessage?: string | undefined);
}
declare class LobService {
    private client;
    private testMode;
    constructor();
    /**
     * Handle API errors and convert to LobApiError
     */
    private handleApiError;
    /**
     * Check if service is configured
     */
    isConfigured(): boolean;
    /**
     * Check if in test mode
     */
    isTestMode(): boolean;
    /**
     * Verify a US address with Lob
     *
     * @param address - Address to verify
     * @returns Verification result with deliverability status
     */
    verifyAddress(address: MailingAddress): Promise<LobAddressVerification>;
    /**
     * Mock address verification for development/testing
     */
    private mockAddressVerification;
    /**
     * Create and send a letter via Lob
     *
     * @param options - Letter creation options
     * @returns Created letter object
     */
    createLetter(options: CreateLetterOptions): Promise<LobLetter>;
    /**
     * Convert MailingAddress to Lob format
     */
    private convertAddress;
    /**
     * Get letter details by Lob ID
     */
    getLetter(lobId: string): Promise<LobLetter>;
    /**
     * Cancel a letter (only if not yet sent)
     */
    cancelLetter(lobId: string): Promise<void>;
    /**
     * List letters with optional filters
     */
    listLetters(options?: {
        limit?: number;
        afterId?: string;
        beforeId?: string;
        dateCreated?: {
            gt?: string;
            gte?: string;
            lt?: string;
            lte?: string;
        };
        metadata?: Record<string, string>;
    }): Promise<{
        data: LobLetter[];
        total_count: number;
    }>;
    /**
     * Mock letter for development/testing
     */
    private mockLetter;
    /**
     * Estimate cost for sending a letter
     *
     * @param pageCount - Number of pages
     * @param mailType - Type of mailing service
     * @returns Cost breakdown
     */
    estimateCost(pageCount: number, mailType: MailType): CostEstimate;
    /**
     * Verify webhook signature
     *
     * @param payload - Raw webhook payload
     * @param signature - Lob signature header
     * @returns true if signature is valid
     */
    verifyWebhookSignature(payload: string, signature: string): boolean;
    /**
     * Parse webhook event type
     */
    parseWebhookEvent(eventType: string): {
        resource: "letter" | "postcard" | "check" | "address";
        action: string;
    };
    /**
     * Map Lob event to internal letter status
     */
    mapEventToLetterStatus(eventType: string): string | null;
}
export declare const lobService: LobService;
export { LobService };
//# sourceMappingURL=lobService.d.ts.map