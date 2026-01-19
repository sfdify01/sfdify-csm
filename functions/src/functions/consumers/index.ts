/**
 * Consumer Management Cloud Functions
 *
 * Handles consumer CRUD, SmartCredit connection, and report management.
 * PII fields (firstName, lastName, dob, ssnLast4) are encrypted at rest.
 */

import * as functions from "firebase-functions";
import { db, storage } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  withAuth,
  RequestContext,
} from "../../middleware/auth";
import {
  validate,
  createConsumerSchema,
  updateConsumerSchema,
  paginationSchema,
  schemas,
} from "../../utils/validation";
import {
  withErrorHandling,
  NotFoundError,
  ConflictError,
  ForbiddenError,
  assertExists,
  ErrorCode,
  AppError,
} from "../../utils/errors";
import {
  encryptPii,
  decryptPiiFields,
  hashPii,
  maskValue,
} from "../../utils/encryption";
import { logAuditEvent } from "../../utils/audit";
import { smartCreditService } from "../../services/smartCreditService";
import { firebaseConfig } from "../../config";
import {
  Consumer,
  ConsumerConsent,
  ConsumerStatus,
  Address,
  Phone,
  Email,
  Tradeline,
  SmartCreditConnection,
  CreditReport,
  Bureau,
  ApiResponse,
  PaginatedResponse,
} from "../../types";
import Joi from "joi";
import * as logger from "firebase-functions/logger";

// ============================================================================
// Constants
// ============================================================================

const PII_FIELDS: (keyof Consumer)[] = ["firstName", "lastName", "dob", "ssnLast4"];

const CONSENT_VERSIONS = {
  terms: "1.0.0",
  privacy: "1.0.0",
  fcraDisclosure: "1.0.0",
};

// ============================================================================
// Type Definitions
// ============================================================================

interface CreateConsumerInput {
  firstName: string;
  lastName: string;
  dob: string;
  ssnLast4: string;
  addresses: Address[];
  phones?: Phone[];
  emails?: Email[];
  consent: {
    termsAccepted: boolean;
    privacyAccepted: boolean;
    fcraDisclosureAccepted: boolean;
  };
}

interface UpdateConsumerInput {
  consumerId: string;
  addresses?: Address[];
  phones?: Phone[];
  emails?: Email[];
}

interface ListConsumersInput {
  search?: string;
  kycStatus?: "pending" | "verified" | "failed";
  limit?: number;
  cursor?: string;
}

interface GetConsumerInput {
  consumerId: string;
  includePii?: boolean;
}

interface SmartCreditConnectInput {
  consumerId: string;
  redirectUri: string;
}

interface SmartCreditDisconnectInput {
  consumerId: string;
}

interface RefreshReportsInput {
  consumerId: string;
  bureaus?: ("equifax" | "experian" | "transunion")[];
}

interface TradelinesListInput {
  consumerId: string;
  bureau?: "equifax" | "experian" | "transunion";
  disputeStatus?: "none" | "in_dispute" | "resolved";
  limit?: number;
  cursor?: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Mask consumer PII for list views and unauthorized access
 */
function maskConsumerPii(consumer: Consumer): Consumer {
  return {
    ...consumer,
    firstName: maskValue(consumer.firstName, 1),
    lastName: maskValue(consumer.lastName, 2),
    dob: "****-**-**",
    ssnLast4: "****",
  };
}

/**
 * Decrypt consumer PII fields
 */
async function decryptConsumerPii(consumer: Consumer): Promise<Consumer> {
  return decryptPiiFields(consumer as unknown as Record<string, unknown>, PII_FIELDS as string[]) as unknown as Consumer;
}

/**
 * Check if consumer belongs to tenant
 */
async function verifyConsumerAccess(
  consumerId: string,
  tenantId: string
): Promise<Consumer> {
  const consumerDoc = await db.collection("consumers").doc(consumerId).get();
  assertExists(consumerDoc.exists ? consumerDoc.data() : null, "Consumer", consumerId);

  const consumer = { id: consumerDoc.id, ...consumerDoc.data() } as Consumer;

  if (consumer.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this consumer");
  }

  return consumer;
}

/**
 * Generate consumer lookup hash for duplicate detection
 */
function generateConsumerHash(
  firstName: string,
  lastName: string,
  dob: string,
  ssnLast4: string
): string {
  const combined = `${firstName.toLowerCase()}|${lastName.toLowerCase()}|${dob}|${ssnLast4}`;
  return hashPii(combined);
}

// ============================================================================
// consumersCreate - Create a new consumer
// ============================================================================

async function createConsumerHandler(
  data: CreateConsumerInput,
  context: RequestContext
): Promise<ApiResponse<Consumer>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;

