/**
 * Validation Utilities
 *
 * Provides Joi schemas for validating API inputs.
 * All inputs are validated before processing for security.
 */

import Joi from "joi";
import { Bureau, DisputeType, MailType, UserRole } from "../types";

// ============================================================================
// Common Schema Components
// ============================================================================

/**
 * US State codes
 */
export const US_STATES = [
  "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
  "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
  "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
  "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
  "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
  "DC", "PR", "VI", "GU", "AS", "MP",
] as const;

/**
 * Document ID pattern (alphanumeric with underscores)
 */
const documentIdPattern = /^[a-zA-Z0-9_-]+$/;

/**
 * Common field schemas
 */
export const schemas = {
  documentId: Joi.string().pattern(documentIdPattern).max(128),

  email: Joi.string().email().max(254),

  phone: Joi.string()
    .pattern(/^\+?[1-9]\d{1,14}$/)
    .message("Phone must be in E.164 format"),

  zipCode: Joi.string()
    .pattern(/^\d{5}(-\d{4})?$/)
    .message("Invalid ZIP code format"),

  state: Joi.string().valid(...US_STATES),

  ssnLast4: Joi.string()
    .pattern(/^\d{4}$/)
    .message("SSN last 4 must be exactly 4 digits"),

  date: Joi.string()
    .pattern(/^\d{4}-\d{2}-\d{2}$/)
    .message("Date must be in YYYY-MM-DD format"),

  bureau: Joi.string().valid("equifax", "experian", "transunion") as Joi.StringSchema<Bureau>,

  disputeType: Joi.string().valid(
    "611_dispute",
    "609_request",
    "605b_identity_theft",
    "reinvestigation",
    "goodwill",
    "pay_for_delete",
    "debt_validation",
    "cease_desist"
  ) as Joi.StringSchema<DisputeType>,

  mailType: Joi.string().valid(
    "usps_first_class",
    "usps_certified",
    "usps_certified_return_receipt"
  ) as Joi.StringSchema<MailType>,

  userRole: Joi.string().valid("owner", "operator", "viewer", "auditor") as Joi.StringSchema<UserRole>,

  priority: Joi.string().valid("low", "normal", "high", "urgent"),
};

// ============================================================================
// Address Schema
// ============================================================================

export const addressSchema = Joi.object({
  type: Joi.string().valid("current", "previous", "mailing").required(),
  street1: Joi.string().min(1).max(200).required(),
  street2: Joi.string().max(200).allow(null, ""),
  city: Joi.string().min(1).max(100).required(),
  state: schemas.state.required(),
  zipCode: schemas.zipCode.required(),
  country: Joi.string().default("US"),
  moveInDate: schemas.date,
  moveOutDate: schemas.date,
  isPrimary: Joi.boolean().default(false),
});

// ============================================================================
// Phone Schema
// ============================================================================

export const phoneSchema = Joi.object({
  type: Joi.string().valid("mobile", "home", "work").required(),
  number: schemas.phone.required(),
  isPrimary: Joi.boolean().default(false),
});

// ============================================================================
// Email Schema
// ============================================================================

export const emailSchema = Joi.object({
  address: schemas.email.required(),
  isPrimary: Joi.boolean().default(false),
});

// ============================================================================
// Consumer Schemas
// ============================================================================

export const createConsumerSchema = Joi.object({
  firstName: Joi.string().min(1).max(100).required(),
  lastName: Joi.string().min(1).max(100).required(),
  dob: schemas.date.required(),
  ssnLast4: schemas.ssnLast4.required(),
  addresses: Joi.array().items(addressSchema).min(1).required(),
  phones: Joi.array().items(phoneSchema).min(1),
  emails: Joi.array().items(emailSchema).min(1),
  consent: Joi.object({
    termsAccepted: Joi.boolean().valid(true).required(),
    privacyAccepted: Joi.boolean().valid(true).required(),
    fcraDisclosureAccepted: Joi.boolean().valid(true).required(),
  }).required(),
});

export const updateConsumerSchema = Joi.object({
  addresses: Joi.array().items(addressSchema),
  phones: Joi.array().items(phoneSchema),
  emails: Joi.array().items(emailSchema),
}).min(1);

// ============================================================================
// Dispute Schemas
// ============================================================================

