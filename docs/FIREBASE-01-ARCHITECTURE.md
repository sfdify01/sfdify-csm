# SFDIFY Credit Dispute System - Firebase Architecture

## Document Info
| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-01-15 | SFDIFY Team |

---

## 1. Overview

SFDIFY is a multi-tenant SaaS platform for automating consumer credit disputes under FCRA regulations. This document describes the complete Firebase-based architecture.

### 1.1 Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Web) |
| **Backend** | Firebase Cloud Functions (Node.js 20) |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Authentication |
| **File Storage** | Firebase Storage |
| **Hosting** | Firebase Hosting |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Analytics** | Firebase Analytics |
| **Monitoring** | Firebase Crashlytics, Performance Monitoring |
| **External APIs** | SmartCredit API, Lob API |

### 1.2 Firebase Project Structure

```
sfdify-production/
├── Authentication
│   ├── Email/Password
│   ├── Custom Claims (roles, tenantId)
│   └── Multi-factor Authentication
├── Firestore Database
│   ├── tenants/
│   ├── users/
│   ├── consumers/
│   ├── creditReports/
│   ├── tradelines/
│   ├── disputes/
│   ├── letters/
│   ├── letterTemplates/
│   ├── evidence/
│   ├── mailings/
│   ├── webhookEvents/
│   └── auditLogs/
├── Cloud Functions
│   ├── auth/
│   ├── consumers/
│   ├── smartcredit/
│   ├── disputes/
│   ├── letters/
│   ├── lob/
│   ├── webhooks/
│   ├── scheduled/
│   └── triggers/
├── Storage
│   ├── evidence/
│   ├── letters/
│   └── exports/
└── Hosting
    └── Flutter Web App
```

---

## 2. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER CLIENTS                                 │
│                     (Web / iOS / Android)                                    │
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Auth      │  │  Disputes   │  │   Letters   │  │  Dashboard  │        │
│  │   Module    │  │   Module    │  │   Module    │  │   Module    │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                │                │
│         └────────────────┴────────────────┴────────────────┘                │
│                                   │                                          │
│                          Firebase SDK                                        │
└───────────────────────────────────┼──────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                           FIREBASE PLATFORM                                    │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │                      FIREBASE AUTHENTICATION                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │   │
│  │  │ Email/Pass   │  │ Custom Claims │  │     MFA      │                  │   │
│  │  │    Auth      │  │ (role,tenant) │  │   (TOTP)     │                  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │                        CLOUD FIRESTORE                                  │   │
│  │                                                                         │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │ tenants │ │  users  │ │consumers│ │disputes │ │ letters │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │credit   │ │trade    │ │evidence │ │mailings │ │ audit   │          │   │
│  │  │Reports  │ │lines    │ │         │ │         │ │ Logs    │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │                       CLOUD FUNCTIONS                                   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    HTTPS CALLABLE FUNCTIONS                      │   │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │   │   │
│  │  │  │  Auth    │ │ Consumer │ │ Dispute  │ │  Letter  │            │   │   │
│  │  │  │ Functions│ │ Functions│ │ Functions│ │ Functions│            │   │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    FIRESTORE TRIGGERS                            │   │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │   │   │
│  │  │  │ onCreate │ │ onUpdate │ │ onDelete │ │  onWrite │            │   │   │
│  │  │  │ Dispute  │ │  Letter  │ │ Consumer │ │  Mailing │            │   │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    SCHEDULED FUNCTIONS                           │   │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │   │   │
│  │  │  │   SLA    │ │  Credit  │ │  Report  │ │  Cleanup │            │   │   │
│  │  │  │  Check   │ │  Refresh │ │Generator │ │   Jobs   │            │   │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    WEBHOOK HANDLERS                              │   │   │
│  │  │  ┌────────────────────┐  ┌────────────────────┐                 │   │   │
│  │  │  │  Lob Webhooks      │  │ SmartCredit Webhooks│                 │   │   │
│  │  │  │  (mail tracking)   │  │  (report updates)   │                 │   │   │
│  │  │  └────────────────────┘  └────────────────────┘                 │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │                       FIREBASE STORAGE                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │   │
│  │  │   evidence/  │  │   letters/   │  │   exports/   │                  │   │
│  │  │  (uploads)   │  │   (PDFs)     │  │  (reports)   │                  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │                    FIREBASE EXTENSIONS                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │   │
│  │  │  Resize      │  │   Delete     │  │   Stream     │                  │   │
│  │  │  Images      │  │   User Data  │  │   to BigQuery│                  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
└───────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL SERVICES                                     │
│                                                                                │
│  ┌────────────────────────────┐    ┌────────────────────────────┐             │
│  │      SMARTCREDIT API       │    │         LOB API            │             │
│  │                            │    │                            │             │
│  │  • OAuth 2.0 Connection    │    │  • Letter Creation         │             │
│  │  • 3-Bureau Credit Pull    │    │  • Certified Mail          │             │
│  │  • Report Webhooks         │    │  • Delivery Tracking       │             │
│  │  • Score Updates           │    │  • Return Mail Handling    │             │
│  │                            │    │                            │             │
│  └────────────────────────────┘    └────────────────────────────┘             │
│                                                                                │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Multi-Tenancy Architecture

