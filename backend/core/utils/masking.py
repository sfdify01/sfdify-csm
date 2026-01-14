"""
PII masking utilities for logging and display.
"""
import re
import logging
from typing import Union


# Patterns for PII detection
SSN_PATTERN = re.compile(r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b')
EMAIL_PATTERN = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
PHONE_PATTERN = re.compile(r'\b(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)(?:\d{3}[-.\s]?)(?:\d{4})\b')
CREDIT_CARD_PATTERN = re.compile(r'\b(?:\d{4}[-\s]?){3}\d{4}\b')


def mask_ssn(ssn: str) -> str:
    """
    Mask SSN to show only last 4 digits.

    Args:
        ssn: Full or partial SSN

    Returns:
        Masked SSN (XXX-XX-1234)
    """
    if not ssn:
        return ''

    # Clean the SSN
    clean = re.sub(r'\D', '', ssn)

    if len(clean) >= 4:
        return f'XXX-XX-{clean[-4:]}'
    return 'XXX-XX-XXXX'


def mask_email(email: str) -> str:
    """
    Mask email to show partial username and domain.

    Args:
        email: Email address

    Returns:
        Masked email (j***@example.com)
    """
    if not email or '@' not in email:
        return '***@***.***'

    local, domain = email.split('@', 1)

    if len(local) <= 2:
        masked_local = '*' * len(local)
    else:
        masked_local = local[0] + '*' * (len(local) - 2) + local[-1]

    return f'{masked_local}@{domain}'


def mask_phone(phone: str) -> str:
    """
    Mask phone number to show only last 4 digits.

    Args:
        phone: Phone number

    Returns:
        Masked phone (XXX-XXX-1234)
    """
    if not phone:
        return ''

    # Clean the phone number
    clean = re.sub(r'\D', '', phone)

    if len(clean) >= 4:
        return f'XXX-XXX-{clean[-4:]}'
    return 'XXX-XXX-XXXX'


def mask_credit_card(card: str) -> str:
    """
    Mask credit card to show only last 4 digits.

    Args:
        card: Credit card number

    Returns:
        Masked card (XXXX-XXXX-XXXX-1234)
    """
    if not card:
        return ''

    clean = re.sub(r'\D', '', card)

    if len(clean) >= 4:
        return f'XXXX-XXXX-XXXX-{clean[-4:]}'
    return 'XXXX-XXXX-XXXX-XXXX'


def mask_pii(text: Union[str, dict, list]) -> Union[str, dict, list]:
    """
    Mask all PII in a text string, dict, or list.

    Args:
        text: Text containing potential PII

    Returns:
        Text with PII masked
    """
    if isinstance(text, dict):
        return {k: mask_pii(v) for k, v in text.items()}
    elif isinstance(text, list):
        return [mask_pii(item) for item in text]
    elif not isinstance(text, str):
        return text

    # Mask SSNs
    result = SSN_PATTERN.sub(
        lambda m: mask_ssn(m.group()),
        text
    )

    # Mask credit cards
    result = CREDIT_CARD_PATTERN.sub(
        lambda m: mask_credit_card(m.group()),
        result
    )

    # Mask phone numbers (be careful not to mask other number sequences)
    result = PHONE_PATTERN.sub(
        lambda m: mask_phone(m.group()),
        result
    )

    # Mask emails
    result = EMAIL_PATTERN.sub(
        lambda m: mask_email(m.group()),
        result
    )

    return result


class PIIMaskingFilter(logging.Filter):
    """
    Logging filter that masks PII in log messages.

    Usage:
        handler.addFilter(PIIMaskingFilter())
    """

    def filter(self, record):
        """Mask PII in the log message and arguments."""
        # Mask the message
        if record.msg:
            record.msg = mask_pii(str(record.msg))

        # Mask arguments
        if record.args:
            if isinstance(record.args, dict):
                record.args = {k: mask_pii(str(v)) for k, v in record.args.items()}
            elif isinstance(record.args, tuple):
                record.args = tuple(mask_pii(str(arg)) for arg in record.args)

        return True


class SensitiveDataFilter(logging.Filter):
    """
    More aggressive filter that also masks:
    - API keys
    - Tokens
    - Passwords
    """

    # Patterns for sensitive data
    API_KEY_PATTERN = re.compile(r'(?i)(api[_-]?key|apikey)["\s:=]+["\']?([A-Za-z0-9_-]{20,})["\']?')
    TOKEN_PATTERN = re.compile(r'(?i)(token|bearer)["\s:=]+["\']?([A-Za-z0-9._-]{20,})["\']?')
    PASSWORD_PATTERN = re.compile(r'(?i)(password|passwd|pwd|secret)["\s:=]+["\']?([^\s"\']{1,})["\']?')

    def filter(self, record):
        """Mask sensitive data in the log message."""
        msg = str(record.msg) if record.msg else ''

        # Apply PII masking
        msg = mask_pii(msg)

        # Mask API keys
        msg = self.API_KEY_PATTERN.sub(r'\1=***REDACTED***', msg)

        # Mask tokens
        msg = self.TOKEN_PATTERN.sub(r'\1=***REDACTED***', msg)

        # Mask passwords
        msg = self.PASSWORD_PATTERN.sub(r'\1=***REDACTED***', msg)

        record.msg = msg

        return True