  // Validate input
  const validatedData = validate(createConsumerSchema, data);

  // Check tenant consumer limits
  const consumersSnapshot = await db
    .collection("consumers")
    .where("tenantId", "==", tenantId)
    .count()
    .get();

  const currentConsumerCount = consumersSnapshot.data().count;
  const maxConsumers = tenant.features?.maxConsumers || 100;

  if (currentConsumerCount >= maxConsumers) {
    throw new AppError(
      ErrorCode.TENANT_LIMIT_EXCEEDED,
      `Consumer limit reached for your plan. Maximum ${maxConsumers} consumers allowed.`,
      400
    );
  }

  // Check for duplicate consumer using hash
  const consumerHash = generateConsumerHash(
    validatedData.firstName,
    validatedData.lastName,
    validatedData.dob,
    validatedData.ssnLast4
  );

  const duplicateSnapshot = await db
    .collection("consumers")
    .where("tenantId", "==", tenantId)
    .where("lookupHash", "==", consumerHash)
    .limit(1)
    .get();

  if (!duplicateSnapshot.empty) {
    throw new ConflictError(
      "A consumer with this information already exists in your account"
    );
  }

  // Encrypt PII fields
  const encryptedFirstName = await encryptPii(validatedData.firstName);
  const encryptedLastName = await encryptPii(validatedData.lastName);
  const encryptedDob = await encryptPii(validatedData.dob);
  const encryptedSsnLast4 = await encryptPii(validatedData.ssnLast4);

  // Ensure at least one address is marked primary
  const addresses = validatedData.addresses.map((addr: Address, index: number) => ({
    ...addr,
    isPrimary: index === 0 ? true : addr.isPrimary || false,
    verified: false,
  }));

  // Process phones with defaults
  const phones = (validatedData.phones || []).map((phone: Phone, index: number) => ({
    ...phone,
    isPrimary: index === 0 ? true : phone.isPrimary || false,
    verified: false,
  }));

  // Process emails with defaults
  const emails = (validatedData.emails || []).map((email: Email, index: number) => ({
    ...email,
    isPrimary: index === 0 ? true : email.isPrimary || false,
    verified: false,
  }));

  // Build consent record
  const consent: ConsumerConsent = {
    agreedAt: FieldValue.serverTimestamp() as unknown as Timestamp,
    ipAddress: ip || "unknown",
    userAgent: userAgent,
    termsVersion: CONSENT_VERSIONS.terms,
    privacyVersion: CONSENT_VERSIONS.privacy,
    fcraDisclosureVersion: CONSENT_VERSIONS.fcraDisclosure,
  };

  // Create consumer document
  const consumerId = uuidv4();
  const consumer: Consumer & { lookupHash: string } = {
    id: consumerId,
    tenantId,
    firstName: encryptedFirstName,
    lastName: encryptedLastName,
    dob: encryptedDob,
    ssnLast4: encryptedSsnLast4,
    addresses,
    phones,
    emails,
    kycStatus: "pending",
    consent,
    // New Disputebee-style fields
    status: "unsent" as ConsumerStatus,
    isActive: true,
    documents: [],
    createdAt: FieldValue.serverTimestamp() as unknown as Timestamp,
    updatedAt: FieldValue.serverTimestamp() as unknown as Timestamp,
    createdBy: actorId,
    lookupHash: consumerHash,
  };

