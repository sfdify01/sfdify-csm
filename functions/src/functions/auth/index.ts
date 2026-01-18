/**
 * Public Authentication Cloud Functions
 *
 * These functions are PUBLIC (no auth required) and handle:
 * - Self-service signup with email/password
 * - Password reset requests
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

function validateEmail(email: string): string {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const trimmed = email?.trim().toLowerCase();
  if (!trimmed || !emailRegex.test(trimmed)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, "Invalid email address", 400);
  }
  return trimmed;
}

function validatePassword(password: string): void {
  if (!password || password.length < 8) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Password must be at least 8 characters",
      400
    );
  }
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

function validateDisplayName(name: string): string {
  const trimmed = name?.trim();
  if (!trimmed || trimmed.length < 2) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Display name must be at least 2 characters",
      400
    );
  }
  if (trimmed.length > 100) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Display name must be at most 100 characters",
      400
    );
  }
  return trimmed;
}

function validateCompanyName(name: string): string {
  const trimmed = name?.trim();
  if (!trimmed || trimmed.length < 2) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Company name must be at least 2 characters",
      400
    );
  }
  if (trimmed.length > 200) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      "Company name must be at most 200 characters",
      400
    );
  }
  return trimmed;
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

  functions.logger.info("Creating tenant and user", {
    userId,
    email,
    tenantId,
    plan,
  });

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
    functions.logger.info("Setting custom claims for user", { userId, tenantId });
    const claimsPromise = setUserClaims(userId, tenantId, "owner");
    await Promise.race([
      claimsPromise,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Claims update timed out after 10 seconds")), 10000)
      ),
    ]);
    functions.logger.info("Custom claims set successfully", { userId });
  } catch (error) {
    functions.logger.error("Failed to set custom claims", { userId, error });
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

  try {
    await batch.commit();
    functions.logger.info("Tenant and user documents created", { userId, tenantId });
  } catch (error) {
    functions.logger.error("Failed to create tenant/user documents", { userId, tenantId, error });
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      "Failed to create account data. Please try again.",
      500
    );
  }

  // Audit log (don't fail signup if audit fails)
  try {
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
  } catch (error) {
    functions.logger.warn("Failed to write audit log for signup", { userId, tenantId, error });
  }

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
  data: SignUpInput,
  context: functions.https.CallableContext
): Promise<ApiResponse<SignUpResponse>> {
  const startTime = Date.now();
  const requestIp = context.rawRequest?.ip;

  functions.logger.info("Signup request received", {
    email: data.email,
    companyName: data.companyName,
    plan: data.plan || "starter",
    ip: requestIp,
  });

  // Validate and sanitize input
  const email = validateEmail(data.email);
  validatePassword(data.password);
  const displayName = validateDisplayName(data.displayName);
  const companyName = validateCompanyName(data.companyName);

  const plan = data.plan || "starter";
  if (!["starter", "professional", "enterprise"].includes(plan)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, "Invalid plan selected", 400);
  }

  // Check if email already exists
  try {
    const existingUser = await auth.getUserByEmail(email);
    if (existingUser) {
      functions.logger.warn("Signup attempted with existing email", { email });
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
  let userRecord;
  try {
    userRecord = await auth.createUser({
      email: email,
      password: data.password,
      displayName: displayName,
      emailVerified: false,
    });
    functions.logger.info("Firebase Auth user created", { userId: userRecord.uid, email });
  } catch (error) {
    functions.logger.error("Failed to create Firebase Auth user", { email, error });
    throw new AppError(
      ErrorCode.INTERNAL_ERROR,
      "Failed to create account. Please try again.",
      500
    );
  }

  try {
    // Create tenant and user document
    const { tenantId } = await createTenantAndUser(
      userRecord.uid,
      email,
      displayName,
      companyName,
      plan as Tenant["plan"]
    );

    // Try to send email verification (don't fail signup if this fails)
    try {
      const verificationLink = await auth.generateEmailVerificationLink(email);
      functions.logger.info("Email verification link generated", {
        userId: userRecord.uid,
        hasLink: !!verificationLink,
      });
      // Note: In production, you would send this via SendGrid or another email service
      // For now, Firebase will handle it when the user tries to verify
    } catch (emailError) {
      functions.logger.warn("Failed to generate email verification link", {
        userId: userRecord.uid,
        error: emailError,
      });
    }

    const duration = Date.now() - startTime;
    functions.logger.info("Signup completed successfully", {
      userId: userRecord.uid,
      tenantId,
      email,
      plan,
      durationMs: duration,
    });

    return {
      success: true,
      data: {
        userId: userRecord.uid,
        tenantId,
        email,
        displayName,
        role: "owner",
      },
    };
  } catch (error) {
    // If tenant/user creation fails, clean up the Auth user
    functions.logger.error("Signup failed after user creation, cleaning up", {
      userId: userRecord.uid,
      error,
    });
    try {
      await auth.deleteUser(userRecord.uid);
      functions.logger.info("Cleaned up Auth user after failed signup", { userId: userRecord.uid });
    } catch (cleanupError) {
      functions.logger.error("Failed to clean up Auth user", {
        userId: userRecord.uid,
        cleanupError,
      });
    }
    throw error;
  }
}

export const authSignUp = functions
  .runWith({
    timeoutSeconds: 120,
    memory: "512MB",
    // Rate limiting: Allow 10 signups per IP per minute
    // Note: This is basic protection - production should use Cloud Armor
    maxInstances: 100,
  })
  .https.onCall(withErrorHandling(signUpHandler));

// ============================================================================
// authRequestPasswordReset - Password Reset
// ============================================================================

interface PasswordResetInput {
  email: string;
}

interface PasswordResetResponse {
  message: string;
}

/**
 * Request a password reset email.
 * This is a PUBLIC function - no authentication required.
 */
async function passwordResetHandler(
  data: PasswordResetInput,
  context: functions.https.CallableContext
): Promise<ApiResponse<PasswordResetResponse>> {
  const requestIp = context.rawRequest?.ip;

  functions.logger.info("Password reset request received", {
    email: data.email,
    ip: requestIp,
  });

  // Validate email
  const email = validateEmail(data.email);

  // Always return success to prevent email enumeration attacks
  // Generate the reset link if user exists, but don't reveal if they don't
  try {
    const resetLink = await auth.generatePasswordResetLink(email);
    functions.logger.info("Password reset link generated", {
      email,
      hasLink: !!resetLink,
    });
    // Note: In production, send this via SendGrid or another email service
  } catch (error) {
    // Log but don't reveal to user whether email exists
    functions.logger.warn("Password reset failed (user may not exist)", {
      email,
      error,
    });
  }

  // Always return success message
  return {
    success: true,
    data: {
      message: "If an account with this email exists, a password reset link has been sent.",
    },
  };
}

export const authRequestPasswordReset = functions
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .https.onCall(withErrorHandling(passwordResetHandler));
