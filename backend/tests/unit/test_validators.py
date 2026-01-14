"""
Unit tests for validators.
"""
import pytest
from django.core.exceptions import ValidationError
from core.utils.validators import SSNValidator, PhoneValidator, validate_ssn, validate_phone


class TestSSNValidator:
    """Tests for SSN validation."""

    def test_valid_ssn_without_dashes(self):
        """Test that valid SSN without dashes passes."""
        validator = SSNValidator()
        validator('123456789')  # Should not raise

    def test_valid_ssn_with_dashes(self):
        """Test that valid SSN with dashes passes."""
        validator = SSNValidator()
        validator('123-45-6789')  # Should not raise

    def test_invalid_ssn_too_short(self):
        """Test that short SSN fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('12345678')

    def test_invalid_ssn_too_long(self):
        """Test that long SSN fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('1234567890')

    def test_invalid_ssn_letters(self):
        """Test that SSN with letters fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('12345678a')

    def test_invalid_ssn_all_zeros(self):
        """Test that SSN starting with 000 fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('000-12-3456')

    def test_invalid_ssn_666_prefix(self):
        """Test that SSN starting with 666 fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('666-12-3456')

    def test_invalid_ssn_900_range(self):
        """Test that SSN in 900 range fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('900-12-3456')

    def test_invalid_ssn_group_00(self):
        """Test that SSN with 00 group fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('123-00-6789')

    def test_invalid_ssn_serial_0000(self):
        """Test that SSN with 0000 serial fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('123-45-0000')

    def test_invalid_ssn_all_same_digit(self):
        """Test that SSN with all same digits fails."""
        validator = SSNValidator()
        with pytest.raises(ValidationError):
            validator('111111111')


class TestPhoneValidator:
    """Tests for phone number validation."""

    def test_valid_phone_10_digit(self):
        """Test that valid 10-digit phone passes."""
        validator = PhoneValidator()
        validator('5551234567')  # Should not raise

    def test_valid_phone_with_dashes(self):
        """Test that phone with dashes passes."""
        validator = PhoneValidator()
        validator('555-123-4567')  # Should not raise

    def test_valid_phone_with_parentheses(self):
        """Test that phone with parentheses passes."""
        validator = PhoneValidator()
        validator('(555) 123-4567')  # Should not raise

    def test_valid_phone_with_country_code(self):
        """Test that phone with +1 country code passes."""
        validator = PhoneValidator()
        validator('+1-555-123-4567')  # Should not raise

    def test_invalid_phone_too_short(self):
        """Test that short phone fails."""
        validator = PhoneValidator()
        with pytest.raises(ValidationError):
            validator('555123456')

    def test_invalid_phone_too_long(self):
        """Test that long phone fails."""
        validator = PhoneValidator()
        with pytest.raises(ValidationError):
            validator('555123456789')

    def test_invalid_phone_area_code_starts_with_0(self):
        """Test that area code starting with 0 fails."""
        validator = PhoneValidator()
        with pytest.raises(ValidationError):
            validator('055-123-4567')

    def test_invalid_phone_area_code_starts_with_1(self):
        """Test that area code starting with 1 fails."""
        validator = PhoneValidator()
        with pytest.raises(ValidationError):
            validator('155-123-4567')

    def test_invalid_phone_exchange_starts_with_0(self):
        """Test that exchange starting with 0 fails."""
        validator = PhoneValidator()
        with pytest.raises(ValidationError):
            validator('555-012-4567')


class TestValidateFunctions:
    """Tests for convenience validation functions."""

    def test_validate_ssn_valid(self):
        """Test validate_ssn with valid SSN."""
        assert validate_ssn('123-45-6789') is True

    def test_validate_ssn_invalid(self):
        """Test validate_ssn with invalid SSN."""
        with pytest.raises(ValidationError):
            validate_ssn('000-00-0000')

    def test_validate_phone_valid(self):
        """Test validate_phone with valid phone."""
        assert validate_phone('555-123-4567') is True

    def test_validate_phone_invalid(self):
        """Test validate_phone with invalid phone."""
        with pytest.raises(ValidationError):
            validate_phone('123')
