/**
 * Authentication Middleware
 *
 * Verifies Firebase authentication and extracts user context.
 * Enforces tenant isolation and role-based access control.
 */

import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";
import { auth, db } from "../admin";
import { AuthError, ForbiddenError, AppError, ErrorCode, NotFoundError } from "../utils/errors";
import { UserRole, DocumentId, User, Tenant } from "../types";

/**
 * User context extracted from authentication
 */
export interface AuthContext {
  userId: DocumentId;
  tenantId: DocumentId;
  email: string;
  role: UserRole;
  permissions: string[];
  ip?: string;
  userAgent?: string;
}

/**
 * Full request context including user and tenant
 */
export interface RequestContext extends AuthContext {
  tenant: Tenant;
  user: User;
  requestId: string;
}

/**
 * Custom claims structure in Firebase Auth token
 */
interface CustomClaims {
  tenantId?: string;
  role?: UserRole;
  permissions?: string[];
}

/**
 * Permission definitions for each role
 */
export const ROLE_PERMISSIONS: Record<UserRole, string[]> = {
  owner: [
    "consumers:read",
    "consumers:write",
    "consumers:delete",
    "disputes:read",
    "disputes:write",
    "disputes:approve",
    "letters:read",
    "letters:write",
    "letters:send",
    "evidence:read",
    "evidence:write",
    "evidence:delete",
    "users:read",
    "users:write",
    "users:delete",
    "tenant:read",
    "tenant:write",
    "billing:read",
    "billing:write",
    "audit:read",
    "analytics:read",
    "settings:read",
    "settings:write",
  ],
  operator: [
    "consumers:read",
    "consumers:write",
    "disputes:read",
    "disputes:write",
    "disputes:approve",
    "letters:read",
    "letters:write",
    "letters:send",
    "evidence:read",
    "evidence:write",
    "users:read",
    "analytics:read",
    "settings:read",
  ],
  viewer: [
    "consumers:read",
    "disputes:read",
    "letters:read",
    "evidence:read",
    "analytics:read",
  ],
  auditor: [
    "consumers:read",
    "disputes:read",
    "letters:read",
    "evidence:read",
    "audit:read",
    "analytics:read",
  ],
};

/**
 * Extract authentication context from Firebase callable context
 */
export async function getAuthContext(
  context: functions.https.CallableContext
): Promise<AuthContext> {
  logger.info("[getAuthContext] Extracting auth context");

  // Verify authentication
  if (!context.auth) {
    logger.error("[getAuthContext] No auth context provided");
    throw new AuthError(ErrorCode.UNAUTHENTICATED, "Authentication required");
  }

  const { uid, token } = context.auth;
  logger.info("[getAuthContext] User authenticated", { uid, email: token.email });

  const claims = token as unknown as CustomClaims;
  logger.info("[getAuthContext] Token claims", {
    hasTenantId: !!claims.tenantId,
    hasRole: !!claims.role,
    tenantId: claims.tenantId,
    role: claims.role,
  });

  // Verify tenant and role are set
  if (!claims.tenantId) {
    logger.error("[getAuthContext] Missing tenantId in claims");
    throw new AuthError(ErrorCode.INVALID_TOKEN, "Tenant ID not found in token. Please sign in again.");
  }

  if (!claims.role) {
    logger.error("[getAuthContext] Missing role in claims");
    throw new AuthError(ErrorCode.INVALID_TOKEN, "User role not found in token. Please contact support.");
  }

  // Get permissions for the role
  const permissions = ROLE_PERMISSIONS[claims.role] || [];

  return {
    userId: uid,
    tenantId: claims.tenantId,
    email: token.email || "",
    role: claims.role,
    permissions,
    ip: context.rawRequest?.ip,
    userAgent: context.rawRequest?.headers?.["user-agent"] as string | undefined,
  };
}

/**
 * Get full request context including tenant and user data
 */
