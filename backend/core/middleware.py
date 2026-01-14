import logging
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger(__name__)


class TenantMiddleware(MiddlewareMixin):
    """
    Middleware to extract and validate tenant from X-Tenant-ID header.

    Sets request.tenant to the Tenant instance if valid.
    """

    # Paths that don't require tenant validation
    EXEMPT_PATHS = [
        '/api/v1/auth/',
        '/api/v1/webhooks/',
        '/admin/',
        '/static/',
        '/media/',
    ]

    def process_request(self, request):
        # Skip tenant validation for exempt paths
        for path in self.EXEMPT_PATHS:
            if request.path.startswith(path):
                request.tenant = None
                return None

        # Get tenant ID from header
        tenant_id = request.headers.get('X-Tenant-ID')

        if not tenant_id:
            # For non-API requests or if no tenant required
            request.tenant = None
            return None

        try:
            from customers.models import Tenant
            request.tenant = Tenant.objects.get(id=tenant_id, is_active=True)
        except Tenant.DoesNotExist:
            logger.warning(f"Invalid tenant ID: {tenant_id}")
            return JsonResponse(
                {
                    'error': 'invalid_tenant',
                    'message': 'The specified tenant does not exist or is inactive.'
                },
                status=403
            )
        except Exception as e:
            logger.error(f"Error validating tenant: {e}")
            return JsonResponse(
                {
                    'error': 'tenant_error',
                    'message': 'Error validating tenant.'
                },
                status=500
            )

        return None


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Middleware for logging API requests (without PII).
    """

    # Sensitive fields to redact from logs
    SENSITIVE_FIELDS = [
        'password', 'ssn', 'social_security', 'token', 'api_key',
        'access_token', 'refresh_token', 'secret', 'credential'
    ]

    def process_request(self, request):
        # Log request metadata (no sensitive data)
        logger.info(
            f"API Request: {request.method} {request.path}",
            extra={
                'method': request.method,
                'path': request.path,
                'user_id': getattr(request.user, 'id', None),
                'tenant_id': getattr(getattr(request, 'tenant', None), 'id', None),
                'ip': self._get_client_ip(request),
            }
        )
        return None

    def process_response(self, request, response):
        # Log response metadata
        logger.info(
            f"API Response: {response.status_code}",
            extra={
                'status_code': response.status_code,
                'path': request.path,
            }
        )
        return response

    def _get_client_ip(self, request):
        """Extract client IP from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Middleware to add security headers to responses.
    """

    def process_response(self, request, response):
        # Prevent content type sniffing
        response['X-Content-Type-Options'] = 'nosniff'

        # Prevent clickjacking
        response['X-Frame-Options'] = 'DENY'

        # XSS protection
        response['X-XSS-Protection'] = '1; mode=block'

        # Referrer policy
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'

        # Content Security Policy (adjust as needed)
        if request.path.startswith('/api/'):
            response['Content-Security-Policy'] = "default-src 'none'"

        return response
