/**
 * Error Handling Utilities
 *
 * Provides standardized error types and handling for Cloud Functions.
 * All errors are converted to consistent API responses.
 */
import * as functions from "firebase-functions";
/**
 * Error codes used throughout the application
 */
export declare enum ErrorCode {
    INTERNAL_ERROR = "INTERNAL_ERROR",
    VALIDATION_ERROR = "VALIDATION_ERROR",
    NOT_FOUND = "NOT_FOUND",
    ALREADY_EXISTS = "ALREADY_EXISTS",
    RATE_LIMITED = "RATE_LIMITED",
    FORBIDDEN = "FORBIDDEN",
    UNAUTHENTICATED = "UNAUTHENTICATED",
    UNAUTHORIZED = "UNAUTHORIZED",
    INVALID_TOKEN = "INVALID_TOKEN",
    TOKEN_EXPIRED = "TOKEN_EXPIRED",
    INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS",
    TENANT_NOT_FOUND = "TENANT_NOT_FOUND",
    TENANT_SUSPENDED = "TENANT_SUSPENDED",
    TENANT_LIMIT_EXCEEDED = "TENANT_LIMIT_EXCEEDED",
    CONSUMER_NOT_FOUND = "CONSUMER_NOT_FOUND",
    CONSUMER_ALREADY_EXISTS = "CONSUMER_ALREADY_EXISTS",
    INVALID_CONSENT = "INVALID_CONSENT",
    INTEGRATION_NOT_CONFIGURED = "INTEGRATION_NOT_CONFIGURED",
    INTEGRATION_ERROR = "INTEGRATION_ERROR",
    EXTERNAL_SERVICE_ERROR = "EXTERNAL_SERVICE_ERROR",
    SMARTCREDIT_NOT_CONNECTED = "SMARTCREDIT_NOT_CONNECTED",
    SMARTCREDIT_AUTH_FAILED = "SMARTCREDIT_AUTH_FAILED",
    SMARTCREDIT_TOKEN_EXPIRED = "SMARTCREDIT_TOKEN_EXPIRED",
    SMARTCREDIT_API_ERROR = "SMARTCREDIT_API_ERROR",
    SMARTCREDIT_RATE_LIMITED = "SMARTCREDIT_RATE_LIMITED",
    DISPUTE_NOT_FOUND = "DISPUTE_NOT_FOUND",
    INVALID_DISPUTE_STATUS = "INVALID_DISPUTE_STATUS",
    DISPUTE_ALREADY_CLOSED = "DISPUTE_ALREADY_CLOSED",
    TRADELINE_NOT_FOUND = "TRADELINE_NOT_FOUND",
    LETTER_NOT_FOUND = "LETTER_NOT_FOUND",
    LETTER_ALREADY_SENT = "LETTER_ALREADY_SENT",
    INVALID_LETTER_STATUS = "INVALID_LETTER_STATUS",
    TEMPLATE_NOT_FOUND = "TEMPLATE_NOT_FOUND",
    PDF_GENERATION_FAILED = "PDF_GENERATION_FAILED",
    LOB_API_ERROR = "LOB_API_ERROR",
    LOB_ADDRESS_INVALID = "LOB_ADDRESS_INVALID",
    LOB_RATE_LIMITED = "LOB_RATE_LIMITED",
    EVIDENCE_NOT_FOUND = "EVIDENCE_NOT_FOUND",
    FILE_TOO_LARGE = "FILE_TOO_LARGE",
    INVALID_FILE_TYPE = "INVALID_FILE_TYPE",
    VIRUS_DETECTED = "VIRUS_DETECTED",
    WEBHOOK_SIGNATURE_INVALID = "WEBHOOK_SIGNATURE_INVALID",
    WEBHOOK_PROCESSING_FAILED = "WEBHOOK_PROCESSING_FAILED"
}
/**
 * Base application error class
 */
export declare class AppError extends Error {
    readonly code: ErrorCode;
    readonly statusCode: number;
    readonly details?: Record<string, unknown>;
    readonly isOperational: boolean;
    constructor(code: ErrorCode, message: string, statusCode?: number, details?: Record<string, unknown>, isOperational?: boolean);
}
/**
 * Authentication error
 */
export declare class AuthError extends AppError {
    constructor(code?: ErrorCode, message?: string);
}
/**
 * Authorization error
 */
export declare class ForbiddenError extends AppError {
    constructor(message?: string);
}
/**
 * Not found error
 */
export declare class NotFoundError extends AppError {
    constructor(entity: string, id?: string);
}
/**
 * Conflict error (e.g., duplicate)
 */
export declare class ConflictError extends AppError {
    constructor(message: string);
}
/**
 * Rate limit error
 */
export declare class RateLimitError extends AppError {
    constructor(message?: string);
}
/**
 * External service error (SmartCredit, Lob, etc.)
 */
export declare class ExternalServiceError extends AppError {
    readonly service: string;
    readonly originalError?: Error;
    constructor(service: string, code: ErrorCode, message: string, originalError?: Error);
}
/**
 * Convert any error to a standardized API response
 */
export declare function formatErrorResponse(error: unknown): {
    success: false;
    error: {
        code: string;
        message: string;
        details?: Record<string, unknown>;
    };
};
/**
 * Convert AppError to Firebase HttpsError for callable functions
 */
export declare function toHttpsError(error: unknown): functions.https.HttpsError;
/**
 * Wrap an async function with error handling for callable functions
 */
export declare function withErrorHandling<T, R>(fn: (data: T, context: functions.https.CallableContext) => Promise<R>): (data: T, context: functions.https.CallableContext) => Promise<R>;
/**
 * Assert a condition and throw if false
 */
export declare function assert(condition: boolean, code: ErrorCode, message: string, details?: Record<string, unknown>): asserts condition;
/**
 * Assert that a value exists and throw NotFoundError if not
 */
export declare function assertExists<T>(value: T | null | undefined, entity: string, id?: string): asserts value is T;
//# sourceMappingURL=errors.d.ts.map