### 3.1 Tenant Isolation Strategy

Firebase multi-tenancy is implemented using:
1. **Custom Claims** - `tenantId` stored in Firebase Auth token
2. **Security Rules** - All queries filtered by `tenantId`
3. **Collection Structure** - Tenant ID as document field

```
┌─────────────────────────────────────────────────────────────────┐
│                    MULTI-TENANCY MODEL                          │
│                                                                 │
│  User Login → Firebase Auth → Custom Claims { tenantId, role }  │
│                                      │                          │
│                                      ▼                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              FIRESTORE SECURITY RULES                    │   │
│  │                                                          │   │
│  │  match /consumers/{consumerId} {                         │   │
│  │    allow read, write: if                                 │   │
│  │      request.auth.token.tenantId == resource.data.tenantId│  │
│  │  }                                                       │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Tenant A Data ──────► Only Tenant A Users Can Access           │
│  Tenant B Data ──────► Only Tenant B Users Can Access           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Role-Based Access Control (RBAC)

| Role | Description | Permissions |
|------|-------------|-------------|
| **owner** | Tenant administrator | Full access to all tenant data, user management, billing |
| **operator** | Staff member | CRUD consumers, disputes, letters; cannot manage users |
| **viewer** | Read-only access | View consumers, disputes, letters; no modifications |
| **auditor** | Compliance reviewer | Read all data + audit logs; no modifications |

Custom claims structure:
```json
{
  "tenantId": "tenant_abc123",
  "role": "operator",
  "permissions": ["consumers:read", "consumers:write", "disputes:read", "disputes:write"]
}
```

---

## 4. Authentication Flow

### 4.1 User Registration & Login

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION FLOW                               │
│                                                                          │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────────────────┐   │
│  │  Flutter │      │   Firebase   │      │    Cloud Function        │   │
│  │   App    │      │     Auth     │      │   (setCustomClaims)      │   │
│  └────┬─────┘      └──────┬───────┘      └────────────┬─────────────┘   │
│       │                   │                           │                  │
│       │  1. signUp()      │                           │                  │
│       │──────────────────►│                           │                  │
│       │                   │                           │                  │
│       │  2. User Created  │                           │                  │
│       │◄──────────────────│                           │                  │
│       │                   │                           │                  │
│       │  3. Call initializeUser()                     │                  │
│       │──────────────────────────────────────────────►│                  │
│       │                   │                           │                  │
│       │                   │  4. Set Custom Claims     │                  │
│       │                   │◄──────────────────────────│                  │
│       │                   │                           │                  │
│       │  5. Force Token Refresh                       │                  │
│       │◄──────────────────────────────────────────────│                  │
│       │                   │                           │                  │
│       │  6. getIdToken(forceRefresh: true)            │                  │
│       │──────────────────►│                           │                  │
│       │                   │                           │                  │
│       │  7. Token with Claims                         │                  │
│       │◄──────────────────│                           │                  │
│       │                   │                           │                  │
└───────┴───────────────────┴───────────────────────────┴──────────────────┘
```

