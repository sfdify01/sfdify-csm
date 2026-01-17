/**
 * Error Handling Utilities
 *
 * Provides standardized error types and handling for Cloud Functions.
 * All errors are converted to consistent API responses.
 */

import * as functions from "firebase-functions";
import { ValidationError } from "./validation";

/**
 * Error codes used throughout the application
 */
export enum ErrorCode {
  // General errors (1000-1099)
  INTERNAL_ERROR = "INTERNAL_ERROR",
  VALIDATION_ERROR = "VALIDATION_ERROR",
  NOT_FOUND = "NOT_FOUND",
  ALREADY_EXISTS = "ALREADY_EXISTS",
  RATE_LIMITED = "RATE_LIMITED",
  FORBIDDEN = "FORBIDDEN",

  // Authentication errors (1100-1199)
  UNAUTHENTICATED = "UNAUTHENTICATED",
  UNAUTHORIZED = "UNAUTHORIZED",
  INVALID_TOKEN = "INVALID_TOKEN",
  TOKEN_EXPIRED = "TOKEN_EXPIRED",
  INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS",

  // Tenant errors (1200-1299)
  TENANT_NOT_FOUND = "TENANT_NOT_FOUND",
  TENANT_SUSPENDED = "TENANT_SUSPENDED",
  TENANT_LIMIT_EXCEEDED = "TENANT_LIMIT_EXCEEDED",

  // Consumer errors (1300-1399)
  CONSUMER_NOT_FOUND = "CONSUMER_NOT_FOUND",
  CONSUMER_ALREADY_EXISTS = "CONSUMER_ALREADY_EXISTS",
  INVALID_CONSENT = "INVALID_CONSENT",

  // Integration errors (1400-1499)
  INTEGRATION_NOT_CONFIGURED = "INTEGRATION_NOT_CONFIGURED",
  INTEGRATION_ERROR = "INTEGRATION_ERROR",
  EXTERNAL_SERVICE_ERROR = "EXTERNAL_SERVICE_ERROR",
  SMARTCREDIT_NOT_CONNECTED = "SMARTCREDIT_NOT_CONNECTED",
  SMARTCREDIT_AUTH_FAILED = "SMARTCREDIT_AUTH_FAILED",
  SMARTCREDIT_TOKEN_EXPIRED = "SMARTCREDIT_TOKEN_EXPIRED",
  SMARTCREDIT_API_ERROR = "SMARTCREDIT_API_ERROR",
  SMARTCREDIT_RATE_LIMITED = "SMARTCREDIT_RATE_LIMITED",

  // Dispute errors (1500-1599)
  DISPUTE_NOT_FOUND = "DISPUTE_NOT_FOUND",
  INVALID_DISPUTE_STATUS = "INVALID_DISPUTE_STATUS",
  DISPUTE_ALREADY_CLOSED = "DISPUTE_ALREADY_CLOSED",
  TRADELINE_NOT_FOUND = "TRADELINE_NOT_FOUND",

  // Letter errors (1600-1699)
  LETTER_NOT_FOUND = "LETTER_NOT_FOUND",
  LETTER_ALREADY_SENT = "LETTER_ALREADY_SENT",
  INVALID_LETTER_STATUS = "INVALID_LETTER_STATUS",
  TEMPLATE_NOT_FOUND = "TEMPLATE_NOT_FOUND",
  PDF_GENERATION_FAILED = "PDF_GENERATION_FAILED",

  // Lob errors (1700-1799)
  LOB_API_ERROR = "LOB_API_ERROR",
  LOB_ADDRESS_INVALID = "LOB_ADDRESS_INVALID",
  LOB_RATE_LIMITED = "LOB_RATE_LIMITED",

  // Evidence errors (1800-1899)
  EVIDENCE_NOT_FOUND = "EVIDENCE_NOT_FOUND",
  FILE_TOO_LARGE = "FILE_TOO_LARGE",
  INVALID_FILE_TYPE = "INVALID_FILE_TYPE",
  VIRUS_DETECTED = "VIRUS_DETECTED",

