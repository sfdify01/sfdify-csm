"""
Encryption service for sensitive data (SSN, tokens, etc.)
"""
import base64
import logging
from typing import Optional

from django.conf import settings

logger = logging.getLogger(__name__)


class EncryptionService:
    """
    Service for encrypting and decrypting sensitive data.

    Uses AES-256-GCM for authenticated encryption.
    """

    def __init__(self, key: Optional[bytes] = None):
        """
        Initialize encryption service.

        Args:
            key: Optional 32-byte encryption key. If not provided,
                 uses ENCRYPTION_KEY from settings.
        """
        if key:
            self._key = key
        else:
            key_str = getattr(settings, 'ENCRYPTION_KEY', None)
            if not key_str:
                raise ValueError("ENCRYPTION_KEY not configured in settings")
            # Key should be base64 encoded 32-byte key
            self._key = base64.b64decode(key_str)

        if len(self._key) != 32:
            raise ValueError("Encryption key must be 32 bytes (256 bits)")

    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt a string value.

        Args:
            plaintext: The string to encrypt

        Returns:
            Base64-encoded encrypted value (nonce + ciphertext + tag)
        """
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
            import os
        except ImportError:
            raise RuntimeError("cryptography library not installed")

        # Generate random 12-byte nonce
        nonce = os.urandom(12)

        # Create AESGCM cipher
        aesgcm = AESGCM(self._key)

        # Encrypt
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode('utf-8'), None)

        # Combine nonce + ciphertext for storage
        combined = nonce + ciphertext

        # Return base64 encoded
        return base64.b64encode(combined).decode('utf-8')

    def decrypt(self, encrypted: str) -> str:
        """
        Decrypt an encrypted value.

        Args:
            encrypted: Base64-encoded encrypted value

        Returns:
            Decrypted plaintext string
        """
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        except ImportError:
            raise RuntimeError("cryptography library not installed")

        # Decode from base64
        combined = base64.b64decode(encrypted)

        # Extract nonce (first 12 bytes) and ciphertext
        nonce = combined[:12]
        ciphertext = combined[12:]

        # Create AESGCM cipher
        aesgcm = AESGCM(self._key)

        # Decrypt
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)

        return plaintext.decode('utf-8')

    def encrypt_ssn(self, ssn: str) -> tuple[str, str]:
        """
        Encrypt SSN and return encrypted value and last 4 digits.

        Args:
            ssn: 9-digit SSN (may contain dashes)

        Returns:
            Tuple of (encrypted_ssn, last_4_digits)
        """
        # Clean SSN
        clean_ssn = ssn.replace('-', '').replace(' ', '')

        if len(clean_ssn) != 9 or not clean_ssn.isdigit():
            raise ValueError("Invalid SSN format")

        encrypted = self.encrypt(clean_ssn)
        last4 = clean_ssn[-4:]

        return encrypted, last4

    def decrypt_ssn(self, encrypted_ssn: str) -> str:
        """
        Decrypt an encrypted SSN.

        Args:
            encrypted_ssn: Base64-encoded encrypted SSN

        Returns:
            Decrypted 9-digit SSN
        """
        return self.decrypt(encrypted_ssn)

    @staticmethod
    def generate_key() -> str:
        """
        Generate a new 256-bit encryption key.

        Returns:
            Base64-encoded 32-byte key
        """
        import os
        key = os.urandom(32)
        return base64.b64encode(key).decode('utf-8')

    @staticmethod
    def mask_ssn(ssn: str) -> str:
        """
        Mask SSN for display (XXX-XX-1234).

        Args:
            ssn: Full SSN

        Returns:
            Masked SSN string
        """
        clean = ssn.replace('-', '').replace(' ', '')
        if len(clean) >= 4:
            return f"XXX-XX-{clean[-4:]}"
        return "XXX-XX-XXXX"
