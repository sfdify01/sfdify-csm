# SFDIFY Credit Dispute System - Firebase API Specification

## Document Info
| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-01-15 | SFDIFY Team |

---

## 1. Overview

This document specifies all Cloud Functions that serve as the API layer for the SFDIFY Credit Dispute System. The API uses Firebase Callable Functions for authenticated client requests and HTTP functions for webhooks.

### 1.1 API Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FIREBASE CLOUD FUNCTIONS                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 CALLABLE FUNCTIONS                        │   │
│  │         (Authenticated client requests)                   │   │
│  │                                                           │   │
│  │  • Auto-authentication via Firebase Auth                  │   │
│  │  • Request/response validation                            │   │
│  │  • CORS handled automatically                             │   │
│  │  • Called via Firebase SDK                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   HTTP FUNCTIONS                          │   │
│  │              (Webhook endpoints)                          │   │
│  │                                                           │   │
│  │  • Public endpoints for external services                 │   │
│  │  • Signature verification required                        │   │
│  │  • Rate limiting applied                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Base Configuration

```typescript
// Cloud Function default configuration
const defaultConfig = {
  region: "us-central1",
  memory: "256MiB",
  timeoutSeconds: 60,
  minInstances: 0,
  maxInstances: 100
};

// High-memory functions (PDF generation, report parsing)
const highMemoryConfig = {
  ...defaultConfig,
  memory: "1GiB",
  timeoutSeconds: 300
};
```

### 1.3 Flutter Client Usage

```dart
// Initialize Cloud Functions
final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

// Call a function
final callable = functions.httpsCallable('createConsumer');
final result = await callable.call({
  'firstName': 'John',
  'lastName': 'Doe',
  'email': 'john@example.com',
  // ... other fields
});

// Handle result
final consumerId = result.data['consumerId'];
```

---

## 2. Authentication Functions

### 2.1 initializeUser

Sets up custom claims after user creation.

**Function Name:** `auth-initializeUser`
**Type:** Callable
**Trigger:** Called after Firebase Auth signup

```typescript
// Request
interface InitializeUserRequest {
  tenantId?: string;     // For joining existing tenant
  tenantName?: string;   // For creating new tenant
  role?: string;         // Role if joining tenant (requires invite)
  inviteCode?: string;   // Invite code for joining tenant
}

// Response
interface InitializeUserResponse {
  success: boolean;
  tenantId: string;
  role: string;
  message: string;
}
```

**Example:**

```dart
// Flutter - New tenant owner signup
final result = await functions.httpsCallable('auth-initializeUser').call({
  'tenantName': 'My Credit Repair Company',
});

// Flutter - Join existing tenant
final result = await functions.httpsCallable('auth-initializeUser').call({
  'tenantId': 'tenant_abc123',
  'inviteCode': 'INVITE123',
});
```

---

### 2.2 updateUserRole

Updates a user's role (owner only).

**Function Name:** `auth-updateUserRole`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface UpdateUserRoleRequest {
  userId: string;
  newRole: "operator" | "viewer" | "auditor";
}

// Response
interface UpdateUserRoleResponse {
  success: boolean;
  message: string;
}
```

---

### 2.3 inviteUser

Creates an invite for a new user.

**Function Name:** `auth-inviteUser`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface InviteUserRequest {
  email: string;
  role: "operator" | "viewer" | "auditor";
  expiresInDays?: number;  // Default: 7
}

// Response
interface InviteUserResponse {
  inviteId: string;
  inviteCode: string;
  inviteUrl: string;
  expiresAt: string;
}
```

---

### 2.4 revokeUserAccess

Revokes a user's access to the tenant.

**Function Name:** `auth-revokeUserAccess`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface RevokeUserAccessRequest {
  userId: string;
}

