/**
 * Public Authentication Cloud Functions
 *
 * These functions are PUBLIC (no auth required) and handle:
 * - Self-service signup with email/password
 * - Google Sign-In completion (tenant setup for new Google users)
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

interface GoogleSignUpInput {
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
  await setUserClaims(userId, tenantId, "owner");

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

export const authSignUp = functions.https.onCall(
  withErrorHandling(signUpHandler)
);

// ============================================================================
// authCompleteGoogleSignUp - Complete Google Sign-In with Tenant Setup
// ============================================================================

/**
 * Complete registration for a Google Sign-In user.
 * The user already exists in Firebase Auth (from Google sign-in on client),
 * but doesn't have a tenant yet.
 *
 * This function REQUIRES authentication (user signed in via Google)
 * but doesn't require a tenant (since that's what we're creating).
 */
async function completeGoogleSignUpHandler(
  data: GoogleSignUpInput,
  context: functions.https.CallableContext
): Promise<ApiResponse<SignUpResponse>> {
  // This function requires the user to be signed in via Google
  if (!context.auth) {
    throw new AppError(
      ErrorCode.UNAUTHENTICATED,
      "Authentication required. Please sign in with Google first.",
      401
    );
  }

  const { uid, token } = context.auth;
  const email = token.email;
  const displayName = token.name || email?.split("@")[0] || "User";

  if (!email) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Email not available from Google account",
      400
    );
  }

  // Check if user already has a tenant
  const existingClaims = token as unknown as { tenantId?: string };
  if (existingClaims.tenantId) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "You already have an account. Please sign in instead.",
      400
    );
  }

  // Check if user document already exists
  const existingUserDoc = await db.collection("users").doc(uid).get();
  if (existingUserDoc.exists) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Account setup already completed. Please sign in.",
      400
    );
  }

  // Validate input
  validateCompanyName(data.companyName);

  const plan = data.plan || "starter";
  if (!["starter", "professional", "enterprise"].includes(plan)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, "Invalid plan selected", 400);
  }

  // Create tenant and user document
  const { tenantId } = await createTenantAndUser(
    uid,
    email,
    displayName,
    data.companyName,
    plan as Tenant["plan"]
  );

  return {
    success: true,
    data: {
      userId: uid,
      tenantId,
      email,
      displayName,
      role: "owner",
    },
  };
}

export const authCompleteGoogleSignUp = functions.https.onCall(
  withErrorHandling(completeGoogleSignUpHandler)
);

// ============================================================================
// authCheckStatus - Check if current user has completed setup
// ============================================================================

/**
 * Check if the current authenticated user has completed account setup.
 * Used by frontend to determine whether to show company setup page.
 *
 * Returns:
 * - needsSetup: true if user exists in Auth but has no tenant
 * - isComplete: true if user has both Auth and tenant configured
 */
async function checkStatusHandler(
  _data: unknown,
  context: functions.https.CallableContext
): Promise<
  ApiResponse<{
    needsSetup: boolean;
    isComplete: boolean;
    email?: string;
    displayName?: string;
  }>
> {
  if (!context.auth) {
    return {
      success: true,
      data: {
        needsSetup: false,
        isComplete: false,
      },
    };
  }

  const { uid, token } = context.auth;
  const claims = token as unknown as { tenantId?: string };

  // Check if user has tenant in claims
  if (claims.tenantId) {
    return {
      success: true,
      data: {
        needsSetup: false,
        isComplete: true,
        email: token.email || undefined,
        displayName: token.name || undefined,
      },
    };
  }

  // Check if user document exists
  const userDoc = await db.collection("users").doc(uid).get();
  if (userDoc.exists) {
    // User doc exists but claims might be stale - refresh claims
    const userData = userDoc.data();
    if (userData?.tenantId) {
      // Refresh claims
      await setUserClaims(uid, userData.tenantId, userData.role || "owner");
      return {
        success: true,
        data: {
          needsSetup: false,
          isComplete: true,
          email: token.email || undefined,
          displayName: token.name || undefined,
        },
      };
    }
  }

  // User needs to complete setup
  return {
    success: true,
    data: {
      needsSetup: true,
      isComplete: false,
      email: token.email || undefined,
      displayName: token.name || undefined,
    },
  };
}

export const authCheckStatus = functions.https.onCall(
  withErrorHandling(checkStatusHandler)
);