  await db.collection("consumers").doc(consumerId).set(consumer);

  // Audit log (with masked PII)
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "consumer",
    entityId: consumerId,
    action: "create",
    newState: {
      ...consumer,
      firstName: "[ENCRYPTED]",
      lastName: "[ENCRYPTED]",
      dob: "[ENCRYPTED]",
      ssnLast4: "[ENCRYPTED]",
    } as unknown as Record<string, unknown>,
    metadata: { source: "consumer_management" },
  });

  // Return decrypted consumer for response
  const responseConsumer = {
    ...consumer,
    firstName: validatedData.firstName,
    lastName: validatedData.lastName,
    dob: validatedData.dob,
    ssnLast4: validatedData.ssnLast4,
  };

  return {
    success: true,
    data: responseConsumer,
  };
}

export const consumersCreate = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:write"], createConsumerHandler)
  )
);

// ============================================================================
// consumersGet - Get consumer details
// ============================================================================

async function getConsumerHandler(
  data: GetConsumerInput,
  context: RequestContext
): Promise<ApiResponse<Consumer>> {
  const { tenantId, role } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      consumerId: schemas.documentId.required(),
      includePii: Joi.boolean().default(false),
    }),
    data
  );

  // Get and verify consumer access
  const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);

  // Decrypt PII if requested and user has permission
  // Only owner and operator roles can see full PII
  const canSeePii = ["owner", "operator"].includes(role) && validatedData.includePii;

  if (canSeePii) {
    const decryptedConsumer = await decryptConsumerPii(consumer);
    return {
      success: true,
      data: decryptedConsumer,
    };
  }

  // Return masked consumer
  return {
    success: true,
    data: maskConsumerPii(consumer),
  };
}

export const consumersGet = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:read"], getConsumerHandler)
  )
);

// ============================================================================
// consumersUpdate - Update consumer details
// ============================================================================

async function updateConsumerHandler(
  data: UpdateConsumerInput,
  context: RequestContext
): Promise<ApiResponse<Consumer>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedConsumerId = validate(
    Joi.object({ consumerId: schemas.documentId.required() }),
    { consumerId: data.consumerId }
  );
  const validatedData = validate(updateConsumerSchema, data);

  // Get current consumer
  const consumerRef = db.collection("consumers").doc(validatedConsumerId.consumerId);
  const currentConsumer = await verifyConsumerAccess(validatedConsumerId.consumerId, tenantId);

  // Build update object
  const updates: Record<string, unknown> = {
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (validatedData.addresses) {
    // Ensure at least one primary address
    const addresses = validatedData.addresses.map((addr: Address, index: number) => ({
      ...addr,
      isPrimary: index === 0 ? true : addr.isPrimary || false,
    }));
    updates.addresses = addresses;
  }

  if (validatedData.phones) {
    const phones = validatedData.phones.map((phone: Phone, index: number) => ({
      ...phone,
      isPrimary: index === 0 ? true : phone.isPrimary || false,
      verified: false,
    }));
    updates.phones = phones;
  }

  if (validatedData.emails) {
    const emails = validatedData.emails.map((email: Email, index: number) => ({
      ...email,
      isPrimary: index === 0 ? true : email.isPrimary || false,
      verified: false,
    }));
    updates.emails = emails;
  }

  // Update consumer
  await consumerRef.update(updates);

  // Get updated consumer
  const updatedDoc = await consumerRef.get();
  const updatedConsumer = { id: updatedDoc.id, ...updatedDoc.data() } as Consumer;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "consumer",
    entityId: validatedConsumerId.consumerId,
    action: "update",
    previousState: {
      addresses: currentConsumer.addresses,
      phones: currentConsumer.phones,
      emails: currentConsumer.emails,
    },
    newState: {
      addresses: updates.addresses || currentConsumer.addresses,
      phones: updates.phones || currentConsumer.phones,
      emails: updates.emails || currentConsumer.emails,
    },
  });

  // Return masked consumer (PII wasn't changed)
  return {
    success: true,
    data: maskConsumerPii(updatedConsumer),
  };
}

