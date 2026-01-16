# SFDIFY Credit Dispute Letter System - Architecture Design

## Executive Summary

A production-ready, Firebase-based multi-tenant web application that automates consumer credit disputes and mailing. The system is an **internal operations tool** for credit repair professionals to manage disputes on behalf of consumers. It generates compliant dispute letters, integrates with SmartCredit for credit data, and sends physical mail through Lob's print-and-mail API.

### Application Scope

This is a **single unified web application** (not consumer-facing) used by credit repair company staff:

| Role | Capabilities |
|------|--------------|
| **Owner** | Full access: user management, billing, analytics, all operations |
| **Operator** | Connect SmartCredit, view reports, create disputes, approve/send letters |
| **Viewer** | Read-only access to disputes, letters, and reports |
| **Auditor** | Read-only access plus full audit log viewing for compliance |

**Not included**: Consumer self-service portal. All actions are performed by staff on behalf of consumers.

---

## 1. High-Level Architecture

### 1.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    CLIENTS                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────┐    ┌──────────────────────────┐     │
│  │         Flutter Web App                    │    │     Webhook Clients      │     │
│  │      (Admin + Operations Portal)           │    │   (SmartCredit / Lob)    │     │
│  │                                            │    │                          │     │
│  │  • Connect SmartCredit accounts            │    │  • Credit report alerts  │     │
│  │  • View 3-bureau credit reports            │    │  • Mail tracking events  │     │
│  │  • Select inaccuracies & create disputes   │    │  • Score change alerts   │     │
│  │  • Track dispute progress & SLAs           │    │                          │     │
│  │  • Business metrics & analytics            │    │                          │     │
│  │  • Billing & usage reports                 │    │                          │     │
│  │  • User management & roles                 │    │                          │     │
│  │  • Audit log viewing                       │    │                          │     │
│  │                                            │    │                          │     │
│  │  Roles: Owner | Operator | Viewer | Auditor│    │                          │     │
│  └─────────────────────┬──────────────────────┘    └────────────┬─────────────┘     │
└────────────────────────┼───────────────────────────────────────┼────────────────────┘
                         │                                       │
                         ▼                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              FIREBASE SERVICES                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         FIREBASE AUTHENTICATION                                │ │
│  │  • Multi-tenant user auth (Email/Password, Google).                            │ │
│  │  • Custom claims for roles: owner, operator, viewer, auditor                   │ │
│  │  • Tenant ID embedded in token                                                 │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CLOUD FIRESTORE (Database)                             │ │
│  │                                                                                │ │
│  │   Collections:                                                                 │ │
│  │   ├── tenants/                    (Multi-tenant configuration)                 │ │
│  │   ├── users/                      (User profiles & roles)                      │ │
│  │   ├── consumers/                  (Consumer PII - encrypted)                   │ │
│  │   │   └── {consumerId}/                                                        │ │
│  │   │       ├── creditReports/      (Subcollection)                              │ │
│  │   │       └── smartCreditTokens/  (Encrypted OAuth tokens)                     │ │
│  │   ├── tradelines/                 (Credit account data)                        │ │
│  │   ├── disputes/                   (Dispute cases)                              │ │
│  │   │   └── {disputeId}/                                                         │ │
│  │   │       ├── letters/            (Subcollection)                              │ │
│  │   │       └── evidence/           (Subcollection)                              │ │
│  │   ├── letterTemplates/            (Tenant letter templates)                    │ │
│  │   ├── webhookEvents/              (Inbound webhook log)                        │ │
│  │   ├── auditLogs/                  (Compliance audit trail)                     │ │
│  │   ├── billingRecords/             (Usage & invoicing)                          │ │
│  │   └── scheduledTasks/             (SLA reminders & follow-ups)                 │ │
│  │                                                                                │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CLOUD FUNCTIONS (Backend Logic)                        │ │
│  │                                                                                │ │
│  │   HTTP Callable Functions:                                                     │ │
│  │   ├── consumers-*          (CRUD, SmartCredit connect)                         │ │
│  │   ├── disputes-*           (Create, update, workflow)                          │ │
│  │   ├── letters-*            (Generate, render, send)                            │ │
│  │   └── admin-*              (Analytics, billing, reports)                       │ │
│  │                                                                                │ │
│  │   Webhook Endpoints:                                                           │ │
│  │   ├── webhooks-lob         (Mail tracking events)                              │ │
│  │   └── webhooks-smartcredit (Credit alerts & updates)                           │ │
│  │                                                                                │ │
│  │   Scheduled Functions (Cloud Scheduler):                                       │ │
│  │   ├── sla-checker          (Every hour - check 30/45 day windows)              │ │
│  │   ├── report-refresh       (Daily - refresh stale reports)                     │ │
│  │   ├── reconciliation       (Daily - compare report changes)                    │ │
│  │   └── billing-aggregator   (Monthly - compute tenant usage)                    │ │
│  │                                                                                │ │
│  │   Firestore Triggers:                                                          │ │
│  │   ├── onDisputeCreate      (Initialize SLA, create tasks)                      │ │
│  │   ├── onLetterStatusChange (Update dispute status, notify)                     │ │
│  │   └── onWebhookReceive     (Process & route events)                            │ │
│  │                                                                                │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CLOUD STORAGE (Files)                                  │ │
│  │                                                                                │ │
│  │   Buckets:                                                                     │ │
│  │   ├── sfdify-letters/         (Generated PDFs - encrypted at rest)             │ │
│  │   │   └── {tenantId}/{disputeId}/{letterId}.pdf                                │ │
│  │   ├── sfdify-evidence/        (Uploaded evidence files)                        │ │
│  │   │   └── {tenantId}/{disputeId}/{evidenceId}/{filename}                       │ │
│  │   ├── sfdify-templates/       (Tenant letterheads & logos)                     │ │
│  │   │   └── {tenantId}/branding/                                                 │ │
│  │   └── sfdify-exports/         (Audit exports, CFPB packages)                   │ │
│  │                                                                                │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CLOUD TASKS (Async Processing)                         │ │
│  │                                                                                │ │
│  │   Queues:                                                                      │ │
│  │   ├── letter-rendering        (PDF generation - rate limited)                  │ │
│  │   ├── lob-mailing             (Send via Lob - retry with backoff)              │ │
│  │   ├── smartcredit-sync        (API calls - rate limited)                       │ │
│  │   ├── notifications           (Email/SMS dispatch)                             │ │
│  │   └── reconciliation          (Report comparison jobs)                         │ │
│  │                                                                                │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         SECRET MANAGER                                         │ │
│  │                                                                                │ │
│  │   Secrets:                                                                     │ │
│  │   ├── SMARTCREDIT_CLIENT_ID                                                    │ │
│  │   ├── SMARTCREDIT_CLIENT_SECRET                                                │ │
│  │   ├── LOB_API_KEY_LIVE                                                         │ │
│  │   ├── LOB_API_KEY_TEST                                                         │ │
│  │   ├── LOB_WEBHOOK_SECRET                                                       │ │
│  │   ├── PII_ENCRYPTION_KEY                                                       │ │
│  │   ├── SENDGRID_API_KEY                                                         │ │
│  │   └── TWILIO_AUTH_TOKEN                                                        │ │
│  │                                                                                 │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL INTEGRATIONS                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌──────────────────────────────┐      ┌──────────────────────────────┐             │
│  │       SMARTCREDIT API        │      │          LOB API             │             │
│  │                              │      │                              │             │
│  │  • OAuth 2.0 Authorization   │      │  • Letters Endpoint          │             │
│  │  • GET /reports              │      │  • Certified Mail Options    │             │
│  │  • GET /tradelines           │      │  • HTML-to-PDF Rendering     │             │
│  │  • GET /alerts               │      │  • Webhooks (tracking)       │             │
│  │  • GET /score-factors        │      │  • Address Verification      │             │
│  │  • Webhooks (alerts)         │      │                              │             │
│  │                              │      │                              │             │
│  └──────────────────────────────┘      └──────────────────────────────┘             │
│                                                                                      │
│  ┌──────────────────────────────┐      ┌──────────────────────────────┐             │
│  │     SENDGRID (Email)         │      │      TWILIO (SMS)            │             │
│  │                              │      │                              │             │
│  │  • Transactional emails      │      │  • SMS notifications         │             │
│  │  • SLA reminders             │      │  • Delivery alerts           │             │
│  │  • Status updates            │      │  • Urgent notifications      │             │
│  │                              │      │                              │             │
│  └──────────────────────────────┘      └──────────────────────────────┘             │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         DISPUTE LETTER WORKFLOW                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
    │ CONNECT  │────▶│  PULL    │────▶│  SELECT  │────▶│ GENERATE │────▶│   MAIL   │
    │SmartCredit│     │ REPORTS  │     │  ISSUES  │     │ LETTERS  │     │  (Lob)   │
    └──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
         │                │                │                │                │
         ▼                ▼                ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
    │  Store   │     │  Store   │     │  Create  │     │  Render  │     │  Track   │
    │  OAuth   │     │ Reports  │     │ Disputes │     │   PDFs   │     │ Delivery │
    │  Tokens  │     │Tradelines│     │          │     │          │     │          │
    └──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
                                                                             │
                          ┌──────────────────────────────────────────────────┘
                          │
                          ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
    │   SLA    │────▶│ REFRESH  │────▶│RECONCILE │────▶│  CLOSE/  │
    │ MONITOR  │     │ REPORTS  │     │ OUTCOMES │     │ ESCALATE │
    └──────────┘     └──────────┘     └──────────┘     └──────────┘
```

### 1.3 Multi-Tenant Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TENANT ISOLATION MODEL                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

  Firebase Auth Custom Claims:
  ┌──────────────────────────────────────────────────────────────────┐
  │  {                                                                │
  │    "tenantId": "tenant_abc123",                                  │
  │    "role": "operator",                                           │
  │    "permissions": ["disputes:read", "disputes:write", ...]       │
  │  }                                                                │
  └──────────────────────────────────────────────────────────────────┘

  Firestore Security Rules (Tenant Isolation):
  ┌──────────────────────────────────────────────────────────────────┐
  │  match /consumers/{consumerId} {                                 │
  │    allow read, write: if                                         │
  │      request.auth.token.tenantId == resource.data.tenantId       │
  │      && hasPermission('consumers', request.method);              │
  │  }                                                                │
  └──────────────────────────────────────────────────────────────────┘

  Per-Tenant Configuration:
  ┌──────────────────────────────────────────────────────────────────┐
  │  tenants/{tenantId}                                              │
  │  ├── branding: { logo, letterhead, colors }                      │
  │  ├── lobConfig: { senderId, returnAddress }                      │
  │  ├── smartCreditConfig: { clientId (ref to secret) }             │
  │  ├── billingPlan: { tier, limits, rates }                        │
  │  └── features: { aiDrafting, certifiedMail, ... }                │
  └──────────────────────────────────────────────────────────────────┘
```

---

## 2. Entity Relationship Diagram (ERD)

### 2.1 Visual ERD

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ENTITY RELATIONSHIP DIAGRAM                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     TENANTS     │       │      USERS      │       │   CONSUMERS     │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ tenantId (FK)   │       │ id (PK)         │
│ name            │       │ id (PK)         │       │ tenantId (FK)   │──────┐
│ plan            │       │ email           │       │ firstName       │      │
│ branding        │       │ role            │       │ lastName        │      │
│ lobConfig       │       │ permissions[]   │       │ dob             │      │
│ features        │       │ twoFactorEnabled│       │ ssnLast4 (enc)  │      │
│ createdAt       │       │ createdAt       │       │ addresses[]     │      │
│ status          │       │ lastLoginAt     │       │ phones[]        │      │
└─────────────────┘       └─────────────────┘       │ emails[]        │      │
                                                    │ kycStatus       │      │
                                                    │ consentAt       │      │
                                                    │ consentIp       │      │
                                                    └────────┬────────┘      │
                                                             │               │
                          ┌──────────────────────────────────┴───────────────┤
                          │                                                  │
                          ▼                                                  │
┌─────────────────────────────────────┐                                      │
│          CREDIT_REPORTS             │                                      │
├─────────────────────────────────────┤                                      │
│ id (PK)                             │                                      │
│ consumerId (FK)                     │                                      │
│ tenantId (FK)                       │                                      │
│ bureau (equifax|experian|transunion)│                                      │
│ pulledAt                            │                                      │
│ rawJsonRef (Storage path, encrypted)│                                      │
│ hash                                │                                      │
│ score                               │                                      │
│ smartCreditReportId                 │                                      │
│ status                              │                                      │
└────────────────┬────────────────────┘                                      │
                 │                                                           │
                 │ 1:N                                                       │
                 ▼                                                           │
┌─────────────────────────────────────┐                                      │
│           TRADELINES                │                                      │
├─────────────────────────────────────┤         ┌─────────────────────────┐  │
│ id (PK)                             │         │     DISPUTES            │  │
│ reportId (FK)                       │◄────────│ tradelineId (FK)        │  │
│ consumerId (FK)                     │         ├─────────────────────────┤  │
│ tenantId (FK)                       │         │ id (PK)                 │  │
│ bureau                              │         │ consumerId (FK)         │◄─┘
│ creditorName                        │         │ tenantId (FK)           │
│ accountNumberMasked                 │         │ bureau                  │
│ accountType                         │         │ type                    │
│ openedDate                          │         │ reasonCodes[]           │
│ closedDate                          │         │ narrative               │
│ balance                             │         │ status                  │
│ creditLimit                         │         │ priority                │
│ paymentStatus                       │         │ assignedTo              │
│ paymentHistory[]                    │         │ createdAt               │
│ disputeStatus                       │         │ submittedAt             │
│ remarks                             │         │ dueAt                   │
│ smartCreditTradelineId              │         │ slaExtendedAt           │
└─────────────────────────────────────┘         │ followedUpAt            │
                                                │ closedAt                │
                                                │ outcome                 │
                                                │ outcomeDetails          │
                                                └────────────┬────────────┘
                                                             │
                 ┌───────────────────────────────────────────┼───────────────┐
                 │                                           │               │
                 ▼                                           ▼               ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐    ┌──────────────┐
