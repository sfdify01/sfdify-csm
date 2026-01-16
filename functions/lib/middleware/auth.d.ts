/**
 * Authentication Middleware
 *
 * Verifies Firebase authentication and extracts user context.
 * Enforces tenant isolation and role-based access control.
 */
import * as functions from "firebase-functions";
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
 * Permission definitions for each role
 */
export declare const ROLE_PERMISSIONS: Record<UserRole, string[]>;
/**
 * Extract authentication context from Firebase callable context
 */
export declare function getAuthContext(context: functions.https.CallableContext): Promise<AuthContext>;
/**
 * Get full request context including tenant and user data
 */
export declare function getRequestContext(context: functions.https.CallableContext): Promise<RequestContext>;
/**
 * Verify the user has a required permission
 */
export declare function requirePermission(authContext: AuthContext, permission: string): void;
/**
 * Verify the user has one of the required roles
 */
export declare function requireRole(authContext: AuthContext, allowedRoles: UserRole[]): void;
/**
 * Verify the resource belongs to the user's tenant
 */
export declare function requireTenantAccess(authContext: AuthContext, resourceTenantId: DocumentId): void;
/**
 * Set custom claims for a user (call this when creating/updating users)
 */
export declare function setUserClaims(userId: DocumentId, tenantId: DocumentId, role: UserRole): Promise<void>;
/**
 * Create a middleware that requires authentication and specific permissions
 */
export declare function withAuth<T, R>(requiredPermissions: string[], fn: (data: T, context: RequestContext) => Promise<R>): (data: T, callableContext: functions.https.CallableContext) => Promise<R>;
/**
 * Create a middleware that only requires authentication (no specific permissions)
 */
export declare function withBasicAuth<T, R>(fn: (data: T, context: RequestContext) => Promise<R>): (data: T, callableContext: functions.https.CallableContext) => Promise<R>;
/**
 * Verify webhook signature (for external webhooks)
 */
export declare function verifyWebhookSignature(payload: string, signature: string, secret: string, algorithm?: "sha256" | "sha1"): boolean;
//# sourceMappingURL=auth.d.ts.map