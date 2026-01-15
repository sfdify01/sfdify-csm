# SFDIFY Credit Dispute System - Firebase Security & Compliance

## Document Info
| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-01-15 | SFDIFY Team |

---

## 1. Overview

This document defines the security rules, compliance requirements, and best practices for the SFDIFY Credit Dispute System on Firebase. Given the sensitive nature of credit data and PII, security is paramount.

### 1.1 Security Principles

1. **Zero Trust** - Verify every request, never assume trust
2. **Least Privilege** - Grant minimum permissions required
3. **Defense in Depth** - Multiple layers of security
4. **Data Minimization** - Only collect/store what's necessary
5. **Encryption Everywhere** - Encrypt data at rest and in transit

---

## 2. Firebase Security Rules

### 2.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Get the user's tenant ID from custom claims
    function getTenantId() {
      return request.auth.token.tenantId;
    }

    // Get the user's role from custom claims
    function getRole() {
      return request.auth.token.role;
    }

    // Check if user has a specific role
    function hasRole(role) {
      return isAuthenticated() && getRole() == role;
    }

    // Check if user has any of the specified roles
    function hasAnyRole(roles) {
      return isAuthenticated() && getRole() in roles;
    }

    // Check if user belongs to the same tenant as the resource
    function isSameTenant() {
      return isAuthenticated() && getTenantId() == resource.data.tenantId;
    }

    // Check if user belongs to the tenant specified in the new document
    function isSameTenantForCreate() {
      return isAuthenticated() && getTenantId() == request.resource.data.tenantId;
    }

    // Check if the resource has not been soft-deleted
    function isNotDeleted() {
      return resource.data.deletedAt == null;
    }

    // Validate that required fields are present
    function hasRequiredFields(fields) {
      return request.resource.data.keys().hasAll(fields);
    }

    // Validate that only allowed fields are being updated
    function onlyUpdatesFields(fields) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(fields);
    }

    // Check if current timestamp is valid
    function isValidTimestamp(field) {
      return request.resource.data[field] is timestamp;
    }

    // ============================================
    // TENANTS COLLECTION
    // ============================================

    match /tenants/{tenantId} {
      // Only owners can read their own tenant
      allow read: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // Only owners can update tenant settings
      allow update: if isAuthenticated()
        && getTenantId() == tenantId
        && hasRole('owner')
        && !('id' in request.resource.data.diff(resource.data).affectedKeys())
        && !('createdAt' in request.resource.data.diff(resource.data).affectedKeys());

      // Tenant creation handled by Cloud Functions only
      allow create: if false;
      allow delete: if false;
    }

    // ============================================
    // USERS COLLECTION
    // ============================================

    match /users/{userId} {
      // Users can read their own profile
      // Owners can read all users in their tenant
      allow read: if isAuthenticated()
        && (request.auth.uid == userId
            || (isSameTenant() && hasRole('owner')));

      // Users can update their own preferences
      allow update: if isAuthenticated()
        && request.auth.uid == userId
        && onlyUpdatesFields(['preferences', 'updatedAt']);

      // Owners can update user roles (except their own)
      allow update: if isAuthenticated()
        && request.auth.uid != userId
        && isSameTenant()
        && hasRole('owner')
        && !('id' in request.resource.data.diff(resource.data).affectedKeys())
        && !('tenantId' in request.resource.data.diff(resource.data).affectedKeys())
        && !('email' in request.resource.data.diff(resource.data).affectedKeys());

      // User creation/deletion handled by Cloud Functions only
      allow create: if false;
      allow delete: if false;
    }

    // ============================================
    // CONSUMERS COLLECTION
    // ============================================

    match /consumers/{consumerId} {
      // Owners, operators, viewers, auditors can read consumers in their tenant
      allow read: if isSameTenant()
        && isNotDeleted()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // Owners and operators can create consumers
      allow create: if isSameTenantForCreate()
        && hasAnyRole(['owner', 'operator'])
        && hasRequiredFields(['tenantId', 'firstName', 'lastName', 'email', 'status', 'createdAt', 'createdBy']);

      // Owners and operators can update consumers
      allow update: if isSameTenant()
        && isNotDeleted()
        && hasAnyRole(['owner', 'operator'])
        && !('id' in request.resource.data.diff(resource.data).affectedKeys())
        && !('tenantId' in request.resource.data.diff(resource.data).affectedKeys())
        && !('ssnEncrypted' in request.resource.data.diff(resource.data).affectedKeys())
        && !('createdAt' in request.resource.data.diff(resource.data).affectedKeys());

      // Only owners can soft-delete consumers
      allow update: if isSameTenant()
        && hasRole('owner')
        && request.resource.data.deletedAt != null
        && resource.data.deletedAt == null;

      // Hard delete not allowed from client
      allow delete: if false;
    }

    // ============================================
    // SMARTCREDIT CONNECTIONS COLLECTION
    // ============================================

    match /smartcreditConnections/{connectionId} {
      // Only operators and owners can read connections
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator']);

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // CREDIT REPORTS COLLECTION
    // ============================================

    match /creditReports/{reportId} {
      // All roles can read credit reports in their tenant
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // TRADELINES COLLECTION
    // ============================================

    match /tradelines/{tradelineId} {
      // All roles can read tradelines in their tenant
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // DISPUTES COLLECTION
    // ============================================

    match /disputes/{disputeId} {
      // All roles can read disputes in their tenant
      allow read: if isSameTenant()
        && isNotDeleted()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // Owners and operators can create disputes
      allow create: if isSameTenantForCreate()
        && hasAnyRole(['owner', 'operator'])
        && hasRequiredFields(['tenantId', 'consumerId', 'tradelineId', 'disputeType', 'status', 'createdAt', 'createdBy']);

      // Owners and operators can update disputes
      allow update: if isSameTenant()
        && isNotDeleted()
        && hasAnyRole(['owner', 'operator'])
        && !('id' in request.resource.data.diff(resource.data).affectedKeys())
        && !('tenantId' in request.resource.data.diff(resource.data).affectedKeys())
        && !('createdAt' in request.resource.data.diff(resource.data).affectedKeys());

      // Hard delete not allowed
      allow delete: if false;

      // ----------------------------------------
      // DISPUTE COMMENTS SUBCOLLECTION
      // ----------------------------------------
      match /comments/{commentId} {
        allow read: if isSameTenant()
          && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

        allow create: if isSameTenantForCreate()
          && hasAnyRole(['owner', 'operator'])
          && request.resource.data.userId == request.auth.uid;

        allow update: if isSameTenant()
          && hasAnyRole(['owner', 'operator'])
          && resource.data.userId == request.auth.uid;

        allow delete: if isSameTenant()
          && hasAnyRole(['owner', 'operator'])
          && resource.data.userId == request.auth.uid;
      }
    }

    // ============================================
    // DISPUTE TASKS COLLECTION
    // ============================================

    match /disputeTasks/{taskId} {
      // All roles can read tasks
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // Owners and operators can update task status
      allow update: if isSameTenant()
        && hasAnyRole(['owner', 'operator'])
        && onlyUpdatesFields(['status', 'completedAt', 'completedBy', 'notes', 'updatedAt']);

      // Creation and deletion handled by Cloud Functions
      allow create, delete: if false;
    }

    // ============================================
    // LETTERS COLLECTION
    // ============================================

    match /letters/{letterId} {
      // All roles can read letters
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // All writes handled by Cloud Functions (generation, approval)
      allow create, update, delete: if false;
    }

    // ============================================
    // LETTER TEMPLATES COLLECTION
    // ============================================

    match /letterTemplates/{templateId} {
      // System templates (tenantId == null) readable by all authenticated users
      allow read: if isAuthenticated()
        && (resource.data.tenantId == null || isSameTenant());

      // Only owners can manage custom templates
      allow create: if isSameTenantForCreate()
        && hasRole('owner');

      allow update: if isSameTenant()
        && hasRole('owner')
        && !('id' in request.resource.data.diff(resource.data).affectedKeys())
        && !('tenantId' in request.resource.data.diff(resource.data).affectedKeys());

      allow delete: if isSameTenant()
        && hasRole('owner');
    }

    // ============================================
    // EVIDENCE COLLECTION
    // ============================================

    match /evidence/{evidenceId} {
      // All roles can read evidence
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // Owners and operators can create evidence records
      // (actual file upload goes to Storage)
      allow create: if isSameTenantForCreate()
        && hasAnyRole(['owner', 'operator'])
        && hasRequiredFields(['tenantId', 'disputeId', 'fileName', 'createdAt', 'createdBy']);

      // Only status updates allowed after creation
      allow update: if isSameTenant()
        && hasAnyRole(['owner', 'operator'])
        && onlyUpdatesFields(['status', 'description', 'updatedAt']);

      // Owners and operators can delete evidence
      allow delete: if isSameTenant()
        && hasAnyRole(['owner', 'operator']);
    }

    // ============================================
    // MAILINGS COLLECTION
    // ============================================

    match /mailings/{mailingId} {
      // All roles can read mailings
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'operator', 'viewer', 'auditor']);

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // AUDIT LOGS COLLECTION
    // ============================================

    match /auditLogs/{logId} {
      // Only owners and auditors can read audit logs
      allow read: if isSameTenant()
        && hasAnyRole(['owner', 'auditor']);

      // Audit logs are immutable - no client writes allowed
      allow create, update, delete: if false;
    }

    // ============================================
    // WEBHOOK EVENTS COLLECTION
    // ============================================

    match /webhookEvents/{eventId} {
      // Only owners can read webhook events
      allow read: if isAuthenticated()
        && hasRole('owner');

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // NOTIFICATIONS COLLECTION
    // ============================================

    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if isAuthenticated()
        && isSameTenant()
        && resource.data.userId == request.auth.uid;

      // Users can mark their notifications as read/dismissed
      allow update: if isAuthenticated()
        && isSameTenant()
        && resource.data.userId == request.auth.uid
        && onlyUpdatesFields(['read', 'readAt', 'dismissed', 'dismissedAt']);

      // Notifications created by Cloud Functions only
      allow create, delete: if false;
    }

    // ============================================
    // INVITES COLLECTION
    // ============================================

    match /invites/{inviteId} {
      // Only owners can read invites
      allow read: if isSameTenant()
        && hasRole('owner');

      // All writes handled by Cloud Functions
      allow create, update, delete: if false;
    }

    // ============================================
    // DEFAULT DENY
    // ============================================

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

### 2.2 Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    function isAuthenticated() {
      return request.auth != null;
    }

    function getTenantId() {
      return request.auth.token.tenantId;
    }

    function getRole() {
      return request.auth.token.role;
    }

    function hasAnyRole(roles) {
      return isAuthenticated() && getRole() in roles;
    }

    // Validate file size (max 10MB)
    function isValidFileSize() {
      return request.resource.size < 10 * 1024 * 1024;
    }

    // Validate allowed content types
    function isAllowedContentType() {
      return request.resource.contentType.matches('image/.*')
        || request.resource.contentType == 'application/pdf'
        || request.resource.contentType == 'text/plain';
    }

    // ============================================
    // TENANT FILES
    // ============================================

    match /tenants/{tenantId}/{allPaths=**} {
      // Users can read files from their own tenant
      allow read: if isAuthenticated()
        && getTenantId() == tenantId;

      // Owners and operators can upload files
      allow write: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner', 'operator'])
        && isValidFileSize()
        && isAllowedContentType();

      // Only owners can delete files
      allow delete: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner', 'operator']);
    }

    // ============================================
    // EVIDENCE FILES
    // ============================================

    match /tenants/{tenantId}/evidence/{disputeId}/{fileName} {
      // All tenant users can read evidence
      allow read: if isAuthenticated()
        && getTenantId() == tenantId;

      // Owners and operators can upload evidence
      allow create: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner', 'operator'])
        && isValidFileSize()
        && isAllowedContentType();

      // Evidence can only be deleted by owners
      allow delete: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner', 'operator']);

      // No updates to evidence files (immutable)
      allow update: if false;
    }

    // ============================================
    // LETTER PDFs
    // ============================================

    match /tenants/{tenantId}/letters/{letterId}/{fileName} {
      // All tenant users can read letters
      allow read: if isAuthenticated()
        && getTenantId() == tenantId;

      // Letters created by Cloud Functions only
      allow create, update, delete: if false;
    }

    // ============================================
    // EXPORTS
    // ============================================

    match /tenants/{tenantId}/exports/{exportId} {
      // Only owners can read exports
      allow read: if isAuthenticated()
        && getTenantId() == tenantId
        && hasAnyRole(['owner']);

      // Exports created by Cloud Functions only
      allow create, update, delete: if false;
    }

    // ============================================
    // TEMPORARY UPLOADS
    // ============================================

    match /temp/{userId}/{fileName} {
      // Users can manage their own temporary files
      allow read, write: if isAuthenticated()
        && request.auth.uid == userId
        && isValidFileSize();

      // Temp files auto-deleted after 24 hours via lifecycle policy
    }

    // ============================================
    // DEFAULT DENY
    // ============================================

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 3. Authentication Security

### 3.1 Custom Claims Structure

```typescript
interface CustomClaims {
  tenantId: string;           // Required: Tenant identifier
  role: UserRole;             // Required: User role
  permissions: string[];      // Optional: Granular permissions
  mfaVerified?: boolean;      // Optional: MFA status
}

type UserRole = "owner" | "operator" | "viewer" | "auditor";
```

### 3.2 Setting Custom Claims

```typescript
// Cloud Function to set custom claims
import { auth } from "firebase-admin";

export async function setUserClaims(
  userId: string,
  claims: CustomClaims
): Promise<void> {
  await auth().setCustomUserClaims(userId, claims);

  // Log the claim change
  await createAuditLog({
    action: "auth.claims_updated",
    userId: userId,
    details: { newClaims: claims }
  });
}
```

### 3.3 Token Refresh After Claim Changes

```dart
// Flutter: Force token refresh after claim changes
Future<void> refreshClaims() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Force token refresh
    await user.getIdToken(true);

    // Reload user to get new claims
    await user.reload();
  }
}
```

### 3.4 Password Policy

Enforce via Firebase Authentication settings:
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character
- Not in common password list

### 3.5 Multi-Factor Authentication (MFA)

```typescript
// Enforcing MFA for sensitive operations
export const approveLetter = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  // Check if MFA is verified for this session
  const token = request.auth.token;
  if (!token.mfaVerified) {
    throw new HttpsError(
      "failed-precondition",
      "MFA verification required for this operation"
    );
  }

  // Proceed with operation...
});
```

---

## 4. Data Encryption

### 4.1 Encryption at Rest

Firebase provides automatic encryption at rest for:
- Firestore data
- Cloud Storage files
- Secret Manager secrets

### 4.2 Application-Level Encryption for PII

```typescript
// utils/encryption.ts
import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";

const encryptionKey = defineSecret("PII_ENCRYPTION_KEY");

const ALGORITHM = "aes-256-gcm";
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;

export async function encryptPII(plaintext: string): Promise<string> {
  const key = Buffer.from(encryptionKey.value(), "hex");
  const iv = crypto.randomBytes(IV_LENGTH);

  const cipher = crypto.createCipheriv(ALGORITHM, key, iv, {
    authTagLength: AUTH_TAG_LENGTH
  });

  let encrypted = cipher.update(plaintext, "utf8", "hex");
  encrypted += cipher.final("hex");

  const authTag = cipher.getAuthTag();

  // Format: iv:authTag:ciphertext
  return `${iv.toString("hex")}:${authTag.toString("hex")}:${encrypted}`;
}

export async function decryptPII(encrypted: string): Promise<string> {
  const key = Buffer.from(encryptionKey.value(), "hex");
  const [ivHex, authTagHex, ciphertext] = encrypted.split(":");

  const iv = Buffer.from(ivHex, "hex");
  const authTag = Buffer.from(authTagHex, "hex");

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv, {
    authTagLength: AUTH_TAG_LENGTH
  });
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(ciphertext, "hex", "utf8");
  decrypted += decipher.final("utf8");

  return decrypted;
}
```

### 4.3 Encrypted Fields

| Collection | Field | Encryption |
|------------|-------|------------|
| consumers | ssnEncrypted | AES-256-GCM |
| consumers | dobEncrypted | AES-256-GCM |
| smartcreditConnections | accessTokenEncrypted | AES-256-GCM |
| smartcreditConnections | refreshTokenEncrypted | AES-256-GCM |

---

## 5. Secret Management

### 5.1 Firebase Secret Manager

```typescript
// Defining secrets
import { defineSecret } from "firebase-functions/params";

export const smartCreditClientSecret = defineSecret("SMARTCREDIT_CLIENT_SECRET");
export const lobApiKey = defineSecret("LOB_API_KEY");
export const piiEncryptionKey = defineSecret("PII_ENCRYPTION_KEY");
export const webhookSigningKey = defineSecret("WEBHOOK_SIGNING_KEY");

// Using secrets in functions
export const pullCreditReport = onCall(
  {
    secrets: [smartCreditClientSecret, piiEncryptionKey]
  },
  async (request) => {
    const clientSecret = smartCreditClientSecret.value();
    // Use secret...
  }
);
```

### 5.2 Secret Rotation

```bash
# Add new version of secret
firebase functions:secrets:set SMARTCREDIT_CLIENT_SECRET

# Deploy functions to use new secret
firebase deploy --only functions

# Destroy old version after verification
firebase functions:secrets:destroy SMARTCREDIT_CLIENT_SECRET --version 1
```

### 5.3 Required Secrets

| Secret Name | Purpose | Rotation Frequency |
|-------------|---------|-------------------|
| SMARTCREDIT_CLIENT_SECRET | SmartCredit OAuth | Quarterly |
| LOB_API_KEY | Lob mail API | Quarterly |
| PII_ENCRYPTION_KEY | PII field encryption | Annually |
| WEBHOOK_SIGNING_KEY | Webhook verification | Quarterly |

---

## 6. Audit Logging

### 6.1 Audit Log Creation

```typescript
// utils/auditLog.ts
import { getFirestore, FieldValue } from "firebase-admin/firestore";

interface AuditLogEntry {
  tenantId: string;
  userId: string;
  userEmail: string;
  userRole: string;
  action: string;
  category: AuditCategory;
  resourceType: string;
  resourceId: string;
  details?: Record<string, any>;
  previousValue?: Record<string, any>;
  newValue?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  requestId?: string;
}

type AuditCategory =
  | "auth"
  | "consumer"
  | "dispute"
  | "letter"
  | "mailing"
  | "admin"
  | "system";

export async function createAuditLog(entry: AuditLogEntry): Promise<string> {
  const db = getFirestore();
  const logRef = db.collection("auditLogs").doc();

  await logRef.set({
    id: logRef.id,
    ...entry,
    timestamp: FieldValue.serverTimestamp()
  });

  return logRef.id;
}
```

### 6.2 Audited Actions

| Category | Action | Description |
|----------|--------|-------------|
| auth | auth.login | User login |
| auth | auth.logout | User logout |
| auth | auth.failed_login | Failed login attempt |
| auth | auth.mfa_enabled | MFA enabled |
| auth | auth.claims_updated | Custom claims changed |
| consumer | consumer.created | Consumer created |
| consumer | consumer.updated | Consumer updated |
| consumer | consumer.deleted | Consumer soft-deleted |
| consumer | consumer.pii_accessed | PII decrypted/viewed |
| dispute | dispute.created | Dispute created |
| dispute | dispute.status_changed | Status transition |
| dispute | dispute.outcome_recorded | Outcome recorded |
| letter | letter.generated | Letter generated |
| letter | letter.approved | Letter approved |
| letter | letter.rejected | Letter rejected |
| letter | letter.sent | Letter sent |
| mailing | mailing.created | Mailing created |
| mailing | mailing.delivered | Mailing delivered |
| mailing | mailing.returned | Mailing returned |
| admin | user.invited | User invited |
| admin | user.role_changed | User role changed |
| admin | user.access_revoked | User access revoked |
| admin | template.created | Template created |
| admin | template.updated | Template updated |

### 6.3 Audit Log Retention

- Retain audit logs for 7 years (FCRA requirement)
- Archive to cold storage after 1 year
- Immutable - no updates or deletes allowed

---

## 7. FCRA Compliance

### 7.1 FCRA Requirements Checklist

| Requirement | Implementation |
|-------------|----------------|
| **Consumer Consent** | Consent captured and timestamped in consumer record |
| **Dispute Time Limits** | SLA tracking with 30/45 day deadlines |
| **Written Verification** | Letter generation with certified mail option |
| **Consumer Notification** | Notifications on status changes |
| **Method of Verification** | MOV letter templates available |
| **7-Year Data Limit** | Flagging of obsolete tradelines |
| **Identity Theft Block** | FCRA 605B letter template |
| **Reinvestigation** | Reinvestigation letter template |

### 7.2 SLA Tracking Implementation

```typescript
// scheduled/slaCheck.ts
export const dailySlaCheck = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "America/New_York"
  },
  async () => {
    const db = getFirestore();
    const now = new Date();

    const disputes = await db.collection("disputes")
      .where("status", "in", ["letter_sent", "in_transit", "delivered", "pending_response"])
      .where("sla.isViolated", "==", false)
      .get();

    for (const doc of disputes.docs) {
      const dispute = doc.data();
      const startDate = dispute.sla.startDate?.toDate();

      if (!startDate) continue;

      const daysSinceStart = Math.floor(
        (now.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)
      );

      // 5-day warning before 30-day deadline
      if (daysSinceStart >= 25 && daysSinceStart < 30 && dispute.sla.warningsSent < 1) {
        await sendSlaWarning(doc.id, dispute, "5 days until 30-day deadline");
        await doc.ref.update({
          "sla.warningsSent": FieldValue.increment(1)
        });
      }

      // 30-day deadline passed
      if (daysSinceStart >= 30 && daysSinceStart < 45 && dispute.sla.warningsSent < 2) {
        await sendSlaWarning(doc.id, dispute, "30-day deadline passed");
        await doc.ref.update({
          "sla.warningsSent": FieldValue.increment(1)
        });
      }

      // 45-day deadline passed - SLA violated
      if (daysSinceStart >= 45) {
        await doc.ref.update({
          "sla.isViolated": true,
          "sla.violatedAt": FieldValue.serverTimestamp()
        });
        await sendSlaViolationAlert(doc.id, dispute);
      }
    }
  }
);
```

### 7.3 Consent Capture

```typescript
interface ConsentRecord {
  creditPull: boolean;
  creditPullAt: Timestamp | null;
  creditPullIp: string | null;
  electronicCommunication: boolean;
  electronicCommunicationAt: Timestamp | null;
  termsOfService: boolean;
  termsOfServiceAt: Timestamp | null;
  termsOfServiceVersion: string | null;
  privacyPolicy: boolean;
  privacyPolicyAt: Timestamp | null;
  privacyPolicyVersion: string | null;
}

// Consent language to display
const CONSENT_LANGUAGE = {
  creditPull: `I authorize [Company Name] to obtain my credit report from one or more credit bureaus for the purpose of reviewing my credit history and identifying potential inaccuracies to dispute. I understand this authorization is valid for the duration of my relationship with [Company Name] or until I revoke it in writing.`,

  electronicCommunication: `I consent to receive electronic communications from [Company Name] regarding my account, including dispute status updates, notifications, and promotional materials. I understand I can opt out at any time.`,

  termsOfService: `I have read and agree to the Terms of Service.`,

  privacyPolicy: `I have read and understand the Privacy Policy, including how my personal information will be collected, used, and protected.`
};
```

---

## 8. GLBA Compliance

### 8.1 GLBA Safeguards Rule Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Designated Security Coordinator** | Document in tenant settings |
| **Risk Assessment** | Annual security review |
| **Employee Training** | Training tracking in user records |
| **Service Provider Oversight** | Vendor agreements documented |
| **Program Updates** | Version-controlled security policies |

### 8.2 Data Protection Measures

```typescript
// Security measures implemented
const securityMeasures = {
  accessControls: {
    authentication: "Firebase Authentication",
    authorization: "Custom claims + Security rules",
    mfa: "Optional TOTP-based MFA",
    sessionTimeout: "1 hour idle timeout"
  },

  dataProtection: {
    encryptionAtRest: "Firebase automatic encryption",
    encryptionInTransit: "TLS 1.3",
    piiEncryption: "AES-256-GCM application-level",
    backups: "Daily automated backups"
  },

  monitoring: {
    auditLogging: "All sensitive operations logged",
    alerting: "Firebase Crashlytics + Cloud Monitoring",
    incidentResponse: "Documented procedures"
  },

  physicalSecurity: {
    dataCenter: "Google Cloud Platform",
    certifications: "SOC 2, ISO 27001"
  }
};
```

---

## 9. Input Validation

### 9.1 Validation Functions

```typescript
// utils/validation.ts
import { HttpsError } from "firebase-functions/v2/https";

export function validateEmail(email: string): void {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError("invalid-argument", "Invalid email format");
  }
}

export function validatePhone(phone: string): void {
  const phoneRegex = /^\+[1-9]\d{1,14}$/;
  if (!phoneRegex.test(phone)) {
    throw new HttpsError("invalid-argument", "Phone must be in E.164 format");
  }
}

export function validateSSN(ssn: string): void {
  // Remove dashes for validation
  const cleaned = ssn.replace(/-/g, "");
  const ssnRegex = /^\d{9}$/;
  if (!ssnRegex.test(cleaned)) {
    throw new HttpsError("invalid-argument", "Invalid SSN format");
  }

  // Check for invalid SSN patterns
  const invalidPatterns = [
    /^000/, /^666/, /^9/,           // Invalid area numbers
    /^\d{3}00/, /^\d{5}0000/        // Invalid group/serial numbers
  ];
  if (invalidPatterns.some(p => p.test(cleaned))) {
    throw new HttpsError("invalid-argument", "Invalid SSN");
  }
}

export function validateDate(dateStr: string): Date {
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) {
    throw new HttpsError("invalid-argument", "Invalid date format");
  }
  return date;
}

export function validateZipCode(zip: string): void {
  const zipRegex = /^\d{5}(-\d{4})?$/;
  if (!zipRegex.test(zip)) {
    throw new HttpsError("invalid-argument", "Invalid ZIP code format");
  }
}

export function validateState(state: string): void {
  const validStates = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    "DC", "PR", "VI", "GU", "AS", "MP"
  ];
  if (!validStates.includes(state.toUpperCase())) {
    throw new HttpsError("invalid-argument", "Invalid state code");
  }
}

export function sanitizeString(input: string): string {
  // Remove potentially dangerous characters
  return input
    .replace(/<[^>]*>/g, "")  // Remove HTML tags
    .replace(/[<>\"'&]/g, "")  // Remove special characters
    .trim();
}
```

### 9.2 Request Validation Middleware

```typescript
// middleware/validateRequest.ts
import { CallableRequest } from "firebase-functions/v2/https";

export function validateConsumerRequest(data: any): void {
  const requiredFields = ["firstName", "lastName", "email", "phone", "ssn", "dob", "currentAddress"];

  for (const field of requiredFields) {
    if (!data[field]) {
      throw new HttpsError("invalid-argument", `Missing required field: ${field}`);
    }
  }

  validateEmail(data.email);
  validatePhone(data.phone);
  validateSSN(data.ssn);
  validateDate(data.dob);

  if (data.currentAddress) {
    if (!data.currentAddress.street1 || !data.currentAddress.city ||
        !data.currentAddress.state || !data.currentAddress.zipCode) {
      throw new HttpsError("invalid-argument", "Incomplete address");
    }
    validateState(data.currentAddress.state);
    validateZipCode(data.currentAddress.zipCode);
  }
}
```

---

## 10. Rate Limiting

### 10.1 Implementation

```typescript
// middleware/rateLimit.ts
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
}

const RATE_LIMITS: Record<string, RateLimitConfig> = {
  "default": { windowMs: 60000, maxRequests: 100 },
  "write": { windowMs: 60000, maxRequests: 30 },
  "creditPull": { windowMs: 3600000, maxRequests: 10 },
  "letterSend": { windowMs: 3600000, maxRequests: 20 }
};

export async function checkRateLimit(
  userId: string,
  tenantId: string,
  operation: string = "default"
): Promise<void> {
  const config = RATE_LIMITS[operation] || RATE_LIMITS["default"];
  const db = getFirestore();

  const windowStart = Date.now() - config.windowMs;
  const rateLimitRef = db.collection("rateLimits").doc(`${userId}_${operation}`);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(rateLimitRef);
    const data = doc.data();

    if (!data) {
      transaction.set(rateLimitRef, {
        requests: [{ timestamp: Date.now() }],
        userId,
        tenantId,
        operation
      });
      return;
    }

    // Filter requests within window
    const recentRequests = (data.requests || []).filter(
      (r: any) => r.timestamp > windowStart
    );

    if (recentRequests.length >= config.maxRequests) {
      const oldestRequest = Math.min(...recentRequests.map((r: any) => r.timestamp));
      const retryAfter = Math.ceil((oldestRequest + config.windowMs - Date.now()) / 1000);

      throw new HttpsError(
        "resource-exhausted",
        `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
        { retryAfter }
      );
    }

    recentRequests.push({ timestamp: Date.now() });
    transaction.update(rateLimitRef, { requests: recentRequests });
  });
}
```

---

## 11. Webhook Security

### 11.1 Lob Webhook Verification

```typescript
// webhooks/verifyLob.ts
import * as crypto from "crypto";