│         LETTERS             │    │         EVIDENCE            │    │DISPUTE_NOTES │
├─────────────────────────────┤    ├─────────────────────────────┤    ├──────────────┤
│ id (PK)                     │    │ id (PK)                     │    │ id (PK)      │
│ disputeId (FK)              │    │ disputeId (FK)              │    │ disputeId    │
│ tenantId (FK)               │    │ tenantId (FK)               │    │ authorId     │
│ type                        │    │ filename                    │    │ content      │
│ templateId                  │    │ fileUrl (Storage ref)       │    │ createdAt    │
│ renderVersion               │    │ mimeType                    │    └──────────────┘
│ contentHtml                 │    │ fileSize                    │
│ pdfUrl (Storage ref)        │    │ checksum                    │
│ lobId                       │    │ source                      │
│ mailType                    │    │ scannedAt                   │
│ trackingCode                │    │ virusScanStatus             │
│ recipientAddress            │    │ uploadedAt                  │
│ returnAddress               │    │ uploadedBy                  │
│ status                      │    └─────────────────────────────┘
│ cost                        │
│ sentAt                      │
│ deliveredAt                 │
│ returnedAt                  │
│ createdAt                   │
│ approvedBy                  │
│ approvedAt                  │
└─────────────────────────────┘

┌─────────────────────────────┐    ┌─────────────────────────────┐
│     LETTER_TEMPLATES        │    │      WEBHOOK_EVENTS         │
├─────────────────────────────┤    ├─────────────────────────────┤
│ id (PK)                     │    │ id (PK)                     │
│ tenantId (FK, nullable)     │    │ tenantId (FK)               │
│ type                        │    │ provider                    │
│ name                        │    │ eventType                   │
│ description                 │    │ resourceId                  │
│ contentTemplate (Markdown)  │    │ payload                     │
│ legalCitations[]            │    │ signature                   │
│ requiredVariables[]         │    │ receivedAt                  │
│ isSystemTemplate            │    │ processedAt                 │
│ version                     │    │ status                      │
│ createdAt                   │    │ errorMessage                │
│ updatedAt                   │    │ retryCount                  │
└─────────────────────────────┘    └─────────────────────────────┘

┌─────────────────────────────┐    ┌─────────────────────────────┐
│        AUDIT_LOGS           │    │    BILLING_RECORDS          │
├─────────────────────────────┤    ├─────────────────────────────┤
│ id (PK)                     │    │ id (PK)                     │
│ tenantId (FK)               │    │ tenantId (FK)               │
│ actorId                     │    │ periodStart                 │
│ actorRole                   │    │ periodEnd                   │
│ actorIp                     │    │ disputesCreated             │
│ entity                      │    │ lettersMailed               │
│ entityId                    │    │ lobPostageTotal             │
│ action                      │    │ smartCreditPulls            │
│ previousState               │    │ storageUsedMb               │
│ newState                    │    │ amountDue                   │
│ diffJson                    │    │ status                      │
│ timestamp                   │    │ paidAt                      │
│ requestId                   │    │ invoiceUrl                  │
└─────────────────────────────┘    └─────────────────────────────┘

┌─────────────────────────────┐    ┌─────────────────────────────┐
│     SCHEDULED_TASKS         │    │  SMARTCREDIT_CONNECTIONS    │
├─────────────────────────────┤    ├─────────────────────────────┤
│ id (PK)                     │    │ id (PK)                     │
│ tenantId (FK)               │    │ consumerId (FK)             │
│ type                        │    │ tenantId (FK)               │
│ entityType                  │    │ accessToken (encrypted)     │
│ entityId                    │    │ refreshToken (encrypted)    │
│ scheduledFor                │    │ tokenExpiresAt              │
│ status                      │    │ scopes[]                    │
│ retryCount                  │    │ connectedAt                 │
│ lastAttemptAt               │    │ lastRefreshedAt             │
│ completedAt                 │    │ status                      │
│ result                      │    │ revokedAt                   │
│ createdAt                   │    └─────────────────────────────┘
└─────────────────────────────┘

┌─────────────────────────────┐
│     NOTIFICATIONS           │
├─────────────────────────────┤
│ id (PK)                     │
│ tenantId (FK)               │
│ userId (FK, nullable)       │
│ consumerId (FK, nullable)   │
│ type                        │
│ channel (email|sms|in_app)  │
│ subject                     │
│ body                        │
│ metadata                    │
│ status                      │
│ sentAt                      │
│ deliveredAt                 │
│ failedAt                    │
│ errorMessage                │
│ createdAt                   │
└─────────────────────────────┘
```

### 2.2 Firestore Collection Structure

```
firestore/
├── tenants/
│   └── {tenantId}/
│       ├── name: string
│       ├── plan: string
│       ├── branding: map
│       ├── lobConfig: map
│       ├── features: map
│       ├── status: string
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
│
├── users/
│   └── {userId}/
│       ├── tenantId: string
│       ├── email: string
│       ├── displayName: string
│       ├── role: string
│       ├── permissions: array
│       ├── twoFactorEnabled: boolean
│       ├── createdAt: timestamp
│       └── lastLoginAt: timestamp
│
├── consumers/
│   └── {consumerId}/
│       ├── tenantId: string
│       ├── firstName: string (encrypted)
│       ├── lastName: string (encrypted)
│       ├── dob: string (encrypted)
│       ├── ssnLast4: string (encrypted)
│       ├── addresses: array
│       ├── phones: array
│       ├── emails: array
│       ├── kycStatus: string
│       ├── consentAt: timestamp
│       ├── consentIp: string
│       ├── createdAt: timestamp
│       ├── updatedAt: timestamp
│       │
│       └── [subcollections]
│           ├── creditReports/
│           │   └── {reportId}/
│           └── smartCreditConnection/
│               └── {connectionId}/
│
├── tradelines/
│   └── {tradelineId}/
│       ├── reportId: string
│       ├── consumerId: string
│       ├── tenantId: string
│       ├── bureau: string
│       ├── creditorName: string
│       ├── accountNumberMasked: string
│       ├── accountType: string
│       ├── balance: number
│       ├── status: string
│       └── ...
│
├── disputes/
│   └── {disputeId}/
│       ├── consumerId: string
│       ├── tradelineId: string
│       ├── tenantId: string
│       ├── bureau: string
│       ├── type: string
│       ├── reasonCodes: array
│       ├── narrative: string
│       ├── status: string
│       ├── timestamps: map
│       │
│       └── [subcollections]
│           ├── letters/
│           │   └── {letterId}/
│           ├── evidence/
│           │   └── {evidenceId}/
│           └── notes/
│               └── {noteId}/
│
├── letterTemplates/
│   └── {templateId}/
│
├── webhookEvents/
│   └── {eventId}/
│
├── auditLogs/
│   └── {logId}/
│
├── billingRecords/
│   └── {recordId}/
│
├── scheduledTasks/
│   └── {taskId}/
│
└── notifications/
    └── {notificationId}/
