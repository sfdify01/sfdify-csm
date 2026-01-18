/**
 * USTAXX Type Definitions
 *
 * Core TypeScript interfaces for all entities in the system.
 * Based on ARCHITECTURE.md ERD and JSON examples.
 */

import { Timestamp, FieldValue } from "firebase-admin/firestore";

// ============================================================================
// Common Types
// ============================================================================

export type DocumentId = string;

export interface Address {
  type: "current" | "previous" | "mailing";
  street1: string;
  street2?: string | null;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  moveInDate?: string;
  moveOutDate?: string;
  isPrimary: boolean;
}

/**
 * Simplified mailing address for letters
 * Used for bureau addresses and return addresses on letters
 */
export interface MailingAddress {
  name: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  zipCode: string;
}

export interface Phone {
  type: "mobile" | "home" | "work";
  number: string;
  isPrimary: boolean;
  verified: boolean;
  verifiedAt?: Timestamp;
}

export interface Email {
  address: string;
  isPrimary: boolean;
  verified: boolean;
  verifiedAt?: Timestamp;
}

export type UserRole = "owner" | "operator" | "viewer" | "auditor";

export type DisputeStatus =
  | "draft"
  | "pending_review"
  | "approved"
  | "rejected"
  | "mailed"
  | "delivered"
  | "bureau_investigating"
  | "resolved"
  | "closed";

export type LetterStatus =
  | "draft"
  | "pending_approval"
  | "approved"
  | "rendering"
  | "ready"
  | "queued"
  | "sent"
  | "in_transit"
  | "delivered"
  | "returned_to_sender";

export type Bureau = "equifax" | "experian" | "transunion";

export type DisputeType =
  | "611_dispute"
  | "609_request"
  | "605b_identity_theft"
  | "reinvestigation"
  | "goodwill"
  | "pay_for_delete"
  | "debt_validation"
  | "cease_desist";

export type MailType = "usps_first_class" | "usps_certified" | "usps_certified_return_receipt";

export type DisputeOutcome =
  | "corrected"
  | "verified_accurate"
  | "deleted"
  | "pending"
  | "no_response"
  | "frivolous";

// ============================================================================
// Tenant
// ============================================================================

export interface TenantBranding {
  logoUrl?: string;
  letterheadUrl?: string;
  primaryColor: string;
  companyName: string;
  tagline?: string;
}

export interface TenantLobConfig {
  senderId?: string;
  returnAddress: Address;
  defaultMailType: MailType;
}

export interface TenantFeatures {
  aiDraftingEnabled: boolean;
  certifiedMailEnabled: boolean;
  identityTheftBlockEnabled: boolean;
  cfpbExportEnabled: boolean;
  maxConsumers: number;
  maxDisputesPerMonth: number;
}

export interface Tenant {
  id: DocumentId;
  name: string;
  plan: "starter" | "professional" | "enterprise";
  status: "active" | "suspended" | "cancelled";
  branding: TenantBranding;
  lobConfig: TenantLobConfig;
  smartCreditConfig?: {
    clientIdSecretRef: string;
    clientSecretRef: string;
    webhookEndpoint: string;
  };
  features: TenantFeatures;
  billing?: {
    stripeCustomerId?: string;
    currentPeriodStart: Timestamp;
    currentPeriodEnd: Timestamp;
  };
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
}

// ============================================================================
// User
// ============================================================================

export interface User {
  id: DocumentId;
  tenantId: DocumentId;
  email: string;
  displayName: string;
  role: UserRole;
  permissions: string[];
  twoFactorEnabled: boolean;
  createdAt: Timestamp | FieldValue;
  lastLoginAt?: Timestamp;
  disabled: boolean;
}

// ============================================================================
// Consumer
// ============================================================================

export interface ConsumerConsent {
  agreedAt: Timestamp;
  ipAddress: string;
  userAgent?: string;
  termsVersion: string;
  privacyVersion: string;
  fcraDisclosureVersion: string;
}

export interface Consumer {
  id: DocumentId;
  tenantId: DocumentId;
  firstName: string; // Encrypted
  lastName: string; // Encrypted
  dob: string; // Encrypted
  ssnLast4: string; // Encrypted
  addresses: Address[];
  phones: Phone[];
  emails: Email[];
  kycStatus: "pending" | "verified" | "failed";
  kycVerifiedAt?: Timestamp;
  consent: ConsumerConsent;
  smartCreditConnectionId?: DocumentId;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  createdBy: DocumentId;
}

