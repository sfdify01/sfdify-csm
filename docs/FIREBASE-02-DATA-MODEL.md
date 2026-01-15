# SFDIFY Credit Dispute System - Firebase Data Model

## Document Info
| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-01-15 | SFDIFY Team |

---

## 1. Overview

This document defines the complete Firestore data model for the SFDIFY Credit Dispute System. Firestore is a NoSQL document database that stores data in collections of documents.

### 1.1 Design Principles

1. **Denormalization** - Duplicate data to reduce reads
2. **Flat Structure** - Avoid deep nesting (max 2 levels)
3. **Tenant Isolation** - Every document includes `tenantId`
4. **Audit Trail** - Track `createdAt`, `updatedAt`, `createdBy`, `updatedBy`
5. **Soft Deletes** - Use `deletedAt` instead of hard deletes for compliance

### 1.2 Naming Conventions

- Collection names: `camelCase`, plural (e.g., `consumers`, `disputes`)
- Document fields: `camelCase` (e.g., `firstName`, `createdAt`)
- IDs: Auto-generated Firestore IDs or prefixed custom IDs (e.g., `tenant_abc123`)

---

## 2. Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           FIRESTORE DATA MODEL                                       │
│                                                                                      │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐                 │
│  │   tenants    │────────►│    users     │         │letterTemplates│                │
│  │              │         │              │         │              │                  │
│  │ • id         │         │ • id         │         │ • id         │                 │
│  │ • name       │         │ • tenantId   │         │ • tenantId   │                 │
│  │ • plan       │         │ • email      │         │ • name       │                 │
│  │ • settings   │         │ • role       │         │ • type       │                 │
│  └──────────────┘         └──────────────┘         │ • content    │                 │
│         │                        │                 └──────────────┘                  │
│         │                        │                        │                          │
│         ▼                        ▼                        │                          │
│  ┌──────────────┐         ┌──────────────┐               │                          │
│  │  consumers   │◄────────│              │               │                          │
│  │              │         │              │               │                          │
│  │ • id         │         │              │               │                          │
│  │ • tenantId   │         │              │               ▼                          │
│  │ • firstName  │         │              │        ┌──────────────┐                  │
│  │ • lastName   │         │              │        │   letters    │                  │
│  │ • ssnEncrypt │         │              │        │              │                  │
│  └──────────────┘         │              │        │ • id         │                  │
│         │                 │              │        │ • tenantId   │                  │
│         │                 │              │        │ • disputeId  │                  │
│         ▼                 │              │        │ • templateId │                  │
│  ┌──────────────┐         │              │        │ • status     │                  │
│  │smartcredit   │         │              │        └──────────────┘                  │
│  │Connections   │         │              │               │                          │
│  │              │         │              │               │                          │
│  │ • consumerId │         │              │               ▼                          │
│  │ • accessToken│         │              │        ┌──────────────┐                  │
│  │ • status     │         │              │        │   mailings   │                  │
│  └──────────────┘         │              │        │              │                  │
│         │                 │              │        │ • letterId   │                  │
│         ▼                 │              │        │ • lobId      │                  │
│  ┌──────────────┐         │              │        │ • status     │                  │
│  │creditReports │         │   disputes   │        │ • events     │                  │
│  │              │         │              │        └──────────────┘                  │
│  │ • consumerId │────────►│ • consumerId │                                          │
│  │ • reportData │         │ • creditReportId                                        │
│  │ • bureaus    │         │ • status     │                                          │
│  └──────────────┘         │ • tradelineId│        ┌──────────────┐                  │
│         │                 │              │        │   evidence   │                  │
│         ▼                 │              │◄───────│              │                  │
│  ┌──────────────┐         │              │        │ • disputeId  │                  │
│  │  tradelines  │────────►│              │        │ • type       │                  │
│  │              │         │              │        │ • fileUrl    │                  │
│  │ • reportId   │         └──────────────┘        └──────────────┘                  │
│  │ • creditor   │                │                                                   │
│  │ • accountNum │                │                                                   │
│  │ • balance    │                ▼                                                   │
│  └──────────────┘         ┌──────────────┐        ┌──────────────┐                  │
│                           │disputeTasks  │        │  auditLogs   │                  │
│                           │              │        │              │                  │
│                           │ • disputeId  │        │ • tenantId   │                  │
│                           │ • name       │        │ • userId     │                  │
│                           │ • status     │        │ • action     │                  │
│                           └──────────────┘        │ • details    │                  │
│                                                   └──────────────┘                  │
│                                                                                      │
│  ┌──────────────┐         ┌──────────────┐                                          │
│  │webhookEvents │         │notifications │                                          │
│  │              │         │              │                                           │
│  │ • source     │         │ • userId     │                                          │
│  │ • eventType  │         │ • title      │                                          │
│  │ • payload    │         │ • read       │                                          │
│  └──────────────┘         └──────────────┘                                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Collection Schemas

### 3.1 tenants

Represents a tenant (company/organization) in the multi-tenant system.

**Collection Path:** `/tenants/{tenantId}`