export const consumersUpdate = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:write"], updateConsumerHandler)
  )
);

// ============================================================================
// consumersList - List consumers in tenant
// ============================================================================

async function listConsumersHandler(
  data: ListConsumersInput,
  context: RequestContext
): Promise<PaginatedResponse<Consumer>> {
  logger.info("[consumersList] Handler started", { data });
  const { tenantId } = context;
  logger.info("[consumersList] TenantId extracted", { tenantId });

  // Validate input
  logger.info("[consumersList] Validating pagination");
  const pagination = validate(paginationSchema, data);
  logger.info("[consumersList] Pagination validated", { pagination });
  logger.info("[consumersList] Validating filters");
  const filters = validate(
    Joi.object({
      search: Joi.string().max(100),
      kycStatus: Joi.string().valid("pending", "verified", "failed"),
    }),
    data
  );
  logger.info("[consumersList] Filters validated", { filters });

  // Build query
  logger.info("[consumersList] Building Firestore query");
  let query = db
    .collection("consumers")
    .where("tenantId", "==", tenantId)
    .orderBy("createdAt", "desc");
  logger.info("[consumersList] Base query built");

  // Filter by KYC status if specified
  if (filters.kycStatus) {
    query = query.where("kycStatus", "==", filters.kycStatus);
  }

  // Apply cursor if provided
  if (pagination.cursor) {
    const cursorDoc = await db.collection("consumers").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  logger.info("[consumersList] Executing query with limit", { limit: pagination.limit + 1 });
  const snapshot = await query.limit(pagination.limit + 1).get();
  logger.info("[consumersList] Query executed", { docCount: snapshot.docs.length });

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
  logger.info("[consumersList] Docs processed", { hasMore, processedCount: docs.length });

  // Map and mask consumers
  logger.info("[consumersList] Mapping and masking consumers");
  const consumers = docs.map((doc) => {
    const consumer = { id: doc.id, ...doc.data() } as Consumer;
    return maskConsumerPii(consumer);
  });
  logger.info("[consumersList] Consumers mapped", { count: consumers.length });

  // Get total count (with optional KYC filter)
  logger.info("[consumersList] Getting total count");
  let countQuery = db.collection("consumers").where("tenantId", "==", tenantId);
  if (filters.kycStatus) {
    countQuery = countQuery.where("kycStatus", "==", filters.kycStatus);
  }
  const countSnapshot = await countQuery.count().get();
  const totalCount = countSnapshot.data().count;
  logger.info("[consumersList] Total count retrieved", { totalCount });

  logger.info("[consumersList] Returning response");
  return {
    success: true,
    data: {
      items: consumers,
      pagination: {
        total: totalCount,
        limit: pagination.limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const consumersList = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:read"], listConsumersHandler)
  )
);

// ============================================================================
// consumersSmartCreditConnect - Initiate SmartCredit OAuth connection
// ============================================================================

async function smartCreditConnectHandler(
  data: SmartCreditConnectInput,
  context: RequestContext
): Promise<ApiResponse<{ authorizationUrl: string; state: string }>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      consumerId: schemas.documentId.required(),
      redirectUri: Joi.string().uri().required(),
    }),
    data
  );

  // Verify consumer access
  const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);

  // Check if already connected
  if (consumer.smartCreditConnectionId) {
    // Check connection status
    const connectionDoc = await db
      .collection("smartcredit_connections")
      .doc(consumer.smartCreditConnectionId)
      .get();

    if (connectionDoc.exists) {
      const connection = connectionDoc.data() as SmartCreditConnection;
      if (connection.status === "connected") {
        throw new ConflictError(
          "Consumer already has an active SmartCredit connection"
        );
      }
    }
  }

  // Check if tenant has SmartCredit configured
  if (!tenant.smartCreditConfig) {
    throw new AppError(
      ErrorCode.INTEGRATION_NOT_CONFIGURED,
      "SmartCredit integration is not configured for this tenant",
      400
    );
  }

  // Generate state for OAuth flow
  const state = uuidv4();

  // Store pending connection
  const pendingConnectionId = uuidv4();
  await db.collection("smartcredit_pending_connections").doc(pendingConnectionId).set({
    id: pendingConnectionId,
    consumerId: validatedData.consumerId,
    tenantId,
    state,
    redirectUri: validatedData.redirectUri,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000)), // 10 minutes
    status: "pending",
  });

  // Build SmartCredit authorization URL using the service
  const callbackUri = `${tenant.smartCreditConfig.webhookEndpoint}/callback`;
  const authorizationUrl = smartCreditService.getAuthorizationUrl(
    callbackUri,
    state,
    ["credit_report", "credit_score", "alerts"]
  );

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "consumer",
    entityId: validatedData.consumerId,
    action: "update",
    metadata: {
      source: "smartcredit_connect",
      action: "oauth_initiated",
      pendingConnectionId,
    },
  });

  return {
    success: true,
    data: {
      authorizationUrl,
      state,
    },
  };
}