### 4.2 Token Structure

```json
{
  "iss": "https://securetoken.google.com/sfdify-production",
  "aud": "sfdify-production",
  "auth_time": 1705315200,
  "user_id": "user_xyz789",
  "sub": "user_xyz789",
  "iat": 1705315200,
  "exp": 1705318800,
  "email": "operator@company.com",
  "email_verified": true,
  "tenantId": "tenant_abc123",
  "role": "operator",
  "permissions": ["consumers:read", "consumers:write", "disputes:read", "disputes:write"],
  "firebase": {
    "identities": {
      "email": ["operator@company.com"]
    },
    "sign_in_provider": "password"
  }
}
```

---

## 5. Cloud Functions Architecture

### 5.1 Function Organization

```
functions/
├── src/
│   ├── index.ts                 # Main exports
│   ├── config/
│   │   ├── firebase.ts          # Firebase Admin initialization
│   │   ├── secrets.ts           # Secret Manager access
│   │   └── constants.ts         # App constants
│   │
│   ├── auth/
│   │   ├── onCreate.ts          # New user trigger
│   │   ├── onDelete.ts          # User deletion trigger
│   │   ├── initializeUser.ts    # Set custom claims
│   │   └── updateRole.ts        # Change user role
│   │
│   ├── consumers/
│   │   ├── create.ts            # Create consumer
│   │   ├── update.ts            # Update consumer
│   │   ├── delete.ts            # Delete consumer
│   │   └── search.ts            # Search consumers
│   │
│   ├── smartcredit/
│   │   ├── initiateOAuth.ts     # Start OAuth flow
│   │   ├── handleCallback.ts    # OAuth callback
│   │   ├── pullReport.ts        # Pull credit report
│   │   ├── refreshReport.ts     # Refresh existing report
│   │   └── parseReport.ts       # Parse report data
│   │
│   ├── disputes/
│   │   ├── create.ts            # Create dispute
│   │   ├── update.ts            # Update dispute
│   │   ├── addEvidence.ts       # Add evidence to dispute
│   │   ├── updateStatus.ts      # Status transitions
│   │   └── onStatusChange.ts    # Trigger on status change
│   │
│   ├── letters/
│   │   ├── generate.ts          # Generate letter
│   │   ├── preview.ts           # Preview letter
│   │   ├── approve.ts           # Approve letter
│   │   ├── regenerate.ts        # Regenerate letter
│   │   └── templates.ts         # Template management
│   │
│   ├── lob/
│   │   ├── sendLetter.ts        # Send via Lob
│   │   ├── cancelLetter.ts      # Cancel mailing
│   │   ├── trackDelivery.ts     # Get delivery status
│   │   └── handleReturn.ts      # Handle returned mail
│   │
│   ├── webhooks/
│   │   ├── lob.ts               # Lob webhook handler
│   │   ├── smartcredit.ts       # SmartCredit webhook
│   │   └── verifySignature.ts   # Signature verification
│   │
│   ├── scheduled/
│   │   ├── slaCheck.ts          # Daily SLA deadline check
│   │   ├── creditRefresh.ts     # Auto-refresh reports
│   │   ├── cleanupExpired.ts    # Cleanup expired data
│   │   └── generateReports.ts   # Generate analytics reports
│   │
│   ├── triggers/
│   │   ├── disputeCreated.ts    # On dispute creation
│   │   ├── letterApproved.ts    # On letter approval
│   │   ├── mailingUpdated.ts    # On mailing status change
│   │   └── auditLog.ts          # Audit log trigger
│   │
│   └── utils/
│       ├── validation.ts        # Input validation
│       ├── encryption.ts        # PII encryption
│       ├── pdf.ts               # PDF generation
│       └── notifications.ts     # FCM notifications
│
├── package.json
├── tsconfig.json
└── firebase.json
```

### 5.2 Function Types

#### 5.2.1 HTTPS Callable Functions
Used for client-initiated operations.