```typescript
interface Tenant {
  // Identity
  id: string;                    // Auto-generated or custom (e.g., "tenant_abc123")
  name: string;                  // Company name
  slug: string;                  // URL-friendly identifier (unique)

  // Contact
  email: string;                 // Primary contact email
  phone: string | null;          // Contact phone
  website: string | null;        // Company website

  // Address
  address: {
    street1: string;
    street2: string | null;
    city: string;
    state: string;               // 2-letter state code
    zipCode: string;
    country: string;             // Default: "US"
  };

  // Subscription
  plan: "free" | "starter" | "professional" | "enterprise";
  planStartedAt: Timestamp;
  planExpiresAt: Timestamp | null;
  billingEmail: string;

  // Usage Limits
  limits: {
    maxUsers: number;            // -1 for unlimited
    maxConsumers: number;        // -1 for unlimited
    maxDisputesPerMonth: number; // -1 for unlimited
    maxLettersPerMonth: number;  // -1 for unlimited
  };

  // Current Usage (reset monthly)
  usage: {
    currentMonth: string;        // "2024-01"
    disputesCreated: number;
    lettersSent: number;
    creditPulls: number;
  };

  // Settings
  settings: {
    defaultLetterFormat: "standard" | "certified";
    autoGenerateLetters: boolean;
    requireApprovalBeforeSend: boolean;
    slaWarningDays: number;      // Days before SLA to warn (default: 5)
    timezone: string;            // e.g., "America/New_York"
  };

  // Integrations
  integrations: {
    smartcredit: {
      enabled: boolean;
      clientId: string | null;
      // clientSecret stored in Secret Manager
    };
    lob: {
      enabled: boolean;
      // apiKey stored in Secret Manager
    };
  };

  // Status
  status: "active" | "suspended" | "cancelled";
  suspendedReason: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: Timestamp | null;
}
```

**Example Document:**

```json
{
  "id": "tenant_abc123",
  "name": "Credit Repair Pro LLC",
  "slug": "credit-repair-pro",
  "email": "admin@creditrepairpro.com",
  "phone": "+1-555-123-4567",
  "website": "https://creditrepairpro.com",
  "address": {
    "street1": "123 Main Street",
    "street2": "Suite 400",
    "city": "Atlanta",
    "state": "GA",
    "zipCode": "30301",
    "country": "US"
  },
  "plan": "professional",
  "planStartedAt": "2024-01-01T00:00:00Z",
  "planExpiresAt": "2025-01-01T00:00:00Z",
  "billingEmail": "billing@creditrepairpro.com",
  "limits": {
    "maxUsers": 10,
    "maxConsumers": 500,
    "maxDisputesPerMonth": 1000,
    "maxLettersPerMonth": 3000
  },
  "usage": {
    "currentMonth": "2024-01",
    "disputesCreated": 45,
    "lettersSent": 120,
    "creditPulls": 30
  },
  "settings": {
    "defaultLetterFormat": "certified",
    "autoGenerateLetters": true,
    "requireApprovalBeforeSend": true,
    "slaWarningDays": 5,
    "timezone": "America/New_York"
  },
  "integrations": {
    "smartcredit": {
      "enabled": true,
      "clientId": "sc_client_xyz"
    },
    "lob": {
      "enabled": true
    }
  },
  "status": "active",
  "suspendedReason": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "deletedAt": null
}
```

**Indexes:**

```
- slug (unique)
- status, plan
- createdAt (descending)
```

---

### 3.2 users

Represents a user account in the system.

**Collection Path:** `/users/{userId}`

```typescript
interface User {
  // Identity
  id: string;                    // Firebase Auth UID
  tenantId: string;              // Reference to tenant
  email: string;                 // Email (unique per tenant)
  emailVerified: boolean;

  // Profile
  firstName: string;
  lastName: string;
  displayName: string;           // Computed: firstName + lastName
  phone: string | null;
  avatarUrl: string | null;

  // Role & Permissions
  role: "owner" | "operator" | "viewer" | "auditor";
  permissions: string[];         // Granular permissions

  // Security
  mfaEnabled: boolean;
  lastLoginAt: Timestamp | null;
  lastLoginIp: string | null;
  failedLoginAttempts: number;
  lockedUntil: Timestamp | null;

  // Preferences
  preferences: {
    theme: "light" | "dark" | "system";
    language: string;            // e.g., "en-US"
    notifications: {
      email: boolean;
      push: boolean;
      slaWarnings: boolean;
      disputeUpdates: boolean;
    };
  };

  // Status
  status: "active" | "inactive" | "locked";

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: Timestamp | null;
  createdBy: string;             // User ID who created this user
}
```

**Example Document:**

```json
{
  "id": "user_xyz789",
  "tenantId": "tenant_abc123",
  "email": "john.doe@creditrepairpro.com",
  "emailVerified": true,
  "firstName": "John",
  "lastName": "Doe",
  "displayName": "John Doe",
  "phone": "+1-555-987-6543",
  "avatarUrl": null,
  "role": "operator",
  "permissions": [
    "consumers:read",
    "consumers:write",
    "disputes:read",
    "disputes:write",
    "letters:read",
    "letters:write"
  ],
  "mfaEnabled": false,
  "lastLoginAt": "2024-01-15T08:00:00Z",
  "lastLoginIp": "192.168.1.100",
  "failedLoginAttempts": 0,
  "lockedUntil": null,
  "preferences": {
    "theme": "light",
    "language": "en-US",
    "notifications": {
      "email": true,
      "push": true,
      "slaWarnings": true,
      "disputeUpdates": true
    }
  },
  "status": "active",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T08:00:00Z",
  "deletedAt": null,
  "createdBy": "user_owner123"
}
```

**Indexes:**

```
- tenantId, email (unique composite)
- tenantId, role
- tenantId, status
- lastLoginAt (descending)
```

---

### 3.3 consumers

Represents a consumer (client) whose credit is being disputed.

**Collection Path:** `/consumers/{consumerId}`