export const consumersSmartCreditConnect = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:write"], smartCreditConnectHandler)
  )
);

// ============================================================================
// consumersSmartCreditDisconnect - Revoke SmartCredit connection
// ============================================================================

async function smartCreditDisconnectHandler(
  data: SmartCreditDisconnectInput,
  context: RequestContext
): Promise<ApiResponse<{ disconnected: boolean }>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      consumerId: schemas.documentId.required(),
    }),
    data
  );

  // Verify consumer access
  const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);

  if (!consumer.smartCreditConnectionId) {
    throw new NotFoundError("Consumer does not have a SmartCredit connection");
  }

  // Get connection
  const connectionRef = db
    .collection("smartcredit_connections")
    .doc(consumer.smartCreditConnectionId);
  const connectionDoc = await connectionRef.get();

  if (!connectionDoc.exists) {
    throw new NotFoundError("SmartCredit connection not found");
  }

  const connection = connectionDoc.data() as SmartCreditConnection;

  // Revoke the connection
  await connectionRef.update({
    status: "revoked",
    revokedAt: FieldValue.serverTimestamp(),
    accessToken: "", // Clear tokens
    refreshToken: "",
  });

  // Remove connection reference from consumer
  await db.collection("consumers").doc(validatedData.consumerId).update({
    smartCreditConnectionId: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "consumer",
    entityId: validatedData.consumerId,
    action: "update",
    metadata: {
      source: "smartcredit_disconnect",
      connectionId: consumer.smartCreditConnectionId,
      previousStatus: connection.status,
    },
  });

  return {
    success: true,
    data: { disconnected: true },
  };
}

export const consumersSmartCreditDisconnect = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:write"], smartCreditDisconnectHandler)
  )
);

// ============================================================================
// consumersReportsRefresh - Refresh credit reports from SmartCredit
// ============================================================================

interface RefreshResult {
  bureau: string;
  success: boolean;
  error?: string;
}