// ============================================================================
// SmartCredit Connection
// ============================================================================

export interface SmartCreditConnection {
  id: DocumentId;
  consumerId: DocumentId;
  tenantId: DocumentId;
  accessToken: string; // Encrypted
  refreshToken: string; // Encrypted
  tokenExpiresAt: Timestamp;
  scopes: string[];
  connectedAt: Timestamp;
  lastRefreshedAt: Timestamp;
  status: "connected" | "expired" | "revoked" | "error";
  revokedAt?: Timestamp;
  errorMessage?: string;
}

// ============================================================================
// Credit Report
// ============================================================================

export interface ScoreFactor {
  code: string;
  description: string;
}

export interface Inquiry {
  creditor: string;
  date: string;
  type: "hard" | "soft";
}

export interface ReportSummary {
  totalAccounts: number;
  openAccounts: number;
  closedAccounts: number;
  delinquentAccounts: number;
  derogatoryAccounts: number;
  totalBalance: number;
  totalCreditLimit: number;
  utilizationPercent: number;
}

export interface CreditReport {
  id: DocumentId;
  consumerId: DocumentId;
  tenantId: DocumentId;
  bureau: Bureau;
  pulledAt: Timestamp;
  rawJsonRef: string; // Storage path, encrypted
  hash: string;
  score?: number;
  scoreFactors: ScoreFactor[];
  smartCreditReportId?: string;
  summary: ReportSummary;
  publicRecords: unknown[];
  inquiries: Inquiry[];
  status: "processing" | "processed" | "error";
  processingError?: string;
  createdAt: Timestamp | FieldValue;
  expiresAt: Timestamp;
}

// ============================================================================
// Tradeline
// ============================================================================

export interface PaymentHistoryEntry {
  month: string;
  status: "current" | "30_days_late" | "60_days_late" | "90_days_late" | "120_days_late" | "charge_off" | "unknown";
}

export interface Tradeline {
  id: DocumentId;
  reportId: DocumentId;
  consumerId: DocumentId;
  tenantId: DocumentId;
  bureau: Bureau;
  creditorName: string;
  originalCreditor?: string;
  accountNumberMasked: string;
  accountType: string;
  accountTypeDetail?: string;
  ownershipType: "individual" | "joint" | "authorized_user";
  openedDate?: string;
  closedDate?: string;
  lastActivityDate?: string;
  lastReportedDate?: string;
  balance: number;
  creditLimit?: number;
  highBalance?: number;
  pastDueAmount: number;
  monthlyPayment?: number;
  paymentStatus: string;
  paymentStatusDetail?: string;
  accountStatus: "open" | "closed" | "paid" | "collection" | "charge_off";
  paymentHistory: PaymentHistoryEntry[];
  remarks: string[];
  disputeStatus: "none" | "in_dispute" | "resolved";
  disputeFlag: boolean;
  consumerStatement?: string;
  smartCreditTradelineId?: string;
  dateOfFirstDelinquency?: string;
  scheduledPayoffDate?: string;
  terms?: {
    frequency: string;
    duration?: number;
  };
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
}

// ============================================================================
// Dispute
// ============================================================================

export interface DisputeReasonDetail {
  reportedValue?: string | number;
  actualValue?: string | number;
  reportedMonth?: string;
  reportedStatus?: string;
  actualStatus?: string;
  explanation: string;
}

export interface DisputeTimestamps {
  createdAt: Timestamp;
  submittedAt?: Timestamp;
  approvedAt?: Timestamp;
  rejectedAt?: Timestamp;
  mailedAt?: Timestamp;
  deliveredAt?: Timestamp;
  dueAt?: Timestamp;
  slaExtendedAt?: Timestamp;
  followedUpAt?: Timestamp;
  closedAt?: Timestamp;
}

export interface DisputeSla {
  baseDays: number;
  extendedDays: number;
  isExtended: boolean;
  extensionReason?: string;
}

export interface DisputeOutcomeDetails {
  balanceCorrected?: boolean;
  statusCorrected?: boolean;
  accountDeleted?: boolean;
  noChange?: boolean;
  bureauResponse?: string;
  responseDate?: Timestamp;
}