```typescript
interface Consumer {
  // Identity
  id: string;
  tenantId: string;

  // Personal Information
  firstName: string;
  lastName: string;
  middleName: string | null;
  suffix: string | null;         // Jr., Sr., III, etc.
  displayName: string;           // Computed full name

  // PII (Encrypted)
  ssnEncrypted: string;          // AES-256 encrypted
  ssnLast4: string;              // Last 4 digits for display
  dobEncrypted: string;          // AES-256 encrypted

  // Contact
  email: string;
  phone: string;
  alternatePhone: string | null;

  // Current Address
  currentAddress: {
    street1: string;
    street2: string | null;
    city: string;
    state: string;
    zipCode: string;
    country: string;
    moveInDate: Timestamp | null;
  };

  // Previous Addresses (for credit bureau matching)
  previousAddresses: Array<{
    street1: string;
    street2: string | null;
    city: string;
    state: string;
    zipCode: string;
    country: string;
    fromDate: Timestamp | null;
    toDate: Timestamp | null;
  }>;

  // SmartCredit Connection
  smartcreditStatus: "not_connected" | "pending" | "connected" | "expired" | "error";
  smartcreditConnectedAt: Timestamp | null;

  // Statistics (denormalized for quick access)
  stats: {
    totalDisputes: number;
    activeDisputes: number;
    resolvedDisputes: number;
    successfulDisputes: number;
    totalLettersSent: number;
    lastCreditPullAt: Timestamp | null;
  };

  // Status
  status: "active" | "inactive" | "archived";

  // Notes
  internalNotes: string | null;

  // Consent
  consent: {
    creditPull: boolean;
    creditPullAt: Timestamp | null;
    electronicCommunication: boolean;
    electronicCommunicationAt: Timestamp | null;
    termsOfService: boolean;
    termsOfServiceAt: Timestamp | null;
    privacyPolicy: boolean;
    privacyPolicyAt: Timestamp | null;
  };

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: Timestamp | null;
  createdBy: string;
  updatedBy: string;
}
```

**Example Document:**

```json
{
  "id": "consumer_def456",
  "tenantId": "tenant_abc123",
  "firstName": "Jane",
  "lastName": "Smith",
  "middleName": "Marie",
  "suffix": null,
  "displayName": "Jane Marie Smith",
  "ssnEncrypted": "encrypted_base64_string...",
  "ssnLast4": "4567",
  "dobEncrypted": "encrypted_base64_string...",
  "email": "jane.smith@email.com",
  "phone": "+1-555-111-2222",
  "alternatePhone": null,
  "currentAddress": {
    "street1": "456 Oak Avenue",
    "street2": "Apt 12B",
    "city": "Miami",
    "state": "FL",
    "zipCode": "33101",
    "country": "US",
    "moveInDate": "2022-06-01T00:00:00Z"
  },
  "previousAddresses": [
    {
      "street1": "789 Pine Street",
      "street2": null,
      "city": "Orlando",
      "state": "FL",
      "zipCode": "32801",
      "country": "US",
      "fromDate": "2019-01-01T00:00:00Z",
      "toDate": "2022-05-31T00:00:00Z"
    }
  ],
  "smartcreditStatus": "connected",
  "smartcreditConnectedAt": "2024-01-10T00:00:00Z",
  "stats": {
    "totalDisputes": 5,
    "activeDisputes": 2,
    "resolvedDisputes": 3,
    "successfulDisputes": 2,
    "totalLettersSent": 9,
    "lastCreditPullAt": "2024-01-10T00:00:00Z"
  },
  "status": "active",
  "internalNotes": "High priority client",
  "consent": {
    "creditPull": true,
    "creditPullAt": "2024-01-05T00:00:00Z",
    "electronicCommunication": true,
    "electronicCommunicationAt": "2024-01-05T00:00:00Z",
    "termsOfService": true,
    "termsOfServiceAt": "2024-01-05T00:00:00Z",
    "privacyPolicy": true,
    "privacyPolicyAt": "2024-01-05T00:00:00Z"
  },
  "createdAt": "2024-01-05T00:00:00Z",
  "updatedAt": "2024-01-15T00:00:00Z",
  "deletedAt": null,
  "createdBy": "user_xyz789",
  "updatedBy": "user_xyz789"
}
```

**Indexes:**

```
- tenantId, status
- tenantId, lastName, firstName
- tenantId, email
- tenantId, ssnLast4
- tenantId, smartcreditStatus
- tenantId, createdAt (descending)
```

---

### 3.4 smartcreditConnections

Stores SmartCredit OAuth tokens and connection status.

**Collection Path:** `/smartcreditConnections/{connectionId}`

```typescript
interface SmartcreditConnection {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;

  // OAuth Tokens (Encrypted)
  accessTokenEncrypted: string;
  refreshTokenEncrypted: string;
  tokenExpiresAt: Timestamp;

  // SmartCredit User Info
  smartcreditUserId: string;
  smartcreditEmail: string | null;

  // Status
  status: "active" | "expired" | "revoked" | "error";
  lastRefreshedAt: Timestamp;
  lastErrorAt: Timestamp | null;
  lastErrorMessage: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Indexes:**

```
- tenantId, consumerId (unique composite)
- status, tokenExpiresAt
```

---

### 3.5 creditReports

Stores credit report data pulled from SmartCredit.

**Collection Path:** `/creditReports/{reportId}`

```typescript
interface CreditReport {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  connectionId: string;          // SmartCredit connection used

  // Report Info
  reportDate: Timestamp;         // Date report was pulled
  reportType: "3bureau" | "single";

  // Scores
  scores: {
    equifax: number | null;
    experian: number | null;
    transunion: number | null;
  };