```

---

## 3. JSON Examples for Key Entities

### 3.1 Tenant Document

```json
{
  "id": "tenant_sfdify_001",
  "name": "SFDIFY Credit Services",
  "plan": "professional",
  "status": "active",
  "branding": {
    "logoUrl": "gs://sfdify-templates/tenant_sfdify_001/branding/logo.png",
    "letterheadUrl": "gs://sfdify-templates/tenant_sfdify_001/branding/letterhead.png",
    "primaryColor": "#1E40AF",
    "companyName": "SFDIFY Credit Services LLC",
    "tagline": "Empowering Your Credit Journey"
  },
  "lobConfig": {
    "senderId": "lob_sender_abc123",
    "returnAddress": {
      "name": "SFDIFY Credit Services",
      "addressLine1": "123 Main Street",
      "addressLine2": "Suite 400",
      "city": "Austin",
      "state": "TX",
      "zipCode": "78701"
    },
    "defaultMailType": "usps_first_class"
  },
  "smartCreditConfig": {
    "clientIdSecretRef": "projects/sfdify-prod/secrets/smartcredit-client-id-tenant001",
    "clientSecretRef": "projects/sfdify-prod/secrets/smartcredit-client-secret-tenant001",
    "webhookEndpoint": "https://us-central1-sfdify-prod.cloudfunctions.net/webhooks-smartcredit"
  },
  "features": {
    "aiDraftingEnabled": true,
    "certifiedMailEnabled": true,
    "identityTheftBlockEnabled": true,
    "cfpbExportEnabled": true,
    "maxConsumers": 10000,
    "maxDisputesPerMonth": 50000
  },
  "billing": {
    "stripeCustomerId": "cus_abc123",
    "currentPeriodStart": "2025-01-01T00:00:00Z",
    "currentPeriodEnd": "2025-01-31T23:59:59Z"
  },
  "createdAt": "2024-06-15T10:30:00Z",
  "updatedAt": "2025-01-10T14:22:00Z"
}
```

### 3.2 Consumer Document

```json
{
  "id": "consumer_78d4f2a1",
  "tenantId": "tenant_sfdify_001",
  "firstName": "enc:AES256:base64encodedciphertext==",
  "lastName": "enc:AES256:base64encodedciphertext==",
  "dob": "enc:AES256:base64encodedciphertext==",
  "ssnLast4": "enc:AES256:base64encodedciphertext==",
  "addresses": [
    {
      "type": "current",
      "street1": "456 Oak Avenue",
      "street2": "Apt 12B",
      "city": "Houston",
      "state": "TX",
      "zipCode": "77001",
      "country": "US",
      "moveInDate": "2022-03-15",
      "isPrimary": true
    },
    {
      "type": "previous",
      "street1": "789 Pine Street",
      "street2": null,
      "city": "Dallas",
      "state": "TX",
      "zipCode": "75201",
      "country": "US",
      "moveInDate": "2019-08-01",
      "moveOutDate": "2022-03-14",
      "isPrimary": false
    }
  ],
  "phones": [
    {
      "type": "mobile",
      "number": "+18325551234",
      "isPrimary": true,
      "verified": true,
      "verifiedAt": "2024-11-20T09:15:00Z"
    }
  ],
  "emails": [
    {
      "address": "john.doe@example.com",
      "isPrimary": true,
      "verified": true,
      "verifiedAt": "2024-11-20T09:10:00Z"
    }
  ],
  "kycStatus": "verified",
  "kycVerifiedAt": "2024-11-20T09:20:00Z",
  "consent": {
    "agreedAt": "2024-11-20T09:00:00Z",
    "ipAddress": "192.168.1.100",
    "userAgent": "Mozilla/5.0...",
    "termsVersion": "2024.1",
    "privacyVersion": "2024.1",
    "fcraDisclosureVersion": "2024.1"
  },
  "smartCreditConnectionId": "sc_conn_xyz789",
  "createdAt": "2024-11-20T09:00:00Z",
  "updatedAt": "2025-01-14T16:45:00Z",
  "createdBy": "user_operator_001"
}
```

### 3.3 Credit Report Document

```json
{
  "id": "report_eq_20250114",
  "consumerId": "consumer_78d4f2a1",
  "tenantId": "tenant_sfdify_001",
  "bureau": "equifax",
  "pulledAt": "2025-01-14T08:00:00Z",
  "rawJsonRef": "gs://sfdify-letters/tenant_sfdify_001/consumer_78d4f2a1/reports/report_eq_20250114.json.enc",
  "hash": "sha256:a1b2c3d4e5f6...",
  "score": 682,
  "scoreFactors": [
    {
      "code": "14",
      "description": "Length of time accounts have been established"
    },
    {
      "code": "09",
      "description": "Too many accounts with balances"
    }
  ],
  "smartCreditReportId": "sc_report_abc123",
  "summary": {
    "totalAccounts": 12,
    "openAccounts": 8,
    "closedAccounts": 4,
    "delinquentAccounts": 1,
    "derogatoryAccounts": 2,
    "totalBalance": 45230.00,
    "totalCreditLimit": 78500.00,
    "utilizationPercent": 57.6
  },
  "publicRecords": [],
  "inquiries": [
    {
      "creditor": "CAPITAL ONE",
      "date": "2024-12-15",
      "type": "hard"
    }
  ],
  "status": "processed",
  "processingError": null,
  "createdAt": "2025-01-14T08:00:00Z",
  "expiresAt": "2025-02-14T08:00:00Z"
}
```

### 3.4 Tradeline Document

```json
{
  "id": "tradeline_tl_001",
  "reportId": "report_eq_20250114",
  "consumerId": "consumer_78d4f2a1",
  "tenantId": "tenant_sfdify_001",
  "bureau": "equifax",
  "creditorName": "CAPITAL ONE BANK USA NA",
  "originalCreditor": null,
  "accountNumberMasked": "****4521",
  "accountType": "credit_card",
  "accountTypeDetail": "Revolving",
  "ownershipType": "individual",
  "openedDate": "2019-05-15",
  "closedDate": null,
  "lastActivityDate": "2025-01-01",
  "lastReportedDate": "2025-01-10",
  "balance": 3450.00,
  "creditLimit": 8000.00,
  "highBalance": 4200.00,
  "pastDueAmount": 0,
  "monthlyPayment": 125.00,
  "paymentStatus": "current",
  "paymentStatusDetail": "Pays as agreed",
  "accountStatus": "open",
  "paymentHistory": [
    { "month": "2025-01", "status": "current" },
    { "month": "2024-12", "status": "current" },
    { "month": "2024-11", "status": "current" },
    { "month": "2024-10", "status": "30_days_late" },
    { "month": "2024-09", "status": "current" }
  ],
  "remarks": [
    "ACCOUNT INFORMATION DISPUTED BY CONSUMER"
  ],
  "disputeStatus": "in_dispute",
  "disputeFlag": true,
  "consumerStatement": null,
  "smartCreditTradelineId": "sc_tl_def456",
  "dateOfFirstDelinquency": "2024-10-15",
  "scheduledPayoffDate": null,
  "terms": {
    "frequency": "monthly",
    "duration": null
  },
  "createdAt": "2025-01-14T08:00:00Z",
  "updatedAt": "2025-01-14T08:00:00Z"
}
```

### 3.5 Dispute Document

```json
{
  "id": "dispute_d_20250114_001",
  "consumerId": "consumer_78d4f2a1",
  "tradelineId": "tradeline_tl_001",
  "tenantId": "tenant_sfdify_001",
  "bureau": "equifax",
  "type": "611_dispute",
  "reasonCodes": [
    "inaccurate_balance",
    "wrong_payment_status",
    "incorrect_late_payment"
  ],
  "reasonDetails": {
    "inaccurate_balance": {
      "reportedValue": 3450.00,
      "actualValue": 2890.00,
      "explanation": "Balance does not reflect payment made on December 28, 2024"
    },
    "incorrect_late_payment": {
      "reportedMonth": "2024-10",
      "reportedStatus": "30_days_late",
      "actualStatus": "current",
      "explanation": "Payment was made on October 14, 2024, before the due date of October 15, 2024"
    }
  },
  "narrative": "I am disputing the accuracy of this account. The reported balance of $3,450.00 does not reflect my payment of $560.00 made on December 28, 2024. Additionally, the October 2024 payment was not late - I made the payment on October 14, 2024, one day before the due date. I have attached bank statements as evidence.",
  "status": "approved",
  "priority": "normal",
  "assignedTo": "user_operator_001",
  "timestamps": {
    "createdAt": "2025-01-14T10:30:00Z",
    "submittedAt": "2025-01-14T11:00:00Z",
    "approvedAt": "2025-01-14T11:15:00Z",
    "mailedAt": "2025-01-14T14:00:00Z",
    "dueAt": "2025-02-13T23:59:59Z",
    "slaExtendedAt": null,
    "followedUpAt": null,
    "closedAt": null
  },
  "sla": {
    "baseDays": 30,
    "extendedDays": 0,
    "isExtended": false,
    "extensionReason": null
  },
  "outcome": null,
  "outcomeDetails": null,
  "bureauResponseRef": null,
  "letterIds": ["letter_l_001"],
  "evidenceIds": ["evidence_e_001", "evidence_e_002"],
  "tags": ["high_balance", "late_payment_dispute"],
  "internalNotes": null,
  "createdBy": "user_operator_001",
  "updatedAt": "2025-01-14T14:00:00Z"
}
```

### 3.6 Letter Document

```json
{
  "id": "letter_l_001",
  "disputeId": "dispute_d_20250114_001",
  "tenantId": "tenant_sfdify_001",
  "type": "611_dispute",
  "templateId": "template_611_dispute_v2",
  "renderVersion": "2025.1.3",
  "contentHtml": "<html>...(rendered HTML content)...</html>",
  "contentMarkdown": "# Dispute Letter\n\nDate: January 14, 2025...",
  "pdfUrl": "gs://sfdify-letters/tenant_sfdify_001/dispute_d_20250114_001/letter_l_001.pdf",
  "pdfHash": "sha256:f8e7d6c5b4a3...",
  "pdfSizeBytes": 245760,
  "pageCount": 3,
  "lobId": "ltr_abc123def456",
  "lobUrl": "https://dashboard.lob.com/letters/ltr_abc123def456",
  "mailType": "usps_certified",
  "mailTypeDetail": {
    "service": "usps_certified",
    "returnReceipt": false,
    "extraService": "certified_mail"
  },
  "trackingCode": "9400111899223456789012",
  "trackingUrl": "https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223456789012",
  "recipientAddress": {
    "name": "Equifax Information Services LLC",
    "addressLine1": "P.O. Box 740256",
    "city": "Atlanta",
    "state": "GA",
    "zipCode": "30374-0256"
  },
  "returnAddress": {
    "name": "John Doe",
    "addressLine1": "456 Oak Avenue",
    "addressLine2": "Apt 12B",
    "city": "Houston",
    "state": "TX",
    "zipCode": "77001"
  },
  "senderOnBehalf": {
    "name": "SFDIFY Credit Services",
    "addressLine1": "123 Main Street",
    "addressLine2": "Suite 400",
    "city": "Austin",
    "state": "TX",
    "zipCode": "78701"
  },
  "status": "delivered",
  "statusHistory": [
    { "status": "draft", "timestamp": "2025-01-14T10:30:00Z" },
    { "status": "pending_approval", "timestamp": "2025-01-14T10:45:00Z" },
    { "status": "approved", "timestamp": "2025-01-14T11:15:00Z", "by": "user_operator_001" },
    { "status": "rendering", "timestamp": "2025-01-14T11:16:00Z" },
    { "status": "ready", "timestamp": "2025-01-14T11:18:00Z" },
    { "status": "queued", "timestamp": "2025-01-14T13:00:00Z" },
    { "status": "sent", "timestamp": "2025-01-14T14:00:00Z" },
    { "status": "in_transit", "timestamp": "2025-01-15T06:00:00Z" },
    { "status": "delivered", "timestamp": "2025-01-17T14:30:00Z" }
  ],
  "cost": {
    "printing": 0.63,
    "postage": 4.85,
    "certifiedFee": 4.15,
    "total": 9.63,
    "currency": "USD"
  },
  "deliveryEvents": [
    {
      "event": "mailed",
      "timestamp": "2025-01-14T14:00:00Z",
      "location": "Austin, TX"
    },
    {
      "event": "in_transit",
      "timestamp": "2025-01-15T06:00:00Z",
      "location": "Dallas, TX"
    },
    {
      "event": "out_for_delivery",
      "timestamp": "2025-01-17T08:00:00Z",
      "location": "Atlanta, GA"
    },
    {
      "event": "delivered",
      "timestamp": "2025-01-17T14:30:00Z",
      "location": "Atlanta, GA"
    }
  ],
  "sentAt": "2025-01-14T14:00:00Z",
  "deliveredAt": "2025-01-17T14:30:00Z",
  "returnedAt": null,
  "returnReason": null,
  "createdAt": "2025-01-14T10:30:00Z",
  "createdBy": "user_operator_001",
  "approvedBy": "user_operator_001",
  "approvedAt": "2025-01-14T11:15:00Z",
  "qualityChecks": {
    "addressValidated": true,
    "narrativeLengthOk": true,
    "evidenceIndexGenerated": true,
    "pdfIntegrityVerified": true,
    "allFieldsComplete": true,
    "checkedAt": "2025-01-14T11:17:00Z"
  },
  "evidenceIndex": [
    {
      "evidenceId": "evidence_e_001",
      "filename": "bank_statement_dec2024.pdf",
      "description": "Bank statement showing payment on Dec 28, 2024",
      "pageInLetter": 2
    },
    {
      "evidenceId": "evidence_e_002",
      "filename": "payment_confirmation.png",
      "description": "Payment confirmation screenshot",
      "pageInLetter": 3
    }
  ]
}
```

### 3.7 Evidence Document

```json
{
  "id": "evidence_e_001",
  "disputeId": "dispute_d_20250114_001",
  "tenantId": "tenant_sfdify_001",
  "filename": "bank_statement_dec2024.pdf",
  "originalFilename": "Bank Statement December 2024.pdf",
  "fileUrl": "gs://sfdify-evidence/tenant_sfdify_001/dispute_d_20250114_001/evidence_e_001/bank_statement_dec2024.pdf",
  "mimeType": "application/pdf",
  "fileSize": 524288,
  "checksum": "sha256:1a2b3c4d5e6f...",
  "source": "consumer_upload",
  "description": "Bank statement showing payment of $560 on December 28, 2024",
  "category": "financial_statement",
  "pageCount": 2,
  "extractedData": {
    "paymentDate": "2024-12-28",
    "paymentAmount": 560.00,
    "payee": "CAPITAL ONE",
    "accountLast4": "4521"
  },
  "virusScan": {
    "status": "clean",
    "scannedAt": "2025-01-14T10:32:00Z",
    "engine": "ClamAV",
    "engineVersion": "1.2.0"
  },
  "redactions": [],
  "linkedToLetters": ["letter_l_001"],
  "uploadedAt": "2025-01-14T10:31:00Z",
  "uploadedBy": "user_operator_001",
  "verifiedAt": "2025-01-14T10:33:00Z",
  "verifiedBy": "user_operator_001"
}
```

### 3.8 Audit Log Document

```json
{
  "id": "audit_al_20250114_001",
  "tenantId": "tenant_sfdify_001",
  "actorId": "user_operator_001",
  "actorEmail": "operator@sfdify.com",
  "actorRole": "operator",
  "actorIp": "192.168.1.50",
  "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...",
  "entity": "dispute",
  "entityId": "dispute_d_20250114_001",
  "entityPath": "disputes/dispute_d_20250114_001",
  "action": "update",
  "actionDetail": "status_change",
  "previousState": {
    "status": "pending_review",
    "approvedAt": null,
    "approvedBy": null
  },
  "newState": {
    "status": "approved",
    "approvedAt": "2025-01-14T11:15:00Z",
    "approvedBy": "user_operator_001"
  },
  "diffJson": {
    "status": { "from": "pending_review", "to": "approved" },
    "approvedAt": { "from": null, "to": "2025-01-14T11:15:00Z" },
    "approvedBy": { "from": null, "to": "user_operator_001" }
  },
  "metadata": {
    "source": "web_ui",
    "sessionId": "sess_xyz123",
    "requestId": "req_abc456"
  },
  "timestamp": "2025-01-14T11:15:00Z",
  "retentionUntil": "2032-01-14T11:15:00Z"
}
```

### 3.9 Webhook Event Document

```json
{
  "id": "webhook_wh_001",
  "tenantId": "tenant_sfdify_001",
  "provider": "lob",
  "eventType": "letter.delivered",
  "resourceType": "letter",
  "resourceId": "ltr_abc123def456",
  "internalResourceId": "letter_l_001",
  "payload": {
    "id": "evt_lob_789",
    "body": {
      "id": "ltr_abc123def456",
      "tracking_number": "9400111899223456789012",
      "expected_delivery_date": "2025-01-17",
      "event_type": {
        "id": "letter.delivered",
        "description": "Letter delivered"
      },
      "date_created": "2025-01-17T14:30:00Z"
    },
    "reference_id": "letter_l_001"
  },
  "signature": "sha256=abc123...",
  "signatureValid": true,
  "receivedAt": "2025-01-17T14:30:05Z",
  "processedAt": "2025-01-17T14:30:08Z",
  "status": "processed",
  "processingResult": {
    "letterUpdated": true,
    "disputeUpdated": true,
    "notificationSent": true
  },
  "errorMessage": null,
  "retryCount": 0
}
```

### 3.10 Scheduled Task Document

```json
{
  "id": "task_st_001",
  "tenantId": "tenant_sfdify_001",
  "type": "sla_follow_up",
  "entityType": "dispute",
  "entityId": "dispute_d_20250114_001",
  "description": "30-day SLA approaching - prepare reinvestigation letter",
  "scheduledFor": "2025-02-11T09:00:00Z",
  "priority": "high",
  "assignTo": "user_operator_001",
  "status": "pending",
  "metadata": {
    "dueDate": "2025-02-13T23:59:59Z",
    "daysUntilDue": 2,
    "bureau": "equifax",
    "disputeType": "611_dispute"
  },
  "notifications": [
    {
      "channel": "email",
      "sentAt": null
    },
    {
      "channel": "in_app",
      "sentAt": null
    }
  ],
  "retryCount": 0,
  "lastAttemptAt": null,
  "completedAt": null,
  "result": null,
  "createdAt": "2025-01-14T14:00:00Z",
  "createdBy": "system"
}
```

---

## 4. API Definitions (Cloud Functions)

### 4.1 API Overview

All APIs are implemented as Firebase Cloud Functions with the following characteristics:
- **Authentication**: Firebase Auth ID tokens required
- **Authorization**: Role-based via custom claims
- **Tenant Isolation**: All queries filtered by `tenantId` from token
- **Rate Limiting**: Implemented via Firebase App Check + custom middleware
- **Idempotency**: Supported via `X-Idempotency-Key` header

### 4.2 Consumer APIs

#### POST /consumers - Create Consumer

**Cloud Function**: `consumers-create`

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "dob": "1985-06-15",
  "ssnLast4": "4521",
  "addresses": [
    {
      "type": "current",
      "street1": "456 Oak Avenue",
      "street2": "Apt 12B",
      "city": "Houston",
      "state": "TX",
      "zipCode": "77001",
      "isPrimary": true
    }
  ],
  "phones": [
    {
      "type": "mobile",
      "number": "+18325551234",
      "isPrimary": true
    }
  ],
  "emails": [
    {
      "address": "john.doe@example.com",
      "isPrimary": true
    }
  ],
  "consent": {
    "termsAccepted": true,
    "privacyAccepted": true,
    "fcraDisclosureAccepted": true
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "consumer_78d4f2a1",
    "tenantId": "tenant_sfdify_001",
    "firstName": "John",
    "lastName": "Doe",
    "kycStatus": "pending",
    "consent": {
      "agreedAt": "2025-01-14T10:00:00Z",
      "termsVersion": "2024.1"
    },
    "createdAt": "2025-01-14T10:00:00Z"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid SSN format",
    "details": {
      "field": "ssnLast4",
      "reason": "Must be exactly 4 digits"
    }
  }
}
```

---

#### POST /consumers/{id}/smartcredit/connect - Connect SmartCredit

**Cloud Function**: `consumers-smartcredit-connect`

**Request:**
```json
{
  "authorizationCode": "sc_auth_xyz789",
  "redirectUri": "https://app.sfdify.com/smartcredit/callback",
  "scopes": ["reports", "tradelines", "alerts", "scores"]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "connectionId": "sc_conn_xyz789",
    "consumerId": "consumer_78d4f2a1",
    "status": "connected",
    "scopes": ["reports", "tradelines", "alerts", "scores"],
    "connectedAt": "2025-01-14T10:15:00Z",
    "tokenExpiresAt": "2025-01-14T11:15:00Z"
  }
}
```

---

#### POST /consumers/{id}/reports/refresh - Refresh Credit Reports

**Cloud Function**: `consumers-reports-refresh`

**Request:**
```json
{
  "bureaus": ["equifax", "experian", "transunion"],
  "forceRefresh": false
}
```

**Response (202 Accepted):**
```json
{
  "success": true,
  "data": {
    "jobId": "job_refresh_abc123",
    "consumerId": "consumer_78d4f2a1",
    "status": "queued",
    "bureaus": ["equifax", "experian", "transunion"],
    "estimatedCompletionSeconds": 30,
    "queuedAt": "2025-01-14T10:20:00Z"
  }
}
```

