from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError as DRFValidationError
import logging

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Custom exception handler that formats errors consistently.

    Returns:
    {
        "error": "error_code",
        "message": "Human readable message",
        "details": {...}  # Optional field-level errors
    }
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)

    if response is not None:
        # Format the error response
        error_data = {
            'error': _get_error_code(exc),
            'message': _get_error_message(exc, response),
        }

        # Add field-level errors for validation errors
        if isinstance(exc, DRFValidationError):
            if isinstance(exc.detail, dict):
                error_data['details'] = exc.detail
            elif isinstance(exc.detail, list):
                error_data['details'] = {'non_field_errors': exc.detail}

        response.data = error_data

    else:
        # Handle non-DRF exceptions
        if isinstance(exc, DjangoValidationError):
            error_data = {
                'error': 'validation_error',
                'message': str(exc.message) if hasattr(exc, 'message') else str(exc),
            }
            if hasattr(exc, 'error_dict'):
                error_data['details'] = exc.error_dict
            response = Response(error_data, status=status.HTTP_400_BAD_REQUEST)
        else:
            # Log unexpected exceptions
            logger.exception(f"Unhandled exception: {exc}")
            response = Response(
                {
                    'error': 'internal_error',
                    'message': 'An unexpected error occurred.',
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    return response


def _get_error_code(exc):
    """Map exception to error code."""
    from rest_framework.exceptions import (
        NotAuthenticated, AuthenticationFailed, PermissionDenied,
        NotFound, MethodNotAllowed, Throttled
    )

    error_map = {
        NotAuthenticated: 'unauthorized',
        AuthenticationFailed: 'invalid_credentials',
        PermissionDenied: 'forbidden',
        NotFound: 'not_found',
        MethodNotAllowed: 'method_not_allowed',
        Throttled: 'rate_limited',
        DRFValidationError: 'validation_error',
    }

    for exc_class, code in error_map.items():
        if isinstance(exc, exc_class):
            return code

    return 'error'


def _get_error_message(exc, response):
    """Get human-readable error message."""
    if hasattr(exc, 'detail'):
        if isinstance(exc.detail, str):
            return exc.detail
        elif isinstance(exc.detail, dict):
            # Get first error message
            for key, value in exc.detail.items():
                if isinstance(value, list) and value:
                    return str(value[0])
                return str(value)
        elif isinstance(exc.detail, list) and exc.detail:
            return str(exc.detail[0])

    # Default messages based on status code
    status_messages = {
        400: 'Invalid request data',
        401: 'Authentication required',
        403: 'Permission denied',
        404: 'Resource not found',
        405: 'Method not allowed',
        429: 'Too many requests',
        500: 'Internal server error',
    }

    return status_messages.get(response.status_code, 'An error occurred')


class APIException(Exception):
    """Base exception for API errors."""

    def __init__(self, message, error_code='error', status_code=400, details=None):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details
        super().__init__(message)


class TenantRequired(APIException):
    """Raised when X-Tenant-ID header is missing."""

    def __init__(self):
        super().__init__(
            message='X-Tenant-ID header is required',
            error_code='tenant_required',
            status_code=400
        )


class InvalidTenant(APIException):
    """Raised when tenant ID is invalid."""

    def __init__(self):
        super().__init__(
            message='Invalid or inactive tenant',
            error_code='invalid_tenant',
            status_code=403
        )


class InsufficientPermissions(APIException):
    """Raised when user lacks required permissions."""

    def __init__(self, required_role=None):
        message = 'You do not have permission to perform this action'
        if required_role:
            message = f'Required role: {required_role}'
        super().__init__(
            message=message,
            error_code='forbidden',
            status_code=403
        )


class ResourceNotFound(APIException):
    """Raised when a resource is not found."""

    def __init__(self, resource_type, resource_id=None):
        message = f'{resource_type} not found'
        if resource_id:
            message = f'{resource_type} with ID {resource_id} not found'
        super().__init__(
            message=message,
            error_code='not_found',
            status_code=404
        )


class ConflictError(APIException):
    """Raised when there's a conflict with current state."""

    def __init__(self, message):
        super().__init__(
            message=message,
            error_code='conflict',
            status_code=409
        )


class ExternalServiceError(APIException):
    """Raised when an external service fails."""

    def __init__(self, service_name, message=None):
        super().__init__(
            message=message or f'{service_name} service unavailable',
            error_code='external_service_error',
            status_code=503
        )
