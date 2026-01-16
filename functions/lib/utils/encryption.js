"use strict";
/**
 * PII Encryption Utilities
 *
 * Provides encryption and decryption for Personally Identifiable Information (PII)
 * using Google Cloud KMS for FCRA/GLBA compliance.
 *
 * Encrypted values are prefixed with "enc:KMS:" to identify them.
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
exports.encryptPii = encryptPii;
exports.decryptPii = decryptPii;
exports.isEncrypted = isEncrypted;
exports.encryptPiiFields = encryptPiiFields;
exports.decryptPiiFields = decryptPiiFields;
exports.hashPii = hashPii;
exports.generateSecureToken = generateSecureToken;
exports.maskValue = maskValue;
const kms_1 = require("@google-cloud/kms");
const config_1 = require("../config");
const crypto = __importStar(require("crypto"));
// KMS Client - lazy initialized
let kmsClient = null;
// For emulator/local development - use AES with a static key
const LOCAL_ENCRYPTION_KEY = crypto.scryptSync(process.env.LOCAL_ENCRYPTION_SECRET || "local-dev-secret-key", "salt", 32);
const ENCRYPTION_ALGORITHM = "aes-256-gcm";
const IV_LENGTH = 16;
// Encryption prefixes
const KMS_PREFIX = "enc:KMS:";
const LOCAL_PREFIX = "enc:LOCAL:";
/**
 * Get or create the KMS client
 */
function getKmsClient() {
    if (!kmsClient) {
        kmsClient = new kms_1.KeyManagementServiceClient();
    }
    return kmsClient;
}
/**
 * Encrypt a value using Cloud KMS (production) or local AES (development)
 *
 * @param plaintext - The value to encrypt
 * @returns Encrypted value with appropriate prefix
 */
async function encryptPii(plaintext) {
    if (!plaintext) {
        return plaintext;
    }
    // Already encrypted
    if (plaintext.startsWith(KMS_PREFIX) || plaintext.startsWith(LOCAL_PREFIX)) {
        return plaintext;
    }
    if (config_1.isEmulator) {
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
async function decryptPii(ciphertext) {
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
async function encryptWithKms(plaintext) {
    const client = getKmsClient();
    const [result] = await client.encrypt({
        name: config_1.kmsConfig.keyName,
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
async function decryptWithKms(ciphertext) {
    const client = getKmsClient();
    const encoded = ciphertext.replace(KMS_PREFIX, "");
    const [result] = await client.decrypt({
        name: config_1.kmsConfig.keyName,
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
function encryptLocal(plaintext) {
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
function decryptLocal(ciphertext) {
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
function isEncrypted(value) {
    return value?.startsWith(KMS_PREFIX) || value?.startsWith(LOCAL_PREFIX);
}
/**
 * Encrypt multiple PII fields in an object
 *
 * @param data - Object containing PII fields
 * @param fields - Array of field names to encrypt
 * @returns Object with specified fields encrypted
 */
async function encryptPiiFields(data, fields) {
    const result = { ...data };
    for (const field of fields) {
        const value = result[field];
        if (typeof value === "string") {
            result[field] = await encryptPii(value);
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
async function decryptPiiFields(data, fields) {
    const result = { ...data };
    for (const field of fields) {
        const value = result[field];
        if (typeof value === "string" && isEncrypted(value)) {
            result[field] = await decryptPii(value);
        }
    }
    return result;
}
/**
 * Hash a value for comparison (one-way)
 * Used for duplicate detection without exposing PII
 */
function hashPii(value) {
    return crypto
        .createHash("sha256")
        .update(value.toLowerCase().trim())
        .digest("hex");
}
/**
 * Generate a secure random token
 */
function generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString("hex");
}
/**
 * Mask a value for display (e.g., SSN: ****1234)
 */
function maskValue(value, visibleChars = 4, maskChar = "*") {
    if (!value || value.length <= visibleChars) {
        return value;
    }
    const masked = maskChar.repeat(value.length - visibleChars);
    const visible = value.slice(-visibleChars);
    return masked + visible;
}
//# sourceMappingURL=encryption.js.map