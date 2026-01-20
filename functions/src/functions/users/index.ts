/**
 * User Management Cloud Functions
 *
 * Handles user creation, updates, role assignment, and listing.
 * Implements role-based access control (RBAC) for multi-tenant security.
 */

import * as functions from "firebase-functions";
import { db, auth } from "../../admin";
import { v4 as uuidv4 } from "uuid";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  withAuth,
  RequestContext,
  setUserClaims,
  requireRole,
  ROLE_PERMISSIONS,
} from "../../middleware/auth";
import {
  validate,
  createUserSchema,
  updateUserSchema,
  paginationSchema,
  schemas,
} from "../../utils/validation";
import {
  withErrorHandling,
  ConflictError,
  ForbiddenError,
  assertExists,
} from "../../utils/errors";
import { logAuditEvent } from "../../utils/audit";
import { User, UserRole, ApiResponse, PaginatedResponse } from "../../types";
import Joi from "joi";

// ============================================================================
// Type Definitions
// ============================================================================

interface CreateUserInput {
  email: string;
  displayName: string;
  role: UserRole;
  password?: string;
}

interface UpdateUserInput {
  displayName?: string;
  role?: UserRole;
  disabled?: boolean;
}

interface ListUsersInput {
  role?: UserRole;
  limit?: number;
  cursor?: string;
}

interface SetRoleInput {
  userId: string;
  role: UserRole;
}

// ============================================================================
// usersCreate - Create a new user
// ============================================================================

async function createUserHandler(
  data: CreateUserInput,
  context: RequestContext
): Promise<ApiResponse<User>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(createUserSchema, data);

  // Check if email already exists
  try {
    const existingUser = await auth.getUserByEmail(validatedData.email);
    if (existingUser) {
      throw new ConflictError(`User with email ${validatedData.email} already exists`);
    }
  } catch (error: unknown) {
    // User doesn't exist - this is expected
    if ((error as { code?: string }).code !== "auth/user-not-found") {
      throw error;
    }
  }

  // Create user in Firebase Auth
  const password = validatedData.password || uuidv4();
  const firebaseUser = await auth.createUser({
    email: validatedData.email,
    displayName: validatedData.displayName,
    password,
    emailVerified: false,
  });

  // Set custom claims
  await setUserClaims(firebaseUser.uid, tenantId, validatedData.role);

  // Create user document
  const user: User = {
    id: firebaseUser.uid,
    tenantId,
    email: validatedData.email,
    displayName: validatedData.displayName,
    role: validatedData.role,
    permissions: ROLE_PERMISSIONS[validatedData.role as UserRole] || [],
    twoFactorEnabled: false,
    createdAt: FieldValue.serverTimestamp() as unknown as Timestamp,
    disabled: false,
  };

  await db.collection("users").doc(firebaseUser.uid).set(user);

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "user",
    entityId: firebaseUser.uid,
    action: "create",
    newState: { ...user, password: "[REDACTED]" } as unknown as Record<string, unknown>,
    metadata: { source: "user_management" },
  });

  return {
    success: true,
    data: user,
  };
}

export const usersCreate = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:write"], createUserHandler)
  )
);

// ============================================================================
// usersGet - Get user details
// ============================================================================

interface GetUserInput {
  userId: string;
}

async function getUserHandler(
  data: GetUserInput,
  context: RequestContext
): Promise<ApiResponse<User>> {
  const { tenantId } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ userId: schemas.documentId.required() }),
    data
  );

  // Get user document
  const userDoc = await db.collection("users").doc(validatedData.userId).get();
  assertExists(userDoc.exists ? userDoc.data() : null, "User", validatedData.userId);

  const user = { id: userDoc.id, ...userDoc.data() } as User;

  // Verify tenant access
  if (user.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this user");
  }

  return {
    success: true,
    data: user,
  };
}

export const usersGet = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:read"], getUserHandler)
  )
);

// ============================================================================
// usersUpdate - Update user details
// ============================================================================

interface UpdateUserHandlerInput extends UpdateUserInput {
  userId: string;
}

async function updateUserHandler(
  data: UpdateUserHandlerInput,
  context: RequestContext
): Promise<ApiResponse<User>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedUserId = validate(
    Joi.object({ userId: schemas.documentId.required() }),
    { userId: data.userId }
  );
  const validatedData = validate(updateUserSchema, data);

  // Get current user
  const userRef = db.collection("users").doc(validatedUserId.userId);
  const userDoc = await userRef.get();
  assertExists(userDoc.exists ? userDoc.data() : null, "User", validatedUserId.userId);

  const currentUser = { id: userDoc.id, ...userDoc.data() } as User;

  // Verify tenant access
  if (currentUser.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this user");
  }

  // Prevent demoting yourself
  if (actorId === validatedUserId.userId && validatedData.role && validatedData.role !== actorRole) {
    throw new ForbiddenError("You cannot change your own role");
  }

  // Prevent disabling yourself
  if (actorId === validatedUserId.userId && validatedData.disabled === true) {
    throw new ForbiddenError("You cannot disable your own account");
  }

  // Only owners can change roles or create other owners
  if (validatedData.role) {
    requireRole(context, ["owner"]);
  }

  // Build update object
  const updates: Record<string, unknown> = {};

  if (validatedData.displayName !== undefined) {
    updates.displayName = validatedData.displayName;
  }

  if (validatedData.role !== undefined) {
    updates.role = validatedData.role;
    updates.permissions = ROLE_PERMISSIONS[validatedData.role as UserRole] || [];

    // Update Firebase Auth custom claims
    await setUserClaims(validatedUserId.userId, tenantId, validatedData.role);
  }

  if (validatedData.disabled !== undefined) {
    updates.disabled = validatedData.disabled;

    // Update Firebase Auth
    await auth.updateUser(validatedUserId.userId, {
      disabled: validatedData.disabled,
    });
  }

  // Update user document
  await userRef.update(updates);

  // Get updated user
  const updatedDoc = await userRef.get();
  const updatedUser = { id: updatedDoc.id, ...updatedDoc.data() } as User;

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "user",
    entityId: validatedUserId.userId,
    action: "update",
    previousState: currentUser as unknown as Record<string, unknown>,
    newState: updatedUser as unknown as Record<string, unknown>,
  });

  return {
    success: true,
    data: updatedUser,
  };
}