// Response
interface RevokeUserAccessResponse {
  success: boolean;
  message: string;
}
```

---

## 3. Consumer Functions

### 3.1 createConsumer

Creates a new consumer record.

**Function Name:** `consumers-create`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface CreateConsumerRequest {
  firstName: string;
  lastName: string;
  middleName?: string;
  suffix?: string;
  email: string;
  phone: string;
  alternatePhone?: string;
  ssn: string;              // Will be encrypted
  dob: string;              // YYYY-MM-DD, will be encrypted
  currentAddress: {
    street1: string;
    street2?: string;
    city: string;
    state: string;
    zipCode: string;
  };
  previousAddresses?: Array<{
    street1: string;
    street2?: string;
    city: string;
    state: string;
    zipCode: string;
    fromDate?: string;
    toDate?: string;
  }>;
  consent: {
    creditPull: boolean;
    electronicCommunication: boolean;
    termsOfService: boolean;
    privacyPolicy: boolean;
  };
  internalNotes?: string;
}

// Response
interface CreateConsumerResponse {
  consumerId: string;
  consumer: Consumer;
}
```

**Example:**

```dart
final result = await functions.httpsCallable('consumers-create').call({
  'firstName': 'Jane',
  'lastName': 'Smith',
  'email': 'jane.smith@email.com',
  'phone': '+15551112222',
  'ssn': '123-45-6789',
  'dob': '1985-03-15',
  'currentAddress': {
    'street1': '456 Oak Avenue',
    'street2': 'Apt 12B',
    'city': 'Miami',
    'state': 'FL',
    'zipCode': '33101',
  },
  'consent': {
    'creditPull': true,
    'electronicCommunication': true,
    'termsOfService': true,
    'privacyPolicy': true,
  },
});

final consumerId = result.data['consumerId'];
```

---

### 3.2 updateConsumer

Updates an existing consumer.

**Function Name:** `consumers-update`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface UpdateConsumerRequest {
  consumerId: string;
  updates: Partial<{
    firstName: string;
    lastName: string;
    middleName: string;
    email: string;
    phone: string;
    alternatePhone: string;
    currentAddress: Address;
    previousAddresses: Address[];
    internalNotes: string;
    status: "active" | "inactive" | "archived";
  }>;
}

// Response
interface UpdateConsumerResponse {
  success: boolean;
  consumer: Consumer;
}
```

---

### 3.3 getConsumer

Retrieves a consumer by ID.

**Function Name:** `consumers-get`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetConsumerRequest {
  consumerId: string;
  includeDisputes?: boolean;
  includeCreditReports?: boolean;
}

// Response
interface GetConsumerResponse {
  consumer: Consumer;
  disputes?: Dispute[];
  creditReports?: CreditReportSummary[];
}
```

---

### 3.4 listConsumers

Lists consumers with pagination and filtering.

**Function Name:** `consumers-list`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface ListConsumersRequest {
  limit?: number;            // Default: 25, Max: 100
  startAfter?: string;       // Document ID for pagination
  orderBy?: "createdAt" | "lastName" | "updatedAt";
  orderDirection?: "asc" | "desc";
  filters?: {
    status?: "active" | "inactive" | "archived";
    smartcreditStatus?: string;
    search?: string;         // Search firstName, lastName, email
  };
}

// Response
interface ListConsumersResponse {
  consumers: Consumer[];
  hasMore: boolean;
  lastDocId: string | null;
  totalCount: number;
}
```

---

### 3.5 deleteConsumer

Soft-deletes a consumer.

**Function Name:** `consumers-delete`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface DeleteConsumerRequest {
  consumerId: string;
}

// Response
interface DeleteConsumerResponse {
  success: boolean;
  message: string;
}
```

---

### 3.6 searchConsumers

Advanced search across consumers.

**Function Name:** `consumers-search`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface SearchConsumersRequest {
  query: string;             // Search term
  fields?: string[];         // Fields to search (default: all)
  limit?: number;
}

// Response
interface SearchConsumersResponse {
  consumers: Consumer[];
  totalResults: number;
}
```

---

## 4. SmartCredit Functions

### 4.1 initiateOAuth

Starts the SmartCredit OAuth flow.

**Function Name:** `smartcredit-initiateOAuth`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface InitiateOAuthRequest {
  consumerId: string;
  redirectUrl: string;
}

// Response
interface InitiateOAuthResponse {
  authorizationUrl: string;
  state: string;
  expiresAt: string;
}
```

