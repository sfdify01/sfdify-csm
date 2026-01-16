"use strict";
/**
 * Authentication Middleware
 *
 * Verifies Firebase authentication and extracts user context.
 * Enforces tenant isolation and role-based access control.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROLE_PERMISSIONS = void 0;
exports.getAuthContext = getAuthContext;
exports.getRequestContext = getRequestContext;
exports.requirePermission = requirePermission;
exports.requireRole = requireRole;
exports.requireTenantAccess = requireTenantAccess;
exports.setUserClaims = setUserClaims;
exports.withAuth = withAuth;
exports.withBasicAuth = withBasicAuth;
exports.verifyWebhookSignature = verifyWebhookSignature;
const admin_1 = require("../admin");
const errors_1 = require("../utils/errors");
/**
 * Permission definitions for each role
 */
exports.ROLE_PERMISSIONS = {
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
async function getAuthContext(context) {
    // Verify authentication
    if (!context.auth) {
        throw new errors_1.AuthError(errors_1.ErrorCode.UNAUTHENTICATED, "Authentication required");
    }
    const { uid, token } = context.auth;
    const claims = token;
    // Verify tenant and role are set
    if (!claims.tenantId) {
        throw new errors_1.AuthError(errors_1.ErrorCode.INVALID_TOKEN, "Tenant ID not found in token. Please sign in again.");
    }
    if (!claims.role) {
        throw new errors_1.AuthError(errors_1.ErrorCode.INVALID_TOKEN, "User role not found in token. Please contact support.");
    }
    // Get permissions for the role
    const permissions = exports.ROLE_PERMISSIONS[claims.role] || [];
    return {
        userId: uid,
        tenantId: claims.tenantId,
        email: token.email || "",
        role: claims.role,
        permissions,
        ip: context.rawRequest?.ip,
        userAgent: context.rawRequest?.headers?.["user-agent"],
    };
}
/**
 * Get full request context including tenant and user data
 */
async function getRequestContext(context) {
    const authContext = await getAuthContext(context);
    // Fetch tenant
    const tenantDoc = await admin_1.db.collection("tenants").doc(authContext.tenantId).get();
    if (!tenantDoc.exists) {
        throw new errors_1.NotFoundError("Tenant", authContext.tenantId);
    }
    const tenant = { id: tenantDoc.id, ...tenantDoc.data() };
    // Check tenant status
    if (tenant.status === "suspended") {
        throw new errors_1.AppError(errors_1.ErrorCode.TENANT_SUSPENDED, "Your account has been suspended. Please contact support.", 403);
    }
    if (tenant.status === "cancelled") {
        throw new errors_1.AppError(errors_1.ErrorCode.TENANT_SUSPENDED, "Your account has been cancelled.", 403);
    }
    // Fetch user
    const userDoc = await admin_1.db.collection("users").doc(authContext.userId).get();
    if (!userDoc.exists) {
        throw new errors_1.NotFoundError("User", authContext.userId);
    }
    const user = { id: userDoc.id, ...userDoc.data() };
    // Check if user is disabled
    if (user.disabled) {
        throw new errors_1.AuthError(errors_1.ErrorCode.UNAUTHORIZED, "Your account has been disabled.");
    }
    // Generate request ID for tracing
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
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
function requirePermission(authContext, permission) {
    if (!authContext.permissions.includes(permission)) {
        throw new errors_1.ForbiddenError(`You do not have permission to perform this action. Required: ${permission}`);
    }
}
/**
 * Verify the user has one of the required roles
 */
function requireRole(authContext, allowedRoles) {
    if (!allowedRoles.includes(authContext.role)) {
        throw new errors_1.ForbiddenError(`This action requires one of the following roles: ${allowedRoles.join(", ")}`);
    }
}
/**
 * Verify the resource belongs to the user's tenant
 */
function requireTenantAccess(authContext, resourceTenantId) {
    if (authContext.tenantId !== resourceTenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this resource.");
    }
}
/**
 * Set custom claims for a user (call this when creating/updating users)
 */
async function setUserClaims(userId, tenantId, role) {
    const permissions = exports.ROLE_PERMISSIONS[role] || [];
    await admin_1.auth.setCustomUserClaims(userId, {
        tenantId,
        role,
        permissions,
    });
}
/**
 * Create a middleware that requires authentication and specific permissions
 */
function withAuth(requiredPermissions, fn) {
    return async (data, callableContext) => {
        // Get request context (includes auth verification)
        const requestContext = await getRequestContext(callableContext);
        // Verify all required permissions
        for (const permission of requiredPermissions) {
            requirePermission(requestContext, permission);
        }
        // Call the wrapped function
        return fn(data, requestContext);
    };
}
/**
 * Create a middleware that only requires authentication (no specific permissions)
 */
function withBasicAuth(fn) {
    return async (data, callableContext) => {
        const requestContext = await getRequestContext(callableContext);
        return fn(data, requestContext);
    };
}
/**
 * Verify webhook signature (for external webhooks)
 */
function verifyWebhookSignature(payload, signature, secret, algorithm = "sha256") {
    const crypto = require("crypto");
    const expectedSignature = crypto
        .createHmac(algorithm, secret)
        .update(payload)
        .digest("hex");
    // Handle signature formats like "sha256=..." or just the hex
    const actualSignature = signature.includes("=")
        ? signature.split("=")[1]
        : signature;
    return crypto.timingSafeEqual(Buffer.from(expectedSignature), Buffer.from(actualSignature || ""));
}
//# sourceMappingURL=auth.js.map