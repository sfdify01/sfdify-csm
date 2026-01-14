from rest_framework.permissions import BasePermission


class HasTenantAccess(BasePermission):
    """
    Permission class to verify user has access to the tenant specified in X-Tenant-ID header.
    """
    message = 'You do not have access to this tenant.'

    def has_permission(self, request, view):
        # Skip for public endpoints
        if not request.user or not request.user.is_authenticated:
            return False

        # Check if tenant is set on request
        if not hasattr(request, 'tenant') or not request.tenant:
            return False

        # Superusers have access to all tenants
        if request.user.is_superuser:
            return True

        # Check user's tenant membership
        # For now, we'll use a simple check. In production, you'd have a TenantMembership model
        return True  # TODO: Implement tenant membership check


class HasRole(BasePermission):
    """
    Permission class to check if user has one of the required roles.

    Usage:
        permission_classes = [IsAuthenticated, HasRole]
        required_roles = ['owner', 'operator']
    """
    message = 'You do not have the required role for this action.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # Superusers bypass role checks
        if request.user.is_superuser:
            return True

        # Get required roles from view
        required_roles = getattr(view, 'required_roles', [])
        if not required_roles:
            return True

        # Check user's role
        if hasattr(request.user, 'agentprofile'):
            user_role = request.user.agentprofile.role
            return user_role in required_roles

        return False


class IsOwner(BasePermission):
    """Permission class for tenant owners only."""
    message = 'Only tenant owners can perform this action.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        if request.user.is_superuser:
            return True

        if hasattr(request.user, 'agentprofile'):
            return request.user.agentprofile.role == 'admin'  # 'admin' is owner-level

        return False


class IsOperator(BasePermission):
    """Permission class for operators and above (owner, admin, operator)."""
    message = 'Only operators can perform this action.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        if request.user.is_superuser:
            return True

        if hasattr(request.user, 'agentprofile'):
            return request.user.agentprofile.role in ['admin', 'supervisor', 'agent']

        return False


class IsViewer(BasePermission):
    """Permission class for viewers and above (all authenticated users with profile)."""
    message = 'You must be a registered user to view this resource.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        if request.user.is_superuser:
            return True

        # Any authenticated user with an agent profile can view
        return hasattr(request.user, 'agentprofile')


class IsAuditor(BasePermission):
    """Permission class for auditors (read-only access to audit logs)."""
    message = 'Only auditors can access audit logs.'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        if request.user.is_superuser:
            return True

        # Auditor role or admin can access
        if hasattr(request.user, 'agentprofile'):
            return request.user.agentprofile.role in ['admin', 'supervisor']

        return False


class IsObjectOwner(BasePermission):
    """
    Object-level permission to only allow owners of an object to access it.

    Assumes the model instance has a `created_by` attribute.
    """
    message = 'You can only access your own objects.'

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True

        # Check if user created the object
        if hasattr(obj, 'created_by'):
            return obj.created_by == request.user

        return False


class TenantIsolation(BasePermission):
    """
    Object-level permission to ensure objects belong to the user's tenant.

    Assumes the model instance has a `tenant` attribute.
    """
    message = 'This resource does not belong to your tenant.'

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True

        if not hasattr(request, 'tenant') or not request.tenant:
            return False

        # Check tenant isolation
        if hasattr(obj, 'tenant'):
            return obj.tenant == request.tenant

        # For nested objects, check through parent
        if hasattr(obj, 'consumer') and hasattr(obj.consumer, 'tenant'):
            return obj.consumer.tenant == request.tenant

        return True


def role_required(*roles):
    """
    Decorator factory for creating role-based permission classes.

    Usage:
        @role_required('owner', 'operator')
        class MyView(APIView):
            pass
    """
    class RolePermission(BasePermission):
        message = f'One of the following roles is required: {", ".join(roles)}'

        def has_permission(self, request, view):
            if not request.user or not request.user.is_authenticated:
                return False

            if request.user.is_superuser:
                return True

            if hasattr(request.user, 'agentprofile'):
                return request.user.agentprofile.role in roles

            return False

    return RolePermission
