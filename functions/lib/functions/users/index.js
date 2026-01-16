"use strict";
/**
 * User Management Cloud Functions
 *
 * Handles user creation, updates, role assignment, and listing.
 * Implements role-based access control (RBAC) for multi-tenant security.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.usersSetRole = exports.usersList = exports.usersDelete = exports.usersUpdate = exports.usersGet = exports.usersCreate = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("../../admin");
const uuid_1 = require("uuid");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../../middleware/auth");
const validation_1 = require("../../utils/validation");
const errors_1 = require("../../utils/errors");
const audit_1 = require("../../utils/audit");
const joi_1 = __importDefault(require("joi"));
// ============================================================================
// usersCreate - Create a new user
// ============================================================================
async function createUserHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent, tenant } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(validation_1.createUserSchema, data);
    // Check tenant user limits based on plan
    const usersSnapshot = await admin_1.db
        .collection("users")
        .where("tenantId", "==", tenantId)
        .where("disabled", "==", false)
        .count()
        .get();
    const currentUserCount = usersSnapshot.data().count;
    // Define user limits per plan
    const userLimits = {
        starter: 3,
        professional: 10,
        enterprise: 100,
    };
    const maxUsers = userLimits[tenant.plan] || 3;
    if (currentUserCount >= maxUsers) {
        throw new errors_1.AppError(errors_1.ErrorCode.TENANT_LIMIT_EXCEEDED, `User limit reached for ${tenant.plan} plan. Maximum ${maxUsers} users allowed.`, 400);
    }
    // Check if email already exists
    try {
        const existingUser = await admin_1.auth.getUserByEmail(validatedData.email);
        if (existingUser) {
            throw new errors_1.ConflictError(`User with email ${validatedData.email} already exists`);
        }
    }
    catch (error) {
        // User doesn't exist - this is expected
        if (error.code !== "auth/user-not-found") {
            throw error;
        }
    }
    // Create user in Firebase Auth
    const password = validatedData.password || (0, uuid_1.v4)();
    const firebaseUser = await admin_1.auth.createUser({
        email: validatedData.email,
        displayName: validatedData.displayName,
        password,
        emailVerified: false,
    });
    // Set custom claims
    await (0, auth_1.setUserClaims)(firebaseUser.uid, tenantId, validatedData.role);
    // Create user document
    const user = {
        id: firebaseUser.uid,
        tenantId,
        email: validatedData.email,
        displayName: validatedData.displayName,
        role: validatedData.role,
        permissions: auth_1.ROLE_PERMISSIONS[validatedData.role] || [],
        twoFactorEnabled: false,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        disabled: false,
    };
    await admin_1.db.collection("users").doc(firebaseUser.uid).set(user);
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "user",
        entityId: firebaseUser.uid,
        action: "create",
        newState: { ...user, password: "[REDACTED]" },
        metadata: { source: "user_management" },
    });
    return {
        success: true,
        data: user,
    };
}
exports.usersCreate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:write"], createUserHandler)));
async function getUserHandler(data, context) {
    const { tenantId } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ userId: validation_1.schemas.documentId.required() }), data);
    // Get user document
    const userDoc = await admin_1.db.collection("users").doc(validatedData.userId).get();
    (0, errors_1.assertExists)(userDoc.exists ? userDoc.data() : null, "User", validatedData.userId);
    const user = { id: userDoc.id, ...userDoc.data() };
    // Verify tenant access
    if (user.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this user");
    }
    return {
        success: true,
        data: user,
    };
}
exports.usersGet = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:read"], getUserHandler)));
async function updateUserHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedUserId = (0, validation_1.validate)(joi_1.default.object({ userId: validation_1.schemas.documentId.required() }), { userId: data.userId });
    const validatedData = (0, validation_1.validate)(validation_1.updateUserSchema, data);
    // Get current user
    const userRef = admin_1.db.collection("users").doc(validatedUserId.userId);
    const userDoc = await userRef.get();
    (0, errors_1.assertExists)(userDoc.exists ? userDoc.data() : null, "User", validatedUserId.userId);
    const currentUser = { id: userDoc.id, ...userDoc.data() };
    // Verify tenant access
    if (currentUser.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this user");
    }
    // Prevent demoting yourself
    if (actorId === validatedUserId.userId && validatedData.role && validatedData.role !== actorRole) {
        throw new errors_1.ForbiddenError("You cannot change your own role");
    }
    // Prevent disabling yourself
    if (actorId === validatedUserId.userId && validatedData.disabled === true) {
        throw new errors_1.ForbiddenError("You cannot disable your own account");
    }
    // Only owners can change roles or create other owners
    if (validatedData.role) {
        (0, auth_1.requireRole)(context, ["owner"]);
    }
    // Build update object
    const updates = {};
    if (validatedData.displayName !== undefined) {
        updates.displayName = validatedData.displayName;
    }
    if (validatedData.role !== undefined) {
        updates.role = validatedData.role;
        updates.permissions = auth_1.ROLE_PERMISSIONS[validatedData.role] || [];
        // Update Firebase Auth custom claims
        await (0, auth_1.setUserClaims)(validatedUserId.userId, tenantId, validatedData.role);
    }
    if (validatedData.disabled !== undefined) {
        updates.disabled = validatedData.disabled;
        // Update Firebase Auth
        await admin_1.auth.updateUser(validatedUserId.userId, {
            disabled: validatedData.disabled,
        });
    }
    // Update user document
    await userRef.update(updates);
    // Get updated user
    const updatedDoc = await userRef.get();
    const updatedUser = { id: updatedDoc.id, ...updatedDoc.data() };
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "user",
        entityId: validatedUserId.userId,
        action: "update",
        previousState: currentUser,
        newState: updatedUser,
    });
    return {
        success: true,
        data: updatedUser,
    };
}
exports.usersUpdate = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:write"], updateUserHandler)));
async function deleteUserHandler(data, context) {
    const { tenantId, userId: actorId, email: actorEmail, role: actorRole, ip, userAgent } = context;
    // Validate input
    const validatedData = (0, validation_1.validate)(joi_1.default.object({ userId: validation_1.schemas.documentId.required() }), data);
    // Get current user
    const userRef = admin_1.db.collection("users").doc(validatedData.userId);
    const userDoc = await userRef.get();
    (0, errors_1.assertExists)(userDoc.exists ? userDoc.data() : null, "User", validatedData.userId);
    const currentUser = { id: userDoc.id, ...userDoc.data() };
    // Verify tenant access
    if (currentUser.tenantId !== tenantId) {
        throw new errors_1.ForbiddenError("You do not have access to this user");
    }
    // Prevent deleting yourself
    if (actorId === validatedData.userId) {
        throw new errors_1.ForbiddenError("You cannot delete your own account");
    }
    // Prevent deleting the last owner
    if (currentUser.role === "owner") {
        const ownersSnapshot = await admin_1.db
            .collection("users")
            .where("tenantId", "==", tenantId)
            .where("role", "==", "owner")
            .where("disabled", "==", false)
            .count()
            .get();
        if (ownersSnapshot.data().count <= 1) {
            throw new errors_1.ForbiddenError("Cannot delete the last owner. Transfer ownership first.");
        }
    }
    // Soft delete - disable the user
    await userRef.update({
        disabled: true,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Disable in Firebase Auth
    await admin_1.auth.updateUser(validatedData.userId, { disabled: true });
    // Audit log
    await (0, audit_1.logAuditEvent)({
        tenantId,
        actor: { userId: actorId, email: actorEmail, role: actorRole, ip, userAgent },
        entity: "user",
        entityId: validatedData.userId,
        action: "delete",
        previousState: currentUser,
        newState: { ...currentUser, disabled: true },
    });
    return {
        success: true,
        data: { deleted: true },
    };
}
exports.usersDelete = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:delete"], deleteUserHandler)));
// ============================================================================
// usersList - List users in tenant
// ============================================================================
async function listUsersHandler(data, context) {
    const { tenantId } = context;
    // Validate pagination
    const pagination = (0, validation_1.validate)(validation_1.paginationSchema, data);
    // Build query
    let query = admin_1.db
        .collection("users")
        .where("tenantId", "==", tenantId)
        .orderBy("createdAt", "desc");
    // Filter by role if specified
    if (data.role) {
        const validRole = (0, validation_1.validate)(validation_1.schemas.userRole, data.role);
        query = query.where("role", "==", validRole);
    }
    // Apply cursor if provided
    if (pagination.cursor) {
        const cursorDoc = await admin_1.db.collection("users").doc(pagination.cursor).get();
        if (cursorDoc.exists) {
            query = query.startAfter(cursorDoc);
        }
    }
    // Execute query with limit + 1 to check for more
    const snapshot = await query.limit(pagination.limit + 1).get();
    const hasMore = snapshot.docs.length > pagination.limit;
    const docs = hasMore ? snapshot.docs.slice(0, -1) : snapshot.docs;
    const users = docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    // Get total count
    const countSnapshot = await admin_1.db
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
exports.usersList = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:read"], listUsersHandler)));
// ============================================================================
// usersSetRole - Update user role (owner only)
// ============================================================================
async function setRoleHandler(data, context) {
    // This is essentially the same as update, but explicitly for role changes
    (0, auth_1.requireRole)(context, ["owner"]);
    return updateUserHandler({ userId: data.userId, role: data.role }, context);
}
exports.usersSetRole = functions.https.onCall((0, errors_1.withErrorHandling)((0, auth_1.withAuth)(["users:write"], setRoleHandler)));
//# sourceMappingURL=index.js.map