export const usersUpdate = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:write"], updateUserHandler)
  )
);

// ============================================================================
// usersDelete - Delete (disable) a user
// ============================================================================

interface DeleteUserInput {
  userId: string;
}

async function deleteUserHandler(
  data: DeleteUserInput,
  context: RequestContext
): Promise<ApiResponse<{ deleted: boolean }>> {
  const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;

  // Validate input
  const validatedData = validate(
    Joi.object({ userId: schemas.documentId.required() }),
    data
  );

  // Get current user
  const userRef = db.collection("users").doc(validatedData.userId);
  const userDoc = await userRef.get();
  assertExists(userDoc.exists ? userDoc.data() : null, "User", validatedData.userId);

  const currentUser = { id: userDoc.id, ...userDoc.data() } as User;

  // Verify tenant access
  if (currentUser.tenantId !== tenantId) {
    throw new ForbiddenError("You do not have access to this user");
  }

  // Prevent deleting yourself
  if (actorId === validatedData.userId) {
    throw new ForbiddenError("You cannot delete your own account");
  }

  // Prevent deleting the last owner
  if (currentUser.role === "owner") {
    const ownersSnapshot = await db
      .collection("users")
      .where("tenantId", "==", tenantId)
      .where("role", "==", "owner")
      .where("disabled", "==", false)
      .count()
      .get();

    if (ownersSnapshot.data().count <= 1) {
      throw new ForbiddenError("Cannot delete the last owner. Transfer ownership first.");
    }
  }

  // Soft delete - disable the user
  await userRef.update({
    disabled: true,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Disable in Firebase Auth
  await auth.updateUser(validatedData.userId, { disabled: true });

  // Audit log
  await logAuditEvent({
    tenantId,
    actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
    entity: "user",
    entityId: validatedData.userId,
    action: "delete",
    previousState: currentUser as unknown as Record<string, unknown>,
    newState: { ...currentUser, disabled: true } as unknown as Record<string, unknown>,
  });

  return {
    success: true,
    data: { deleted: true },
  };
}

export const usersDelete = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:delete"], deleteUserHandler)
  )
);

// ============================================================================
// usersList - List users in tenant
// ============================================================================

async function listUsersHandler(
  data: ListUsersInput,
  context: RequestContext
): Promise<PaginatedResponse<User>> {
  const { tenantId } = context;

  // Validate pagination
  const pagination = validate(paginationSchema, data);

  // Build query
  let query = db
    .collection("users")
    .where("tenantId", "==", tenantId)
    .orderBy("createdAt", "desc");

  // Filter by role if specified
  if (data.role) {
    const validRole = validate(schemas.userRole, data.role);
    query = query.where("role", "==", validRole);
  }

  // Apply cursor if provided
  if (pagination.cursor) {
    const cursorDoc = await db.collection("users").doc(pagination.cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  // Execute query with limit + 1 to check for more
  const snapshot = await query.limit(pagination.limit + 1).get();

  const hasMore = snapshot.docs.length > pagination.limit;
  const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;

  const users = docs.map((doc) => ({ id: doc.id, ...doc.data() } as User));

  // Get total count
  const countSnapshot = await db
    .collection("users")
    .where("tenantId", "==", tenantId)
    .count()
    .get();

  return {
    success: true,
    data: {
      items: users,
      pagination: {
        total: countSnapshot.data().count,
        limit: pagination.limit,
        hasMore,
        nextCursor: hasMore ? docs[docs.length - 1].id : undefined,
      },
    },
  };
}

export const usersList = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:read"], listUsersHandler)
  )
);

// ============================================================================
// usersSetRole - Update user role (owner only)
// ============================================================================

async function setRoleHandler(
  data: SetRoleInput,
  context: RequestContext
): Promise<ApiResponse<User>> {
  // This is essentially the same as update, but explicitly for role changes
  requireRole(context, ["owner"]);

  return updateUserHandler(
    { userId: data.userId, role: data.role },
    context
  );
}

export const usersSetRole = functions.https.onCall(
  withErrorHandling(
    withAuth(["users:write"], setRoleHandler)
  )
);