**Example:**

```dart
final result = await functions.httpsCallable('smartcredit-initiateOAuth').call({
  'consumerId': 'consumer_def456',
  'redirectUrl': 'https://app.sfdify.com/oauth/callback',
});

// Redirect user to SmartCredit authorization page
final authUrl = result.data['authorizationUrl'];
launchUrl(Uri.parse(authUrl));
```

---

### 4.2 handleOAuthCallback

Completes the OAuth flow and stores tokens.

**Function Name:** `smartcredit-handleOAuthCallback`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface HandleOAuthCallbackRequest {
  code: string;
  state: string;
}

// Response
interface HandleOAuthCallbackResponse {
  success: boolean;
  consumerId: string;
  connectionStatus: string;
}
```

---

### 4.3 pullCreditReport

Pulls a credit report from SmartCredit.

**Function Name:** `smartcredit-pullCreditReport`
**Type:** Callable
**Required Role:** owner, operator
**Config:** highMemory (1GB, 5min timeout)

```typescript
// Request
interface PullCreditReportRequest {
  consumerId: string;
  bureaus?: ("equifax" | "experian" | "transunion")[];  // Default: all
}

// Response
interface PullCreditReportResponse {
  reportId: string;
  status: "processing" | "complete";
  scores: {
    equifax: number | null;
    experian: number | null;
    transunion: number | null;
  };
  summary: {
    totalAccounts: number;
    delinquentAccounts: number;
    collections: number;
  };
  tradelineCount: number;
}
```

---

### 4.4 refreshCreditReport

Refreshes an existing SmartCredit connection.

**Function Name:** `smartcredit-refreshCreditReport`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface RefreshCreditReportRequest {
  consumerId: string;
}

// Response
interface RefreshCreditReportResponse {
  reportId: string;
  previousReportId: string;
  changesDetected: boolean;
  summary: {
    newAccounts: number;
    closedAccounts: number;
    scoreChanges: {
      equifax: number;
      experian: number;
      transunion: number;
    };
  };
}
```

---

### 4.5 getCreditReport

Retrieves a credit report.

**Function Name:** `smartcredit-getCreditReport`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetCreditReportRequest {
  reportId: string;
  includeTradelines?: boolean;
}

// Response
interface GetCreditReportResponse {
  report: CreditReport;
  tradelines?: Tradeline[];
}
```

---

### 4.6 disconnectSmartCredit

Revokes SmartCredit connection.

**Function Name:** `smartcredit-disconnect`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface DisconnectSmartCreditRequest {
  consumerId: string;
}

// Response
interface DisconnectSmartCreditResponse {
  success: boolean;
  message: string;
}
```

---

## 5. Dispute Functions

### 5.1 createDispute

Creates a new dispute.

**Function Name:** `disputes-create`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface CreateDisputeRequest {
  consumerId: string;
  creditReportId: string;
  tradelineId: string;
  disputeType: DisputeType;
  disputeReason: DisputeReason;
  customReason?: string;
  priority?: "low" | "normal" | "high" | "urgent";
  autoGenerateLetter?: boolean;  // Default: true
}

// Response
interface CreateDisputeResponse {
  disputeId: string;
  dispute: Dispute;
  letterId?: string;             // If auto-generated
}
```

**Example:**

```dart
final result = await functions.httpsCallable('disputes-create').call({
  'consumerId': 'consumer_def456',
  'creditReportId': 'report_xyz123',
  'tradelineId': 'tradeline_ghi789',
  'disputeType': 'incorrect_info',
  'disputeReason': 'payment_history_wrong',
  'priority': 'normal',
  'autoGenerateLetter': true,
});

final disputeId = result.data['disputeId'];
```

---

### 5.2 updateDispute

Updates a dispute.

**Function Name:** `disputes-update`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface UpdateDisputeRequest {
  disputeId: string;
  updates: Partial<{
    disputeType: DisputeType;
    disputeReason: DisputeReason;
    customReason: string;
    narrative: string;
    priority: string;
  }>;
}

// Response
interface UpdateDisputeResponse {
  success: boolean;
  dispute: Dispute;
}
```

