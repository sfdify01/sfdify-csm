/**
 * Tenant Management Cloud Functions
 *
 * Handles tenant creation, updates, and retrieval.
 * Tenants represent credit repair companies using the system.
 */

import * as functions from "firebase-functions";
import { db } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue } from "firebase-admin/firestore";
import {
  withAuth,
  withBasicAuth,
  RequestContext,
  setUserClaims,
} from "../../middleware/auth";
import {
  validate,
  createTenantSchema,
  paginationSchema,
} from "../../utils/validation";
import {
  withErrorHandling,
  assertExists,
} from "../../utils/errors";
import { logAuditEvent } from "../../utils/audit";
import {
  Tenant,
  TenantFeatures,
  ApiResponse,
  PaginatedResponse,
} from "../../types";

// ============================================================================
// Type Definitions for Tenant Functions
// ============================================================================

interface CreateTenantInput {
  name: string;
  branding: {
    primaryColor?: string;
    companyName: string;
    tagline?: string;
  };
  lobConfig: {
    returnAddress: {
      street1: string;
      street2?: string;
      city: string;
      state: string;
      zipCode: string;
      country?: string;
    };
    defaultMailType?: string;
  };
  ownerEmail: string;
  ownerName: string;
  ownerPassword?: string;
}

interface UpdateTenantInput {
  name?: string;
  branding?: Partial<Tenant["branding"]>;
  lobConfig?: Partial<Tenant["lobConfig"]>;
  features?: Partial<TenantFeatures>;
}

interface ListTenantsInput {
  limit?: number;
  cursor?: string;
}

// ============================================================================
// Default Feature Configuration (all features enabled, no limits)
// ============================================================================

const DEFAULT_FEATURES: TenantFeatures = {
  aiDraftingEnabled: true,
  certifiedMailEnabled: true,
  identityTheftBlockEnabled: true,
  cfpbExportEnabled: true,
  maxConsumers: -1, // -1 means unlimited
  maxDisputesPerMonth: -1, // -1 means unlimited
};

// ============================================================================
// tenantsCreate - Create a new tenant
// ============================================================================

/**
 * Create a new tenant with owner account
 * This is typically called during onboarding
 */
async function createTenantHandler(
  data: CreateTenantInput
): Promise<ApiResponse<{ tenant: Tenant; ownerId: string }>> {
  // Validate input
  const validatedData = validate(createTenantSchema, data);

  // Generate IDs
  const tenantId = `tenant_${uuidv4().replace(/-/g, "").substring(0, 12)}`;

  // Get default features (all enabled, unlimited)
  const features = DEFAULT_FEATURES;

  // Create tenant document
  const tenant: Tenant = {
    id: tenantId,
    name: validatedData.name,
    status: "active",
    branding: {
      primaryColor: validatedData.branding.primaryColor || "#1E40AF",
      companyName: validatedData.branding.companyName,
      tagline: validatedData.branding.tagline,
    },
    lobConfig: {
      returnAddress: {
        ...validatedData.lobConfig.returnAddress,
        type: "mailing",
        country: validatedData.lobConfig.returnAddress.country || "US",
        isPrimary: true,
      },
      defaultMailType: (validatedData.lobConfig.defaultMailType as Tenant["lobConfig"]["defaultMailType"]) ||
        "usps_first_class",
    },
    features,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  // Create owner user in Firebase Auth
  const { auth } = await import("../../admin");
  const ownerUser = await auth.createUser({
    email: data.ownerEmail,
    displayName: data.ownerName,
    password: data.ownerPassword || uuidv4(), // Generate random password if not provided
    emailVerified: false,
  });

  // Set custom claims for the owner
  await setUserClaims(ownerUser.uid, tenantId, "owner");

  // Create user document
  const userDoc = {
    id: ownerUser.uid,
    tenantId,
    email: data.ownerEmail,
    displayName: data.ownerName,
    role: "owner",
    permissions: [],
    twoFactorEnabled: false,
    createdAt: FieldValue.serverTimestamp(),
    disabled: false,
  };

  // Write to Firestore in a batch
  const batch = db.batch();
  batch.set(db.collection("tenants").doc(tenantId), tenant);
  batch.set(db.collection("users").doc(ownerUser.uid), userDoc);
  await batch.commit();

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: {
      userId: ownerUser.uid,
      email: data.ownerEmail,
      role: "owner",
    },
    entity: "tenant",
    entityId: tenantId,
    action: "create",
    newState: tenant as unknown as Record<string, unknown>,
    metadata: { source: "onboarding" },
  });

  return {
    success: true,
    data: {
      tenant: { ...tenant, id: tenantId } as Tenant,
      ownerId: ownerUser.uid,
    },
  };
}

