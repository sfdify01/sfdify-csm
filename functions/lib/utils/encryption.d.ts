/**
 * PII Encryption Utilities
 *
 * Provides encryption and decryption for Personally Identifiable Information (PII)
 * using Google Cloud KMS for FCRA/GLBA compliance.
 *
 * Encrypted values are prefixed with "enc:KMS:" to identify them.
 */
/**
 * Encrypt a value using Cloud KMS (production) or local AES (development)
 *
 * @param plaintext - The value to encrypt
 * @returns Encrypted value with appropriate prefix
 */
export declare function encryptPii(plaintext: string): Promise<string>;
/**
 * Decrypt a value using Cloud KMS (production) or local AES (development)
 *
 * @param ciphertext - The encrypted value
 * @returns Decrypted plaintext
 */
export declare function decryptPii(ciphertext: string): Promise<string>;
/**
 * Check if a value is encrypted
 */
export declare function isEncrypted(value: string): boolean;
/**
 * Encrypt multiple PII fields in an object
 *
 * @param data - Object containing PII fields
 * @param fields - Array of field names to encrypt
 * @returns Object with specified fields encrypted
 */
export declare function encryptPiiFields<T extends Record<string, unknown>>(data: T, fields: (keyof T)[]): Promise<T>;
/**
 * Decrypt multiple PII fields in an object
 *
 * @param data - Object containing encrypted PII fields
 * @param fields - Array of field names to decrypt
 * @returns Object with specified fields decrypted
 */
export declare function decryptPiiFields<T extends Record<string, unknown>>(data: T, fields: (keyof T)[]): Promise<T>;
/**
 * Hash a value for comparison (one-way)
 * Used for duplicate detection without exposing PII
 */
export declare function hashPii(value: string): string;
/**
 * Generate a secure random token
 */
export declare function generateSecureToken(length?: number): string;
/**
 * Mask a value for display (e.g., SSN: ****1234)
 */
export declare function maskValue(value: string, visibleChars?: number, maskChar?: string): string;
//# sourceMappingURL=encryption.d.ts.map