  // Summary Statistics
  summary: {
    totalAccounts: number;
    openAccounts: number;
    closedAccounts: number;
    delinquentAccounts: number;
    derogatoryAccounts: number;
    totalBalance: number;
    totalMonthlyPayment: number;
    inquiriesLast6Months: number;
    inquiriesLast12Months: number;
    publicRecords: number;
    collections: number;
  };

  // Bureau-specific data stored as subcollection tradelines
  // Raw report data (for reference)
  rawDataStoragePath: string | null;  // Path in Firebase Storage

  // Status
  status: "processing" | "complete" | "error";
  errorMessage: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  expiresAt: Timestamp;          // Reports expire after 30 days
}
```

**Indexes:**

```
- tenantId, consumerId, createdAt (descending)
- tenantId, status
- expiresAt
```

---

### 3.6 tradelines

Stores individual tradeline (account) data from credit reports.

**Collection Path:** `/tradelines/{tradelineId}`

```typescript
interface Tradeline {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  creditReportId: string;

  // Bureau Information
  bureau: "equifax" | "experian" | "transunion";
  bureauAccountId: string | null; // Bureau's internal ID

  // Creditor Information
  creditorName: string;
  originalCreditorName: string | null;
  accountNumberMasked: string;   // Last 4 digits: "****1234"

  // Account Details
  accountType: string;           // "Revolving", "Installment", "Mortgage", etc.
  accountTypeCode: string;       // Raw code from bureau
  ownership: "individual" | "joint" | "authorized_user" | "cosigner";
  dateOpened: Timestamp | null;
  dateClosed: Timestamp | null;
  dateReported: Timestamp;

  // Financial Details
  creditLimit: number | null;
  highBalance: number | null;
  currentBalance: number;
  pastDueAmount: number;
  monthlyPayment: number | null;
  lastPaymentDate: Timestamp | null;
  lastPaymentAmount: number | null;

  // Status
  accountStatus: string;         // "Open", "Closed", "Paid", etc.
  accountStatusCode: string;
  paymentStatus: string;         // "Current", "30 Days Late", etc.
  paymentStatusCode: string;

  // Payment History (24-month rolling)
  paymentHistory: Array<{
    month: string;               // "2024-01"
    status: string;              // "OK", "30", "60", "90", "120", "CO", etc.
  }>;

  // Derogatory Indicators
  isDerogatory: boolean;
  isCollection: boolean;
  isChargeOff: boolean;
  isBankruptcy: boolean;
  derogatoryType: string | null;

  // Dispute Information
  hasDispute: boolean;
  disputeId: string | null;      // Active dispute reference