export interface Dispute {
  id: DocumentId;
  consumerId: DocumentId;
  tradelineId: DocumentId;
  tenantId: DocumentId;
  bureau: Bureau;
  type: DisputeType;
  reasonCodes: string[];
  reasonDetails: Record<string, DisputeReasonDetail>;
  narrative: string;
  status: DisputeStatus;
  priority: "low" | "normal" | "high" | "urgent";
  assignedTo?: DocumentId;
  timestamps: DisputeTimestamps;
  sla: DisputeSla;
  outcome?: DisputeOutcome;
  outcomeDetails?: DisputeOutcomeDetails;
  bureauResponseRef?: string;
  letterIds: DocumentId[];
  evidenceIds: DocumentId[];
  tags: string[];
  internalNotes?: string;
  createdBy: DocumentId;
  updatedAt: Timestamp | FieldValue;
}

// ============================================================================
// Letter
// ============================================================================

export interface LetterStatusHistoryEntry {
  status: LetterStatus;
  timestamp: Timestamp;
  by?: string;
}

export interface LetterCost {
  printing: number;
  postage: number;
  certifiedFee?: number;
  total: number;
  currency: string;
}

export interface DeliveryEvent {
  event: string;
  timestamp: Timestamp;
  location?: string;
}

export interface QualityChecks {
  addressValidated: boolean;
  narrativeLengthOk: boolean;
  evidenceIndexGenerated: boolean;
  pdfIntegrityVerified: boolean;
  allFieldsComplete: boolean;
  checkedAt?: Timestamp;
}

export interface EvidenceIndexEntry {
  evidenceId: DocumentId;
  filename: string;
  description: string;
  pageInLetter?: number;
}

export interface Letter {
  id: DocumentId;
  disputeId: DocumentId;
  tenantId: DocumentId;
  type: DisputeType;
  templateId: DocumentId;
  renderVersion: string;
  contentHtml?: string;
  contentMarkdown?: string;
  pdfUrl?: string;
  pdfHash?: string;
  pdfSizeBytes?: number;
  pageCount?: number;
  lobId?: string;
  lobUrl?: string;
  mailType: MailType;
  mailTypeDetail?: {
    service: string;
    returnReceipt: boolean;
    extraService?: string;
  };
  trackingCode?: string;
  trackingUrl?: string;
  recipientAddress: MailingAddress;
  returnAddress: MailingAddress;
  senderOnBehalf?: MailingAddress;
  status: LetterStatus;
  statusHistory: LetterStatusHistoryEntry[];
  cost?: LetterCost;
  deliveryEvents: DeliveryEvent[];
  sentAt?: Timestamp;
  deliveredAt?: Timestamp;
  returnedAt?: Timestamp;
  returnReason?: string;
  createdAt: Timestamp | FieldValue;
  createdBy: DocumentId;
  approvedBy?: DocumentId;
  approvedAt?: Timestamp;
  qualityChecks?: QualityChecks;
  evidenceIndex: EvidenceIndexEntry[];
}

// ============================================================================
// Evidence
// ============================================================================

export interface VirusScan {
  status: "pending" | "scanning" | "clean" | "infected" | "error";
  scannedAt?: Timestamp;
  engine?: string;
  engineVersion?: string;
  virusName?: string;
}

export interface Evidence {
  id: DocumentId;
  disputeId: DocumentId;
  tenantId: DocumentId;
  filename: string;
  originalFilename: string;
  fileUrl: string; // Storage path
  mimeType: string;
  fileSize: number;
  checksum: string;
  source: "consumer_upload" | "operator_upload" | "smartcredit" | "system";
  description?: string;
  category?: string;
  pageCount?: number;
  extractedData?: Record<string, unknown>;
  virusScan: VirusScan;
  redactions: unknown[];
  linkedToLetters: DocumentId[];
  uploadedAt: Timestamp | FieldValue;
  uploadedBy: DocumentId;
  verifiedAt?: Timestamp;
  verifiedBy?: DocumentId;
}

// ============================================================================
// Letter Template
// ============================================================================

export interface LetterTemplate {
  id: DocumentId;
  tenantId?: DocumentId; // null for system templates
  type: DisputeType;
  name: string;
  description: string;
  contentTemplate: string; // Markdown with Handlebars variables
  legalCitations: string[];
  requiredVariables: string[];
  isSystemTemplate: boolean;
  version: string;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
}