```typescript
// Example: Create Consumer
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const createConsumer = onCall(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { tenantId, role } = request.auth.token;

    // Verify permissions
    if (!["owner", "operator"].includes(role)) {
      throw new HttpsError("permission-denied", "Insufficient permissions");
    }

    const { firstName, lastName, email, ssn, dob, address } = request.data;

    // Encrypt PII
    const encryptedSsn = await encryptPII(ssn);
    const encryptedDob = await encryptPII(dob);

    const db = getFirestore();
    const consumerRef = db.collection("consumers").doc();

    await consumerRef.set({
      id: consumerRef.id,
      tenantId,
      firstName,
      lastName,
      email,
      ssnEncrypted: encryptedSsn,
      dobEncrypted: encryptedDob,
      address,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
      updatedAt: FieldValue.serverTimestamp()
    });

    // Create audit log
    await createAuditLog(tenantId, request.auth.uid, "consumer.created", {
      consumerId: consumerRef.id
    });

    return { consumerId: consumerRef.id };
  }
);
```

#### 5.2.2 Firestore Triggers
Used for reactive operations.

```typescript
// Example: On Dispute Created
import { onDocumentCreated } from "firebase-functions/v2/firestore";

export const onDisputeCreated = onDocumentCreated(
  {
    document: "disputes/{disputeId}",
    region: "us-central1"
  },
  async (event) => {
    const dispute = event.data?.data();
    if (!dispute) return;

    const db = getFirestore();

    // Create default tasks for the dispute
    const tasks = [
      { name: "Generate dispute letter", status: "pending", order: 1 },
      { name: "Review and approve letter", status: "pending", order: 2 },
      { name: "Mail letter to bureau", status: "pending", order: 3 },
      { name: "Track delivery", status: "pending", order: 4 },
      { name: "Monitor for response", status: "pending", order: 5 }
    ];

    const batch = db.batch();

    for (const task of tasks) {
      const taskRef = db.collection("disputeTasks").doc();
      batch.set(taskRef, {
        ...task,
        disputeId: event.params.disputeId,
        tenantId: dispute.tenantId,
        createdAt: FieldValue.serverTimestamp()
      });
    }

    await batch.commit();

    // Send notification
    await sendNotification(dispute.tenantId, {
      title: "New Dispute Created",
      body: `Dispute for ${dispute.consumerName} has been created`
    });
  }
);
```

#### 5.2.3 Scheduled Functions
Used for periodic tasks.

```typescript
// Example: Daily SLA Check
import { onSchedule } from "firebase-functions/v2/scheduler";

export const dailySlaCheck = onSchedule(
  {
    schedule: "0 8 * * *", // Every day at 8 AM
    timeZone: "America/New_York",
    region: "us-central1"
  },
  async (event) => {
    const db = getFirestore();
    const now = new Date();

    // Find disputes approaching SLA deadline
    const disputes = await db.collection("disputes")
      .where("status", "in", ["letter_sent", "pending_response"])
      .get();

    for (const doc of disputes.docs) {
      const dispute = doc.data();
      const mailedDate = dispute.mailedAt?.toDate();

      if (!mailedDate) continue;

      const daysSinceMailed = Math.floor(
        (now.getTime() - mailedDate.getTime()) / (1000 * 60 * 60 * 24)
      );

      // Check 30-day SLA (FCRA requirement)
      if (daysSinceMailed >= 25 && daysSinceMailed < 30) {
        await sendSlaWarning(dispute, "5 days remaining");
      } else if (daysSinceMailed >= 30 && daysSinceMailed < 45) {
        await sendSlaWarning(dispute, "30-day deadline passed");
      } else if (daysSinceMailed >= 45) {
        await markSlaViolation(doc.id, dispute);
      }
    }
  }
);
```

#### 5.2.4 HTTP Webhook Handlers
Used for external service callbacks.