  // Remarks
  remarks: string[];

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Example Document:**

```json
{
  "id": "tradeline_ghi789",
  "tenantId": "tenant_abc123",
  "consumerId": "consumer_def456",
  "creditReportId": "report_xyz123",
  "bureau": "equifax",
  "bureauAccountId": "EQ12345678",
  "creditorName": "CAPITAL ONE",
  "originalCreditorName": null,
  "accountNumberMasked": "****5678",
  "accountType": "Revolving",
  "accountTypeCode": "R",
  "ownership": "individual",
  "dateOpened": "2019-03-15T00:00:00Z",
  "dateClosed": null,
  "dateReported": "2024-01-01T00:00:00Z",
  "creditLimit": 5000,
  "highBalance": 4800,
  "currentBalance": 2500,
  "pastDueAmount": 0,
  "monthlyPayment": 75,
  "lastPaymentDate": "2024-01-05T00:00:00Z",
  "lastPaymentAmount": 75,
  "accountStatus": "Open",
  "accountStatusCode": "11",
  "paymentStatus": "Current",
  "paymentStatusCode": "C",
  "paymentHistory": [
    { "month": "2024-01", "status": "OK" },
    { "month": "2023-12", "status": "OK" },
    { "month": "2023-11", "status": "OK" },
    { "month": "2023-10", "status": "30" },
    { "month": "2023-09", "status": "OK" }
  ],
  "isDerogatory": true,
  "isCollection": false,
  "isChargeOff": false,
  "isBankruptcy": false,
  "derogatoryType": "late_payment",
  "hasDispute": true,
  "disputeId": "dispute_abc123",
  "remarks": ["ACCOUNT CURRENT"],
  "createdAt": "2024-01-10T00:00:00Z",
  "updatedAt": "2024-01-15T00:00:00Z"
}
```

**Indexes:**

```
- tenantId, consumerId, bureau
- tenantId, creditReportId
- tenantId, isDerogatory
- tenantId, hasDispute
- tenantId, creditorName
```

---

### 3.7 disputes

Represents a credit dispute for a specific tradeline.

**Collection Path:** `/disputes/{disputeId}`

```typescript
interface Dispute {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  consumerName: string;          // Denormalized for display

  // Related Records
  creditReportId: string;
  tradelineId: string;

  // Tradeline Info (denormalized)
  tradeline: {
    creditorName: string;
    accountNumberMasked: string;
    bureau: "equifax" | "experian" | "transunion";
    accountType: string;
    currentBalance: number;
  };

  // Dispute Details
  disputeType: DisputeType;
  disputeReason: DisputeReason;
  customReason: string | null;   // If disputeReason is "other"

  // Narrative
  narrative: string;             // Generated dispute narrative
  narrativeGeneratedAt: Timestamp | null;
  narrativeApprovedBy: string | null;

  // Bureau Information
  bureauAddress: {
    name: string;
    street1: string;
    street2: string | null;
    city: string;
    state: string;
    zipCode: string;
  };

  // Status Workflow
  status: DisputeStatus;
  statusHistory: Array<{
    status: DisputeStatus;
    changedAt: Timestamp;
    changedBy: string;
    notes: string | null;
  }>;

  // SLA Tracking
  sla: {
    startDate: Timestamp | null;     // When letter was mailed
    deadline30Day: Timestamp | null; // 30-day FCRA deadline
    deadline45Day: Timestamp | null; // 45-day extended deadline
    warningsSent: number;
    isViolated: boolean;
    violatedAt: Timestamp | null;
  };

  // Outcome
  outcome: {
    result: "pending" | "deleted" | "updated" | "verified" | "no_response" | null;
    resultDate: Timestamp | null;
    resultNotes: string | null;
    newBalance: number | null;
    newStatus: string | null;
  };

  // Statistics
  stats: {
    lettersGenerated: number;
    lettersSent: number;
    evidenceCount: number;
  };

  // Priority
  priority: "low" | "normal" | "high" | "urgent";

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: Timestamp | null;
  createdBy: string;
  updatedBy: string;
}

type DisputeType =
  | "not_mine"           // Account doesn't belong to consumer
  | "incorrect_info"     // Information is inaccurate
  | "identity_theft"     // Fraudulent account
  | "paid_account"       // Account was paid but shows otherwise
  | "duplicate"          // Same account reported twice
  | "outdated"           // Information is too old (7+ years)
  | "other";

type DisputeReason =
  | "balance_incorrect"
  | "payment_history_wrong"
  | "account_status_wrong"
  | "dates_incorrect"
  | "not_my_account"
  | "identity_theft"
  | "account_paid"
  | "account_closed"
  | "duplicate_entry"
  | "obsolete_info"
  | "other";

type DisputeStatus =
  | "draft"              // Initial state
  | "pending_letter"     // Waiting for letter generation
  | "letter_generated"   // Letter created, awaiting approval
  | "letter_approved"    // Letter approved, ready to send
  | "letter_sent"        // Letter mailed
  | "in_transit"         // Mail in transit
  | "delivered"          // Mail delivered to bureau
  | "pending_response"   // Waiting for bureau response
  | "response_received"  // Bureau responded
  | "resolved"           // Dispute resolved (any outcome)
  | "escalated"          // Escalated (CFPB complaint, etc.)
  | "cancelled";         // Cancelled by user
```

**Example Document:**

```json
{
  "id": "dispute_abc123",
  "tenantId": "tenant_abc123",
  "consumerId": "consumer_def456",
  "consumerName": "Jane Marie Smith",
  "creditReportId": "report_xyz123",
  "tradelineId": "tradeline_ghi789",
  "tradeline": {
    "creditorName": "CAPITAL ONE",
    "accountNumberMasked": "****5678",
    "bureau": "equifax",
    "accountType": "Revolving",
    "currentBalance": 2500
  },
  "disputeType": "incorrect_info",
  "disputeReason": "payment_history_wrong",
  "customReason": null,
  "narrative": "I am writing to dispute inaccurate information on my credit report. The payment history for my Capital One account (****5678) incorrectly shows a 30-day late payment in October 2023. I have attached bank statements proving payment was made on time.",
  "narrativeGeneratedAt": "2024-01-15T10:00:00Z",
  "narrativeApprovedBy": "user_xyz789",
  "bureauAddress": {
    "name": "Equifax Information Services LLC",
    "street1": "P.O. Box 740256",
    "street2": null,
    "city": "Atlanta",
    "state": "GA",
    "zipCode": "30374"
  },
  "status": "letter_sent",
  "statusHistory": [
    {
      "status": "draft",
      "changedAt": "2024-01-15T09:00:00Z",
      "changedBy": "user_xyz789",
      "notes": "Dispute created"
    },
    {
      "status": "letter_generated",
      "changedAt": "2024-01-15T10:00:00Z",
      "changedBy": "system",
      "notes": "FCRA 611 letter generated"
    },
    {
      "status": "letter_approved",
      "changedAt": "2024-01-15T11:00:00Z",
      "changedBy": "user_xyz789",
      "notes": null
    },
    {
      "status": "letter_sent",
      "changedAt": "2024-01-15T12:00:00Z",
      "changedBy": "system",
      "notes": "Mailed via Lob"
    }
  ],
  "sla": {
    "startDate": "2024-01-15T12:00:00Z",
    "deadline30Day": "2024-02-14T12:00:00Z",
    "deadline45Day": "2024-03-01T12:00:00Z",
    "warningsSent": 0,
    "isViolated": false,
    "violatedAt": null
  },
  "outcome": {
    "result": "pending",
    "resultDate": null,
    "resultNotes": null,
    "newBalance": null,
    "newStatus": null
  },
  "stats": {
    "lettersGenerated": 1,
    "lettersSent": 1,
    "evidenceCount": 2
  },
  "priority": "normal",
  "createdAt": "2024-01-15T09:00:00Z",
  "updatedAt": "2024-01-15T12:00:00Z",
  "deletedAt": null,
  "createdBy": "user_xyz789",
  "updatedBy": "system"
}
```

**Indexes:**

```
- tenantId, status
- tenantId, consumerId, status
- tenantId, priority, status
- tenantId, sla.deadline30Day
- tenantId, createdAt (descending)
- tenantId, tradeline.bureau
```

---

### 3.8 letters

Represents a dispute letter.

**Collection Path:** `/letters/{letterId}`

```typescript
interface Letter {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  disputeId: string;

  // Template
  templateId: string;
  templateName: string;          // Denormalized
  letterType: LetterType;

  // Content
  content: {
    html: string;                // Rendered HTML
    plainText: string;           // Plain text version
    variables: Record<string, any>; // Variables used
  };

  // PDF
  pdfStoragePath: string | null; // Path in Firebase Storage
  pdfUrl: string | null;         // Signed URL (temporary)
  pdfGeneratedAt: Timestamp | null;
  pageCount: number;

  // Status
  status: LetterStatus;

  // Approval
  approvedBy: string | null;
  approvedAt: Timestamp | null;
  rejectedBy: string | null;
  rejectedAt: Timestamp | null;
  rejectionReason: string | null;

  // Mailing
  mailingId: string | null;      // Reference to mailings collection

  // Version Control
  version: number;
  previousVersionId: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

type LetterType =
  | "fcra_609"           // Request for information
  | "fcra_611"           // Dispute letter
  | "mov"                // Method of Verification
  | "reinvestigation"    // Reinvestigation request
  | "goodwill"           // Goodwill deletion request
  | "pay_for_delete"     // Pay for delete offer
  | "fcra_605b"          // Identity theft block
  | "cfpb_complaint";    // CFPB complaint

type LetterStatus =
  | "draft"
  | "generated"
  | "pending_approval"
  | "approved"
  | "rejected"
  | "sent"
  | "cancelled";
```

**Indexes:**

```
- tenantId, disputeId
- tenantId, consumerId
- tenantId, status
- tenantId, letterType
- tenantId, createdAt (descending)
```

---

### 3.9 letterTemplates

Stores letter templates for generating dispute letters.

**Collection Path:** `/letterTemplates/{templateId}`

```typescript
interface LetterTemplate {
  // Identity
  id: string;
  tenantId: string | null;       // null = system template

  // Template Info
  name: string;
  description: string;
  letterType: LetterType;
  category: "bureau" | "creditor" | "collection" | "other";

  // Content
  content: {
    html: string;                // HTML template with {{variables}}
    css: string;                 // Custom CSS
    headerHtml: string | null;   // Optional header
    footerHtml: string | null;   // Optional footer
  };

  // Variables
  variables: Array<{
    name: string;
    description: string;
    required: boolean;
    defaultValue: string | null;
  }>;

  // Settings
  settings: {
    pageSize: "letter" | "a4";
    orientation: "portrait" | "landscape";
    margins: {
      top: string;
      right: string;
      bottom: string;
      left: string;
    };
  };

  // Status
  isActive: boolean;
  isDefault: boolean;            // Default template for this letter type

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}
```

**Indexes:**

```
- tenantId, letterType, isActive
- tenantId, isDefault
```

---

### 3.10 evidence

Stores evidence documents attached to disputes.

**Collection Path:** `/evidence/{evidenceId}`

```typescript
interface Evidence {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  disputeId: string;

  // File Info
  fileName: string;
  fileType: string;              // MIME type
  fileSize: number;              // Bytes
  storagePath: string;           // Firebase Storage path

  // Evidence Details
  evidenceType: EvidenceType;
  description: string | null;
  dateOfDocument: Timestamp | null;

  // Processing
  status: "uploading" | "processing" | "ready" | "error";
  thumbnailPath: string | null;  // For images/PDFs
  extractedText: string | null;  // OCR text if applicable
  errorMessage: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

type EvidenceType =
  | "bank_statement"
  | "payment_confirmation"
  | "correspondence"
  | "id_document"
  | "police_report"
  | "ftc_affidavit"
  | "court_document"
  | "credit_report"
  | "other";
```

**Indexes:**

```
- tenantId, disputeId
- tenantId, consumerId
- tenantId, evidenceType
```

---

### 3.11 mailings

Tracks physical mail sent via Lob.

**Collection Path:** `/mailings/{mailingId}`

```typescript
interface Mailing {
  // Identity
  id: string;
  tenantId: string;
  consumerId: string;
  disputeId: string;
  letterId: string;

  // Lob Information
  lobId: string;                 // Lob letter ID
  lobUrl: string | null;         // Lob dashboard URL

  // Addresses
  fromAddress: {
    name: string;
    street1: string;
    street2: string | null;
    city: string;
    state: string;
    zipCode: string;
  };
  toAddress: {
    name: string;
    street1: string;
    street2: string | null;
    city: string;
    state: string;
    zipCode: string;
  };

  // Mail Options
  mailType: "usps_first_class" | "usps_standard" | "certified" | "certified_return_receipt";
  color: boolean;
  doubleSided: boolean;
  extraService: string | null;   // "certified", "registered", etc.

  // Tracking
  trackingNumber: string | null;
  trackingUrl: string | null;
  carrier: string;               // "USPS"

  // Status
  status: MailingStatus;
  statusHistory: Array<{
    status: MailingStatus;
    timestamp: Timestamp;
    details: string | null;
  }>;

  // Expected Dates
  expectedDeliveryDate: Timestamp | null;
  sendDate: Timestamp | null;

  // Delivery Confirmation
  deliveredAt: Timestamp | null;
  returnedAt: Timestamp | null;
  returnReason: string | null;

  // Cost
  cost: {
    amount: number;
    currency: string;
  };

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

type MailingStatus =
  | "created"
  | "processing"
  | "rendered"
  | "mailed"
  | "in_transit"
  | "in_local_area"
  | "out_for_delivery"
  | "delivered"
  | "returned"
  | "cancelled"
  | "failed";
```

**Example Document:**

```json
{
  "id": "mailing_xyz789",
  "tenantId": "tenant_abc123",
  "consumerId": "consumer_def456",
  "disputeId": "dispute_abc123",
  "letterId": "letter_def456",
  "lobId": "ltr_1234567890abcdef",
  "lobUrl": "https://dashboard.lob.com/letters/ltr_1234567890abcdef",
  "fromAddress": {
    "name": "Jane Marie Smith",
    "street1": "456 Oak Avenue",
    "street2": "Apt 12B",
    "city": "Miami",
    "state": "FL",
    "zipCode": "33101"
  },
  "toAddress": {
    "name": "Equifax Information Services LLC",
    "street1": "P.O. Box 740256",
    "street2": null,
    "city": "Atlanta",
    "state": "GA",
    "zipCode": "30374"
  },
  "mailType": "certified_return_receipt",
  "color": false,
  "doubleSided": true,
  "extraService": "certified_return_receipt",
  "trackingNumber": "9400111899223456789012",
  "trackingUrl": "https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223456789012",
  "carrier": "USPS",
  "status": "in_transit",
  "statusHistory": [
    {
      "status": "created",
      "timestamp": "2024-01-15T12:00:00Z",
      "details": "Letter created in Lob"
    },
    {
      "status": "rendered",
      "timestamp": "2024-01-15T12:05:00Z",
      "details": "PDF rendered"
    },
    {
      "status": "mailed",
      "timestamp": "2024-01-16T08:00:00Z",
      "details": "Mailed from facility"
    },
    {
      "status": "in_transit",
      "timestamp": "2024-01-17T10:00:00Z",
      "details": "In transit to destination"
    }
  ],
  "expectedDeliveryDate": "2024-01-20T00:00:00Z",
  "sendDate": "2024-01-16T08:00:00Z",
  "deliveredAt": null,
  "returnedAt": null,
  "returnReason": null,
  "cost": {
    "amount": 1.50,
    "currency": "USD"
  },
  "createdAt": "2024-01-15T12:00:00Z",
  "updatedAt": "2024-01-17T10:00:00Z"
}
```

**Indexes:**

```
- tenantId, disputeId
- tenantId, status
- tenantId, createdAt (descending)
- lobId (unique)
```

---

### 3.12 disputeTasks

Tracks tasks/checklist items for each dispute.

**Collection Path:** `/disputeTasks/{taskId}`

```typescript
interface DisputeTask {
  // Identity
  id: string;
  tenantId: string;
  disputeId: string;

  // Task Info
  name: string;
  description: string | null;
  order: number;                 // Display order

  // Status
  status: "pending" | "in_progress" | "completed" | "skipped";
  completedAt: Timestamp | null;
  completedBy: string | null;

  // Due Date
  dueDate: Timestamp | null;
  isOverdue: boolean;

  // Notes
  notes: string | null;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Indexes:**

```
- tenantId, disputeId, order
- tenantId, status
- tenantId, dueDate
```

---

### 3.13 auditLogs

Immutable audit log for compliance.

**Collection Path:** `/auditLogs/{logId}`

```typescript
interface AuditLog {
  // Identity
  id: string;
  tenantId: string;