async function reportsRefreshHandler(
  data: RefreshReportsInput,
  context: RequestContext
): Promise<ApiResponse<{ requested: boolean; bureaus: string[]; results: RefreshResult[] }>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      consumerId: schemas.documentId.required(),
      bureaus: Joi.array().items(schemas.bureau).default(["equifax", "experian", "transunion"]),
    }),
    data
  );

  // Verify consumer access
  const consumer = await verifyConsumerAccess(validatedData.consumerId, tenantId);

  // Check SmartCredit connection
  if (!consumer.smartCreditConnectionId) {
    throw new AppError(
      ErrorCode.INTEGRATION_NOT_CONFIGURED,
      "Consumer does not have an active SmartCredit connection. Connect to SmartCredit first.",
      400
    );
  }

  // Verify connection is active
  const connectionDoc = await db
    .collection("smartcredit_connections")
    .doc(consumer.smartCreditConnectionId)
    .get();

  if (!connectionDoc.exists) {
    throw new NotFoundError("SmartCredit connection not found");
  }

  const connection = connectionDoc.data() as SmartCreditConnection;

  if (connection.status !== "connected") {
    throw new AppError(
      ErrorCode.INTEGRATION_ERROR,
      `SmartCredit connection is ${connection.status}. Please reconnect.`,
      400
    );
  }

  // Check if token is expired
  if (connection.tokenExpiresAt.toDate() < new Date()) {
    throw new AppError(
      ErrorCode.INTEGRATION_ERROR,
      "SmartCredit session has expired. Please reconnect.",
      400
    );
  }

  // Get active SmartCredit connection with valid access token
  const activeConnection = await smartCreditService.getActiveConnection(
    consumer.smartCreditConnectionId
  );

  if (!activeConnection) {
    throw new AppError(
      ErrorCode.SMARTCREDIT_TOKEN_EXPIRED,
      "SmartCredit session has expired. Please reconnect.",
      400
    );
  }

  const { accessToken } = activeConnection;
  const bureaus = (validatedData.bureaus || ["equifax", "experian", "transunion"]) as Bureau[];
  const results: { bureau: string; success: boolean; error?: string }[] = [];

  // Fetch reports from SmartCredit for each bureau
  for (const bureau of bureaus) {
    try {
      logger.info("[Consumer] Fetching credit report", {
        consumerId: validatedData.consumerId,
        bureau,
      });

      // Call SmartCredit API
      const scReport = await smartCreditService.getCreditReport(accessToken, bureau);

      // Store raw report in Cloud Storage (encrypted)
      const reportId = uuidv4();
      const rawJsonPath = `tenants/${tenantId}/consumers/${validatedData.consumerId}/reports/${reportId}.json`;
      const bucket = storage.bucket(firebaseConfig.storageBucket);
      const file = bucket.file(rawJsonPath);
      await file.save(JSON.stringify(scReport), {
        contentType: "application/json",
        metadata: { cacheControl: "private, max-age=0" },
      });

      // Create credit report entry
      const report: Omit<CreditReport, "id"> = {
        consumerId: validatedData.consumerId,
        tenantId,
        bureau,
        pulledAt: FieldValue.serverTimestamp() as unknown as Timestamp,
        rawJsonRef: rawJsonPath,
        hash: "", // Would calculate in production
        score: scReport.score,
        scoreFactors: scReport.scoreFactors || [],
        smartCreditReportId: scReport.id,
        summary: {
          totalAccounts: scReport.summary.totalAccounts,
          openAccounts: scReport.summary.openAccounts,
          closedAccounts: scReport.summary.closedAccounts,
          delinquentAccounts: scReport.summary.delinquentCount,
          derogatoryAccounts: scReport.summary.derogatoryCount,
          totalBalance: scReport.summary.totalBalance,
          totalCreditLimit: scReport.summary.totalCreditLimit,
          utilizationPercent: scReport.summary.utilizationPercent,
        },
        publicRecords: scReport.publicRecords || [],
        inquiries: (scReport.inquiries || []).map((inq) => ({
          creditor: inq.creditorName,
          date: inq.date,
          type: inq.type === "H" ? "hard" : "soft",
        })),
        status: "processed",
        createdAt: FieldValue.serverTimestamp() as unknown as Timestamp,
        expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)),
      };

      await db.collection("credit_reports").doc(reportId).set({ id: reportId, ...report });

      // Store tradelines
      for (const scTradeline of scReport.tradelines) {
        const tradeline = smartCreditService.convertTradeline(
          scTradeline,
          reportId,
          validatedData.consumerId,
          tenantId,
          bureau
        );
        await db.collection("tradelines").doc(tradeline.id).set({
          ...tradeline,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      results.push({ bureau, success: true });
      logger.info("[Consumer] Credit report stored", {
        consumerId: validatedData.consumerId,
        bureau,
        reportId,
        tradelineCount: scReport.tradelines.length,
      });
    } catch (error) {
      logger.error("[Consumer] Failed to fetch credit report", {
        consumerId: validatedData.consumerId,
        bureau,
        error: error instanceof Error ? error.message : "Unknown error",
      });
      results.push({
        bureau,
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }

  // Update connection last refresh timestamp
  await db
    .collection("smartcredit_connections")
    .doc(consumer.smartCreditConnectionId)
    .update({
      lastRefreshedAt: FieldValue.serverTimestamp(),
    });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "consumer",
    entityId: validatedData.consumerId,
    action: "update",
    metadata: {
      source: "reports_refresh",
      bureaus,
    },
  });

  const successfulBureaus = results.filter((r) => r.success).map((r) => r.bureau);
  const failedBureaus = results.filter((r) => !r.success);

  return {
    success: failedBureaus.length === 0,
    data: {
      requested: true,
      bureaus: successfulBureaus,
      results,
    },
  };
}

export const consumersReportsRefresh = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:write"], reportsRefreshHandler)
  )
);