export const reasonDetailSchema = Joi.object({
  reportedValue: Joi.alternatives().try(Joi.string(), Joi.number()),
  actualValue: Joi.alternatives().try(Joi.string(), Joi.number()),
  reportedMonth: Joi.string(),
  reportedStatus: Joi.string(),
  actualStatus: Joi.string(),
  explanation: Joi.string().min(10).max(2000).required(),
});

export const createDisputeSchema = Joi.object({
  consumerId: schemas.documentId.required(),
  tradelineId: schemas.documentId.required(),
  bureau: schemas.bureau.required(),
  type: schemas.disputeType.required(),
  reasonCodes: Joi.array().items(Joi.string().max(50)).min(1).required(),
  reasonDetails: Joi.object().pattern(Joi.string(), reasonDetailSchema),
  narrative: Joi.string().min(50).max(5000),
  evidenceIds: Joi.array().items(schemas.documentId),
  priority: schemas.priority.default("normal"),
  aiDraftAssist: Joi.boolean().default(false),
});

export const updateDisputeSchema = Joi.object({
  narrative: Joi.string().min(50).max(5000),
  priority: schemas.priority,
  assignedTo: schemas.documentId.allow(null),
  reasonCodes: Joi.array().items(Joi.string().max(50)).min(1),
  reasonDetails: Joi.object().pattern(Joi.string(), reasonDetailSchema),
  internalNotes: Joi.string().max(2000),
  tags: Joi.array().items(Joi.string().max(50)),
}).min(1);

// ============================================================================
// Letter Schemas
// ============================================================================

export const generateLetterSchema = Joi.object({
  templateId: schemas.documentId.required(),
  mailType: schemas.mailType.required(),
  customizations: Joi.object({
    includeEvidenceIndex: Joi.boolean().default(true),
    attachEvidence: Joi.boolean().default(true),
    additionalText: Joi.string().max(2000).allow(null, ""),
  }),
});

export const sendLetterSchema = Joi.object({
  mailType: schemas.mailType,
  scheduledSendDate: Joi.date().iso().greater("now").allow(null),
  idempotencyKey: Joi.string().max(256).required(),
});

// ============================================================================
// User Schemas
// ============================================================================

export const createUserSchema = Joi.object({
  email: schemas.email.required(),
  displayName: Joi.string().min(1).max(100).required(),
  role: schemas.userRole.required(),
  password: Joi.string().min(8).max(128),
});

export const updateUserSchema = Joi.object({
  displayName: Joi.string().min(1).max(100),
  role: schemas.userRole,
  disabled: Joi.boolean(),
}).min(1);

// ============================================================================
// Tenant Schemas
// ============================================================================

export const createTenantSchema = Joi.object({
  name: Joi.string().min(1).max(200).required(),
  plan: Joi.string().valid("starter", "professional", "enterprise").required(),
  branding: Joi.object({
    primaryColor: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).default("#1E40AF"),
    companyName: Joi.string().min(1).max(200).required(),
    tagline: Joi.string().max(200),
  }).required(),
  lobConfig: Joi.object({
    returnAddress: addressSchema.required(),
    defaultMailType: schemas.mailType.default("usps_first_class"),
  }).required(),
});

// ============================================================================
// Validation Helper Functions
// ============================================================================

/**
 * Validate data against a schema and throw if invalid
 */
export function validate<T>(
  schema: Joi.Schema<T>,
  data: unknown
): T {
  const { error, value } = schema.validate(data, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const details = error.details.map((d) => ({
      field: d.path.join("."),
      message: d.message,
    }));

    throw new ValidationError("Validation failed", details);
  }

  return value;
}

/**
 * Custom validation error class
 */
export class ValidationError extends Error {
  public readonly details: Array<{ field: string; message: string }>;

  constructor(message: string, details: Array<{ field: string; message: string }>) {
    super(message);
    this.name = "ValidationError";
    this.details = details;
  }
}

/**
 * Validate pagination parameters
 */
export const paginationSchema = Joi.object({
  limit: Joi.number().integer().min(1).max(100).default(50),
  cursor: Joi.string().max(1000),
  offset: Joi.number().integer().min(0),
});

/**
 * Validate date range parameters
 */
export const dateRangeSchema = Joi.object({
  startDate: schemas.date,
  endDate: schemas.date,
}).and("startDate", "endDate");
