/**
 * PII Encryption Utilities
 *
 * Provides encryption and decryption for Personally Identifiable Information (PII)
 * using Google Cloud KMS for FCRA/GLBA compliance.
 *
 * Encrypted values are prefixed with "enc:KMS:" to identify them.
 */

import { KeyManagementServiceClient } from "@google-cloud/kms";
import { kmsConfig, isEmulator } from "../config";
import * as crypto from "crypto";

// KMS Client - lazy initialized
let kmsClient: KeyManagementServiceClient | null = null;

// For emulator/local development - use AES with a static key
const LOCAL_ENCRYPTION_KEY = crypto.scryptSync(
  process.env.LOCAL_ENCRYPTION_SECRET || "local-dev-secret-key",
  "salt",
  32
);
const ENCRYPTION_ALGORITHM = "aes-256-gcm";
const IV_LENGTH = 16;

// Encryption prefixes
const KMS_PREFIX = "enc:KMS:";
const LOCAL_PREFIX = "enc:LOCAL:";

/**
 * Get or create the KMS client
 */
function getKmsClient(): KeyManagementServiceClient {
  if (!kmsClient) {
    kmsClient = new KeyManagementServiceClient();
  }
  return kmsClient;
}

/**
 * Encrypt a value using Cloud KMS (production) or local AES (development)
 *
 * @param plaintext - The value to encrypt
 * @returns Encrypted value with appropriate prefix
 */
export async function encryptPii(plaintext: string): Promise<string> {
  if (!plaintext) {
    return plaintext;
  }

  // Already encrypted
  if (plaintext.startsWith(KMS_PREFIX) || plaintext.startsWith(LOCAL_PREFIX)) {
    return plaintext;
  }

  if (isEmulator) {
    return encryptLocal(plaintext);
  }

  return encryptWithKms(plaintext);
}

/**
 * Decrypt a value using Cloud KMS (production) or local AES (development)
 *
 * @param ciphertext - The encrypted value
 * @returns Decrypted plaintext
 */
export async function decryptPii(ciphertext: string): Promise<string> {
  if (!ciphertext) {
    return ciphertext;
  }

  if (ciphertext.startsWith(KMS_PREFIX)) {
    return decryptWithKms(ciphertext);
  }

  if (ciphertext.startsWith(LOCAL_PREFIX)) {
    return decryptLocal(ciphertext);
  }

  // Not encrypted - return as-is (for backward compatibility during migration)
  return ciphertext;
}

/**
 * Encrypt using Google Cloud KMS
 */
async function encryptWithKms(plaintext: string): Promise<string> {
  const client = getKmsClient();

  const [result] = await client.encrypt({
    name: kmsConfig.keyName,
    plaintext: Buffer.from(plaintext, "utf8"),
  });

  if (!result.ciphertext) {
    throw new Error("KMS encryption returned no ciphertext");
  }

  const ciphertextBase64 = Buffer.from(result.ciphertext).toString("base64");
  return `${KMS_PREFIX}${ciphertextBase64}`;
}

/**
 * Decrypt using Google Cloud KMS
 */
async function decryptWithKms(ciphertext: string): Promise<string> {
  const client = getKmsClient();
  const encoded = ciphertext.replace(KMS_PREFIX, "");

  const [result] = await client.decrypt({
    name: kmsConfig.keyName,
    ciphertext: Buffer.from(encoded, "base64"),
  });

  if (!result.plaintext) {
    throw new Error("KMS decryption returned no plaintext");
  }

  return Buffer.from(result.plaintext).toString("utf8");
}

/**
 * Encrypt using local AES-256-GCM (for development/emulator)
 */
function encryptLocal(plaintext: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ENCRYPTION_ALGORITHM, LOCAL_ENCRYPTION_KEY, iv);

  let encrypted = cipher.update(plaintext, "utf8", "hex");
  encrypted += cipher.final("hex");

  const authTag = cipher.getAuthTag();

  // Format: iv:authTag:encrypted
  const combined = `${iv.toString("hex")}:${authTag.toString("hex")}:${encrypted}`;
  return `${LOCAL_PREFIX}${Buffer.from(combined).toString("base64")}`;
}

/**
 * Decrypt using local AES-256-GCM (for development/emulator)
 */
function decryptLocal(ciphertext: string): string {
  const encoded = ciphertext.replace(LOCAL_PREFIX, "");
  const combined = Buffer.from(encoded, "base64").toString("utf8");

  const [ivHex, authTagHex, encrypted] = combined.split(":");

  if (!ivHex || !authTagHex || !encrypted) {
    throw new Error("Invalid local encrypted format");
  }

  const iv = Buffer.from(ivHex, "hex");
  const authTag = Buffer.from(authTagHex, "hex");

  const decipher = crypto.createDecipheriv(ENCRYPTION_ALGORITHM, LOCAL_ENCRYPTION_KEY, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, "hex", "utf8");
  decrypted += decipher.final("utf8");

  return decrypted;
}

/**
 * Check if a value is encrypted
 */
export function isEncrypted(value: string): boolean {
  return value?.startsWith(KMS_PREFIX) || value?.startsWith(LOCAL_PREFIX);
}

/**
 * Encrypt multiple PII fields in an object
 *
 * @param data - Object containing PII fields
 * @param fields - Array of field names to encrypt
 * @returns Object with specified fields encrypted
 */
export async function encryptPiiFields<T extends Record<string, unknown>>(
  data: T,
  fields: (keyof T)[]
): Promise<T> {
  const result = { ...data };

  for (const field of fields) {
    const value = result[field];
    if (typeof value === "string") {
      result[field] = await encryptPii(value) as T[keyof T];
    }
  }

  return result;
}

/**
 * Decrypt multiple PII fields in an object
 *
 * @param data - Object containing encrypted PII fields
 * @param fields - Array of field names to decrypt
 * @returns Object with specified fields decrypted
 */
export async function decryptPiiFields<T extends Record<string, unknown>>(
  data: T,
  fields: (keyof T)[]
): Promise<T> {
  const result = { ...data };

  for (const field of fields) {
    const value = result[field];
    if (typeof value === "string" && isEncrypted(value)) {
      result[field] = await decryptPii(value) as T[keyof T];
    }
  }

  return result;
}

/**
 * Hash a value for comparison (one-way)
 * Used for duplicate detection without exposing PII
 */
export function hashPii(value: string): string {
  return crypto
    .createHash("sha256")
    .update(value.toLowerCase().trim())
    .digest("hex");
}

/**
 * Generate a secure random token
 */
export function generateSecureToken(length = 32): string {
  return crypto.randomBytes(length).toString("hex");
}

/**
 * Mask a value for display (e.g., SSN: ****1234)
 */
export function maskValue(value: string, visibleChars = 4, maskChar = "*"): string {
  if (!value || value.length <= visibleChars) {
    return value;
  }

  const masked = maskChar.repeat(value.length - visibleChars);
  const visible = value.slice(-visibleChars);
  return masked + visible;
}