```typescript
// Example: Lob Webhook Handler
import { onRequest } from "firebase-functions/v2/https";
import * as crypto from "crypto";

export const lobWebhook = onRequest(
  {
    region: "us-central1",
    cors: false
  },
  async (req, res) => {
    // Verify Lob signature
    const signature = req.headers["lob-signature"];
    const timestamp = req.headers["lob-signature-timestamp"];

    if (!verifyLobSignature(req.body, signature, timestamp)) {
      res.status(401).send("Invalid signature");
      return;
    }

    const event = req.body;
    const db = getFirestore();

    // Find mailing by Lob ID
    const mailingQuery = await db.collection("mailings")
      .where("lobId", "==", event.body.id)
      .limit(1)
      .get();

    if (mailingQuery.empty) {
      res.status(404).send("Mailing not found");
      return;
    }

    const mailingDoc = mailingQuery.docs[0];

    // Update mailing status based on event
    const statusMap: Record<string, string> = {
      "letter.created": "processing",
      "letter.rendered_pdf": "rendered",
      "letter.rendered_thumbnails": "rendered",
      "letter.mailed": "mailed",
      "letter.in_transit": "in_transit",
      "letter.in_local_area": "in_local_area",
      "letter.processed_for_delivery": "out_for_delivery",
      "letter.delivered": "delivered",
      "letter.returned_to_sender": "returned"
    };

    await mailingDoc.ref.update({
      status: statusMap[event.event_type.id] || mailingDoc.data().status,
      lastEventAt: FieldValue.serverTimestamp(),
      events: FieldValue.arrayUnion({
        type: event.event_type.id,
        timestamp: event.date_created,
        details: event.body
      })
    });

    // Store webhook event for audit
    await db.collection("webhookEvents").add({
      source: "lob",
      eventType: event.event_type.id,
      payload: event,
      processedAt: FieldValue.serverTimestamp()
    });

    res.status(200).send("OK");
  }
);
```

---

## 6. External API Integration

### 6.1 SmartCredit Integration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SMARTCREDIT OAUTH FLOW                                  │
│                                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌─────────────────────────────────┐  │
│  │  Flutter │     │ Cloud Function│     │        SmartCredit API          │  │
│  └────┬─────┘     └──────┬───────┘     └───────────────┬─────────────────┘  │
│       │                  │                             │                     │
│       │ 1. initiateOAuth │                             │                     │
│       │─────────────────►│                             │                     │
│       │                  │                             │                     │
│       │                  │ 2. Generate state, store    │                     │
│       │                  │────────────────────────────►│                     │
│       │                  │                             │                     │
│       │ 3. Return OAuth URL                            │                     │
│       │◄─────────────────│                             │                     │
│       │                  │                             │                     │
│       │ 4. Redirect to SmartCredit                     │                     │
│       │───────────────────────────────────────────────►│                     │
│       │                  │                             │                     │
│       │                  │    5. User Authenticates    │                     │
│       │                  │             &               │                     │
│       │                  │    Grants Permission        │                     │
│       │                  │                             │                     │
│       │ 6. Redirect with code                          │                     │
│       │◄───────────────────────────────────────────────│                     │
│       │                  │                             │                     │
│       │ 7. handleCallback│                             │                     │
│       │─────────────────►│                             │                     │
│       │                  │                             │                     │
│       │                  │ 8. Exchange code for token  │                     │
│       │                  │────────────────────────────►│                     │
│       │                  │                             │                     │
│       │                  │ 9. Access + Refresh tokens  │                     │
│       │                  │◄────────────────────────────│                     │
│       │                  │                             │                     │
│       │                  │ 10. Store tokens (encrypted)│                     │
│       │                  │                             │                     │
│       │ 11. Connection Success                         │                     │
│       │◄─────────────────│                             │                     │
│       │                  │                             │                     │
└───────┴──────────────────┴─────────────────────────────┴─────────────────────┘
```

### 6.2 Lob Integration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LOB MAIL FLOW                                        │
│                                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌─────────────────────────────────┐  │
│  │  Flutter │     │ Cloud Function│     │           Lob API               │  │
│  └────┬─────┘     └──────┬───────┘     └───────────────┬─────────────────┘  │
│       │                  │                             │                     │
│       │ 1. approveLetter │                             │                     │
│       │─────────────────►│                             │                     │
│       │                  │                             │                     │
│       │                  │ 2. Generate PDF             │                     │
│       │                  │ (WeasyPrint/Puppeteer)      │                     │
│       │                  │                             │                     │
│       │                  │ 3. Upload to Storage        │                     │
│       │                  │                             │                     │
│       │                  │ 4. Create Letter via Lob    │                     │
│       │                  │────────────────────────────►│                     │
│       │                  │                             │                     │
│       │                  │ 5. Letter ID + Preview URL  │                     │
│       │                  │◄────────────────────────────│                     │
│       │                  │                             │                     │
│       │                  │ 6. Store mailing record     │                     │
│       │                  │                             │                     │
│       │ 7. Mailing Created                             │                     │
│       │◄─────────────────│                             │                     │
│       │                  │                             │                     │
│       │                  │         [ASYNC]             │                     │
│       │                  │                             │                     │
│       │                  │ 8. Webhook: letter.mailed   │                     │
│       │                  │◄────────────────────────────│                     │
│       │                  │                             │                     │
│       │                  │ 9. Update mailing status    │                     │
│       │                  │                             │                     │
│       │                  │ 10. Webhook: delivered      │                     │
│       │                  │◄────────────────────────────│                     │
│       │                  │                             │                     │
│       │                  │ 11. Update dispute status   │                     │
│       │                  │                             │                     │
│       │ 12. Push Notification                          │                     │
│       │◄─────────────────│                             │                     │
│       │                  │                             │                     │
└───────┴──────────────────┴─────────────────────────────┴─────────────────────┘
```