  // Actor
  userId: string;
  userEmail: string;             // Denormalized
  userRole: string;

  // Action
  action: string;                // e.g., "consumer.created", "letter.approved"
  category: "auth" | "consumer" | "dispute" | "letter" | "mailing" | "admin" | "system";

  // Target
  resourceType: string;          // e.g., "consumer", "dispute"
  resourceId: string;

  // Details
  details: Record<string, any>;  // Action-specific details
  previousValue: Record<string, any> | null;  // For updates
  newValue: Record<string, any> | null;

  // Context
  ipAddress: string | null;
  userAgent: string | null;
  requestId: string | null;

  // Timestamp (cannot be modified)
  timestamp: Timestamp;
}
```

**Example Document:**

```json
{
  "id": "audit_xyz123",
  "tenantId": "tenant_abc123",
  "userId": "user_xyz789",
  "userEmail": "john.doe@creditrepairpro.com",
  "userRole": "operator",
  "action": "letter.approved",
  "category": "letter",
  "resourceType": "letter",
  "resourceId": "letter_def456",
  "details": {
    "disputeId": "dispute_abc123",
    "letterType": "fcra_611",
    "consumerId": "consumer_def456"
  },
  "previousValue": {
    "status": "pending_approval"
  },
  "newValue": {
    "status": "approved",
    "approvedBy": "user_xyz789",
    "approvedAt": "2024-01-15T11:00:00Z"
  },
  "ipAddress": "192.168.1.100",
  "userAgent": "Mozilla/5.0...",
  "requestId": "req_abc123",
  "timestamp": "2024-01-15T11:00:00Z"
}
```

**Indexes:**

```
- tenantId, timestamp (descending)
- tenantId, action, timestamp (descending)
- tenantId, userId, timestamp (descending)
- tenantId, resourceType, resourceId
```

---

### 3.14 webhookEvents

Stores incoming webhook events from external services.

**Collection Path:** `/webhookEvents/{eventId}`

```typescript
interface WebhookEvent {
  // Identity
  id: string;

