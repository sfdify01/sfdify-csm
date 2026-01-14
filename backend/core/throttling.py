"""
Custom throttling classes for rate limiting.
"""
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle


class BurstRateThrottle(UserRateThrottle):
    """
    Throttle for burst requests (short-term limit).

    Default: 60 requests per minute for authenticated users.
    """
    scope = 'burst'
    rate = '60/min'


class SustainedRateThrottle(UserRateThrottle):
    """
    Throttle for sustained requests (long-term limit).

    Default: 1000 requests per hour for authenticated users.
    """
    scope = 'sustained'
    rate = '1000/hour'


class CreditPullThrottle(UserRateThrottle):
    """
    Throttle for credit report pulls.

    More restrictive due to cost and rate limits from SmartCredit.
    Default: 10 pulls per hour per user.
    """
    scope = 'credit_pull'
    rate = '10/hour'


class LetterSendThrottle(UserRateThrottle):
    """
    Throttle for sending letters via Lob.

    More restrictive due to cost.
    Default: 50 letters per day per user.
    """
    scope = 'letter_send'
    rate = '50/day'


class LoginThrottle(AnonRateThrottle):
    """
    Throttle for login attempts.

    Helps prevent brute force attacks.
    Default: 5 attempts per minute.
    """
    scope = 'login'
    rate = '5/min'


class PasswordResetThrottle(AnonRateThrottle):
    """
    Throttle for password reset requests.

    Prevents email flooding.
    Default: 3 requests per hour.
    """
    scope = 'password_reset'
    rate = '3/hour'


class WebhookThrottle(AnonRateThrottle):
    """
    Throttle for incoming webhooks.

    Higher limit since webhooks come from trusted sources.
    Default: 100 per minute per IP.
    """
    scope = 'webhook'
    rate = '100/min'


class ExportThrottle(UserRateThrottle):
    """
    Throttle for data export operations.

    Prevents abuse of resource-intensive exports.
    Default: 10 exports per hour.
    """
    scope = 'export'
    rate = '10/hour'


# Default throttle classes for different view types
STANDARD_THROTTLES = [BurstRateThrottle, SustainedRateThrottle]
SENSITIVE_THROTTLES = [BurstRateThrottle, SustainedRateThrottle, CreditPullThrottle]
AUTH_THROTTLES = [LoginThrottle]