---

## 7. Storage Architecture

### 7.1 Storage Structure

```
gs://sfdify-production.appspot.com/
├── tenants/
│   └── {tenantId}/
│       ├── evidence/
│       │   └── {disputeId}/
│       │       └── {evidenceId}.{ext}
│       ├── letters/
│       │   └── {letterId}/
│       │       ├── letter.pdf
│       │       └── preview.png
│       ├── exports/
│       │   └── {exportId}.{ext}
│       └── imports/
│           └── {importId}.csv
```

### 7.2 Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function getTenantId() {
      return request.auth.token.tenantId;
    }

    function hasRole(role) {
      return request.auth.token.role == role;
    }

    // Tenant files
    match /tenants/{tenantId}/{allPaths=**} {
      allow read: if isAuthenticated() && getTenantId() == tenantId;
      allow write: if isAuthenticated()
        && getTenantId() == tenantId
        && (hasRole('owner') || hasRole('operator'));
    }
  }
}
```

---

## 8. Firebase Extensions

### 8.1 Recommended Extensions

| Extension | Purpose |
|-----------|---------|
| **Delete User Data** | Automatically delete user data when account is deleted |
| **Resize Images** | Resize evidence images for thumbnails |
| **Export Collections to BigQuery** | Stream Firestore data to BigQuery for analytics |
| **Trigger Email** | Send transactional emails (optional, can use FCM) |

---

## 9. Environment Configuration

### 9.1 Firebase Projects

| Environment | Project ID | Purpose |
|-------------|------------|---------|
| **Development** | sfdify-dev | Local development and testing |
| **Staging** | sfdify-staging | Pre-production testing |
| **Production** | sfdify-production | Live production environment |

### 9.2 Secret Management

Secrets are stored in Firebase Secret Manager:

```typescript
// Accessing secrets in Cloud Functions
import { defineSecret } from "firebase-functions/params";

const smartCreditClientSecret = defineSecret("SMARTCREDIT_CLIENT_SECRET");
const lobApiKey = defineSecret("LOB_API_KEY");
const encryptionKey = defineSecret("PII_ENCRYPTION_KEY");