---

### 5.3 getDispute

Retrieves a dispute with related data.

**Function Name:** `disputes-get`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetDisputeRequest {
  disputeId: string;
  includeLetters?: boolean;
  includeEvidence?: boolean;
  includeTasks?: boolean;
  includeComments?: boolean;
}

// Response
interface GetDisputeResponse {
  dispute: Dispute;
  letters?: Letter[];
  evidence?: Evidence[];
  tasks?: DisputeTask[];
  comments?: DisputeComment[];
}
```

---

### 5.4 listDisputes

Lists disputes with filtering.

**Function Name:** `disputes-list`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface ListDisputesRequest {
  limit?: number;
  startAfter?: string;
  orderBy?: "createdAt" | "updatedAt" | "priority";
  orderDirection?: "asc" | "desc";
  filters?: {
    consumerId?: string;
    status?: DisputeStatus | DisputeStatus[];
    bureau?: "equifax" | "experian" | "transunion";
    priority?: string;
    disputeType?: DisputeType;
    slaWarning?: boolean;        // Approaching deadline
  };
}

// Response
interface ListDisputesResponse {
  disputes: Dispute[];
  hasMore: boolean;
  lastDocId: string | null;
  stats: {
    total: number;
    byStatus: Record<DisputeStatus, number>;
    slaWarnings: number;
  };
}
```

---

### 5.5 updateDisputeStatus

Updates dispute status with validation.

**Function Name:** `disputes-updateStatus`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface UpdateDisputeStatusRequest {
  disputeId: string;
  newStatus: DisputeStatus;
  notes?: string;
}

// Response
interface UpdateDisputeStatusResponse {
  success: boolean;
  previousStatus: DisputeStatus;
  newStatus: DisputeStatus;
  statusHistory: StatusHistoryEntry[];
}
```

---

### 5.6 recordDisputeOutcome

Records the outcome of a dispute.

**Function Name:** `disputes-recordOutcome`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface RecordDisputeOutcomeRequest {
  disputeId: string;
  outcome: {
    result: "deleted" | "updated" | "verified" | "no_response";
    resultNotes?: string;
    newBalance?: number;
    newStatus?: string;
  };
}

// Response
interface RecordDisputeOutcomeResponse {
  success: boolean;
  dispute: Dispute;
}
```

---

### 5.7 cancelDispute

Cancels a dispute.

**Function Name:** `disputes-cancel`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface CancelDisputeRequest {
  disputeId: string;
  reason: string;
}

// Response
interface CancelDisputeResponse {
  success: boolean;
  message: string;
}
```

---

## 6. Letter Functions

### 6.1 generateLetter

Generates a dispute letter.

**Function Name:** `letters-generate`
**Type:** Callable
**Required Role:** owner, operator
**Config:** highMemory

```typescript
// Request
interface GenerateLetterRequest {
  disputeId: string;
  letterType: LetterType;
  templateId?: string;           // Use specific template
  customVariables?: Record<string, any>;
}

// Response
interface GenerateLetterResponse {
  letterId: string;
  letter: Letter;
  previewUrl: string;            // Temporary signed URL
}
```

**Example:**

```dart
final result = await functions.httpsCallable('letters-generate').call({
  'disputeId': 'dispute_abc123',
  'letterType': 'fcra_611',
});

final letterId = result.data['letterId'];
final previewUrl = result.data['previewUrl'];
```

---

### 6.2 previewLetter

Generates a preview without saving.

**Function Name:** `letters-preview`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface PreviewLetterRequest {
  disputeId: string;
  letterType: LetterType;
  templateId?: string;
  customNarrative?: string;
}

// Response
interface PreviewLetterResponse {
  html: string;
  previewPdfUrl: string;         // Temporary URL
}
```

---

### 6.3 approveLetter

Approves a letter for sending.

