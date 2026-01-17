/**
 * Public Authentication Cloud Functions
 *
 * These functions are PUBLIC (no auth required) and handle:
 * - Self-service signup with email/password
 *
 * Unlike other functions, these don't use withAuth middleware
 * since they're called by unauthenticated users.
 */

import * as functions from "firebase-functions";
import { auth, db } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue } from "firebase-admin/firestore";
import { setUserClaims, ROLE_PERMISSIONS } from "../../middleware/auth";
import { withErrorHandling, AppError, ErrorCode } from "../../utils/errors";
import { logAuditEvent } from "../../utils/audit";
import { Tenant, TenantFeatures, ApiResponse } from "../../types";

// ============================================================================
// Type Definitions
// ============================================================================

interface SignUpInput {
  email: string;
  password: string;
  displayName: string;
  companyName: string;
  plan?: "starter" | "professional" | "enterprise";
}

interface SignUpResponse {
  userId: string;
  tenantId: string;
  email: string;
  displayName: string;
  role: string;
}

// ============================================================================
// Default Feature Configurations by Plan
// ============================================================================

const PLAN_FEATURES: Record<Tenant["plan"], TenantFeatures> = {
  starter: {
    aiDraftingEnabled: false,
    certifiedMailEnabled: false,
    identityTheftBlockEnabled: false,
    cfpbExportEnabled: false,
    maxConsumers: 100,
    maxDisputesPerMonth: 500,
  },
  professional: {
    aiDraftingEnabled: true,
    certifiedMailEnabled: true,
    identityTheftBlockEnabled: true,
    cfpbExportEnabled: false,
    maxConsumers: 1000,
    maxDisputesPerMonth: 5000,
  },
  enterprise: {
    aiDraftingEnabled: true,
    certifiedMailEnabled: true,
    identityTheftBlockEnabled: true,
    cfpbExportEnabled: true,
    maxConsumers: 10000,
    maxDisputesPerMonth: 50000,
  },
};

// ============================================================================
// Validation Helpers
// ============================================================================

function validateEmail(email: string): void {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || !emailRegex.test(email)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, "Invalid email address", 400);
  }
}

function validatePassword(password: string): void {
  if (!password || password.length < 8) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Password must be at least 8 characters",
      400
    );
  }
  // Check for at least one uppercase, one lowercase, one number
  if (!/[A-Z]/.test(password)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Password must contain at least one uppercase letter",
      400
    );
  }
  if (!/[a-z]/.test(password)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Password must contain at least one lowercase letter",
      400
    );
  }
  if (!/[0-9]/.test(password)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Password must contain at least one number",
      400
    );
  }
}

function validateDisplayName(name: string): void {
  if (!name || name.trim().length < 2) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Display name must be at least 2 characters",
      400
    );
  }
}

function validateCompanyName(name: string): void {
  if (!name || name.trim().length < 2) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Company name must be at least 2 characters",
      400
    );
  }
}

// ============================================================================
// Helper: Create Tenant and User
// ============================================================================

async function createTenantAndUser(
  userId: string,
  email: string,
  displayName: string,
  companyName: string,
  plan: Tenant["plan"]
): Promise<{ tenantId: string }> {
  // Generate tenant ID
  const tenantId = `tenant_${uuidv4().replace(/-/g, "").substring(0, 12)}`;

  // Get default features for the plan
  const features = PLAN_FEATURES[plan];

  // Create tenant document
  const tenant: Omit<Tenant, "createdAt" | "updatedAt"> & {
    createdAt: FieldValue;
    updatedAt: FieldValue;
  } = {
    id: tenantId,
    name: companyName,
    plan,
    status: "active",
    branding: {
      primaryColor: "#1E40AF",
      companyName: companyName,
    },
    lobConfig: {
      returnAddress: {
        type: "mailing",
        street1: "",
        city: "",
        state: "",
        zipCode: "",
        country: "US",
        isPrimary: true,
      },
      defaultMailType: "usps_first_class",
    },
    features,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  // Create user document
  const userDoc = {
    id: userId,
    tenantId,
    email,
    displayName,
    role: "owner",
    permissions: ROLE_PERMISSIONS.owner,
    twoFactorEnabled: false,
    disabled: false,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  // Set custom claims BEFORE writing to Firestore
  // This ensures the token is ready when user signs in
  // Wrap with timeout protection to prevent hanging
  try {
    const claimsPromise = setUserClaims(userId, tenantId, "owner");
    await Promise.race([
      claimsPromise,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Claims update timed out after 10 seconds")), 10000)
      ),
    ]);
  } catch (error) {
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      "Failed to configure user permissions. This may be a temporary issue - please try again or contact support.",
      500
    );
  }

  // Write to Firestore in a batch
  const batch = db.batch();
  batch.set(db.collection("tenants").doc(tenantId), tenant);
  batch.set(db.collection("users").doc(userId), userDoc);
  await batch.commit();

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: {
      userId,
      email,
      role: "owner",
    },
    entity: "tenant",
    entityId: tenantId,
    action: "create",
    newState: { ...tenant, id: tenantId } as unknown as Record<string, unknown>,
    metadata: { source: "self_service_signup" },
  });

  return { tenantId };
}

// ============================================================================
// authSignUp - Email/Password Registration
// ============================================================================

/**
 * Self-service signup with email and password.
 * Creates a new Firebase Auth user, tenant, and user document.
 *
 * This is a PUBLIC function - no authentication required.
 */
async function signUpHandler(
  data: SignUpInput
): Promise<ApiResponse<SignUpResponse>> {
  // Validate input
  validateEmail(data.email);
  validatePassword(data.password);
  validateDisplayName(data.displayName);
  validateCompanyName(data.companyName);

  const plan = data.plan || "starter";
  if (!["starter", "professional", "enterprise"].includes(plan)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, "Invalid plan selected", 400);
  }

  // Check if email already exists
  try {
    const existingUser = await auth.getUserByEmail(data.email);
    if (existingUser) {
      throw new AppError(
        ErrorCode.VALIDATION_ERROR,
        "An account with this email already exists",
        400
      );
    }
  } catch (error: unknown) {
    // User not found is expected - continue with creation
    if (
      error instanceof Error &&
      "code" in error &&
      (error as { code: string }).code !== "auth/user-not-found"
    ) {
      throw error;
    }
  }

  // Create Firebase Auth user
  const userRecord = await auth.createUser({
    email: data.email,
    password: data.password,
    displayName: data.displayName,
    emailVerified: false,
  });

  try {
    // Create tenant and user document
    const { tenantId } = await createTenantAndUser(
      userRecord.uid,
      data.email,
      data.displayName,
      data.companyName,
      plan as Tenant["plan"]
    );

    return {
      success: true,
      data: {
        userId: userRecord.uid,
        tenantId,
        email: data.email,
        displayName: data.displayName,
        role: "owner",
      },
    };
  } catch (error) {
    // If tenant/user creation fails, clean up the Auth user
    try {
      await auth.deleteUser(userRecord.uid);
    } catch {
      // Ignore cleanup errors
    }
    throw error;
  }
}

export const authSignUp = functions
  .runWith({
    timeoutSeconds: 120,
    memory: "512MB",
  })
  .https.onCall(withErrorHandling(signUpHandler));
