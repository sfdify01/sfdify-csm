"use strict";
/**
 * Error Handling Utilities
 *
 * Provides standardized error types and handling for Cloud Functions.
 * All errors are converted to consistent API responses.
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExternalServiceError = exports.RateLimitError = exports.ConflictError = exports.NotFoundError = exports.ForbiddenError = exports.AuthError = exports.AppError = exports.ErrorCode = void 0;
exports.formatErrorResponse = formatErrorResponse;
exports.toHttpsError = toHttpsError;
exports.withErrorHandling = withErrorHandling;
exports.assert = assert;
exports.assertExists = assertExists;
const functions = __importStar(require("firebase-functions"));
const validation_1 = require("./validation");
/**
 * Error codes used throughout the application
 */
var ErrorCode;
(function (ErrorCode) {
    // General errors (1000-1099)
    ErrorCode["INTERNAL_ERROR"] = "INTERNAL_ERROR";
    ErrorCode["VALIDATION_ERROR"] = "VALIDATION_ERROR";
    ErrorCode["NOT_FOUND"] = "NOT_FOUND";
    ErrorCode["ALREADY_EXISTS"] = "ALREADY_EXISTS";
    ErrorCode["RATE_LIMITED"] = "RATE_LIMITED";
    ErrorCode["FORBIDDEN"] = "FORBIDDEN";
    // Authentication errors (1100-1199)
    ErrorCode["UNAUTHENTICATED"] = "UNAUTHENTICATED";
    ErrorCode["UNAUTHORIZED"] = "UNAUTHORIZED";
    ErrorCode["INVALID_TOKEN"] = "INVALID_TOKEN";
    ErrorCode["TOKEN_EXPIRED"] = "TOKEN_EXPIRED";
    ErrorCode["INSUFFICIENT_PERMISSIONS"] = "INSUFFICIENT_PERMISSIONS";
    // Tenant errors (1200-1299)
    ErrorCode["TENANT_NOT_FOUND"] = "TENANT_NOT_FOUND";
    ErrorCode["TENANT_SUSPENDED"] = "TENANT_SUSPENDED";
    ErrorCode["TENANT_LIMIT_EXCEEDED"] = "TENANT_LIMIT_EXCEEDED";
    // Consumer errors (1300-1399)
    ErrorCode["CONSUMER_NOT_FOUND"] = "CONSUMER_NOT_FOUND";
    ErrorCode["CONSUMER_ALREADY_EXISTS"] = "CONSUMER_ALREADY_EXISTS";
    ErrorCode["INVALID_CONSENT"] = "INVALID_CONSENT";
    // Integration errors (1400-1499)
    ErrorCode["INTEGRATION_NOT_CONFIGURED"] = "INTEGRATION_NOT_CONFIGURED";
    ErrorCode["INTEGRATION_ERROR"] = "INTEGRATION_ERROR";
    ErrorCode["EXTERNAL_SERVICE_ERROR"] = "EXTERNAL_SERVICE_ERROR";
    ErrorCode["SMARTCREDIT_NOT_CONNECTED"] = "SMARTCREDIT_NOT_CONNECTED";
    ErrorCode["SMARTCREDIT_AUTH_FAILED"] = "SMARTCREDIT_AUTH_FAILED";
    ErrorCode["SMARTCREDIT_TOKEN_EXPIRED"] = "SMARTCREDIT_TOKEN_EXPIRED";
    ErrorCode["SMARTCREDIT_API_ERROR"] = "SMARTCREDIT_API_ERROR";
    ErrorCode["SMARTCREDIT_RATE_LIMITED"] = "SMARTCREDIT_RATE_LIMITED";
    // Dispute errors (1500-1599)
    ErrorCode["DISPUTE_NOT_FOUND"] = "DISPUTE_NOT_FOUND";
    ErrorCode["INVALID_DISPUTE_STATUS"] = "INVALID_DISPUTE_STATUS";
    ErrorCode["DISPUTE_ALREADY_CLOSED"] = "DISPUTE_ALREADY_CLOSED";
    ErrorCode["TRADELINE_NOT_FOUND"] = "TRADELINE_NOT_FOUND";
    // Letter errors (1600-1699)
    ErrorCode["LETTER_NOT_FOUND"] = "LETTER_NOT_FOUND";
    ErrorCode["LETTER_ALREADY_SENT"] = "LETTER_ALREADY_SENT";
    ErrorCode["INVALID_LETTER_STATUS"] = "INVALID_LETTER_STATUS";
    ErrorCode["TEMPLATE_NOT_FOUND"] = "TEMPLATE_NOT_FOUND";
    ErrorCode["PDF_GENERATION_FAILED"] = "PDF_GENERATION_FAILED";
    // Lob errors (1700-1799)
    ErrorCode["LOB_API_ERROR"] = "LOB_API_ERROR";
    ErrorCode["LOB_ADDRESS_INVALID"] = "LOB_ADDRESS_INVALID";
    ErrorCode["LOB_RATE_LIMITED"] = "LOB_RATE_LIMITED";
    // Evidence errors (1800-1899)
    ErrorCode["EVIDENCE_NOT_FOUND"] = "EVIDENCE_NOT_FOUND";
    ErrorCode["FILE_TOO_LARGE"] = "FILE_TOO_LARGE";
    ErrorCode["INVALID_FILE_TYPE"] = "INVALID_FILE_TYPE";
    ErrorCode["VIRUS_DETECTED"] = "VIRUS_DETECTED";
    // Webhook errors (1900-1999)
    ErrorCode["WEBHOOK_SIGNATURE_INVALID"] = "WEBHOOK_SIGNATURE_INVALID";
    ErrorCode["WEBHOOK_PROCESSING_FAILED"] = "WEBHOOK_PROCESSING_FAILED";
})(ErrorCode || (exports.ErrorCode = ErrorCode = {}));
/**
 * Base application error class
 */
