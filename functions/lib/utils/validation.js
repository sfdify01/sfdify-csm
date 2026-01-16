"use strict";
/**
 * Validation Utilities
 *
 * Provides Joi schemas for validating API inputs.
 * All inputs are validated before processing for security.
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.dateRangeSchema = exports.paginationSchema = exports.ValidationError = exports.createTenantSchema = exports.updateUserSchema = exports.createUserSchema = exports.sendLetterSchema = exports.generateLetterSchema = exports.updateDisputeSchema = exports.createDisputeSchema = exports.reasonDetailSchema = exports.updateConsumerSchema = exports.createConsumerSchema = exports.emailSchema = exports.phoneSchema = exports.addressSchema = exports.schemas = exports.US_STATES = void 0;
exports.validate = validate;
const joi_1 = __importDefault(require("joi"));
// ============================================================================
// Common Schema Components
// ============================================================================
/**
 * US State codes
 */
exports.US_STATES = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    "DC", "PR", "VI", "GU", "AS", "MP",
];
/**
 * Document ID pattern (alphanumeric with underscores)
 */
const documentIdPattern = /^[a-zA-Z0-9_-]+$/;
/**
 * Common field schemas
 */
exports.schemas = {
    documentId: joi_1.default.string().pattern(documentIdPattern).max(128),
    email: joi_1.default.string().email().max(254),
    phone: joi_1.default.string()
        .pattern(/^\+?[1-9]\d{1,14}$/)
        .message("Phone must be in E.164 format"),
    zipCode: joi_1.default.string()
        .pattern(/^\d{5}(-\d{4})?$/)
        .message("Invalid ZIP code format"),
    state: joi_1.default.string().valid(...exports.US_STATES),
    ssnLast4: joi_1.default.string()
        .pattern(/^\d{4}$/)
        .message("SSN last 4 must be exactly 4 digits"),
    date: joi_1.default.string()
        .pattern(/^\d{4}-\d{2}-\d{2}$/)
        .message("Date must be in YYYY-MM-DD format"),
    bureau: joi_1.default.string().valid("equifax", "experian", "transunion"),
    disputeType: joi_1.default.string().valid("611_dispute", "609_request", "605b_identity_theft", "reinvestigation", "goodwill", "pay_for_delete", "debt_validation", "cease_desist"),
    mailType: joi_1.default.string().valid("usps_first_class", "usps_certified", "usps_certified_return_receipt"),
    userRole: joi_1.default.string().valid("owner", "operator", "viewer", "auditor"),
    priority: joi_1.default.string().valid("low", "normal", "high", "urgent"),
};
// ============================================================================
// Address Schema
// ============================================================================
exports.addressSchema = joi_1.default.object({
    type: joi_1.default.string().valid("current", "previous", "mailing").required(),
    street1: joi_1.default.string().min(1).max(200).required(),
    street2: joi_1.default.string().max(200).allow(null, ""),
    city: joi_1.default.string().min(1).max(100).required(),
    state: exports.schemas.state.required(),
    zipCode: exports.schemas.zipCode.required(),
    country: joi_1.default.string().default("US"),
    moveInDate: exports.schemas.date,
    moveOutDate: exports.schemas.date,
    isPrimary: joi_1.default.boolean().default(false),
});
// ============================================================================
// Phone Schema
// ============================================================================
exports.phoneSchema = joi_1.default.object({
    type: joi_1.default.string().valid("mobile", "home", "work").required(),
    number: exports.schemas.phone.required(),
    isPrimary: joi_1.default.boolean().default(false),
});
// ============================================================================
// Email Schema
// ============================================================================
exports.emailSchema = joi_1.default.object({
    address: exports.schemas.email.required(),
    isPrimary: joi_1.default.boolean().default(false),
});
// ============================================================================
// Consumer Schemas
// ============================================================================
exports.createConsumerSchema = joi_1.default.object({
    firstName: joi_1.default.string().min(1).max(100).required(),
    lastName: joi_1.default.string().min(1).max(100).required(),
    dob: exports.schemas.date.required(),
    ssnLast4: exports.schemas.ssnLast4.required(),
    addresses: joi_1.default.array().items(exports.addressSchema).min(1).required(),
    phones: joi_1.default.array().items(exports.phoneSchema).min(1),
    emails: joi_1.default.array().items(exports.emailSchema).min(1),
    consent: joi_1.default.object({
        termsAccepted: joi_1.default.boolean().valid(true).required(),
        privacyAccepted: joi_1.default.boolean().valid(true).required(),
        fcraDisclosureAccepted: joi_1.default.boolean().valid(true).required(),
    }).required(),
});
exports.updateConsumerSchema = joi_1.default.object({
    addresses: joi_1.default.array().items(exports.addressSchema),
    phones: joi_1.default.array().items(exports.phoneSchema),
    emails: joi_1.default.array().items(exports.emailSchema),
}).min(1);
// ============================================================================
// Dispute Schemas
// ============================================================================
exports.reasonDetailSchema = joi_1.default.object({
    reportedValue: joi_1.default.alternatives().try(joi_1.default.string(), joi_1.default.number()),
    actualValue: joi_1.default.alternatives().try(joi_1.default.string(), joi_1.default.number()),
    reportedMonth: joi_1.default.string(),
    reportedStatus: joi_1.default.string(),
    actualStatus: joi_1.default.string(),
    explanation: joi_1.default.string().min(10).max(2000).required(),
});
exports.createDisputeSchema = joi_1.default.object({
    consumerId: exports.schemas.documentId.required(),
    tradelineId: exports.schemas.documentId.required(),
    bureau: exports.schemas.bureau.required(),
    type: exports.schemas.disputeType.required(),
    reasonCodes: joi_1.default.array().items(joi_1.default.string().max(50)).min(1).required(),
    reasonDetails: joi_1.default.object().pattern(joi_1.default.string(), exports.reasonDetailSchema),
    narrative: joi_1.default.string().min(50).max(5000),
    evidenceIds: joi_1.default.array().items(exports.schemas.documentId),
    priority: exports.schemas.priority.default("normal"),
    aiDraftAssist: joi_1.default.boolean().default(false),
});
exports.updateDisputeSchema = joi_1.default.object({
    narrative: joi_1.default.string().min(50).max(5000),
    priority: exports.schemas.priority,
    assignedTo: exports.schemas.documentId.allow(null),
    reasonCodes: joi_1.default.array().items(joi_1.default.string().max(50)).min(1),
    reasonDetails: joi_1.default.object().pattern(joi_1.default.string(), exports.reasonDetailSchema),
    internalNotes: joi_1.default.string().max(2000),
    tags: joi_1.default.array().items(joi_1.default.string().max(50)),
}).min(1);
// ============================================================================
// Letter Schemas
// ============================================================================
exports.generateLetterSchema = joi_1.default.object({
    templateId: exports.schemas.documentId.required(),
    mailType: exports.schemas.mailType.required(),
    customizations: joi_1.default.object({
        includeEvidenceIndex: joi_1.default.boolean().default(true),
        attachEvidence: joi_1.default.boolean().default(true),
        additionalText: joi_1.default.string().max(2000).allow(null, ""),
    }),
});
exports.sendLetterSchema = joi_1.default.object({
    mailType: exports.schemas.mailType,
    scheduledSendDate: joi_1.default.date().iso().greater("now").allow(null),
    idempotencyKey: joi_1.default.string().max(256).required(),
});
// ============================================================================
// User Schemas
// ============================================================================
exports.createUserSchema = joi_1.default.object({
    email: exports.schemas.email.required(),
    displayName: joi_1.default.string().min(1).max(100).required(),
    role: exports.schemas.userRole.required(),
    password: joi_1.default.string().min(8).max(128),
});
exports.updateUserSchema = joi_1.default.object({
    displayName: joi_1.default.string().min(1).max(100),
    role: exports.schemas.userRole,
    disabled: joi_1.default.boolean(),
}).min(1);
// ============================================================================
// Tenant Schemas
// ============================================================================
exports.createTenantSchema = joi_1.default.object({
    name: joi_1.default.string().min(1).max(200).required(),
    plan: joi_1.default.string().valid("starter", "professional", "enterprise").required(),
    branding: joi_1.default.object({
        primaryColor: joi_1.default.string().pattern(/^#[0-9A-Fa-f]{6}$/).default("#1E40AF"),
        companyName: joi_1.default.string().min(1).max(200).required(),
        tagline: joi_1.default.string().max(200),
    }).required(),
    lobConfig: joi_1.default.object({
        returnAddress: exports.addressSchema.required(),
        defaultMailType: exports.schemas.mailType.default("usps_first_class"),
    }).required(),
});
// ============================================================================
// Validation Helper Functions
// ============================================================================
/**
 * Validate data against a schema and throw if invalid
 */
function validate(schema, data) {
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
class ValidationError extends Error {
    details;
    constructor(message, details) {
        super(message);
        this.name = "ValidationError";
        this.details = details;
    }
}
exports.ValidationError = ValidationError;
/**
 * Validate pagination parameters
 */
exports.paginationSchema = joi_1.default.object({
    limit: joi_1.default.number().integer().min(1).max(100).default(50),
    cursor: joi_1.default.string().max(1000),
    offset: joi_1.default.number().integer().min(0),
});
/**
 * Validate date range parameters
 */
exports.dateRangeSchema = joi_1.default.object({
    startDate: exports.schemas.date,
    endDate: exports.schemas.date,
}).and("startDate", "endDate");
//# sourceMappingURL=validation.js.map