  // Webhook errors (1900-1999)
  WEBHOOK_SIGNATURE_INVALID = "WEBHOOK_SIGNATURE_INVALID",
  WEBHOOK_PROCESSING_FAILED = "WEBHOOK_PROCESSING_FAILED",
}

/**
 * Base application error class
 */
export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly details?: Record<string, unknown>;
  public readonly isOperational: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    statusCode = 400,
    details?: Record<string, unknown>,
    isOperational = true
  ) {
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

/**
 * Authentication error
 */
export class AuthError extends AppError {
  constructor(code: ErrorCode = ErrorCode.UNAUTHENTICATED, message = "Authentication required") {
    super(code, message, 401);
    this.name = "AuthError";
  }
}

/**
 * Authorization error
 */
export class ForbiddenError extends AppError {
  constructor(message = "You do not have permission to perform this action") {
    super(ErrorCode.UNAUTHORIZED, message, 403);
    this.name = "ForbiddenError";
  }
}

/**
 * Not found error
 */
export class NotFoundError extends AppError {
  constructor(entity: string, id?: string) {
    const message = id
      ? `${entity} with id '${id}' not found`
      : `${entity} not found`;
    super(ErrorCode.NOT_FOUND, message, 404);
    this.name = "NotFoundError";
  }
}

/**
 * Conflict error (e.g., duplicate)
 */
export class ConflictError extends AppError {
  constructor(message: string) {
    super(ErrorCode.ALREADY_EXISTS, message, 409);
    this.name = "ConflictError";
  }
}

/**
 * Rate limit error
 */
export class RateLimitError extends AppError {
  constructor(message = "Rate limit exceeded. Please try again later.") {
    super(ErrorCode.RATE_LIMITED, message, 429);
    this.name = "RateLimitError";
  }
}

/**
 * External service error (SmartCredit, Lob, etc.)
 */
export class ExternalServiceError extends AppError {
  public readonly service: string;
  public readonly originalError?: Error;

  constructor(service: string, code: ErrorCode, message: string, originalError?: Error) {
    super(code, message, 502, { service, originalMessage: originalError?.message });
    this.name = "ExternalServiceError";
    this.service = service;
    this.originalError = originalError;
  }
}

/**
 * Convert any error to a standardized API response
 */
export function formatErrorResponse(error: unknown): {
  success: false;
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
} {
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
  if (error instanceof ValidationError) {
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
        details: error.details as Record<string, unknown> | undefined,
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
export function toHttpsError(error: unknown): functions.https.HttpsError {
  if (error instanceof AppError) {
    const codeMap: Record<number, functions.https.FunctionsErrorCode> = {
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

  if (error instanceof ValidationError) {
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

  return new functions.https.HttpsError(
    "internal",
    process.env.NODE_ENV === "production"
      ? "An unexpected error occurred"
      : (error instanceof Error ? error.message : "Unknown error")
  );
}

/**
 * Wrap an async function with error handling for callable functions
 */
export function withErrorHandling<T, R>(
  fn: (data: T, context: functions.https.CallableContext) => Promise<R>
): (data: T, context: functions.https.CallableContext) => Promise<R> {
  return async (data: T, context: functions.https.CallableContext) => {
    try {
      return await fn(data, context);
    } catch (error) {
      throw toHttpsError(error);
    }
  };
}

/**
 * Assert a condition and throw if false
 */
export function assert(
  condition: boolean,
  code: ErrorCode,
  message: string,
  details?: Record<string, unknown>
): asserts condition {
  if (!condition) {
    throw new AppError(code, message, 400, details);
  }
}

/**
 * Assert that a value exists and throw NotFoundError if not
 */
export function assertExists<T>(
  value: T | null | undefined,
  entity: string,
  id?: string
): asserts value is T {
  if (value === null || value === undefined) {
    throw new NotFoundError(entity, id);
  }
}