**Function Name:** `letters-approve`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface ApproveLetterRequest {
  letterId: string;
  autoSend?: boolean;            // Send immediately after approval
  mailType?: "usps_first_class" | "certified" | "certified_return_receipt";
}

// Response
interface ApproveLetterResponse {
  success: boolean;
  letter: Letter;
  mailingId?: string;            // If autoSend is true
}
```

---

### 6.4 rejectLetter

Rejects a letter with reason.

**Function Name:** `letters-reject`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface RejectLetterRequest {
  letterId: string;
  reason: string;
}

// Response
interface RejectLetterResponse {
  success: boolean;
  letter: Letter;
}
```

---

### 6.5 regenerateLetter

Regenerates a letter (creates new version).

**Function Name:** `letters-regenerate`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface RegenerateLetterRequest {
  letterId: string;
  customNarrative?: string;
  templateId?: string;
}

// Response
interface RegenerateLetterResponse {
  newLetterId: string;
  letter: Letter;
  previousVersionId: string;
}
```

---

### 6.6 getLetter

Retrieves a letter.

**Function Name:** `letters-get`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetLetterRequest {
  letterId: string;
  includePdfUrl?: boolean;
}

// Response
interface GetLetterResponse {
  letter: Letter;
  pdfUrl?: string;               // Signed URL if requested
}
```

---

### 6.7 downloadLetterPdf

Generates a signed download URL.

**Function Name:** `letters-downloadPdf`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface DownloadLetterPdfRequest {
  letterId: string;
  expiresInMinutes?: number;     // Default: 60
}

// Response
interface DownloadLetterPdfResponse {
  downloadUrl: string;
  expiresAt: string;
}
```

---

## 7. Mailing Functions

### 7.1 sendLetter

Sends a letter via Lob.

**Function Name:** `mailings-send`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface SendLetterRequest {
  letterId: string;
  mailType: "usps_first_class" | "certified" | "certified_return_receipt";
  scheduledDate?: string;        // ISO date for scheduling
}

// Response
interface SendLetterResponse {
  mailingId: string;
  mailing: Mailing;
  expectedDeliveryDate: string;
  cost: {
    amount: number;
    currency: string;
  };
}
```

---

### 7.2 cancelMailing

Cancels a mailing (if not yet sent).

**Function Name:** `mailings-cancel`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface CancelMailingRequest {
  mailingId: string;
  reason: string;
}

// Response
interface CancelMailingResponse {
  success: boolean;
  refundAmount?: number;
  message: string;
}
```

---

### 7.3 trackMailing

Gets current tracking status.

**Function Name:** `mailings-track`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface TrackMailingRequest {
  mailingId: string;
}

// Response
interface TrackMailingResponse {
  mailing: Mailing;
  trackingEvents: Array<{
    status: string;
    timestamp: string;
    location?: string;
    details?: string;
  }>;
  estimatedDelivery?: string;
}
```

---

### 7.4 getMailing

Retrieves mailing details.

**Function Name:** `mailings-get`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetMailingRequest {
  mailingId: string;
}

// Response
interface GetMailingResponse {
  mailing: Mailing;
}
```

---

## 8. Evidence Functions

### 8.1 uploadEvidence

Uploads evidence to a dispute.

**Function Name:** `evidence-upload`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface UploadEvidenceRequest {
  disputeId: string;
  fileName: string;
  fileType: string;              // MIME type
  fileSize: number;
  evidenceType: EvidenceType;
  description?: string;
  dateOfDocument?: string;
}

// Response
interface UploadEvidenceResponse {
  evidenceId: string;
  uploadUrl: string;             // Signed upload URL
  uploadFields: Record<string, string>;  // For multipart upload
}
```

**Flutter Upload Flow:**

```dart
// Step 1: Get upload URL
final result = await functions.httpsCallable('evidence-upload').call({
  'disputeId': 'dispute_abc123',
  'fileName': 'bank_statement.pdf',
  'fileType': 'application/pdf',
  'fileSize': 102400,
  'evidenceType': 'bank_statement',
  'description': 'October 2023 statement showing payment',
});

final uploadUrl = result.data['uploadUrl'];
final evidenceId = result.data['evidenceId'];

// Step 2: Upload file to signed URL
final ref = FirebaseStorage.instance.refFromURL(uploadUrl);
await ref.putFile(file);

// Step 3: Confirm upload
await functions.httpsCallable('evidence-confirmUpload').call({
  'evidenceId': evidenceId,
});
```

