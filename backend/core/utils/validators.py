"""
Custom validators for PII and other sensitive data.
"""
import re
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator


class SSNValidator:
    """
    Validator for US Social Security Numbers.

    Validates format and checks for obviously invalid SSNs.
    """

    SSN_PATTERN = re.compile(r'^\d{3}-?\d{2}-?\d{4}$')

    # Invalid SSN prefixes (per SSA rules)
    INVALID_PREFIXES = {'000', '666', '900', '901', '902', '903', '904',
                        '905', '906', '907', '908', '909', '910', '911',
                        '912', '913', '914', '915', '916', '917', '918',
                        '919', '920', '921', '922', '923', '924', '925',
                        '926', '927', '928', '929', '930', '931', '932',
                        '933', '934', '935', '936', '937', '938', '939',
                        '940', '941', '942', '943', '944', '945', '946',
                        '947', '948', '949', '950', '951', '952', '953',
                        '954', '955', '956', '957', '958', '959', '960',
                        '961', '962', '963', '964', '965', '966', '967',
                        '968', '969', '970', '971', '972', '973', '974',
                        '975', '976', '977', '978', '979', '980', '981',
                        '982', '983', '984', '985', '986', '987', '988',
                        '989', '990', '991', '992', '993', '994', '995',
                        '996', '997', '998', '999'}

    # Invalid group numbers (middle two digits)
    INVALID_GROUPS = {'00'}

    # Invalid serial numbers (last four digits)
    INVALID_SERIALS = {'0000'}

    message = 'Enter a valid Social Security Number.'
    code = 'invalid_ssn'

    def __init__(self, message=None, code=None):
        if message is not None:
            self.message = message
        if code is not None:
            self.code = code

    def __call__(self, value):
        # Clean the value
        clean_ssn = self._clean(value)

        # Check length
        if len(clean_ssn) != 9:
            raise ValidationError(self.message, code=self.code)

        # Check if all digits
        if not clean_ssn.isdigit():
            raise ValidationError(self.message, code=self.code)

        # Extract parts
        prefix = clean_ssn[:3]
        group = clean_ssn[3:5]
        serial = clean_ssn[5:9]

        # Check for invalid patterns
        if prefix in self.INVALID_PREFIXES:
            raise ValidationError(self.message, code=self.code)

        if group in self.INVALID_GROUPS:
            raise ValidationError(self.message, code=self.code)

        if serial in self.INVALID_SERIALS:
            raise ValidationError(self.message, code=self.code)

        # Check for repeating digits
        if len(set(clean_ssn)) == 1:
            raise ValidationError(self.message, code=self.code)

        # Check for sequential numbers
        if clean_ssn in ('123456789', '987654321'):
            raise ValidationError(self.message, code=self.code)

    def _clean(self, value):
        """Remove formatting characters."""
        return str(value).replace('-', '').replace(' ', '')


class PhoneValidator:
    """
    Validator for US phone numbers.

    Accepts various formats and validates structure.
    """

    # Pattern matches: (XXX) XXX-XXXX, XXX-XXX-XXXX, XXXXXXXXXX, +1XXXXXXXXXX
    PHONE_PATTERN = re.compile(
        r'^(?:\+?1[-.\s]?)?'  # Optional +1 country code
        r'(?:\(?\d{3}\)?[-.\s]?)'  # Area code
        r'(?:\d{3}[-.\s]?)'  # Exchange
        r'(?:\d{4})$'  # Subscriber
    )

    # Invalid area codes
    INVALID_AREA_CODES = {'000', '555'}  # 555 is reserved for fictitious use

    message = 'Enter a valid US phone number.'
    code = 'invalid_phone'

    def __init__(self, message=None, code=None):
        if message is not None:
            self.message = message
        if code is not None:
            self.code = code

    def __call__(self, value):
        if not value:
            return

        clean_phone = self._clean(value)

        # Check length (should be 10 or 11 with country code)
        if len(clean_phone) not in (10, 11):
            raise ValidationError(self.message, code=self.code)

        # If 11 digits, first should be '1'
        if len(clean_phone) == 11:
            if clean_phone[0] != '1':
                raise ValidationError(self.message, code=self.code)
            clean_phone = clean_phone[1:]  # Remove country code

        # Extract area code
        area_code = clean_phone[:3]

        # Check for invalid area codes
        if area_code in self.INVALID_AREA_CODES:
            raise ValidationError(self.message, code=self.code)

        # Area code cannot start with 0 or 1
        if area_code[0] in ('0', '1'):
            raise ValidationError(self.message, code=self.code)

        # Exchange (next 3 digits) cannot start with 0 or 1
        exchange = clean_phone[3:6]
        if exchange[0] in ('0', '1'):
            raise ValidationError(self.message, code=self.code)

    def _clean(self, value):
        """Remove all non-digit characters."""
        return re.sub(r'\D', '', str(value))


# Convenience functions
def validate_ssn(value):
    """Validate a Social Security Number."""
    validator = SSNValidator()
    validator(value)
    return True


def validate_phone(value):
    """Validate a US phone number."""
    validator = PhoneValidator()
    validator(value)
    return True


# Django validators for model fields
ssn_validator = SSNValidator()
phone_validator = PhoneValidator()

# Email validator (use Django's built-in)
from django.core.validators import EmailValidator
email_validator = EmailValidator()