export async function getRequestContext(
  context: functions.https.CallableContext
): Promise<RequestContext> {
  logger.info("[getRequestContext] Starting");

  const authContext = await getAuthContext(context);
  logger.info("[getRequestContext] Auth context obtained", {
    userId: authContext.userId,
    tenantId: authContext.tenantId,
  });

  // Fetch tenant
  logger.info("[getRequestContext] Fetching tenant", { tenantId: authContext.tenantId });
  const tenantDoc = await db.collection("tenants").doc(authContext.tenantId).get();
  if (!tenantDoc.exists) {
    logger.error("[getRequestContext] Tenant not found", { tenantId: authContext.tenantId });
    throw new NotFoundError("Tenant", authContext.tenantId);
  }

  const tenant = { id: tenantDoc.id, ...tenantDoc.data() } as Tenant;
  logger.info("[getRequestContext] Tenant found", { tenantStatus: tenant.status });

  // Check tenant status
  if (tenant.status === "suspended") {
    throw new AppError(
      ErrorCode.TENANT_SUSPENDED,
      "Your account has been suspended. Please contact support.",
      403
    );
  }

  if (tenant.status === "cancelled") {
    throw new AppError(
      ErrorCode.TENANT_SUSPENDED,
      "Your account has been cancelled.",
      403
    );
  }

  // Fetch user
  logger.info("[getRequestContext] Fetching user", { userId: authContext.userId });
  const userDoc = await db.collection("users").doc(authContext.userId).get();
  if (!userDoc.exists) {
    logger.error("[getRequestContext] User not found", { userId: authContext.userId });
    throw new NotFoundError("User", authContext.userId);
  }

  const user = { id: userDoc.id, ...userDoc.data() } as User;
  logger.info("[getRequestContext] User found", { email: user.email, disabled: user.disabled });

  // Check if user is disabled
  if (user.disabled) {
    logger.error("[getRequestContext] User is disabled", { userId: authContext.userId });
    throw new AuthError(ErrorCode.UNAUTHORIZED, "Your account has been disabled.");
  }

  // Generate request ID for tracing
  const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  logger.info("[getRequestContext] Request context complete", { requestId });

  return {
    ...authContext,
    tenant,
    user,
    requestId,
  };
}

/**
 * Verify the user has a required permission
 */
export function requirePermission(
  authContext: AuthContext,
  permission: string
): void {
  if (!authContext.permissions.includes(permission)) {
    throw new ForbiddenError(
      `You do not have permission to perform this action. Required: ${permission}`
    );
  }
}

/**
 * Verify the user has one of the required roles
 */
export function requireRole(
  authContext: AuthContext,
  allowedRoles: UserRole[]
): void {
  if (!allowedRoles.includes(authContext.role)) {
    throw new ForbiddenError(
      `This action requires one of the following roles: ${allowedRoles.join(", ")}`
    );
  }
}

/**
 * Verify the resource belongs to the user's tenant
 */
export function requireTenantAccess(
  authContext: AuthContext,
  resourceTenantId: DocumentId
): void {
  if (authContext.tenantId !== resourceTenantId) {
    throw new ForbiddenError("You do not have access to this resource.");
  }
}

/**
 * Set custom claims for a user (call this when creating/updating users)
 */
export async function setUserClaims(
  userId: DocumentId,
  tenantId: DocumentId,
  role: UserRole
): Promise<void> {
  const permissions = ROLE_PERMISSIONS[role] || [];

  await auth.setCustomUserClaims(userId, {
    tenantId,
    role,
    permissions,
  });
}

/**
 * Create a middleware that requires authentication and specific permissions
 */
export function withAuth<T, R>(
  requiredPermissions: string[],
  fn: (data: T, context: RequestContext) => Promise<R>
): (data: T, callableContext: functions.https.CallableContext) => Promise<R> {
  return async (data: T, callableContext: functions.https.CallableContext) => {
    logger.info("[withAuth] Starting authentication", { requiredPermissions });

    // Get request context (includes auth verification)
    const requestContext = await getRequestContext(callableContext);

    // Verify all required permissions
    logger.info("[withAuth] Checking permissions", {
      required: requiredPermissions,
      userPermissions: requestContext.permissions,
    });

    for (const permission of requiredPermissions) {
      requirePermission(requestContext, permission);
    }

    logger.info("[withAuth] Permission check passed, calling handler");

    // Call the wrapped function
    return fn(data, requestContext);
  };
}

/**
 * Create a middleware that only requires authentication (no specific permissions)
 */
export function withBasicAuth<T, R>(
  fn: (data: T, context: RequestContext) => Promise<R>
): (data: T, callableContext: functions.https.CallableContext) => Promise<R> {
  return async (data: T, callableContext: functions.https.CallableContext) => {
    const requestContext = await getRequestContext(callableContext);
    return fn(data, requestContext);
  };
}

/**
 * Verify webhook signature (for external webhooks)
 */
export function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string,
  algorithm: "sha256" | "sha1" = "sha256"
): boolean {
  const crypto = require("crypto");
  const expectedSignature = crypto
    .createHmac(algorithm, secret)
    .update(payload)
    .digest("hex");

  // Handle signature formats like "sha256=..." or just the hex
  const actualSignature = signature.includes("=")
    ? signature.split("=")[1]
    : signature;

  return crypto.timingSafeEqual(
    Buffer.from(expectedSignature),
    Buffer.from(actualSignature || "")
  );
}