export function verifyLobSignature(
  payload: string,
  signature: string | undefined,
  timestamp: string | undefined,
  secret: string
): boolean {
  if (!signature || !timestamp) {
    return false;
  }

  // Check timestamp is within 5 minutes
  const timestampMs = parseInt(timestamp) * 1000;
  const now = Date.now();
  if (Math.abs(now - timestampMs) > 5 * 60 * 1000) {
    return false;
  }

  // Compute expected signature
  const message = `${timestamp}.${payload}`;
  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(message)
    .digest("hex");

  // Constant-time comparison
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

### 11.2 SmartCredit Webhook Verification

```typescript
// webhooks/verifySmartCredit.ts
import * as crypto from "crypto";

export function verifySmartCreditSignature(
  payload: string,
  signature: string | undefined,
  secret: string
): boolean {
  if (!signature) {
    return false;
  }

  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("base64");

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

---

## 12. Incident Response

### 12.1 Security Incident Types

| Type | Severity | Response Time |
|------|----------|---------------|
| Data Breach | Critical | Immediate |
| Unauthorized Access | High | 1 hour |
| Service Disruption | High | 1 hour |
| Suspicious Activity | Medium | 4 hours |
| Policy Violation | Low | 24 hours |

### 12.2 Incident Response Procedure

1. **Detection** - Monitor alerts, logs, user reports
2. **Containment** - Isolate affected systems/accounts
3. **Investigation** - Analyze logs, determine scope
4. **Notification** - Notify affected users within 72 hours (GDPR/CCPA)
5. **Remediation** - Fix vulnerabilities, restore services
6. **Documentation** - Document incident and response
7. **Review** - Post-incident review and improvements

### 12.3 Emergency Account Lockdown

```typescript
// admin/emergencyLockdown.ts
export async function lockdownTenant(tenantId: string, reason: string): Promise<void> {
  const db = getFirestore();
  const auth = getAuth();

  // Update tenant status
  await db.collection("tenants").doc(tenantId).update({
    status: "suspended",
    suspendedReason: reason,
    suspendedAt: FieldValue.serverTimestamp()
  });

  // Revoke all user sessions
  const users = await db.collection("users")
    .where("tenantId", "==", tenantId)
    .get();

  for (const userDoc of users.docs) {
    await auth.revokeRefreshTokens(userDoc.id);
  }

  // Log incident
  await createAuditLog({
    tenantId,
    userId: "system",
    userEmail: "system",
    userRole: "system",
    action: "admin.tenant_lockdown",
    category: "admin",
    resourceType: "tenant",
    resourceId: tenantId,
    details: { reason }
  });
}
```

---

## 13. Security Testing

### 13.1 Security Test Checklist

- [ ] Authentication bypass attempts
- [ ] Authorization escalation tests
- [ ] Cross-tenant data access
- [ ] SQL/NoSQL injection attempts
- [ ] XSS vulnerability scanning
- [ ] CSRF protection verification
- [ ] Rate limit enforcement
- [ ] Encryption validation
- [ ] Secret exposure checks
- [ ] Audit log completeness

### 13.2 Security Rules Testing

```typescript
// test/security-rules.test.ts
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";

describe("Firestore Security Rules", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: "demo-test-project",
      firestore: {
        rules: readFileSync("firestore.rules", "utf8")
      }
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  describe("consumers collection", () => {
    it("allows operators to read consumers in their tenant", async () => {
      const db = testEnv.authenticatedContext("user1", {
        tenantId: "tenant1",
        role: "operator"
      }).firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("consumers").doc("consumer1").set({
          tenantId: "tenant1",
          firstName: "Test",
          deletedAt: null
        });
      });

      await assertSucceeds(
        db.collection("consumers").doc("consumer1").get()
      );
    });

    it("denies access to consumers in different tenant", async () => {
      const db = testEnv.authenticatedContext("user1", {
        tenantId: "tenant2",
        role: "operator"
      }).firestore();

      await assertFails(
        db.collection("consumers").doc("consumer1").get()
      );
    });

    it("denies viewers from creating consumers", async () => {
      const db = testEnv.authenticatedContext("user1", {
        tenantId: "tenant1",
        role: "viewer"
      }).firestore();

      await assertFails(
        db.collection("consumers").doc("newConsumer").set({
          tenantId: "tenant1",
          firstName: "Test"
        })
      );
    });
  });
});
```

---

## Appendix A: Security Headers

For Firebase Hosting, configure security headers in `firebase.json`:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Strict-Transport-Security",
            "value": "max-age=31536000; includeSubDomains"
          },
          {
            "key": "Content-Security-Policy",
            "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://apis.google.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com;"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          },
          {
            "key": "Permissions-Policy",
            "value": "geolocation=(), microphone=(), camera=()"
          }
        ]
      }
    ]
  }
}
```

---

## Appendix B: Compliance Checklist

### Pre-Launch Security Checklist

- [ ] All security rules deployed and tested
- [ ] PII encryption implemented and verified
- [ ] Audit logging enabled for all sensitive operations
- [ ] Rate limiting configured
- [ ] Webhook signature verification implemented
- [ ] Secrets stored in Secret Manager
- [ ] MFA available for sensitive operations
- [ ] Backup and recovery tested
- [ ] Incident response plan documented
- [ ] Security testing completed
- [ ] FCRA compliance requirements met
- [ ] GLBA safeguards implemented
- [ ] Privacy policy and terms of service published
- [ ] Data retention policies configured
- [ ] Employee security training completed