// ============================================================================
// consumersTradelinesList - List tradelines for a consumer
// ============================================================================

async function tradelinesListHandler(
  data: TradelinesListInput,
  context: RequestContext
): Promise<PaginatedResponse<Tradeline>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({
      consumerId: schemas.documentId.required(),
      bureau: schemas.bureau,
      disputeStatus: Joi.string().valid("none", "in_dispute", "resolved"),
      limit: Joi.number().integer().min(1).max(100).default(50),
      cursor: Joi.string().max(1000),
    }),
    data
  );

  // Verify consumer access
  await verifyConsumerAccess(validatedData.consumerId, tenantId);

  // Build query
  let query = db
    .collection("tradelines")
    .where("tenantId", "==", tenantId)
    .where("consumerId", "==", validatedData.consumerId)
    .orderBy("lastReportedDate", "desc");

  // Filter by bureau if specified
  if (validatedData.bureau) {
    query = query.where("bureau", "==", validatedData.bureau);
  }

  // Filter by dispute status if specified
  if (validatedData.disputeStatus) {
    query = query.where("disputeStatus", "==", validatedData.disputeStatus);
  }

  // Apply cursor if provided
  if (validatedData.cursor) {
    const cursorDoc = await db.collection("tradelines").doc(validatedData.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  const limit = validatedData.limit || 50;
  const snapshot = await query.limit(limit + 1).get();

  const hasMore = snapshot.docs.length > limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const tradelines = docs.map((doc) => ({ id: doc.id, ...doc.data() } as Tradeline));

  // Get total count with filters
  let countQuery = db
    .collection("tradelines")
    .where("tenantId", "==", tenantId)
    .where("consumerId", "==", validatedData.consumerId);

  if (validatedData.bureau) {
    countQuery = countQuery.where("bureau", "==", validatedData.bureau);
  }
  if (validatedData.disputeStatus) {
    countQuery = countQuery.where("disputeStatus", "==", validatedData.disputeStatus);
  }

  const countSnapshot = await countQuery.count().get();

  return {
    success: true,
    data: {
      items: tradelines,
      pagination: {
        total: countSnapshot.data().count,
        limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const consumersTradelinesList = functions.https.onCall(
  withErrorHandling(
    withAuth(["consumers:read"], tradelinesListHandler)
  )
);