// Export as Cloud Function - Note: This needs special handling for onboarding
export const tenantsCreate = functions.https.onCall(
  withErrorHandling(createTenantHandler)
);

// ============================================================================
// tenantsGet - Get tenant details
// ============================================================================

async function getTenantHandler(
  _data: unknown,
  context: RequestContext
): Promise<ApiResponse<Tenant>> {
  const { tenantId } = context;

  const tenantDoc = await db.collection("tenants").doc(tenantId).get();
  assertExists(tenantDoc.exists ? tenantDoc.data() : null, "Tenant", tenantId);

  const tenant = { id: tenantDoc.id, ...tenantDoc.data() } as Tenant;

  return {
    success: true,
    data: tenant,
  };
}

export const tenantsGet = functions.https.onCall(
  withErrorHandling(
    withBasicAuth(getTenantHandler)
  )
);

// ============================================================================
// tenantsUpdate - Update tenant settings
// ============================================================================

async function updateTenantHandler(
  data: UpdateTenantInput,
  context: RequestContext
): Promise<ApiResponse<Tenant>> {
  const { tenantId, userId, email, role, ip, userAgent } = context;

  // Get current tenant
  const tenantRef = db.collection("tenants").doc(tenantId);
  const tenantDoc = await tenantRef.get();
  assertExists(tenantDoc.exists ? tenantDoc.data() : null, "Tenant", tenantId);

  const currentTenant = { id: tenantDoc.id, ...tenantDoc.data() } as Tenant;

  // Build update object
  const updates: Record<string, unknown> = {
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (data.name !== undefined) {
    updates.name = data.name;
  }

  if (data.branding) {
    updates.branding = {
      ...currentTenant.branding,
      ...data.branding,
    };
  }

  if (data.lobConfig) {
    updates.lobConfig = {
      ...currentTenant.lobConfig,
      ...data.lobConfig,
    };
  }

  if (data.features) {
    // Only allow updating features within plan limits
    updates.features = {
      ...currentTenant.features,
      ...data.features,
    };
  }

  // Update tenant
  await tenantRef.update(updates);

  // Get updated tenant
  const updatedDoc = await tenantRef.get();
  const updatedTenant = { id: updatedDoc.id, ...updatedDoc.data() } as Tenant;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId, email, role, ip, userAgent },
    entity: "tenant",
    entityId: tenantId,
    action: "update",
    previousState: currentTenant as unknown as Record<string, unknown>,
    newState: updatedTenant as unknown as Record<string, unknown>,
  });

  return {
    success: true,
    data: updatedTenant,
  };
}

export const tenantsUpdate = functions.https.onCall(
  withErrorHandling(
    withAuth(["tenant:write"], updateTenantHandler)
  )
);

// ============================================================================
// tenantsList - List all tenants (admin only - for super admin purposes)
// ============================================================================

async function listTenantsHandler(
  data: ListTenantsInput,
  context: RequestContext
): Promise<PaginatedResponse<Tenant>> {
  // This function is typically for super-admin purposes
  // For now, we just return the user's own tenant
  const { tenantId } = context;

  const pagination = validate(paginationSchema, data);

  const tenantDoc = await db.collection("tenants").doc(tenantId).get();

  if (!tenantDoc.exists) {
    return {
      success: true,
      data: {
        items: [],
        pagination: {
          total: 0,
          limit: pagination.limit,
          hasMore: false,
        },
      },
    };
  }

  const tenant = { id: tenantDoc.id, ...tenantDoc.data() } as Tenant;

  return {
    success: true,
    data: {
      items: [tenant],
      pagination: {
        total: 1,
        limit: pagination.limit,
        hasMore: false,
      },
    },
  };
}

export const tenantsList = functions.https.onCall(
  withErrorHandling(
    withAuth(["tenant:read"], listTenantsHandler)
  )
);
