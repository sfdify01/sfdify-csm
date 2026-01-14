"""
Unit tests for PII masking utilities.
"""
import pytest
from core.utils.masking import (
    mask_ssn, mask_email, mask_phone, mask_credit_card, mask_pii
)


class TestMaskSSN:
    """Tests for SSN masking."""

    def test_mask_full_ssn(self):
        """Test masking full SSN."""
        assert mask_ssn('123456789') == 'XXX-XX-6789'

    def test_mask_ssn_with_dashes(self):
        """Test masking SSN with dashes."""
        assert mask_ssn('123-45-6789') == 'XXX-XX-6789'

    def test_mask_ssn_short(self):
        """Test masking short value."""
        assert mask_ssn('12') == 'XXX-XX-XXXX'

    def test_mask_ssn_empty(self):
        """Test masking empty string."""
        assert mask_ssn('') == ''

    def test_mask_ssn_none(self):
        """Test masking None."""
        assert mask_ssn(None) == ''


class TestMaskEmail:
    """Tests for email masking."""

    def test_mask_email_long_local(self):
        """Test masking email with long local part."""
        assert mask_email('johndoe@example.com') == 'j*****e@example.com'

    def test_mask_email_short_local(self):
        """Test masking email with short local part."""
        assert mask_email('jd@example.com') == '**@example.com'

    def test_mask_email_single_char(self):
        """Test masking single character local part."""
        assert mask_email('j@example.com') == '*@example.com'

    def test_mask_email_invalid(self):
        """Test masking invalid email."""
        assert mask_email('notanemail') == '***@***.***'

    def test_mask_email_empty(self):
        """Test masking empty email."""
        assert mask_email('') == '***@***.***'


class TestMaskPhone:
    """Tests for phone masking."""

    def test_mask_phone_10_digit(self):
        """Test masking 10-digit phone."""
        assert mask_phone('5551234567') == 'XXX-XXX-4567'

    def test_mask_phone_with_formatting(self):
        """Test masking formatted phone."""
        assert mask_phone('(555) 123-4567') == 'XXX-XXX-4567'

    def test_mask_phone_short(self):
        """Test masking short phone."""
        assert mask_phone('123') == 'XXX-XXX-XXXX'

    def test_mask_phone_empty(self):
        """Test masking empty phone."""
        assert mask_phone('') == ''


class TestMaskCreditCard:
    """Tests for credit card masking."""

    def test_mask_credit_card(self):
        """Test masking credit card."""
        assert mask_credit_card('4111111111111111') == 'XXXX-XXXX-XXXX-1111'

    def test_mask_credit_card_with_dashes(self):
        """Test masking formatted credit card."""
        assert mask_credit_card('4111-1111-1111-1111') == 'XXXX-XXXX-XXXX-1111'

    def test_mask_credit_card_empty(self):
        """Test masking empty card."""
        assert mask_credit_card('') == ''


class TestMaskPII:
    """Tests for general PII masking."""

    def test_mask_pii_string_with_ssn(self):
        """Test masking SSN in string."""
        text = 'User SSN is 123-45-6789'
        result = mask_pii(text)
        assert '123-45-6789' not in result
        assert 'XXX-XX-6789' in result

    def test_mask_pii_string_with_email(self):
        """Test masking email in string."""
        text = 'Contact: john.doe@example.com'
        result = mask_pii(text)
        assert 'john.doe@example.com' not in result
        assert '@example.com' in result

    def test_mask_pii_string_with_phone(self):
        """Test masking phone in string."""
        text = 'Call me at (555) 123-4567'
        result = mask_pii(text)
        assert '(555) 123-4567' not in result

    def test_mask_pii_dict(self):
        """Test masking PII in dict."""
        data = {
            'ssn': '123-45-6789',
            'email': 'test@example.com',
            'name': 'John Doe'
        }
        result = mask_pii(data)
        assert 'XXX-XX-6789' in result['ssn']
        assert result['name'] == 'John Doe'

    def test_mask_pii_list(self):
        """Test masking PII in list."""
        data = ['SSN: 123-45-6789', 'Phone: 555-123-4567']
        result = mask_pii(data)
        assert 'XXX-XX-6789' in result[0]

    def test_mask_pii_preserves_non_string(self):
        """Test that non-strings are preserved."""
        assert mask_pii(123) == 123
        assert mask_pii(None) is None
