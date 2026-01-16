/**
 * Validation Utilities
 *
 * Provides Joi schemas for validating API inputs.
 * All inputs are validated before processing for security.
 */
import Joi from "joi";
import { Bureau, DisputeType, MailType, UserRole } from "../types";
/**
 * US State codes
 */
export declare const US_STATES: readonly ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "DC", "PR", "VI", "GU", "AS", "MP"];
/**
 * Common field schemas
 */
export declare const schemas: {
    documentId: Joi.StringSchema<string>;
    email: Joi.StringSchema<string>;
    phone: Joi.StringSchema<string>;
    zipCode: Joi.StringSchema<string>;
    state: Joi.StringSchema<string>;
    ssnLast4: Joi.StringSchema<string>;
    date: Joi.StringSchema<string>;
    bureau: Joi.StringSchema<Bureau>;
    disputeType: Joi.StringSchema<DisputeType>;
    mailType: Joi.StringSchema<MailType>;
    userRole: Joi.StringSchema<UserRole>;
    priority: Joi.StringSchema<string>;
};
export declare const addressSchema: Joi.ObjectSchema<any>;
export declare const phoneSchema: Joi.ObjectSchema<any>;
export declare const emailSchema: Joi.ObjectSchema<any>;
export declare const createConsumerSchema: Joi.ObjectSchema<any>;
export declare const updateConsumerSchema: Joi.ObjectSchema<any>;
export declare const reasonDetailSchema: Joi.ObjectSchema<any>;
export declare const createDisputeSchema: Joi.ObjectSchema<any>;
export declare const updateDisputeSchema: Joi.ObjectSchema<any>;
export declare const generateLetterSchema: Joi.ObjectSchema<any>;
export declare const sendLetterSchema: Joi.ObjectSchema<any>;
export declare const createUserSchema: Joi.ObjectSchema<any>;
export declare const updateUserSchema: Joi.ObjectSchema<any>;
export declare const createTenantSchema: Joi.ObjectSchema<any>;
/**
 * Validate data against a schema and throw if invalid
 */
export declare function validate<T>(schema: Joi.Schema<T>, data: unknown): T;
/**
 * Custom validation error class
 */
export declare class ValidationError extends Error {
    readonly details: Array<{
        field: string;
        message: string;
    }>;
    constructor(message: string, details: Array<{
        field: string;
        message: string;
    }>);
}
/**
 * Validate pagination parameters
 */
export declare const paginationSchema: Joi.ObjectSchema<any>;
/**
 * Validate date range parameters
 */
export declare const dateRangeSchema: Joi.ObjectSchema<any>;
//# sourceMappingURL=validation.d.ts.map