**Async Completion (via Firestore listener or polling):**
```json
{
  "jobId": "job_refresh_abc123",
  "status": "completed",
  "results": {
    "equifax": {
      "reportId": "report_eq_20250114",
      "success": true,
      "score": 682,
      "tradelineCount": 12
    },
    "experian": {
      "reportId": "report_ex_20250114",
      "success": true,
      "score": 678,
      "tradelineCount": 11
    },
    "transunion": {
      "reportId": "report_tu_20250114",
      "success": true,
      "score": 685,
      "tradelineCount": 13
    }
  },
  "completedAt": "2025-01-14T10:20:45Z"
}
```

---

#### GET /consumers/{id}/tradelines - Get Consumer Tradelines

**Cloud Function**: `consumers-tradelines-list`

**Query Parameters:**
- `bureau`: Filter by bureau (optional)
- `status`: Filter by status (optional)
- `disputeStatus`: Filter by dispute status (optional)
- `limit`: Max results (default 50)
- `cursor`: Pagination cursor

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "tradelines": [
      {
        "id": "tradeline_tl_001",
        "bureau": "equifax",
        "creditorName": "CAPITAL ONE BANK USA NA",
        "accountNumberMasked": "****4521",
        "accountType": "credit_card",
        "balance": 3450.00,
        "creditLimit": 8000.00,
        "paymentStatus": "current",
        "disputeStatus": "in_dispute",
        "hasActiveDispute": true,
        "activeDisputeId": "dispute_d_20250114_001"
      },
      {
        "id": "tradeline_tl_002",
        "bureau": "equifax",
        "creditorName": "CHASE BANK USA",
        "accountNumberMasked": "****8876",
        "accountType": "auto_loan",
        "balance": 15230.00,
        "creditLimit": null,
        "paymentStatus": "current",
        "disputeStatus": "none",
        "hasActiveDispute": false
      }
    ],
    "pagination": {
      "total": 12,
      "limit": 50,
      "hasMore": false,
      "nextCursor": null
    }
  }
}
```

---

### 4.3 Dispute APIs

#### POST /disputes - Create Dispute

**Cloud Function**: `disputes-create`

**Request:**
```json
{
  "consumerId": "consumer_78d4f2a1",
  "tradelineId": "tradeline_tl_001",
  "bureau": "equifax",
  "type": "611_dispute",
  "reasonCodes": ["inaccurate_balance", "incorrect_late_payment"],
  "reasonDetails": {
    "inaccurate_balance": {
      "reportedValue": 3450.00,
      "actualValue": 2890.00,
      "explanation": "Balance does not reflect payment made on December 28, 2024"
    },
    "incorrect_late_payment": {
      "reportedMonth": "2024-10",
      "explanation": "Payment was made before due date"
    }
  },
  "narrative": "I am disputing the accuracy of this account...",
  "evidenceIds": ["evidence_e_001", "evidence_e_002"],
  "priority": "normal",
  "aiDraftAssist": true
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "dispute_d_20250114_001",
    "consumerId": "consumer_78d4f2a1",
    "tradelineId": "tradeline_tl_001",
    "bureau": "equifax",
    "type": "611_dispute",
    "status": "draft",
    "narrative": "I am disputing the accuracy of this account...",
    "aiSuggestedNarrative": "Under the Fair Credit Reporting Act, 15 U.S.C. § 1681i, I am formally disputing the following inaccurate information...",
    "aiDisclaimer": "AI-generated content requires human review. This is not legal advice.",
    "timestamps": {
      "createdAt": "2025-01-14T10:30:00Z",
      "dueAt": "2025-02-13T23:59:59Z"
    },
    "sla": {
      "baseDays": 30,
      "dueDate": "2025-02-13T23:59:59Z"
    },
    "createdBy": "user_operator_001"
  }
}
```

---

#### GET /disputes/{id} - Get Dispute Details

**Cloud Function**: `disputes-get`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "dispute_d_20250114_001",
    "consumerId": "consumer_78d4f2a1",
    "consumer": {
      "firstName": "John",
      "lastName": "Doe",
      "currentAddress": {
        "street1": "456 Oak Avenue",
        "city": "Houston",
        "state": "TX",
        "zipCode": "77001"
      }
    },
    "tradelineId": "tradeline_tl_001",
    "tradeline": {
      "creditorName": "CAPITAL ONE BANK USA NA",
      "accountNumberMasked": "****4521",
      "balance": 3450.00
    },
    "bureau": "equifax",
    "bureauAddress": {
      "name": "Equifax Information Services LLC",
      "addressLine1": "P.O. Box 740256",
      "city": "Atlanta",
      "state": "GA",
      "zipCode": "30374-0256"
    },
    "type": "611_dispute",
    "reasonCodes": ["inaccurate_balance", "incorrect_late_payment"],
    "narrative": "I am disputing the accuracy of this account...",
    "status": "approved",
    "priority": "normal",
    "assignedTo": {
      "id": "user_operator_001",
      "name": "Jane Operator"
    },
    "timestamps": {
      "createdAt": "2025-01-14T10:30:00Z",
      "submittedAt": "2025-01-14T11:00:00Z",
      "approvedAt": "2025-01-14T11:15:00Z",
      "mailedAt": "2025-01-14T14:00:00Z",
      "dueAt": "2025-02-13T23:59:59Z"
    },
    "letters": [
      {
        "id": "letter_l_001",
        "type": "611_dispute",
        "status": "delivered",
        "mailType": "usps_certified",
        "trackingCode": "9400111899223456789012",
        "deliveredAt": "2025-01-17T14:30:00Z"
      }
    ],
    "evidence": [
      {
        "id": "evidence_e_001",
        "filename": "bank_statement_dec2024.pdf",
        "category": "financial_statement"
      }
    ],
    "sla": {
      "baseDays": 30,
      "daysRemaining": 27,
      "isOverdue": false,
      "percentComplete": 10
    },
    "outcome": null
  }
}
```

---

#### PATCH /disputes/{id} - Update Dispute

**Cloud Function**: `disputes-update`

**Request:**
```json
{
  "status": "approved",
  "narrative": "Updated narrative with corrections...",
  "priority": "high",
  "assignedTo": "user_operator_002"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "dispute_d_20250114_001",
    "status": "approved",
    "narrative": "Updated narrative with corrections...",
    "priority": "high",
    "assignedTo": "user_operator_002",
    "updatedAt": "2025-01-14T11:15:00Z",
    "updatedBy": "user_operator_001"
  }
}
```

---

### 4.4 Letter APIs

#### POST /disputes/{id}/letters - Generate Letter

**Cloud Function**: `letters-generate`

**Request:**
```json
{
  "templateId": "template_611_dispute_v2",
  "mailType": "usps_certified",
  "customizations": {
    "includeEvidenceIndex": true,
    "attachEvidence": true,
    "additionalText": null
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "letter_l_001",
    "disputeId": "dispute_d_20250114_001",
    "type": "611_dispute",
    "status": "draft",
    "templateId": "template_611_dispute_v2",
    "renderVersion": "2025.1.3",
    "mailType": "usps_certified",
    "estimatedCost": {
      "printing": 0.63,
      "postage": 4.85,
      "certifiedFee": 4.15,
      "total": 9.63
    },
    "recipientAddress": {
      "name": "Equifax Information Services LLC",
      "addressLine1": "P.O. Box 740256",
      "city": "Atlanta",
      "state": "GA",
      "zipCode": "30374-0256"
    },
    "previewUrl": "https://storage.googleapis.com/sfdify-letters/.../preview_letter_l_001.pdf?token=...",
    "createdAt": "2025-01-14T10:45:00Z"
  }
}
```

---

#### POST /letters/{id}/approve - Approve Letter

**Cloud Function**: `letters-approve`

**Request:**
```json
{
  "approvalNotes": "Reviewed and verified all information is accurate"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "letter_l_001",
    "status": "approved",
    "approvedBy": "user_operator_001",
    "approvedAt": "2025-01-14T11:15:00Z",
    "qualityChecks": {
      "addressValidated": true,
      "narrativeLengthOk": true,
      "evidenceIndexGenerated": true,
      "pdfIntegrityVerified": true,
      "allFieldsComplete": true
    },
    "readyToSend": true
  }
}
```

---

#### POST /letters/{id}/send - Send Letter via Lob

**Cloud Function**: `letters-send`

**Request:**
```json
{
  "mailType": "usps_certified",
  "scheduledSendDate": null,
  "idempotencyKey": "send_letter_l_001_20250114"
}
```

**Response (202 Accepted):**
```json
{
  "success": true,
  "data": {
    "id": "letter_l_001",
    "status": "queued",
    "lobJobId": "job_lob_xyz123",
    "mailType": "usps_certified",
    "estimatedMailDate": "2025-01-14T18:00:00Z",
    "estimatedDeliveryDate": "2025-01-17",
    "cost": {
      "printing": 0.63,
      "postage": 4.85,
      "certifiedFee": 4.15,
      "total": 9.63
    },
    "queuedAt": "2025-01-14T13:00:00Z"
  }
}
```

**Async Completion (webhook updates status):**
```json
{
  "id": "letter_l_001",
  "status": "sent",
  "lobId": "ltr_abc123def456",
  "trackingCode": "9400111899223456789012",
  "sentAt": "2025-01-14T14:00:00Z"
}
```

---

#### GET /letters/{id} - Get Letter Details

**Cloud Function**: `letters-get`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "letter_l_001",
    "disputeId": "dispute_d_20250114_001",
    "type": "611_dispute",
    "templateId": "template_611_dispute_v2",
    "status": "delivered",
    "mailType": "usps_certified",
    "lobId": "ltr_abc123def456",
    "trackingCode": "9400111899223456789012",
    "trackingUrl": "https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223456789012",
    "pdfUrl": "https://storage.googleapis.com/sfdify-letters/.../letter_l_001.pdf?token=...",
    "recipientAddress": {
      "name": "Equifax Information Services LLC",
      "addressLine1": "P.O. Box 740256",
      "city": "Atlanta",
      "state": "GA",
      "zipCode": "30374-0256"
    },
    "cost": {
      "printing": 0.63,
      "postage": 4.85,
      "certifiedFee": 4.15,
      "total": 9.63
    },
    "timeline": [
      { "event": "created", "timestamp": "2025-01-14T10:45:00Z" },
      { "event": "approved", "timestamp": "2025-01-14T11:15:00Z", "by": "Jane Operator" },
      { "event": "sent", "timestamp": "2025-01-14T14:00:00Z" },
      { "event": "in_transit", "timestamp": "2025-01-15T06:00:00Z" },
      { "event": "delivered", "timestamp": "2025-01-17T14:30:00Z" }
    ],
    "deliveredAt": "2025-01-17T14:30:00Z"
  }
}
```

---

### 4.5 Webhook Endpoints

#### POST /webhooks/lob - Lob Webhook Handler

**Cloud Function**: `webhooks-lob`

**Lob Webhook Payload:**
```json
{
  "id": "evt_lob_789",
  "body": {
    "id": "ltr_abc123def456",
    "tracking_number": "9400111899223456789012",
    "carrier": "USPS",
    "event_type": {
      "id": "letter.delivered",
      "enabled_for_test": true
    },
    "date_created": "2025-01-17T14:30:00Z",
    "object": "tracking_event"
  },
  "reference_id": "letter_l_001",
  "date_created": "2025-01-17T14:30:00Z"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "processed": true,
  "eventId": "webhook_wh_001"
}
```

---

#### POST /webhooks/smartcredit - SmartCredit Webhook Handler

**Cloud Function**: `webhooks-smartcredit`

**SmartCredit Webhook Payload:**
```json
{
  "event_type": "alert.new_inquiry",
  "timestamp": "2025-01-15T10:00:00Z",
  "consumer_id": "sc_consumer_abc",
  "data": {
    "bureau": "equifax",
    "creditor": "CAPITAL ONE",
    "inquiry_date": "2025-01-15",
    "inquiry_type": "hard"
  },
  "signature": "sha256=xyz..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "processed": true,
  "actions": [
    "notification_sent",
    "report_refresh_scheduled"
  ]
}
```

---

### 4.6 Admin APIs

#### GET /admin/analytics/disputes - Dispute Analytics

**Cloud Function**: `admin-analytics-disputes`

**Query Parameters:**
- `startDate`: Start of period
- `endDate`: End of period
- `groupBy`: day, week, month

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "period": {
      "start": "2025-01-01",
      "end": "2025-01-31"
    },
    "summary": {
      "totalDisputes": 1247,
      "disputesByStatus": {
        "draft": 45,
        "pending_review": 89,
        "approved": 156,
        "mailed": 412,
        "delivered": 389,
        "resolved": 156
      },
      "disputesByType": {
        "611_dispute": 523,
        "609_request": 312,
        "reinvestigation": 178,
        "goodwill": 89,
        "identity_theft_block": 45,
        "other": 100
      },
      "disputesByBureau": {
        "equifax": 456,
        "experian": 421,
        "transunion": 370
      }
    },
    "outcomes": {
      "corrected": 89,
      "verified_accurate": 34,
      "deleted": 23,
      "pending": 10,
      "total_resolved": 156
    },
    "sla": {
      "onTime": 1198,
      "overdue": 49,
      "onTimePercent": 96.1
    },
    "timeSeries": [
      { "date": "2025-01-01", "created": 42, "resolved": 12 },
      { "date": "2025-01-02", "created": 38, "resolved": 15 }
    ]
  }
}
```

---

#### GET /admin/billing/usage - Billing Usage Report