export const pullCreditReport = onCall(
  {
    secrets: [smartCreditClientSecret, lobApiKey, encryptionKey]
  },
  async (request) => {
    const secret = smartCreditClientSecret.value();
    // Use secret...
  }
);
```

### 9.3 Environment Variables

```typescript
// firebase.json
{
  "functions": {
    "runtime": "nodejs20",
    "source": "functions",
    "predeploy": ["npm --prefix functions run build"],
    "env": {
      "SMARTCREDIT_BASE_URL": "https://api.smartcredit.com/v1",
      "LOB_BASE_URL": "https://api.lob.com/v1",
      "APP_URL": "https://app.sfdify.com"
    }
  }
}
```

---

## 10. Monitoring & Logging

### 10.1 Firebase Services

| Service | Purpose |
|---------|---------|
| **Firebase Console** | Overview dashboard, real-time metrics |
| **Cloud Logging** | Function logs, error tracking |
| **Performance Monitoring** | App performance, network latency |
| **Crashlytics** | Crash reports, error analysis |
| **Analytics** | User behavior, feature usage |

### 10.2 Custom Logging

```typescript
import { logger } from "firebase-functions/v2";

// Structured logging
logger.info("Consumer created", {
  tenantId: "tenant_abc",
  consumerId: "consumer_xyz",
  userId: "user_123",
  action: "create"
});

// Error logging
logger.error("Credit pull failed", {
  error: error.message,
  stack: error.stack,
  consumerId: "consumer_xyz"
});
```

### 10.3 Alerting

Configure alerts in Firebase Console for:
- Function errors exceeding threshold
- High latency functions
- Storage quota warnings
- Authentication failures
- Billing anomalies

---

## 11. Deployment

### 11.1 Firebase CLI Commands

```bash
# Deploy all
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:createConsumer

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Hosting
firebase deploy --only hosting
```

### 11.2 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Firebase

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Dependencies
        run: |
          npm ci
          cd functions && npm ci

      - name: Run Tests
        run: |
          npm test
          cd functions && npm test

      - name: Build Functions
        run: cd functions && npm run build

      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

---

## 12. Cost Optimization

### 12.1 Firestore Optimization

- Use composite indexes for common queries
- Implement pagination (limit queries to 25-50 documents)
- Use collection group queries sparingly
- Denormalize data to reduce reads

### 12.2 Cloud Functions Optimization

- Use appropriate memory allocation (start with 256MB)
- Set realistic timeouts
- Use connection pooling for external APIs
- Implement caching where appropriate

### 12.3 Storage Optimization

- Compress images before upload
- Set lifecycle policies for temporary files
- Use resumable uploads for large files

---

## 13. Disaster Recovery

### 13.1 Backup Strategy

| Data | Backup Method | Frequency |
|------|---------------|-----------|
| Firestore | Automated exports to Cloud Storage | Daily |
| Storage | Cross-region replication | Real-time |
| Secrets | Version history in Secret Manager | On change |

### 13.2 Recovery Procedures

```bash
# Export Firestore
gcloud firestore export gs://sfdify-backups/$(date +%Y-%m-%d)

# Import Firestore (recovery)
gcloud firestore import gs://sfdify-backups/2024-01-15
```

---

## Appendix A: Flutter Firebase Setup

### pubspec.yaml Dependencies

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^2.24.2

  # Authentication
  firebase_auth: ^4.16.0

  # Firestore
  cloud_firestore: ^4.14.0

  # Storage
  firebase_storage: ^11.6.0

  # Cloud Functions
  cloud_functions: ^4.6.0

  # Messaging
  firebase_messaging: ^14.7.10

  # Analytics
  firebase_analytics: ^10.8.0

  # Crashlytics
  firebase_crashlytics: ^3.4.9

  # Performance
  firebase_performance: ^0.9.3+9
```

### Flutter Initialization

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SfdifyApp());
}
```

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **FCRA** | Fair Credit Reporting Act |
| **GLBA** | Gramm-Leach-Bliley Act |
| **PII** | Personally Identifiable Information |
| **SLA** | Service Level Agreement |
| **Tradeline** | An account on a credit report |
| **Bureau** | Credit reporting agency (Equifax, Experian, TransUnion) |
| **MOV** | Method of Verification letter |
| **Custom Claims** | Additional data stored in Firebase Auth tokens |