---

### 8.2 confirmUpload

Confirms evidence upload completed.

**Function Name:** `evidence-confirmUpload`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface ConfirmUploadRequest {
  evidenceId: string;
}

// Response
interface ConfirmUploadResponse {
  success: boolean;
  evidence: Evidence;
}
```

---

### 8.3 deleteEvidence

Deletes evidence from a dispute.

**Function Name:** `evidence-delete`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface DeleteEvidenceRequest {
  evidenceId: string;
}

// Response
interface DeleteEvidenceResponse {
  success: boolean;
  message: string;
}
```

---

### 8.4 listEvidence

Lists evidence for a dispute.

**Function Name:** `evidence-list`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface ListEvidenceRequest {
  disputeId: string;
}

// Response
interface ListEvidenceResponse {
  evidence: Evidence[];
}
```

---

## 9. Template Functions

### 9.1 listTemplates

Lists available letter templates.

**Function Name:** `templates-list`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface ListTemplatesRequest {
  letterType?: LetterType;
  includeSystemTemplates?: boolean;
}

// Response
interface ListTemplatesResponse {
  templates: LetterTemplate[];
}
```

---

### 9.2 getTemplate

Gets a template by ID.

**Function Name:** `templates-get`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetTemplateRequest {
  templateId: string;
}

// Response
interface GetTemplateResponse {
  template: LetterTemplate;
}
```

---

### 9.3 createTemplate

Creates a custom template.

**Function Name:** `templates-create`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface CreateTemplateRequest {
  name: string;
  description: string;
  letterType: LetterType;
  category: "bureau" | "creditor" | "collection" | "other";
  content: {
    html: string;
    css?: string;
    headerHtml?: string;
    footerHtml?: string;
  };
  variables: Array<{
    name: string;
    description: string;
    required: boolean;
    defaultValue?: string;
  }>;
}

// Response
interface CreateTemplateResponse {
  templateId: string;
  template: LetterTemplate;
}
```

---

### 9.4 updateTemplate

Updates a custom template.

**Function Name:** `templates-update`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface UpdateTemplateRequest {
  templateId: string;
  updates: Partial<CreateTemplateRequest>;
}

// Response
interface UpdateTemplateResponse {
  success: boolean;
  template: LetterTemplate;
}
```

---

### 9.5 deleteTemplate

Deletes a custom template.

**Function Name:** `templates-delete`
**Type:** Callable
**Required Role:** owner

```typescript
// Request
interface DeleteTemplateRequest {
  templateId: string;
}

// Response
interface DeleteTemplateResponse {
  success: boolean;
  message: string;
}
```

---

## 10. Webhook Handlers (HTTP Functions)

### 10.1 Lob Webhook

**Function Name:** `webhooks-lob`
**Type:** HTTP (POST)
**URL:** `https://us-central1-{project}.cloudfunctions.net/webhooks-lob`

```typescript
// Lob webhook payload
interface LobWebhookPayload {
  id: string;
  event_type: {
    id: string;                  // e.g., "letter.mailed"
    enabled_for_test: boolean;
  };
  date_created: string;
  body: {
    id: string;                  // Letter ID
    tracking_number?: string;
    carrier?: string;
    expected_delivery_date?: string;
    // ... other Lob letter fields
  };
}
```

**Supported Events:**
- `letter.created`
- `letter.rendered_pdf`
- `letter.rendered_thumbnails`
- `letter.mailed`
- `letter.in_transit`
- `letter.in_local_area`
- `letter.processed_for_delivery`
- `letter.delivered`
- `letter.returned_to_sender`

---

### 10.2 SmartCredit Webhook