**Cloud Function**: `admin-billing-usage`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "tenantId": "tenant_sfdify_001",
    "period": {
      "start": "2025-01-01",
      "end": "2025-01-31"
    },
    "usage": {
      "consumers": {
        "total": 1523,
        "new": 127
      },
      "disputes": {
        "created": 1247,
        "resolved": 156
      },
      "letters": {
        "generated": 1312,
        "mailed": 1189
      },
      "smartCredit": {
        "reportPulls": 2847,
        "alerts": 523
      },
      "storage": {
        "usedMb": 4523.5,
        "files": 3891
      }
    },
    "costs": {
      "lobPostage": 5234.67,
      "lobPrinting": 749.07,
      "smartCreditApi": 1423.50,
      "total": 7407.24
    },
    "billing": {
      "basePlanFee": 499.00,
      "overageCharges": 234.56,
      "totalDue": 7640.80,
      "status": "pending"
    }
  }
}
```

---

## 5. Sample Letter Templates

### 5.1 FCRA 611 Dispute Letter Template

**Template ID**: `template_611_dispute_v2`

**Template (Markdown with Variables):**

```markdown
{{consumer_name}}
{{current_address.street1}}
{{#if current_address.street2}}{{current_address.street2}}{{/if}}
{{current_address.city}}, {{current_address.state}} {{current_address.zipCode}}

{{current_date}}

{{bureau_name}}
{{bureau_address.addressLine1}}
{{bureau_address.city}}, {{bureau_address.state}} {{bureau_address.zipCode}}

**Re: Formal Dispute Under Fair Credit Reporting Act, 15 U.S.C. § 1681i**

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number (last 4): XXX-XX-{{ssn_last4}}

To Whom It May Concern:

I am writing pursuant to my rights under the Fair Credit Reporting Act (FCRA), specifically 15 U.S.C. § 1681i, to formally dispute the accuracy of the following information appearing on my credit report.

**Account in Dispute:**
Creditor Name: {{creditor_name}}
Account Number: {{account_number_masked}}
Date Opened: {{open_date}}
Reported Balance: ${{reported_balance}}

**Reason for Dispute:**
{{#each reason_codes}}
• {{this.description}}
{{/each}}

**Detailed Explanation:**
{{narrative}}

**Legal Requirements:**
Under Section 611 of the FCRA (15 U.S.C. § 1681i), you are required to:

1. Conduct a reasonable investigation of my dispute within 30 days of receipt
2. Forward all relevant information I provide to the furnisher of the disputed information
3. Notify me of the results of your investigation within 5 business days of completion
4. If the investigation results in modification, deletion, or blocking of the disputed information, notify me in writing
5. Provide me with a free copy of my updated credit report if changes are made

**Evidence Enclosed:**
{{#if evidence_index}}
I have enclosed the following supporting documentation:
{{#each evidence_index}}
{{@index}}. {{this.filename}} - {{this.description}}
{{/each}}
{{/if}}

Please conduct your investigation and provide written verification of the outcome. If you cannot verify the accuracy of this information, I respectfully request that it be deleted from my credit file immediately.

Failure to comply with the FCRA requirements may result in legal action to enforce my rights, including recovery of actual and statutory damages as provided under 15 U.S.C. § 1681n and § 1681o.

Thank you for your prompt attention to this matter.

Sincerely,

{{consumer_signature_line}}
{{consumer_name}}

**Enclosures:**
{{#if evidence_index}}
{{#each evidence_index}}
- {{this.filename}}
{{/each}}
{{else}}
- Copy of identification
{{/if}}
```

**Rendered Example with Demo Data:**

---

**John Michael Doe**
456 Oak Avenue
Apt 12B
Houston, TX 77001

January 14, 2025

Equifax Information Services LLC
P.O. Box 740256
Atlanta, GA 30374-0256

**Re: Formal Dispute Under Fair Credit Reporting Act, 15 U.S.C. § 1681i**

**Consumer Information:**
Name: John Michael Doe
Date of Birth: June 15, 1985
Social Security Number (last 4): XXX-XX-4521

To Whom It May Concern:

I am writing pursuant to my rights under the Fair Credit Reporting Act (FCRA), specifically 15 U.S.C. § 1681i, to formally dispute the accuracy of the following information appearing on my credit report.

**Account in Dispute:**
Creditor Name: CAPITAL ONE BANK USA NA
Account Number: ****4521
Date Opened: May 15, 2019
Reported Balance: $3,450.00

**Reason for Dispute:**
• Balance reported is inaccurate and does not reflect recent payment
• Payment status for October 2024 is incorrectly reported as 30 days late

**Detailed Explanation:**
I am disputing the accuracy of this account. The reported balance of $3,450.00 does not reflect my payment of $560.00 made on December 28, 2024. Additionally, the October 2024 payment was not late - I made the payment on October 14, 2024, one day before the due date of October 15, 2024. I have attached bank statements as evidence proving both the recent payment and the timely October payment.

**Legal Requirements:**
Under Section 611 of the FCRA (15 U.S.C. § 1681i), you are required to:

1. Conduct a reasonable investigation of my dispute within 30 days of receipt
2. Forward all relevant information I provide to the furnisher of the disputed information
3. Notify me of the results of your investigation within 5 business days of completion
4. If the investigation results in modification, deletion, or blocking of the disputed information, notify me in writing
5. Provide me with a free copy of my updated credit report if changes are made

**Evidence Enclosed:**
I have enclosed the following supporting documentation:
1. bank_statement_dec2024.pdf - Bank statement showing payment of $560 on December 28, 2024
2. bank_statement_oct2024.pdf - Bank statement showing payment on October 14, 2024
3. payment_confirmation.png - Payment confirmation screenshot from creditor portal

Please conduct your investigation and provide written verification of the outcome. If you cannot verify the accuracy of this information, I respectfully request that it be deleted from my credit file immediately.

Failure to comply with the FCRA requirements may result in legal action to enforce my rights, including recovery of actual and statutory damages as provided under 15 U.S.C. § 1681n and § 1681o.

Thank you for your prompt attention to this matter.

Sincerely,

_______________________________
John Michael Doe

**Enclosures:**
- bank_statement_dec2024.pdf
- bank_statement_oct2024.pdf
- payment_confirmation.png

---

### 5.2 FCRA 609 Information Request Template

**Template ID**: `template_609_request_v1`

**Template (Markdown with Variables):**

```markdown
{{consumer_name}}
{{current_address.street1}}
{{#if current_address.street2}}{{current_address.street2}}{{/if}}
{{current_address.city}}, {{current_address.state}} {{current_address.zipCode}}

{{current_date}}

{{bureau_name}}
{{bureau_address.addressLine1}}
{{bureau_address.city}}, {{bureau_address.state}} {{bureau_address.zipCode}}

**Re: Request for Information Under FCRA Section 609 (15 U.S.C. § 1681g)**

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number (last 4): XXX-XX-{{ssn_last4}}

To Whom It May Concern:

Pursuant to Section 609 of the Fair Credit Reporting Act (15 U.S.C. § 1681g), I am requesting disclosure of all information in your files regarding me.

**Specifically, I request:**

1. **All information in my file** - A complete copy of all information contained in my consumer file, including all tradelines, public records, and inquiries.

2. **Sources of Information** - The name, address, and telephone number of each person or entity that has furnished information about me to your agency.

3. **Recipients of Reports** - A list of all entities that have received a consumer report about me within the past two years (or one year for employment purposes), including:
   - The date of each request
   - The name and address of each recipient
   - The purpose for which each report was requested

4. **Documentation for the following account:**
   - Creditor Name: {{creditor_name}}
   - Account Number: {{account_number_masked}}
   - I request any original documentation, including the original signed application or agreement bearing my signature, that your agency used to verify this account.

**Legal Basis:**
Under FCRA Section 609(a)(1), you are required to clearly and accurately disclose all information in my file upon request. Under Section 611(a)(6)(B)(iii), if the completeness or accuracy of any item is disputed, you must provide me with a description of the procedure used to determine the accuracy and completeness of the information.

**Response Requirements:**
Please respond to this request within 15 days as required by the FCRA. Your response should be sent to the address listed above.

{{#if evidence_index}}
**Enclosed Documentation:**
{{#each evidence_index}}
- {{this.filename}}
{{/each}}
{{else}}
**Enclosed Documentation:**
- Copy of government-issued identification
- Proof of current address (utility bill)
{{/if}}

Thank you for your prompt attention to this matter.

Sincerely,

{{consumer_signature_line}}
{{consumer_name}}
```

**Rendered Example with Demo Data:**

---

**Maria Elena Rodriguez**
1234 Sunset Boulevard
Apartment 5C
Los Angeles, CA 90028

January 14, 2025

Experian
P.O. Box 4500
Allen, TX 75013

**Re: Request for Information Under FCRA Section 609 (15 U.S.C. § 1681g)**

**Consumer Information:**
Name: Maria Elena Rodriguez
Date of Birth: March 22, 1990
Social Security Number (last 4): XXX-XX-7892

To Whom It May Concern:

Pursuant to Section 609 of the Fair Credit Reporting Act (15 U.S.C. § 1681g), I am requesting disclosure of all information in your files regarding me.

**Specifically, I request:**

1. **All information in my file** - A complete copy of all information contained in my consumer file, including all tradelines, public records, and inquiries.

2. **Sources of Information** - The name, address, and telephone number of each person or entity that has furnished information about me to your agency.

3. **Recipients of Reports** - A list of all entities that have received a consumer report about me within the past two years (or one year for employment purposes), including:
   - The date of each request
   - The name and address of each recipient
   - The purpose for which each report was requested

4. **Documentation for the following account:**
   - Creditor Name: SYNCHRONY BANK / AMAZON
   - Account Number: ****3456
   - I request any original documentation, including the original signed application or agreement bearing my signature, that your agency used to verify this account.

**Legal Basis:**
Under FCRA Section 609(a)(1), you are required to clearly and accurately disclose all information in my file upon request. Under Section 611(a)(6)(B)(iii), if the completeness or accuracy of any item is disputed, you must provide me with a description of the procedure used to determine the accuracy and completeness of the information.

**Response Requirements:**
Please respond to this request within 15 days as required by the FCRA. Your response should be sent to the address listed above.

**Enclosed Documentation:**
- Copy of government-issued identification
- Proof of current address (utility bill)

Thank you for your prompt attention to this matter.

Sincerely,

_______________________________
Maria Elena Rodriguez

---

### 5.3 Identity Theft Block Request (FCRA 605B) Template

**Template ID**: `template_605b_identity_theft_v1`

**Template (Markdown with Variables):**

```markdown
{{consumer_name}}
{{current_address.street1}}
{{#if current_address.street2}}{{current_address.street2}}{{/if}}
{{current_address.city}}, {{current_address.state}} {{current_address.zipCode}}

{{current_date}}

{{bureau_name}}
{{bureau_address.addressLine1}}
{{bureau_address.city}}, {{bureau_address.state}} {{bureau_address.zipCode}}

**Re: Identity Theft Block Request Under FCRA Section 605B (15 U.S.C. § 1681c-2)**

**URGENT - IDENTITY THEFT VICTIM**

**Consumer Information:**
Name: {{consumer_name}}
Date of Birth: {{dob}}
Social Security Number (last 4): XXX-XX-{{ssn_last4}}

To Whom It May Concern:

I am a victim of identity theft. Pursuant to Section 605B of the Fair Credit Reporting Act (15 U.S.C. § 1681c-2), I am requesting that you block the following fraudulent information from my credit report.

**Fraudulent Account(s) to be Blocked:**
{{#each disputed_accounts}}
Account {{@index}}:
- Creditor Name: {{this.creditor_name}}
- Account Number: {{this.account_number_masked}}
- Reported Balance: ${{this.balance}}
- Date Opened: {{this.open_date}}
- Reason: This account was opened fraudulently without my knowledge or consent

{{/each}}

**Identity Theft Declaration:**
I hereby declare under penalty of perjury that the information identified above appeared in my credit file as a result of identity theft. I did not authorize, apply for, or benefit from the above-referenced account(s).

**Date of Discovery:** {{theft_discovery_date}}
**Police Report Number:** {{police_report_number}}
**Police Department:** {{police_department}}

**Your Legal Obligations Under FCRA 605B:**
1. **Block the information** within 4 business days of receiving this request and the required documentation
2. **Notify the furnisher** that the information has been blocked due to identity theft
3. **Decline to reinvestigate** the blocked information if challenged by the furnisher, unless you determine that:
   - The block was requested by the wrong person
   - The block was requested in error
   - There is a material misrepresentation of fact

**Required Documentation Enclosed:**
{{#each evidence_index}}
{{@index}}. {{this.filename}} - {{this.description}}
{{/each}}

**I certify that the enclosed documentation includes:**
- [X] Copy of Identity Theft Report (FTC Affidavit and/or Police Report)
- [X] Proof of identity (government-issued ID)
- [X] Proof of address

**Notification Request:**
Please notify me in writing once the block has been placed, confirming which account(s) have been blocked and the date of the block.

**Warning to Furnishers:**
Under 15 U.S.C. § 1681s-2(a)(6), any person who furnishes information to a consumer reporting agency after receiving notice of an identity theft block may be liable for actual damages, statutory damages, and attorney's fees.

This matter requires immediate attention. Failure to block this fraudulent information as required by law will be considered a willful violation of the FCRA, exposing your agency to statutory damages of up to $1,000 per violation plus punitive damages.

Sincerely,

{{consumer_signature_line}}
{{consumer_name}}

**Enclosures:**
{{#each evidence_index}}
- {{this.filename}}
{{/each}}

**Sworn Declaration:**
I, {{consumer_name}}, declare under penalty of perjury under the laws of the United States that the foregoing is true and correct.

Executed on {{current_date}}

{{consumer_signature_line}}
{{consumer_name}}
```

**Rendered Example with Demo Data:**

---

**Robert James Wilson**
789 Maple Street
Chicago, IL 60601

January 14, 2025

TransUnion LLC
P.O. Box 2000
Chester, PA 19016

**Re: Identity Theft Block Request Under FCRA Section 605B (15 U.S.C. § 1681c-2)**

**URGENT - IDENTITY THEFT VICTIM**

**Consumer Information:**
Name: Robert James Wilson
Date of Birth: November 8, 1978
Social Security Number (last 4): XXX-XX-5678

To Whom It May Concern:

I am a victim of identity theft. Pursuant to Section 605B of the Fair Credit Reporting Act (15 U.S.C. § 1681c-2), I am requesting that you block the following fraudulent information from my credit report.

**Fraudulent Account(s) to be Blocked:**

Account 1:
- Creditor Name: DISCOVER FINANCIAL SERVICES
- Account Number: ****9012
- Reported Balance: $8,523.00
- Date Opened: September 3, 2024
- Reason: This account was opened fraudulently without my knowledge or consent

Account 2:
- Creditor Name: BEST BUY / CITIBANK
- Account Number: ****3344
- Reported Balance: $2,156.00
- Date Opened: October 15, 2024
- Reason: This account was opened fraudulently without my knowledge or consent

**Identity Theft Declaration:**
I hereby declare under penalty of perjury that the information identified above appeared in my credit file as a result of identity theft. I did not authorize, apply for, or benefit from the above-referenced account(s).

**Date of Discovery:** December 20, 2024
**Police Report Number:** CPD-2024-1234567
**Police Department:** Chicago Police Department, 1st District

**Your Legal Obligations Under FCRA 605B:**
1. **Block the information** within 4 business days of receiving this request and the required documentation
2. **Notify the furnisher** that the information has been blocked due to identity theft
3. **Decline to reinvestigate** the blocked information if challenged by the furnisher, unless you determine that:
   - The block was requested by the wrong person
   - The block was requested in error
   - There is a material misrepresentation of fact

**Required Documentation Enclosed:**
1. ftc_identity_theft_affidavit.pdf - FTC Identity Theft Report and Affidavit
2. police_report_cpd.pdf - Chicago Police Department Identity Theft Report
3. drivers_license_copy.pdf - Copy of Illinois Driver's License
4. utility_bill_proof.pdf - Current utility bill for address verification

**I certify that the enclosed documentation includes:**
- [X] Copy of Identity Theft Report (FTC Affidavit and/or Police Report)
- [X] Proof of identity (government-issued ID)
- [X] Proof of address

**Notification Request:**
Please notify me in writing once the block has been placed, confirming which account(s) have been blocked and the date of the block.

**Warning to Furnishers:**
Under 15 U.S.C. § 1681s-2(a)(6), any person who furnishes information to a consumer reporting agency after receiving notice of an identity theft block may be liable for actual damages, statutory damages, and attorney's fees.

This matter requires immediate attention. Failure to block this fraudulent information as required by law will be considered a willful violation of the FCRA, exposing your agency to statutory damages of up to $1,000 per violation plus punitive damages.

Sincerely,

_______________________________
Robert James Wilson

**Enclosures:**
- ftc_identity_theft_affidavit.pdf
- police_report_cpd.pdf
- drivers_license_copy.pdf
- utility_bill_proof.pdf

**Sworn Declaration:**
I, Robert James Wilson, declare under penalty of perjury under the laws of the United States that the foregoing is true and correct.

Executed on January 14, 2025

_______________________________
Robert James Wilson

---

## 6. Test Plan (Sandbox Testing)

### 6.1 Test Environment Setup

#### Prerequisites
```bash
# Firebase Emulators
firebase emulators:start --only auth,firestore,functions,storage

# Environment Variables
export SMARTCREDIT_API_URL="https://sandbox.smartcredit.com/api/v1"
export SMARTCREDIT_CLIENT_ID="sandbox_client_id"
export SMARTCREDIT_CLIENT_SECRET="sandbox_client_secret"
export LOB_API_KEY="test_xxxxxxxxxxxx"
export LOB_API_URL="https://api.lob.com/v1"
export ENVIRONMENT="test"
```

#### Test Data Fixtures
```json
{
  "testTenant": {
    "id": "tenant_test_001",
    "name": "Test Credit Services",
    "plan": "professional"
  },
  "testUser": {
    "id": "user_test_operator",
    "email": "operator@test.com",
    "role": "operator"
  },
  "testConsumer": {
    "firstName": "Test",
    "lastName": "Consumer",
    "dob": "1985-01-15",
    "ssnLast4": "1234"
  }
}
```

### 6.2 Test Scenarios

#### Test Suite 1: Consumer Onboarding

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 1.1 | Create consumer via API | Consumer document created in Firestore | `consumerId` returned, status 201 |
| 1.2 | Verify PII encryption | firstName, lastName, dob, ssnLast4 encrypted | Fields start with `enc:` prefix |
| 1.3 | Verify audit log | Create action logged | Audit log entry with action `create` |
| 1.4 | Verify consent capture | Consent timestamp and IP recorded | `consent.agreedAt` populated |

**Test Script:**
```javascript
// test/e2e/consumer-onboarding.test.js
describe('Consumer Onboarding', () => {
  it('should create consumer with encrypted PII', async () => {
    const response = await callFunction('consumers-create', {
      firstName: 'Test',
      lastName: 'Consumer',
      dob: '1985-01-15',
      ssnLast4: '1234',
      addresses: [{ street1: '123 Test St', city: 'Austin', state: 'TX', zipCode: '78701' }],
      consent: { termsAccepted: true, privacyAccepted: true, fcraDisclosureAccepted: true }
    });

    expect(response.status).toBe(201);
    expect(response.data.id).toBeDefined();

    // Verify encryption in Firestore
    const doc = await firestore.collection('consumers').doc(response.data.id).get();
    expect(doc.data().firstName).toMatch(/^enc:/);
  });
});
```

---

#### Test Suite 2: SmartCredit Integration

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 2.1 | Initiate OAuth flow | Redirect URL returned | Valid SmartCredit auth URL |
| 2.2 | Exchange auth code | Access/refresh tokens stored | Connection status `connected` |
| 2.3 | Pull credit reports | 3 bureau reports created | Reports for EQ, EX, TU |
| 2.4 | Parse tradelines | Tradelines normalized | All required fields populated |
| 2.5 | Handle API errors | Graceful error handling | Retry queued, error logged |
| 2.6 | Verify token refresh | Auto-refresh before expiry | New token stored |

**Test Script:**
```javascript
// test/e2e/smartcredit-integration.test.js
describe('SmartCredit Integration', () => {
  it('should connect and pull 3-bureau reports', async () => {
    // Step 1: Connect
    const connectResponse = await callFunction('consumers-smartcredit-connect', {
      consumerId: testConsumerId,
      authorizationCode: 'sandbox_auth_code_123'
    });
    expect(connectResponse.data.status).toBe('connected');

    // Step 2: Pull reports
    const refreshResponse = await callFunction('consumers-reports-refresh', {
      consumerId: testConsumerId,
      bureaus: ['equifax', 'experian', 'transunion']
    });
    expect(refreshResponse.data.status).toBe('queued');

    // Step 3: Wait for completion (poll or listen)
    await waitForJobCompletion(refreshResponse.data.jobId);

    // Step 4: Verify reports
    const tradelines = await callFunction('consumers-tradelines-list', {
      consumerId: testConsumerId
    });
    expect(tradelines.data.tradelines.length).toBeGreaterThan(0);
  });
});
```

**SmartCredit Sandbox Test Accounts:**
- Test Consumer ID: `sc_sandbox_consumer_001`
- Expected tradelines: 12 accounts across 3 bureaus
- Expected scores: EQ: 682, EX: 678, TU: 685

---

#### Test Suite 3: Dispute Creation and Management

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 3.1 | Create dispute | Dispute document created | Status `draft` |
| 3.2 | Add evidence files | Files uploaded, scanned | `virusScanStatus: clean` |
| 3.3 | Generate AI narrative | Suggested text returned | Contains FCRA citations |
| 3.4 | Submit for review | Status changed | Status `pending_review` |
| 3.5 | Approve dispute | Status changed, letter queued | Status `approved` |
| 3.6 | Verify SLA calculation | Due date set | 30 days from submission |

**Test Script:**
```javascript
// test/e2e/dispute-lifecycle.test.js
describe('Dispute Lifecycle', () => {
  it('should create dispute with evidence and AI narrative', async () => {
    // Create dispute
    const createResponse = await callFunction('disputes-create', {
      consumerId: testConsumerId,
      tradelineId: testTradelineId,
      bureau: 'equifax',
      type: '611_dispute',
      reasonCodes: ['inaccurate_balance'],
      aiDraftAssist: true
    });

    expect(createResponse.data.status).toBe('draft');
    expect(createResponse.data.aiSuggestedNarrative).toContain('15 U.S.C.');
    expect(createResponse.data.aiDisclaimer).toBeDefined();

    // Upload evidence
    const evidenceResponse = await uploadEvidence(
      createResponse.data.id,
      'test_bank_statement.pdf'
    );
    expect(evidenceResponse.data.virusScan.status).toBe('clean');

    // Submit for review
    const submitResponse = await callFunction('disputes-update', {
      disputeId: createResponse.data.id,
      status: 'pending_review'
    });
    expect(submitResponse.data.status).toBe('pending_review');

    // Verify SLA
    const dispute = await getDispute(createResponse.data.id);
    const dueDate = new Date(dispute.timestamps.dueAt);
    const submittedDate = new Date(dispute.timestamps.submittedAt);
    const daysDiff = Math.round((dueDate - submittedDate) / (1000 * 60 * 60 * 24));
    expect(daysDiff).toBe(30);
  });
});
```

---

#### Test Suite 4: Letter Generation and Quality Checks

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 4.1 | Generate letter | Letter document created | Status `draft` |
| 4.2 | Render PDF | PDF generated in Storage | Valid PDF, correct page count |
| 4.3 | Verify template merge | All variables populated | No `{{variable}}` remaining |
| 4.4 | Run quality checks | All checks pass | `qualityChecks.allFieldsComplete: true` |
| 4.5 | Verify PDF integrity | Hash comparison | Two renders produce same hash |
| 4.6 | Generate evidence index | Index created | Filenames and checksums listed |

**Test Script:**
```javascript
// test/e2e/letter-generation.test.js
describe('Letter Generation', () => {
  it('should generate letter with all quality checks passing', async () => {
    // Generate letter
    const generateResponse = await callFunction('letters-generate', {
      disputeId: testDisputeId,
      templateId: 'template_611_dispute_v2',
      mailType: 'usps_certified'
    });

    expect(generateResponse.data.status).toBe('draft');

    // Approve letter
    const approveResponse = await callFunction('letters-approve', {
      letterId: generateResponse.data.id
    });

    expect(approveResponse.data.qualityChecks.addressValidated).toBe(true);
    expect(approveResponse.data.qualityChecks.narrativeLengthOk).toBe(true);
    expect(approveResponse.data.qualityChecks.evidenceIndexGenerated).toBe(true);
    expect(approveResponse.data.qualityChecks.pdfIntegrityVerified).toBe(true);
    expect(approveResponse.data.qualityChecks.allFieldsComplete).toBe(true);

    // Verify PDF content
    const pdfContent = await downloadAndParsePdf(approveResponse.data.pdfUrl);
    expect(pdfContent).not.toContain('{{');
    expect(pdfContent).toContain('CAPITAL ONE');
    expect(pdfContent).toContain('15 U.S.C.');
  });
});
```

---

#### Test Suite 5: Lob Integration (Sandbox)

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 5.1 | Verify address | Address validated | `deliverability: deliverable` |
| 5.2 | Send test letter | Letter created in Lob | `lob_id` returned |
| 5.3 | Simulate webhooks | Events processed | Letter status updated |
| 5.4 | Track delivery | Status progression | `mailed` → `in_transit` → `delivered` |
| 5.5 | Handle returned mail | Return processed | Status `returned`, reason captured |
| 5.6 | Verify idempotency | Duplicate prevented | Same `lob_id` returned |

**Lob Test Configuration:**
```javascript
// Lob Test API Key provides sandbox environment
// All letters created in test mode are NOT actually mailed
// Webhooks can be simulated via Lob dashboard or API

const lobConfig = {
  apiKey: 'test_xxxxxxxxxxxx',
  testAddresses: {
    deliverable: {
      name: 'Test Recipient',
      address_line1: '185 BERRY ST STE 6100',
      address_city: 'SAN FRANCISCO',
      address_state: 'CA',
      address_zip: '94107'
    },
    undeliverable: {
      name: 'Test Recipient',
      address_line1: '1 FAKE ST',
      address_city: 'FAKETOWN',
      address_state: 'CA',
      address_zip: '00000'
    }
  }
};
```

**Test Script:**
```javascript
// test/e2e/lob-integration.test.js
describe('Lob Integration', () => {
  it('should send letter and track delivery via webhooks', async () => {
    // Send letter
    const sendResponse = await callFunction('letters-send', {
      letterId: testLetterId,
      mailType: 'usps_certified',
      idempotencyKey: `test_send_${testLetterId}`
    });

    expect(sendResponse.data.status).toBe('queued');
    expect(sendResponse.data.lobJobId).toBeDefined();

    // Simulate Lob webhooks
    await simulateLobWebhook('letter.mailed', {
      id: sendResponse.data.lobId,
      tracking_number: '9400111899223456789012'
    });

    let letter = await getLetter(testLetterId);
    expect(letter.status).toBe('sent');

    await simulateLobWebhook('letter.in_transit', {
      id: sendResponse.data.lobId
    });

    letter = await getLetter(testLetterId);
    expect(letter.status).toBe('in_transit');

    await simulateLobWebhook('letter.delivered', {
      id: sendResponse.data.lobId
    });

    letter = await getLetter(testLetterId);
    expect(letter.status).toBe('delivered');
    expect(letter.deliveredAt).toBeDefined();
  });

  it('should handle idempotent send requests', async () => {
    const idempotencyKey = `test_idempotent_${Date.now()}`;

    const response1 = await callFunction('letters-send', {
      letterId: testLetterId,
      idempotencyKey
    });

    const response2 = await callFunction('letters-send', {
      letterId: testLetterId,
      idempotencyKey
    });

    expect(response1.data.lobId).toBe(response2.data.lobId);
  });
});
```

---

#### Test Suite 6: SLA Monitoring and Follow-ups

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 6.1 | Create dispute | SLA due date calculated | 30 days from submission |
| 6.2 | Advance time to day 25 | Reminder task created | Task type `sla_reminder` |
| 6.3 | Advance time to day 30 | Follow-up task created | Task type `sla_follow_up` |
| 6.4 | Mark SLA extended | Due date extended | 45 days total |
| 6.5 | Verify notifications | Emails/SMS sent | Notification status `sent` |

**Test Script:**
```javascript
// test/e2e/sla-monitoring.test.js
describe('SLA Monitoring', () => {
  it('should create follow-up tasks as SLA approaches', async () => {
    // Create and submit dispute
    const dispute = await createAndSubmitDispute();

    // Fast-forward time to day 25 (5 days before due)
    await setMockTime(addDays(dispute.timestamps.submittedAt, 25));
    await triggerScheduledFunction('sla-checker');

    // Verify reminder task created
    const tasks = await getScheduledTasks(dispute.id);
    const reminderTask = tasks.find(t => t.type === 'sla_reminder');
    expect(reminderTask).toBeDefined();
    expect(reminderTask.metadata.daysUntilDue).toBe(5);

    // Fast-forward to day 30 (due date)
    await setMockTime(addDays(dispute.timestamps.submittedAt, 30));
    await triggerScheduledFunction('sla-checker');

    // Verify follow-up task created
    const followUpTask = tasks.find(t => t.type === 'sla_follow_up');
    expect(followUpTask).toBeDefined();
  });
});
```

---

#### Test Suite 7: Reconciliation and Outcomes

| Step | Action | Expected Result | Validation |
|------|--------|-----------------|------------|
| 7.1 | Pull fresh report | New report stored | Different `reportId` |
| 7.2 | Compare tradelines | Changes detected | Diff calculated |
| 7.3 | Auto-close corrected | Dispute closed | `outcome: corrected` |
| 7.4 | Flag unresolved | Reinvestigation queued | New task created |
| 7.5 | Verify audit trail | All changes logged | Complete history |

**Test Script:**
```javascript
// test/e2e/reconciliation.test.js
describe('Outcome Reconciliation', () => {
  it('should auto-close dispute when tradeline corrected', async () => {
    // Setup: Create dispute for balance issue
    const dispute = await createDispute({
      reasonCodes: ['inaccurate_balance'],
      reasonDetails: {
        inaccurate_balance: {
          reportedValue: 3450.00,
          actualValue: 2890.00
        }
      }
    });

    // Mail the letter
    await sendLetter(dispute.id);
    await simulateLobWebhook('letter.delivered', { id: dispute.letterId });

    // Simulate SmartCredit returning corrected data
    mockSmartCreditResponse({
      tradelineId: dispute.tradelineId,
      balance: 2890.00 // Now matches claimed actual value
    });

    // Trigger reconciliation
    await triggerScheduledFunction('reconciliation');

    // Verify dispute auto-closed
    const updatedDispute = await getDispute(dispute.id);
    expect(updatedDispute.status).toBe('resolved');
    expect(updatedDispute.outcome).toBe('corrected');
    expect(updatedDispute.outcomeDetails.balanceCorrected).toBe(true);

    // Verify audit log
    const auditLogs = await getAuditLogs('dispute', dispute.id);
    const closeLog = auditLogs.find(l => l.action === 'auto_close');
    expect(closeLog).toBeDefined();
    expect(closeLog.newState.outcome).toBe('corrected');
  });
});
```

---

#### Test Suite 8: Full End-to-End Workflow

| Step | Action | Expected Result |
|------|--------|-----------------|
| 8.1 | Create consumer | Consumer created with encrypted PII |
| 8.2 | Connect SmartCredit | OAuth tokens stored |
| 8.3 | Pull 3-bureau reports | Reports and tradelines created |
| 8.4 | Identify issue | Tradeline with inaccuracy found |
| 8.5 | Create dispute | Dispute created with narrative |
| 8.6 | Upload evidence | Evidence scanned and stored |
| 8.7 | Submit for review | Status changed to pending_review |
| 8.8 | Approve dispute | Status changed to approved |
| 8.9 | Generate letter | PDF rendered with all variables |
| 8.10 | Send via Lob | Letter queued and sent |
| 8.11 | Track delivery | Webhook updates status to delivered |
| 8.12 | Monitor SLA | Reminder tasks created |
| 8.13 | Refresh report | New report pulled |
| 8.14 | Reconcile outcome | Dispute closed if corrected |
| 8.15 | Export audit log | Complete chain of custody |

**Test Script:**
```javascript
// test/e2e/full-workflow.test.js
describe('Full Dispute Workflow E2E', () => {
  it('should complete entire dispute lifecycle', async () => {
    // 1. Create consumer
    const consumer = await createConsumer(testConsumerData);
    expect(consumer.id).toBeDefined();

    // 2. Connect SmartCredit
    const connection = await connectSmartCredit(consumer.id);
    expect(connection.status).toBe('connected');

    // 3. Pull reports
    await refreshReports(consumer.id);
    const tradelines = await getTradelines(consumer.id);
    expect(tradelines.length).toBeGreaterThan(0);

    // 4. Find disputable tradeline
    const targetTradeline = tradelines.find(t =>
      t.balance > 0 && t.paymentStatus === '30_days_late'
    );
    expect(targetTradeline).toBeDefined();

    // 5. Create dispute
    const dispute = await createDispute({
      consumerId: consumer.id,
      tradelineId: targetTradeline.id,
      bureau: targetTradeline.bureau,
      type: '611_dispute',
      reasonCodes: ['incorrect_late_payment']
    });
    expect(dispute.status).toBe('draft');

    // 6. Upload evidence
    const evidence = await uploadEvidence(dispute.id, 'bank_statement.pdf');
    expect(evidence.virusScan.status).toBe('clean');

    // 7. Submit
    await updateDispute(dispute.id, { status: 'pending_review' });

    // 8. Approve
    await updateDispute(dispute.id, { status: 'approved' });

    // 9. Generate letter
    const letter = await generateLetter(dispute.id);
    expect(letter.qualityChecks.allFieldsComplete).toBe(true);

    // 10. Send
    const sentLetter = await sendLetter(letter.id);
    expect(sentLetter.lobId).toBeDefined();

    // 11. Simulate delivery
    await simulateLobWebhook('letter.delivered', { id: sentLetter.lobId });
    const deliveredLetter = await getLetter(letter.id);
    expect(deliveredLetter.status).toBe('delivered');

    // 12. Verify SLA task
    const tasks = await getScheduledTasks(dispute.id);
    expect(tasks.length).toBeGreaterThan(0);

    // 13. Simulate correction and reconcile
    mockSmartCreditCorrectedTradeline(targetTradeline.id);
    await triggerScheduledFunction('reconciliation');

    // 14. Verify outcome
    const finalDispute = await getDispute(dispute.id);
    expect(finalDispute.status).toBe('resolved');
    expect(finalDispute.outcome).toBe('corrected');

    // 15. Export audit
    const auditExport = await exportAuditTrail(dispute.id);
    expect(auditExport.events.length).toBeGreaterThan(10);
    expect(auditExport.pdfArchiveUrl).toBeDefined();
  });
});
```

---

### 6.3 Test Execution Commands

```bash
# Run all E2E tests
npm run test:e2e

# Run specific test suite
npm run test:e2e -- --grep "Consumer Onboarding"

# Run with Firebase emulators
firebase emulators:exec "npm run test:e2e"

# Generate coverage report
npm run test:e2e:coverage

# Run load tests
npm run test:load -- --vus 50 --duration 5m
```

### 6.4 Test Environment Cleanup

```javascript
// test/helpers/cleanup.js
async function cleanupTestData() {
  const testTenantId = 'tenant_test_001';

  // Delete test consumers and subcollections
  await deleteCollection(`consumers`, { tenantId: testTenantId });

  // Delete test disputes
  await deleteCollection(`disputes`, { tenantId: testTenantId });

  // Delete test letters
  await deleteCollection(`letters`, { tenantId: testTenantId });

  // Clean up Storage
  await deleteStorageFolder(`sfdify-letters/${testTenantId}`);
  await deleteStorageFolder(`sfdify-evidence/${testTenantId}`);

  // Clean up audit logs (keep for compliance, just mark as test)
  await markAuditLogsAsTest(testTenantId);
}
```

---

## 7. Security and Compliance Checklist

### 7.1 FCRA Compliance Checklist

| Requirement | Section | Implementation | Status |
|-------------|---------|----------------|--------|
| **Consumer Disclosure** | 609 | Provide complete file disclosure on request | ☐ |
| **Dispute Investigation** | 611 | Complete investigation within 30 days | ☐ |
| **Reinvestigation** | 611(a)(1) | Forward dispute info to furnisher | ☐ |
| **Notification of Results** | 611(a)(6) | Notify consumer within 5 days of completion | ☐ |
| **Free Report on Dispute** | 611(d) | Provide free report if info modified | ☐ |
| **Identity Theft Block** | 605B | Block fraudulent info within 4 business days | ☐ |
| **Accuracy Requirements** | 607 | Maintain reasonable procedures for accuracy | ☐ |
| **Permissible Purpose** | 604 | Only access reports for permissible purposes | ☐ |
| **Consumer Consent** | 604(a)(2) | Obtain written consent before pulling reports | ☐ |
| **Adverse Action Notice** | 615 | N/A (not taking adverse action) | ☐ |

### 7.2 GLBA Safeguards Rule Checklist

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| **Designate Qualified Individual** | Assign security program coordinator | ☐ |
| **Risk Assessment** | Document risks to customer information | ☐ |
| **Access Controls** | Role-based access, least privilege principle | ☐ |
| **Encryption** | AES-256 for PII at rest, TLS 1.3 in transit | ☐ |
| **Secure Development** | Security code reviews, penetration testing | ☐ |
| **Authentication** | Multi-factor authentication for operators | ☐ |
| **Employee Training** | Annual security awareness training | ☐ |
| **Service Provider Oversight** | Vendor security assessments (Lob, SmartCredit) | ☐ |
| **Incident Response Plan** | Documented breach response procedures | ☐ |
| **Change Management** | Evaluate security impact of system changes | ☐ |
| **Continuous Monitoring** | Security logging and alerting | ☐ |
| **Disposal** | Secure deletion of customer information | ☐ |
| **Annual Assessment** | Evaluate safeguards program effectiveness | ☐ |

### 7.3 Technical Security Controls

#### 7.3.1 Data Encryption

| Data Type | At Rest | In Transit | Key Management |
|-----------|---------|------------|----------------|
| SSN (last 4) | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| DOB | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| Full Name | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| Addresses | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| Credit Reports | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| OAuth Tokens | AES-256-GCM | TLS 1.3 | Cloud KMS, rotated quarterly |
| PDF Letters | At-rest encryption (GCS) | Signed URLs | Google-managed |
| Evidence Files | At-rest encryption (GCS) | Signed URLs | Google-managed |

**Implementation:**
```javascript
// functions/src/utils/encryption.js
const { KeyManagementServiceClient } = require('@google-cloud/kms');

const kmsClient = new KeyManagementServiceClient();
const keyName = `projects/${PROJECT_ID}/locations/global/keyRings/sfdify-pii/cryptoKeys/pii-encryption-key`;

async function encryptPii(plaintext) {
  const [result] = await kmsClient.encrypt({
    name: keyName,
    plaintext: Buffer.from(plaintext),
  });
  return `enc:KMS:${result.ciphertext.toString('base64')}`;
}

async function decryptPii(ciphertext) {
  const encoded = ciphertext.replace('enc:KMS:', '');
  const [result] = await kmsClient.decrypt({
    name: keyName,
    ciphertext: Buffer.from(encoded, 'base64'),
  });
  return result.plaintext.toString();
}
```

#### 7.3.2 Authentication and Authorization

| Control | Implementation |
|---------|----------------|
| User Authentication | Firebase Auth with email/password, Google, Microsoft SSO |
| MFA | TOTP-based 2FA required for operators and owners |
| Session Management | Firebase ID tokens, 1-hour expiry, refresh tokens |
| Role-Based Access | Custom claims: owner, operator, viewer, auditor |
| Tenant Isolation | `tenantId` in token, enforced in security rules |
| API Authentication | Firebase ID token required for all endpoints |
| Webhook Authentication | HMAC signature verification (Lob, SmartCredit) |

**Firestore Security Rules:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function getTenantId() {
      return request.auth.token.tenantId;
    }

    function getRole() {
      return request.auth.token.role;
    }

    function hasRole(allowedRoles) {
      return getRole() in allowedRoles;
    }

    function isTenantMember() {
      return resource.data.tenantId == getTenantId();
    }

    // Consumers collection
    match /consumers/{consumerId} {
      allow read: if isAuthenticated()
        && isTenantMember()
        && hasRole(['owner', 'operator', 'viewer', 'auditor']);

      allow create: if isAuthenticated()
        && request.resource.data.tenantId == getTenantId()
        && hasRole(['owner', 'operator']);

      allow update: if isAuthenticated()
        && isTenantMember()
        && hasRole(['owner', 'operator']);

      allow delete: if isAuthenticated()
        && isTenantMember()
        && hasRole(['owner']);

      // Subcollections
      match /creditReports/{reportId} {
        allow read: if isAuthenticated() && isTenantMember();
        allow write: if false; // Only Cloud Functions can write
      }
    }

    // Disputes collection
    match /disputes/{disputeId} {
      allow read: if isAuthenticated()
        && isTenantMember()
        && hasRole(['owner', 'operator', 'viewer', 'auditor']);

      allow create: if isAuthenticated()
        && request.resource.data.tenantId == getTenantId()
        && hasRole(['owner', 'operator']);

      allow update: if isAuthenticated()
        && isTenantMember()
        && hasRole(['owner', 'operator']);

      allow delete: if false; // Never delete disputes
    }

    // Audit logs - read only for auditors
    match /auditLogs/{logId} {
      allow read: if isAuthenticated()
        && resource.data.tenantId == getTenantId()
        && hasRole(['owner', 'auditor']);

      allow write: if false; // Only Cloud Functions can write
    }
  }
}
```

#### 7.3.3 Audit Logging

| Event Type | Logged Fields | Retention |
|------------|---------------|-----------|
| User login | userId, timestamp, IP, userAgent, success/failure | 7 years |
| Consumer create/update | actorId, changes, timestamp, IP | 7 years |
| Credit report pull | consumerId, bureau, timestamp, source | 7 years |
| Dispute actions | disputeId, action, previousState, newState | 7 years |
| Letter generation | letterId, templateId, timestamp | 7 years |
| Letter sent | letterId, lobId, mailType, cost | 7 years |
| Evidence upload | evidenceId, filename, checksum | 7 years |
| Webhook received | provider, eventType, payload hash | 7 years |
| API errors | endpoint, error, requestId | 1 year |
| Admin actions | adminId, action, targetEntity | 7 years |

**Audit Log Implementation:**
```javascript
// functions/src/utils/audit.js
async function logAuditEvent({
  tenantId,
  actorId,
  actorRole,
  actorIp,
  entity,
  entityId,
  action,
  previousState,
  newState,
  metadata
}) {
  const diffJson = generateDiff(previousState, newState);

  await firestore.collection('auditLogs').add({
    id: uuidv4(),
    tenantId,
    actorId,
    actorRole,
    actorIp,
    userAgent: metadata?.userAgent,
    entity,
    entityId,
    entityPath: `${entity}/${entityId}`,
    action,
    actionDetail: metadata?.actionDetail,
    previousState: sanitizeForLog(previousState),
    newState: sanitizeForLog(newState),
    diffJson,
    metadata: {
      source: metadata?.source || 'api',
      sessionId: metadata?.sessionId,
      requestId: metadata?.requestId
    },
    timestamp: FieldValue.serverTimestamp(),
    retentionUntil: addYears(new Date(), 7)
  });
}

// Sanitize PII from logs
function sanitizeForLog(data) {
  if (!data) return null;
  const sanitized = { ...data };
  const piiFields = ['ssnLast4', 'dob', 'firstName', 'lastName'];
  piiFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  });
  return sanitized;
}
```

#### 7.3.4 File Security

| Control | Implementation |
|---------|----------------|
| Upload validation | MIME type verification, file extension whitelist |
| Virus scanning | ClamAV scan on all uploads |
| Size limits | Max 10MB per file, 50MB per dispute |
| Access control | Signed URLs with 15-minute expiry |
| Storage encryption | Google Cloud Storage default encryption |

**File Upload Security:**
```javascript
// functions/src/utils/fileValidation.js
const allowedMimeTypes = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/gif',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
];

const maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

async function validateUpload(file) {
  // Check MIME type
  if (!allowedMimeTypes.includes(file.mimetype)) {
    throw new Error(`Invalid file type: ${file.mimetype}`);
  }

  // Check file size
  if (file.size > maxFileSizeBytes) {
    throw new Error(`File too large: ${file.size} bytes`);
  }

  // Verify MIME type matches content (magic bytes)
  const detectedType = await detectMimeType(file.buffer);
  if (detectedType !== file.mimetype) {
    throw new Error('File content does not match declared MIME type');
  }

  // Virus scan
  const scanResult = await scanForVirus(file.buffer);
  if (scanResult.infected) {
    throw new Error(`Virus detected: ${scanResult.virus}`);
  }

  return {
    valid: true,
    checksum: calculateChecksum(file.buffer),
    scannedAt: new Date().toISOString()
  };
}
```

#### 7.3.5 API Security

| Control | Implementation |
|---------|----------------|
| Rate limiting | 100 requests/minute per user, 1000/minute per tenant |
| Input validation | Joi schema validation on all inputs |
| Output sanitization | Remove internal fields from responses |
| CORS | Restrict to allowed origins |
| Request signing | Idempotency keys for mutations |
| Error handling | Generic errors to clients, detailed internal logging |

### 7.4 Privacy Controls

| Requirement | Implementation |
|-------------|----------------|
| Consent capture | Timestamp, IP, terms version recorded |
| Right to access | Export consumer data via admin function |
| Right to deletion | Soft delete with 30-day grace period |
| Data minimization | Only collect required fields |
| Purpose limitation | Data used only for dispute processing |
| Retention limits | Auto-delete after 7 years (configurable per tenant) |

### 7.5 Incident Response Plan

```markdown
## Security Incident Response Procedures

### 1. Detection
- Monitor Cloud Functions logs for anomalies
- Alert on unusual API patterns (spike in 401/403 errors)
- Webhook validation failures trigger alerts

### 2. Classification
- Level 1: Suspicious activity (investigate within 4 hours)
- Level 2: Confirmed unauthorized access (respond within 1 hour)
- Level 3: Data breach confirmed (respond immediately)

### 3. Containment
- Revoke compromised user sessions
- Rotate affected API keys
- Disable affected Cloud Functions if necessary
- Block suspicious IP addresses

### 4. Eradication
- Patch vulnerability
- Remove malicious access
- Restore from clean backup if needed

### 5. Recovery
- Verify system integrity
- Re-enable services
- Monitor for recurrence

### 6. Notification (if data breach)
- Notify affected consumers within 72 hours
- Report to regulators as required
- Document all actions taken

### 7. Post-Incident Review
- Root cause analysis
- Update security controls
- Train staff on lessons learned
```

### 7.6 Compliance Documentation

| Document | Purpose | Update Frequency |
|----------|---------|------------------|
| Privacy Policy | Consumer data practices | Annual or on change |
| FCRA Disclosure | Consumer rights under FCRA | Annual or on change |
| Terms of Service | Service agreement | Annual or on change |
| Security Policy | Internal security procedures | Annual |
| Incident Response Plan | Breach response procedures | Annual |
| Vendor Assessment | Third-party security review | Annual |
| Penetration Test Report | Security vulnerability assessment | Annual |
| SOC 2 Report | (If applicable) Service organization controls | Annual |

---

## 8. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

#### Week 1: Project Setup
- [ ] Initialize Firebase project with Firestore, Auth, Functions, Storage
- [ ] Configure development, staging, and production environments
- [ ] Set up Cloud KMS for PII encryption
- [ ] Configure Secret Manager for API keys
- [ ] Set up CI/CD pipeline (GitHub Actions)
- [ ] Create base Flutter project structure (already done)
- [ ] Configure Firebase emulators for local development

#### Week 2: Core Data Models and Security
- [ ] Implement Firestore collections and indexes
- [ ] Write security rules for all collections
- [ ] Implement PII encryption/decryption utilities
- [ ] Create audit logging middleware
- [ ] Implement RBAC system with custom claims
- [ ] Build tenant isolation layer
- [ ] Unit tests for encryption and security

#### Week 3: Consumer Management
- [ ] Build consumer CRUD Cloud Functions
- [ ] Implement consent capture flow
- [ ] Build address validation service
- [ ] Create consumer profile UI in Flutter
- [ ] Implement KYC status tracking
- [ ] Build consumer search and listing
- [ ] Integration tests for consumer APIs

#### Week 4: SmartCredit Integration Foundation
- [ ] Set up SmartCredit sandbox account
- [ ] Implement OAuth 2.0 flow
- [ ] Build token storage and refresh logic
- [ ] Create credit report pull function
- [ ] Implement tradeline normalization
- [ ] Build report comparison utilities
- [ ] Test with SmartCredit sandbox data

**Milestone 1 Deliverables:**
- Consumer onboarding working
- SmartCredit OAuth flow complete
- 3-bureau report pulling functional
- Security rules and encryption verified

---

### Phase 2: Dispute Engine (Weeks 5-8)

#### Week 5: Dispute Core
- [ ] Implement dispute CRUD Cloud Functions
- [ ] Build dispute status state machine
- [ ] Create reason code catalog
- [ ] Implement narrative composition
- [ ] Build dispute assignment workflow
- [ ] Create dispute listing and filtering UI
- [ ] Unit tests for status transitions

#### Week 6: Evidence Management
- [ ] Implement file upload Cloud Function
- [ ] Build virus scanning integration
- [ ] Create evidence linking to disputes
- [ ] Implement checksum verification
- [ ] Build evidence viewer UI
- [ ] Create evidence index generator
- [ ] Security testing for file uploads

#### Week 7: Letter Templates
- [ ] Design template schema
- [ ] Implement 8 base templates
- [ ] Build Handlebars template engine
- [ ] Create variable extraction from disputes
- [ ] Implement bureau address lookup
- [ ] Build template preview functionality
- [ ] Test all templates with sample data

#### Week 8: PDF Generation
- [ ] Implement PDF rendering service
- [ ] Build HTML-to-PDF conversion
- [ ] Create letterhead integration
- [ ] Implement evidence attachment
- [ ] Build PDF hash verification
- [ ] Create PDF preview and download
- [ ] Performance testing for rendering

**Milestone 2 Deliverables:**
- Full dispute creation workflow
- All 8 letter templates implemented
- Evidence upload and management
- PDF generation working

---

### Phase 3: Mailing Integration (Weeks 9-10)

#### Week 9: Lob Integration
- [ ] Set up Lob test account
- [ ] Implement address verification API
- [ ] Build letter creation function
- [ ] Implement mail type selection (First Class, Certified)
- [ ] Create webhook endpoint for Lob events
- [ ] Build tracking status updates
- [ ] Implement idempotency for send requests

#### Week 10: Mail Tracking and Notifications
- [ ] Build delivery event processing
- [ ] Implement status progression logic
- [ ] Create notification triggers
- [ ] Build email notification service (SendGrid)
- [ ] Implement SMS notifications (Twilio)
- [ ] Create notification preferences UI
- [ ] End-to-end testing with Lob sandbox

**Milestone 3 Deliverables:**
- Letters sending via Lob
- Mail tracking working
- Notifications operational
- Full send-and-track workflow tested

---

### Phase 4: SLA and Reconciliation (Weeks 11-12)

#### Week 11: SLA Management
- [ ] Implement SLA calculation logic
- [ ] Build scheduled task system
- [ ] Create SLA reminder generation
- [ ] Implement follow-up task creation
- [ ] Build SLA extension handling
- [ ] Create SLA dashboard UI
- [ ] Test SLA edge cases

#### Week 12: Outcome Reconciliation
- [ ] Implement report refresh scheduling
- [ ] Build tradeline comparison logic
- [ ] Create auto-close for corrected disputes
- [ ] Implement reinvestigation triggers
- [ ] Build outcome tracking
- [ ] Create reconciliation reports
- [ ] End-to-end SLA and reconciliation tests

**Milestone 4 Deliverables:**
- Automated SLA monitoring
- Outcome reconciliation working
- Follow-up workflow automated
- Complete dispute lifecycle

---

### Phase 5: Admin and Compliance (Weeks 13-14)

#### Week 13: Admin Features
- [ ] Build analytics dashboards
- [ ] Implement billing usage tracking
- [ ] Create tenant management UI
- [ ] Build user management features
- [ ] Implement audit log viewer
- [ ] Create export functionality
- [ ] Build CFPB complaint package export

#### Week 14: Compliance and Security Hardening
- [ ] Implement data retention policies
- [ ] Build consumer data export
- [ ] Create deletion request handling
- [ ] Conduct security code review
- [ ] Perform penetration testing
- [ ] Document compliance procedures
- [ ] Create runbooks and documentation

**Milestone 5 Deliverables:**
- Admin dashboard complete
- Compliance features implemented
- Security audit passed
- Documentation complete

---

### Phase 6: Testing and Launch (Weeks 15-16)

#### Week 15: Comprehensive Testing
- [ ] Complete E2E test suite execution
- [ ] Perform load testing
- [ ] Execute security penetration testing
- [ ] User acceptance testing with pilot tenant
- [ ] Bug fixes and refinements
- [ ] Performance optimization
- [ ] Final security review

#### Week 16: Production Launch
- [ ] Production environment setup
- [ ] Data migration (if applicable)
- [ ] Production credentials configuration
- [ ] Monitoring and alerting setup
- [ ] Launch to pilot tenants
- [ ] Monitor and support
- [ ] Post-launch assessment

**Final Deliverables:**
- Production system live
- All tests passing
- Documentation complete
- Monitoring operational

---

### Key Milestones Summary

| Milestone | Week | Description |
|-----------|------|-------------|
| M1 | 4 | Consumer onboarding + SmartCredit integration |
| M2 | 8 | Dispute engine + letter generation |
| M3 | 10 | Lob mailing + notifications |
| M4 | 12 | SLA monitoring + reconciliation |
| M5 | 14 | Admin features + compliance |
| M6 | 16 | Production launch |

### Resource Requirements

| Role | Allocation | Responsibilities |
|------|------------|------------------|
| Full-stack Developer | 100% | Flutter UI, Cloud Functions, integrations |
| Backend Developer | 100% | Cloud Functions, data models, security |
| DevOps Engineer | 50% | CI/CD, infrastructure, monitoring |
| QA Engineer | 50% | Testing, automation, security testing |
| Product Manager | 25% | Requirements, prioritization, UAT |
| Security Consultant | 10% | Security review, penetration testing |

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| SmartCredit API changes | Use adapter pattern, version API calls |
| Lob rate limits | Implement queue with backoff, cache addresses |
| PII data breach | Encryption at rest/transit, access controls, auditing |
| Compliance violations | Legal review, regular audits, documentation |
| Performance issues | Load testing, CDN for PDFs, async processing |

---

## 9. Appendix

### 9.1 Bureau Addresses

```javascript
const BUREAU_ADDRESSES = {
  equifax: {
    name: 'Equifax Information Services LLC',
    addressLine1: 'P.O. Box 740256',
    city: 'Atlanta',
    state: 'GA',
    zipCode: '30374-0256'
  },
  experian: {
    name: 'Experian',
    addressLine1: 'P.O. Box 4500',
    city: 'Allen',
    state: 'TX',
    zipCode: '75013'
  },
  transunion: {
    name: 'TransUnion LLC',
    addressLine1: 'P.O. Box 2000',
    city: 'Chester',
    state: 'PA',
    zipCode: '19016'
  }
};
```

### 9.2 Dispute Reason Codes

```javascript
const DISPUTE_REASON_CODES = {
  not_mine: {
    code: 'NOT_MINE',
    description: 'This account does not belong to me',
    fcraSection: '611'
  },
  inaccurate_balance: {
    code: 'INACCURATE_BALANCE',
    description: 'The reported balance is incorrect',
    fcraSection: '611'
  },
  paid_but_showing_open: {
    code: 'PAID_SHOWING_OPEN',
    description: 'Account is paid but reporting as open/unpaid',
    fcraSection: '611'
  },
  wrong_dates: {
    code: 'WRONG_DATES',
    description: 'Account dates are incorrect',
    fcraSection: '611'
  },
  duplicate_account: {
    code: 'DUPLICATE',
    description: 'This account appears multiple times',
    fcraSection: '611'
  },
  obsolete: {
    code: 'OBSOLETE',
    description: 'This information is too old to report',
    fcraSection: '605'
  },
  re_aged: {
    code: 'RE_AGED',
    description: 'Account dates have been improperly updated',
    fcraSection: '605'
  },
  incorrect_late_payment: {
    code: 'INCORRECT_LATE',
    description: 'Late payment status is incorrect',
    fcraSection: '611'
  },
  identity_theft: {
    code: 'ID_THEFT',
    description: 'Account opened fraudulently',
    fcraSection: '605B'
  },
  wrong_status: {
    code: 'WRONG_STATUS',
    description: 'Account status is incorrect',
    fcraSection: '611'
  }
};
```

### 9.3 Letter Status Flow

```
draft → pending_approval → approved → rendering → ready → queued → sent → in_transit → delivered
                                                                            ↓
                                                                      returned_to_sender
```

### 9.4 Dispute Status Flow

```
draft → pending_review → approved → mailed → delivered → bureau_investigating → resolved
           ↓                                                                      ↓
        rejected                                                               closed
```

---

*Document Version: 1.0*
*Last Updated: January 2025*
*Author: SFDIFY Architecture Team*