// ============================================================================
// Webhook Event
// ============================================================================

export interface WebhookEvent {
  id: DocumentId;
  tenantId: DocumentId;
  provider: "lob" | "smartcredit";
  eventType: string;
  resourceType: string;
  resourceId: string;
  internalResourceId?: DocumentId;
  payload: unknown;
  signature: string;
  signatureValid: boolean;
  receivedAt: Timestamp | FieldValue;
  processedAt?: Timestamp;
  status: "received" | "processing" | "processed" | "failed" | "ignored";
  processingResult?: Record<string, unknown>;
  errorMessage?: string;
  retryCount: number;
}

// ============================================================================
// Audit Log
// ============================================================================

export interface AuditLog {
  id: DocumentId;
  tenantId: DocumentId;
  actorId: DocumentId;
  actorEmail?: string;
  actorRole: UserRole;
  actorIp?: string;
  userAgent?: string;
  entity: string;
  entityId: DocumentId;
  entityPath: string;
  action: "create" | "read" | "update" | "delete" | "auto_close" | "status_change" | "login" | "logout" | "export" | "send" | "approve" | "reject" | "upload" | "download" | "connect" | "disconnect" | "refresh";
  actionDetail?: string;
  previousState?: Record<string, unknown>;
  newState?: Record<string, unknown>;
  diffJson?: Record<string, { from: unknown; to: unknown }>;
  metadata?: {
    source: string;
    sessionId?: string;
    requestId?: string;
  };
  timestamp: Timestamp | FieldValue;
  retentionUntil: Timestamp;
}

// ============================================================================
// Scheduled Task
// ============================================================================

export interface ScheduledTask {
  id: DocumentId;
  tenantId: DocumentId;
  type: "sla_reminder" | "sla_follow_up" | "report_refresh" | "reconciliation" | "notification";
  entityType: string;
  entityId: DocumentId;
  description: string;
  scheduledFor: Timestamp;
  priority: "low" | "normal" | "high" | "urgent";
  assignTo?: DocumentId;
  status: "pending" | "in_progress" | "completed" | "failed" | "cancelled";
  metadata?: Record<string, unknown>;
  notifications?: Array<{
    channel: "email" | "sms" | "in_app";
    sentAt?: Timestamp;
  }>;
  retryCount: number;
  lastAttemptAt?: Timestamp;
  completedAt?: Timestamp;
  result?: Record<string, unknown>;
  createdAt: Timestamp | FieldValue;
  createdBy: string;
}

// ============================================================================
// Billing Record
// ============================================================================

export interface BillingRecord {
  id: DocumentId;
  tenantId: DocumentId;
  periodStart: Timestamp;
  periodEnd: Timestamp;
  usage: {
    consumersTotal: number;
    consumersNew: number;
    disputesCreated: number;
    disputesResolved: number;
    lettersGenerated: number;
    lettersMailed: number;
    smartCreditPulls: number;
    smartCreditAlerts: number;
    storageUsedMb: number;
    filesStored: number;
  };
  costs: {
    lobPostage: number;
    lobPrinting: number;
    smartCreditApi: number;
    total: number;
  };
  billing: {
    basePlanFee: number;
    overageCharges: number;
    totalDue: number;
    status: "pending" | "invoiced" | "paid" | "overdue";
  };
  paidAt?: Timestamp;
  invoiceUrl?: string;
  createdAt: Timestamp | FieldValue;
}

// ============================================================================
// Notification
// ============================================================================

export interface Notification {
  id: DocumentId;
  tenantId: DocumentId;
  userId?: DocumentId;
  consumerId?: DocumentId;
  type: string;
  channel: "email" | "sms" | "in_app";
  subject?: string;
  body: string;
  metadata?: Record<string, unknown>;
  status: "pending" | "sent" | "delivered" | "failed";
  sentAt?: Timestamp;
  deliveredAt?: Timestamp;
  failedAt?: Timestamp;
  errorMessage?: string;
  createdAt: Timestamp | FieldValue;
}

// ============================================================================
// API Request/Response Types
// ============================================================================

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}

export interface PaginatedResponse<T> extends ApiResponse<{ items: T[]; pagination: Pagination }> {}

export interface Pagination {
  total: number;
  limit: number;
  offset?: number;
  hasMore: boolean;
  nextCursor?: string;
}