  // Source
  source: "lob" | "smartcredit";
  eventType: string;

  // Payload
  payload: Record<string, any>;
  signature: string | null;
  signatureValid: boolean;

  // Processing
  status: "received" | "processing" | "processed" | "failed";
  processedAt: Timestamp | null;
  errorMessage: string | null;

  // Related Records
  relatedRecords: Array<{
    type: string;
    id: string;
  }>;

  // Timestamps
  receivedAt: Timestamp;
  createdAt: Timestamp;
}
```

**Indexes:**

```
- source, eventType, receivedAt (descending)
- status, receivedAt (descending)
```

---

### 3.15 notifications

User notifications (in-app and push).

**Collection Path:** `/notifications/{notificationId}`

```typescript
interface Notification {
  // Identity
  id: string;
  tenantId: string;
  userId: string;

  // Content
  title: string;
  body: string;
  type: NotificationType;
  priority: "low" | "normal" | "high";

  // Action
  action: {
    type: "navigate" | "external_url" | "none";
    destination: string | null;  // Route or URL
    params: Record<string, any> | null;
  } | null;

  // Related Resource
  resourceType: string | null;
  resourceId: string | null;

  // Status
  read: boolean;
  readAt: Timestamp | null;
  dismissed: boolean;
  dismissedAt: Timestamp | null;