class AppError extends Error {
    code;
    statusCode;
    details;
    isOperational;
    constructor(code, message, statusCode = 400, details, isOperational = true) {
        super(message);
        this.name = "AppError";
        this.code = code;
        this.statusCode = statusCode;
        this.details = details;
        this.isOperational = isOperational;
        // Capture stack trace
        Error.captureStackTrace(this, this.constructor);
    }
}
exports.AppError = AppError;
/**
 * Authentication error
 */
class AuthError extends AppError {
    constructor(code = ErrorCode.UNAUTHENTICATED, message = "Authentication required") {
        super(code, message, 401);
        this.name = "AuthError";
    }
}
exports.AuthError = AuthError;
/**
 * Authorization error
 */
class ForbiddenError extends AppError {
    constructor(message = "You do not have permission to perform this action") {
        super(ErrorCode.UNAUTHORIZED, message, 403);
        this.name = "ForbiddenError";
    }
}
exports.ForbiddenError = ForbiddenError;
/**
 * Not found error
 */
class NotFoundError extends AppError {
    constructor(entity, id) {
        const message = id
            ? `${entity} with id '${id}' not found`
            : `${entity} not found`;
        super(ErrorCode.NOT_FOUND, message, 404);
        this.name = "NotFoundError";
    }
}
exports.NotFoundError = NotFoundError;
/**
 * Conflict error (e.g., duplicate)
 */
class ConflictError extends AppError {
    constructor(message) {
        super(ErrorCode.ALREADY_EXISTS, message, 409);
        this.name = "ConflictError";
    }
}
exports.ConflictError = ConflictError;
/**
 * Rate limit error
 */
class RateLimitError extends AppError {
    constructor(message = "Rate limit exceeded. Please try again later.") {
        super(ErrorCode.RATE_LIMITED, message, 429);
        this.name = "RateLimitError";
    }
}
exports.RateLimitError = RateLimitError;
/**
 * External service error (SmartCredit, Lob, etc.)
 */
class ExternalServiceError extends AppError {
    service;
    originalError;
    constructor(service, code, message, originalError) {
        super(code, message, 502, { service, originalMessage: originalError?.message });
        this.name = "ExternalServiceError";
        this.service = service;
        this.originalError = originalError;
    }
}
exports.ExternalServiceError = ExternalServiceError;
/**
 * Convert any error to a standardized API response
 */
function formatErrorResponse(error) {
    // Handle AppError (our custom errors)
    if (error instanceof AppError) {
        return {
            success: false,
            error: {
                code: error.code,
                message: error.message,
                details: error.details,
            },
        };
    }
    // Handle ValidationError from Joi
    if (error instanceof validation_1.ValidationError) {
        return {
            success: false,
            error: {
                code: ErrorCode.VALIDATION_ERROR,
                message: error.message,
                details: { validationErrors: error.details },
            },
        };
    }
    // Handle Firebase Functions HttpsError
    if (error instanceof functions.https.HttpsError) {
        return {
            success: false,
            error: {
                code: error.code.toUpperCase(),
                message: error.message,
                details: error.details,
            },
        };
    }
    // Handle standard Error
    if (error instanceof Error) {
        // Don't expose internal error messages in production
        const isProduction = process.env.NODE_ENV === "production";
        return {
            success: false,
            error: {
                code: ErrorCode.INTERNAL_ERROR,
                message: isProduction
                    ? "An unexpected error occurred"
                    : error.message,
            },
        };
    }
    // Handle unknown error types
    return {
        success: false,
        error: {
            code: ErrorCode.INTERNAL_ERROR,
            message: "An unexpected error occurred",
        },
    };
}
/**
 * Convert AppError to Firebase HttpsError for callable functions
 */
function toHttpsError(error) {
    if (error instanceof AppError) {
        const codeMap = {
            400: "invalid-argument",
            401: "unauthenticated",
            403: "permission-denied",
            404: "not-found",
            409: "already-exists",
            429: "resource-exhausted",
            500: "internal",
            502: "unavailable",
        };
        const functionsCode = codeMap[error.statusCode] || "unknown";
        return new functions.https.HttpsError(functionsCode, error.message, {
            code: error.code,
            details: error.details,
        });
    }
    if (error instanceof validation_1.ValidationError) {
        return new functions.https.HttpsError("invalid-argument", error.message, {
            code: ErrorCode.VALIDATION_ERROR,
            validationErrors: error.details,
        });
    }
    if (error instanceof functions.https.HttpsError) {
        return error;
    }
    // Log unexpected errors
    console.error("Unexpected error:", error);
    return new functions.https.HttpsError("internal", process.env.NODE_ENV === "production"
        ? "An unexpected error occurred"
        : (error instanceof Error ? error.message : "Unknown error"));
}
/**
 * Wrap an async function with error handling for callable functions
 */
function withErrorHandling(fn) {
    return async (data, context) => {
        try {
            return await fn(data, context);
        }
        catch (error) {
            throw toHttpsError(error);
        }
    };
}
/**
 * Assert a condition and throw if false
 */
function assert(condition, code, message, details) {
    if (!condition) {
        throw new AppError(code, message, 400, details);
    }
}
/**
 * Assert that a value exists and throw NotFoundError if not
 */
function assertExists(value, entity, id) {
    if (value === null || value === undefined) {
        throw new NotFoundError(entity, id);
    }
}
//# sourceMappingURL=errors.js.map