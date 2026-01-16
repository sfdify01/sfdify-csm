/**
 * Application Configuration
 *
 * Central configuration for all Cloud Functions.
 * Uses Firebase Functions config() for secrets in production.
 */
export declare const isProduction: boolean;
export declare const isEmulator: boolean;
/**
 * Firebase project configuration
 */
export declare const firebaseConfig: {
    projectId: string;
    region: string;
    storageBucket: string;
};
/**
 * Cloud KMS configuration for PII encryption
 */
export declare const kmsConfig: {
    projectId: string;
    location: string;
    keyRing: string;
    cryptoKey: string;
    readonly keyName: string;
};
/**
 * SmartCredit API configuration
 */
export declare const smartCreditConfig: {
    baseUrl: string;
    clientId: any;
    clientSecret: any;
    webhookSecret: any;
    tokenExpiryBuffer: number;
    rateLimitPerMinute: number;
};
/**
 * Lob API configuration for mail services
 */
export declare const lobConfig: {
    baseUrl: string;
    apiKey: any;
    webhookSecret: any;
    rateLimitPerMinute: number;
};
/**
 * SendGrid configuration for email notifications
 */
export declare const sendgridConfig: {
    apiKey: any;
    fromEmail: string;
    fromName: string;
};
/**
 * Twilio configuration for SMS notifications
 */
export declare const twilioConfig: {
    accountSid: any;
    authToken: any;
    fromNumber: any;
};
/**
 * SLA configuration for dispute timelines
 */
export declare const slaConfig: {
    baseDays: number;
    extensionDays: number;
    reminderDays: number[];
    followUpGraceDays: number;
};
/**
 * File upload configuration
 */
export declare const uploadConfig: {
    maxFileSizeBytes: number;
    maxTotalSizePerDispute: number;
    allowedMimeTypes: string[];
    virusScanEnabled: boolean;
};
/**
 * Rate limiting configuration
 */
export declare const rateLimitConfig: {
    perUser: {
        requestsPerMinute: number;
        burstSize: number;
    };
    perTenant: {
        requestsPerMinute: number;
        burstSize: number;
    };
};
/**
 * Audit log retention configuration
 */
export declare const auditConfig: {
    retentionYears: number;
    sensitiveFieldsToRedact: string[];
};
/**
 * Bureau addresses for dispute letters
 */
export declare const BUREAU_ADDRESSES: {
    readonly equifax: {
        readonly name: "Equifax Information Services LLC";
        readonly addressLine1: "P.O. Box 740256";
        readonly city: "Atlanta";
        readonly state: "GA";
        readonly zipCode: "30374-0256";
    };
    readonly experian: {
        readonly name: "Experian";
        readonly addressLine1: "P.O. Box 4500";
        readonly city: "Allen";
        readonly state: "TX";
        readonly zipCode: "75013";
    };
    readonly transunion: {
        readonly name: "TransUnion LLC";
        readonly addressLine1: "P.O. Box 2000";
        readonly city: "Chester";
        readonly state: "PA";
        readonly zipCode: "19016";
    };
};
export type Bureau = keyof typeof BUREAU_ADDRESSES;
//# sourceMappingURL=index.d.ts.map