  // Push Notification
  pushSent: boolean;
  pushSentAt: Timestamp | null;

  // Timestamps
  createdAt: Timestamp;
  expiresAt: Timestamp | null;
}

type NotificationType =
  | "dispute_created"
  | "dispute_status_change"
  | "letter_ready"
  | "letter_approved"
  | "mailing_delivered"
  | "mailing_returned"
  | "sla_warning"
  | "sla_violation"
  | "credit_report_ready"
  | "system";
```

**Indexes:**

```
- tenantId, userId, read, createdAt (descending)
- tenantId, userId, type
- expiresAt
```

---

## 4. Subcollections

Some documents may have subcollections for better organization:

### 4.1 Dispute Comments

**Collection Path:** `/disputes/{disputeId}/comments/{commentId}`

```typescript
interface DisputeComment {
  id: string;
  userId: string;
  userDisplayName: string;
  content: string;
  isInternal: boolean;           // Internal note vs. consumer-visible
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

## 5. Data Validation Rules

### 5.1 Required Fields by Collection

| Collection | Required Fields |
|------------|-----------------|
| tenants | id, name, email, plan, status |
| users | id, tenantId, email, role, status |
| consumers | id, tenantId, firstName, lastName, email, status |
| disputes | id, tenantId, consumerId, tradelineId, disputeType, status |
| letters | id, tenantId, disputeId, templateId, letterType, status |
| mailings | id, tenantId, letterId, lobId, status |

### 5.2 Field Constraints

```typescript
// Email validation
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Phone validation (E.164 format)
const phoneRegex = /^\+[1-9]\d{1,14}$/;

// ZIP code validation (US)
const zipRegex = /^\d{5}(-\d{4})?$/;

// State code validation (US)
const stateRegex = /^[A-Z]{2}$/;

// SSN last 4 validation
const ssnLast4Regex = /^\d{4}$/;
```

---

## 6. Data Retention Policies

| Data Type | Retention Period | Action |
|-----------|------------------|--------|
| Audit Logs | 7 years | Archive to cold storage |
| Credit Reports | 30 days | Soft delete, retain summary |
| Deleted Consumers | 90 days | Hard delete after retention |
| Webhook Events | 90 days | Hard delete |
| Notifications (dismissed) | 30 days | Hard delete |
| Letters (cancelled) | 1 year | Archive |

---

## 7. Migration from PostgreSQL

### 7.1 Data Type Mapping

| PostgreSQL | Firestore |
|------------|-----------|
| UUID | string (auto-generated ID) |
| VARCHAR | string |
| TEXT | string |
| INTEGER | number |
| DECIMAL | number |
| BOOLEAN | boolean |
| TIMESTAMP | Timestamp |
| JSONB | map (nested object) |
| ARRAY | array |
| BYTEA | string (base64) or Storage reference |

### 7.2 Relationship Mapping

| PostgreSQL | Firestore Approach |
|------------|-------------------|
| Foreign Key | Document ID reference + denormalized fields |
| One-to-Many | Parent ID field + collection query |
| Many-to-Many | Array of IDs or junction collection |
| JOIN | Denormalization or multiple queries |

---

## 8. Backup and Export

### 8.1 Automated Backups

```bash
# Daily backup to Cloud Storage
gcloud firestore export gs://sfdify-backups/firestore/$(date +%Y-%m-%d)
```

### 8.2 Collection Export for Analysis

Use Firebase Extension "Export Collections to BigQuery" for analytics queries.

---

## Appendix A: Bureau Addresses Reference

```typescript
const bureauAddresses = {
  equifax: {
    disputes: {
      name: "Equifax Information Services LLC",
      street1: "P.O. Box 740256",
      city: "Atlanta",
      state: "GA",
      zipCode: "30374"
    },
    certified: {
      name: "Equifax Information Services LLC",
      street1: "P.O. Box 740241",
      city: "Atlanta",
      state: "GA",
      zipCode: "30374"
    }
  },
  experian: {
    disputes: {
      name: "Experian",
      street1: "P.O. Box 4500",
      city: "Allen",
      state: "TX",
      zipCode: "75013"
    },
    certified: {
      name: "Experian",
      street1: "P.O. Box 4500",
      city: "Allen",
      state: "TX",
      zipCode: "75013"
    }
  },
  transunion: {
    disputes: {
      name: "TransUnion LLC",
      street1: "P.O. Box 2000",
      city: "Chester",
      state: "PA",
      zipCode: "19016"
    },
    certified: {
      name: "TransUnion Consumer Solutions",
      street1: "P.O. Box 2000",
      city: "Chester",
      state: "PA",
      zipCode: "19016"
    }
  }
};
```

---

## Appendix B: Status State Machines

### Dispute Status Flow

```
draft → pending_letter → letter_generated → letter_approved → letter_sent
                                    ↓
                                rejected → letter_generated (regenerate)

letter_sent → in_transit → delivered → pending_response → response_received → resolved
                                                    ↓
                                                escalated → resolved

Any state → cancelled
```

### Mailing Status Flow

```
created → processing → rendered → mailed → in_transit → in_local_area
                                                    ↓
                                          out_for_delivery → delivered

Any state before mailed → cancelled
mailed onwards → returned (if undeliverable)
```