**Function Name:** `webhooks-smartcredit`
**Type:** HTTP (POST)
**URL:** `https://us-central1-{project}.cloudfunctions.net/webhooks-smartcredit`

```typescript
// SmartCredit webhook payload
interface SmartCreditWebhookPayload {
  event: string;
  timestamp: string;
  data: {
    userId: string;
    reportId?: string;
    changes?: {
      newAccounts?: number;
      scoreChanges?: object;
    };
  };
}
```

**Supported Events:**
- `report.ready`
- `report.updated`
- `connection.expired`
- `connection.revoked`

---

## 11. Scheduled Functions

### 11.1 Daily SLA Check

**Function Name:** `scheduled-slaCheck`
**Schedule:** `0 8 * * *` (Daily at 8 AM ET)

Checks for disputes approaching SLA deadlines and sends notifications.

---

### 11.2 Credit Refresh

**Function Name:** `scheduled-creditRefresh`
**Schedule:** `0 2 * * 0` (Weekly on Sunday at 2 AM ET)

Auto-refreshes credit reports for active disputes.

---

### 11.3 Cleanup Expired Data

**Function Name:** `scheduled-cleanup`
**Schedule:** `0 3 * * *` (Daily at 3 AM ET)

Cleans up:
- Expired credit reports
- Old webhook events
- Dismissed notifications

---

### 11.4 Generate Reports

**Function Name:** `scheduled-generateReports`
**Schedule:** `0 6 1 * *` (Monthly on 1st at 6 AM ET)

Generates monthly analytics reports for tenants.

---

## 12. Analytics Functions

### 12.1 getDashboardStats

Gets dashboard statistics.

**Function Name:** `analytics-getDashboardStats`
**Type:** Callable
**Required Role:** owner, operator, viewer, auditor

```typescript
// Request
interface GetDashboardStatsRequest {
  dateRange?: {
    start: string;
    end: string;
  };
}

// Response
interface GetDashboardStatsResponse {
  consumers: {
    total: number;
    active: number;
    newThisMonth: number;
  };
  disputes: {
    total: number;
    active: number;
    resolved: number;
    successRate: number;
    averageResolutionDays: number;
    byStatus: Record<DisputeStatus, number>;
    byBureau: Record<string, number>;
  };
  letters: {
    sent: number;
    pending: number;
    delivered: number;
    returned: number;
  };
  sla: {
    approaching: number;
    violated: number;
  };
}
```

---

### 12.2 getDisputeAnalytics

Gets detailed dispute analytics.

**Function Name:** `analytics-getDisputeAnalytics`
**Type:** Callable
**Required Role:** owner, operator

```typescript
// Request
interface GetDisputeAnalyticsRequest {
  dateRange: {
    start: string;
    end: string;
  };
  groupBy?: "day" | "week" | "month";
}

// Response
interface GetDisputeAnalyticsResponse {
  timeSeries: Array<{
    date: string;
    created: number;
    resolved: number;
    successful: number;
  }>;
  byDisputeType: Record<DisputeType, {
    total: number;
    successRate: number;
  }>;
  byBureau: Record<string, {
    total: number;
    successRate: number;
    averageResolutionDays: number;
  }>;
  topCreditors: Array<{
    name: string;
    disputes: number;
    successRate: number;
  }>;
}
```

---

## 13. Error Handling

### 13.1 Error Codes

```typescript
// Standard error codes
const ErrorCodes = {
  // Authentication errors
  UNAUTHENTICATED: "unauthenticated",
  PERMISSION_DENIED: "permission-denied",
  INVALID_TOKEN: "invalid-token",

  // Validation errors
  INVALID_ARGUMENT: "invalid-argument",
  MISSING_REQUIRED_FIELD: "missing-required-field",
  INVALID_FORMAT: "invalid-format",

  // Resource errors
  NOT_FOUND: "not-found",
  ALREADY_EXISTS: "already-exists",
  RESOURCE_EXHAUSTED: "resource-exhausted",

  // State errors
  FAILED_PRECONDITION: "failed-precondition",
  INVALID_STATE: "invalid-state",

  // External service errors
  EXTERNAL_SERVICE_ERROR: "external-service-error",
  SMARTCREDIT_ERROR: "smartcredit-error",
  LOB_ERROR: "lob-error",

  // Internal errors
  INTERNAL: "internal",
  UNAVAILABLE: "unavailable"
};
```

### 13.2 Error Response Format

```typescript
interface ErrorResponse {
  code: string;
  message: string;
  details?: Record<string, any>;
}
```

**Flutter Error Handling:**

```dart
try {
  final result = await functions.httpsCallable('consumers-create').call(data);
  // Handle success
} on FirebaseFunctionsException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      // Handle permission error
      break;
    case 'invalid-argument':
      // Handle validation error
      final details = e.details as Map<String, dynamic>?;
      final field = details?['field'];
      // Show field-specific error
      break;
    default:
      // Handle other errors
  }
}
```

---

## 14. Rate Limiting

### 14.1 Rate Limits

| Function Category | Limit per User | Limit per Tenant |
|-------------------|----------------|------------------|
| Read operations | 100/minute | 1000/minute |
| Write operations | 30/minute | 300/minute |
| Credit pulls | 10/hour | 50/hour |
| Letter sends | 20/hour | 100/hour |

### 14.2 Rate Limit Response

When rate limited, functions return:

```typescript
{
  code: "resource-exhausted",
  message: "Rate limit exceeded. Try again in X seconds.",
  details: {
    retryAfter: 60
  }
}
```

---

## Appendix A: TypeScript Types

```typescript
// Common types used across API

type DisputeType =
  | "not_mine"
  | "incorrect_info"
  | "identity_theft"
  | "paid_account"
  | "duplicate"
  | "outdated"
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
  | "draft"
  | "pending_letter"
  | "letter_generated"
  | "letter_approved"
  | "letter_sent"
  | "in_transit"
  | "delivered"
  | "pending_response"
  | "response_received"
  | "resolved"
  | "escalated"
  | "cancelled";

type LetterType =
  | "fcra_609"
  | "fcra_611"
  | "mov"
  | "reinvestigation"
  | "goodwill"
  | "pay_for_delete"
  | "fcra_605b"
  | "cfpb_complaint";

type LetterStatus =
  | "draft"
  | "generated"
  | "pending_approval"
  | "approved"
  | "rejected"
  | "sent"
  | "cancelled";

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

interface Address {
  street1: string;
  street2?: string;
  city: string;
  state: string;
  zipCode: string;
  country?: string;
}
```

---

## Appendix B: Flutter Service Example

```dart
// lib/services/dispute_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class DisputeService {
  final FirebaseFunctions _functions;

  DisputeService()
      : _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Dispute> createDispute({
    required String consumerId,
    required String creditReportId,
    required String tradelineId,
    required String disputeType,
    required String disputeReason,
    String? customReason,
    String priority = 'normal',
  }) async {
    try {
      final callable = _functions.httpsCallable('disputes-create');
      final result = await callable.call({
        'consumerId': consumerId,
        'creditReportId': creditReportId,
        'tradelineId': tradelineId,
        'disputeType': disputeType,
        'disputeReason': disputeReason,
        'customReason': customReason,
        'priority': priority,
        'autoGenerateLetter': true,
      });

      return Dispute.fromJson(result.data['dispute']);
    } on FirebaseFunctionsException catch (e) {
      throw DisputeServiceException(
        code: e.code,
        message: e.message ?? 'Unknown error',
        details: e.details,
      );
    }
  }

  Future<List<Dispute>> listDisputes({
    String? consumerId,
    List<String>? statuses,
    int limit = 25,
    String? startAfter,
  }) async {
    final callable = _functions.httpsCallable('disputes-list');
    final result = await callable.call({
      'limit': limit,
      'startAfter': startAfter,
      'filters': {
        'consumerId': consumerId,
        'status': statuses,
      },
    });

    final disputes = (result.data['disputes'] as List)
        .map((d) => Dispute.fromJson(d))
        .toList();

    return disputes;
  }

  // ... other methods
}
```
