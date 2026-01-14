"""
Lob API integration service for letter mailing.
"""
import hashlib
import hmac
import logging
from datetime import datetime, timedelta
from typing import Optional

import requests
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)


class LobError(Exception):
    """Base exception for Lob errors."""
    pass


class LobAPIError(LobError):
    """Lob API error."""

    def __init__(self, message: str, status_code: int = None, response: dict = None):
        super().__init__(message)
        self.status_code = status_code
        self.response = response


class LobAddressError(LobError):
    """Address verification error."""
    pass


class LobService:
    """
    Service for Lob API operations (letter mailing).

    Lob provides programmatic direct mail including address verification,
    letter printing, and delivery tracking.
    """

    BASE_URL = "https://api.lob.com/v1"
    SANDBOX_URL = "https://api.lob.com/v1"  # Same URL, different API key

    def __init__(self, tenant=None):
        """
        Initialize Lob service.

        Args:
            tenant: Tenant model instance for multi-tenant configuration
        """
        self.tenant = tenant

        # Get API key from tenant settings or global settings
        if tenant and tenant.settings.get('lob'):
            lob_settings = tenant.settings['lob']
            self.api_key = lob_settings.get('api_key')
            self.is_test = lob_settings.get('test_mode', True)
        else:
            self.api_key = getattr(settings, 'LOB_API_KEY', None)
            self.is_test = getattr(settings, 'LOB_TEST_MODE', True)

        self.webhook_secret = getattr(settings, 'LOB_WEBHOOK_SECRET', None)

    def _get_auth(self) -> tuple:
        """Get basic auth tuple for API requests."""
        return (self.api_key, '')

    def _get_headers(self) -> dict:
        """Get headers for API requests."""
        return {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'SFDIFY-CreditDispute/1.0',
        }

    def _make_request(
        self,
        method: str,
        endpoint: str,
        data: dict = None,
        files: dict = None
    ) -> dict:
        """Make an API request to Lob."""
        url = f"{self.BASE_URL}/{endpoint}"

        try:
            if files:
                # Multipart request for file uploads
                response = requests.request(
                    method,
                    url,
                    auth=self._get_auth(),
                    data=data,
                    files=files,
                    timeout=60
                )
            else:
                response = requests.request(
                    method,
                    url,
                    auth=self._get_auth(),
                    headers=self._get_headers(),
                    json=data,
                    timeout=30
                )

            response.raise_for_status()
            return response.json()

        except requests.RequestException as e:
            error_data = None
            status_code = None

            if hasattr(e, 'response') and e.response is not None:
                status_code = e.response.status_code
                try:
                    error_data = e.response.json()
                except ValueError:
                    error_data = {'message': e.response.text}

            logger.error(f"Lob API error: {e}, response: {error_data}")
            raise LobAPIError(
                f"Lob API request failed: {e}",
                status_code=status_code,
                response=error_data
            )

    # ==================== Address Verification ====================

    def verify_address(self, address: dict) -> dict:
        """
        Verify a mailing address.

        Args:
            address: Dict with line1, line2, city, state, zip

        Returns:
            Verified address with deliverability info
        """
        data = {
            'primary_line': address.get('line1', ''),
            'secondary_line': address.get('line2', ''),
            'city': address.get('city', ''),
            'state': address.get('state', ''),
            'zip_code': address.get('zip', ''),
        }

        result = self._make_request('POST', 'us_verifications', data)

        deliverability = result.get('deliverability', 'undeliverable')

        if deliverability == 'undeliverable':
            raise LobAddressError(
                f"Address is undeliverable: {result.get('deliverability_analysis', {})}"
            )

        return {
            'deliverable': deliverability in ['deliverable', 'deliverable_incorrect_unit'],
            'deliverability': deliverability,
            'primary_line': result.get('primary_line'),
            'secondary_line': result.get('secondary_line'),
            'city': result.get('components', {}).get('city'),
            'state': result.get('components', {}).get('state'),
            'zip_code': result.get('components', {}).get('zip_code'),
            'zip_code_plus_4': result.get('components', {}).get('zip_code_plus_4'),
            'analysis': result.get('deliverability_analysis', {}),
        }

    # ==================== Letter Mailing ====================

    def send_letter(
        self,
        letter,
        mail_type: str = 'usps_first_class',
        color: bool = False
    ) -> dict:
        """
        Send a letter via Lob.

        Args:
            letter: Letter model instance
            mail_type: Mail type (usps_first_class, usps_standard, certified, registered)
            color: Whether to print in color

        Returns:
            Lob letter response with tracking info
        """
        if not letter.pdf_url:
            raise LobError("Letter must have a rendered PDF before sending")

        # Format addresses for Lob
        from_address = self._format_address(letter.return_address, 'sender')
        to_address = self._format_address(letter.recipient_address, letter.recipient_name)

        # Determine mail type
        lob_mail_type = self._map_mail_type(mail_type or letter.mail_type)

        # Build request data
        data = {
            'description': f"Dispute Letter {letter.dispute.dispute_number}",
            'to': to_address,
            'from': from_address,
            'file': letter.pdf_url,
            'color': color,
            'mail_type': lob_mail_type,
            'merge_variables': {
                'letter_id': str(letter.id),
                'dispute_number': letter.dispute.dispute_number,
            },
            'metadata': {
                'letter_id': str(letter.id),
                'dispute_id': str(letter.dispute.id),
                'consumer_id': str(letter.dispute.consumer.id),
            },
        }

        # Add certified mail options if applicable
        if lob_mail_type == 'certified':
            data['extra_service'] = 'certified'
        elif mail_type == 'certified_return_receipt':
            data['extra_service'] = 'certified_return_receipt_requested'

        result = self._make_request('POST', 'letters', data)

        # Update letter with Lob info
        letter.lob_id = result.get('id')
        letter.lob_url = result.get('url')
        letter.tracking_number = result.get('tracking_number', '')
        letter.carrier = result.get('carrier', 'USPS')
        letter.expected_delivery = self._parse_date(result.get('expected_delivery_date'))
        letter.cost_printing = result.get('cost', {}).get('printing', 0)
        letter.cost_postage = result.get('cost', {}).get('postage', 0)
        letter.cost_total = (letter.cost_printing or 0) + (letter.cost_postage or 0)
        letter.status = 'sent'
        letter.sent_at = timezone.now()
        letter.save()

        # Create letter event
        from ..models import LetterEvent
        LetterEvent.objects.create(
            letter=letter,
            event_type='submitted_to_lob',
            event_data=result,
            source='system',
            source_id=result.get('id'),
        )

        return {
            'lob_id': letter.lob_id,
            'lob_url': letter.lob_url,
            'tracking_number': letter.tracking_number,
            'expected_delivery': letter.expected_delivery,
            'cost_total': float(letter.cost_total) if letter.cost_total else 0,
            'status': letter.status,
        }

    def _format_address(self, address: dict, name: str) -> dict:
        """Format address for Lob API."""
        return {
            'name': name,
            'address_line1': address.get('line1', ''),
            'address_line2': address.get('line2', ''),
            'address_city': address.get('city', ''),
            'address_state': address.get('state', ''),
            'address_zip': address.get('zip', ''),
            'address_country': 'US',
        }

    def _map_mail_type(self, mail_type: str) -> str:
        """Map internal mail type to Lob mail type."""
        mapping = {
            'first_class': 'usps_first_class',
            'usps_first_class': 'usps_first_class',
            'standard': 'usps_standard',
            'usps_standard': 'usps_standard',
            'certified': 'certified',
            'certified_return_receipt': 'certified',
        }
        return mapping.get(mail_type, 'usps_first_class')

    def _parse_date(self, date_str: str) -> Optional[datetime]:
        """Parse date string from Lob API."""
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return None

    def get_letter_status(self, lob_id: str) -> dict:
        """
        Get letter status from Lob.

        Args:
            lob_id: Lob letter ID

        Returns:
            Letter status and tracking info
        """
        result = self._make_request('GET', f'letters/{lob_id}')

        return {
            'id': result.get('id'),
            'status': self._map_lob_status(result.get('tracking', {}).get('status')),
            'tracking_number': result.get('tracking_number'),
            'tracking_events': result.get('tracking', {}).get('events', []),
            'expected_delivery': result.get('expected_delivery_date'),
            'carrier': result.get('carrier'),
        }

    def _map_lob_status(self, lob_status: str) -> str:
        """Map Lob tracking status to internal status."""
        if not lob_status:
            return 'sent'

        mapping = {
            'Mailed': 'sent',
            'In Transit': 'in_transit',
            'In Local Area': 'in_transit',
            'Processed for Delivery': 'in_transit',
            'Delivered': 'delivered',
            'Re-Routed': 'in_transit',
            'Returned to Sender': 'returned',
        }
        return mapping.get(lob_status, 'sent')

    def cancel_letter(self, lob_id: str) -> bool:
        """
        Cancel a letter (only possible before mailing).

        Args:
            lob_id: Lob letter ID

        Returns:
            True if cancelled successfully
        """
        try:
            result = self._make_request('DELETE', f'letters/{lob_id}')
            return result.get('deleted', False)
        except LobAPIError as e:
            if e.status_code == 422:
                # Letter already mailed, cannot cancel
                return False
            raise

    # ==================== Webhook Handling ====================

    def verify_webhook_signature(self, payload: bytes, signature: str, timestamp: str) -> bool:
        """
        Verify Lob webhook signature.

        Args:
            payload: Raw request body bytes
            signature: Signature from Lob-Signature header
            timestamp: Timestamp from Lob-Signature-Timestamp header

        Returns:
            True if signature is valid
        """
        if not self.webhook_secret:
            logger.warning("Lob webhook secret not configured")
            return False

        # Construct the signed payload
        signed_payload = f"{timestamp}.{payload.decode('utf-8')}"

        expected = hmac.new(
            self.webhook_secret.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        return hmac.compare_digest(expected, signature)

    def process_webhook(self, event_type: str, payload: dict):
        """
        Process incoming Lob webhook.

        Args:
            event_type: Webhook event type
            payload: Webhook payload data

        Returns:
            Processing result
        """
        handlers = {
            'letter.created': self._handle_letter_created,
            'letter.rendered_pdf': self._handle_letter_rendered,
            'letter.rendered_thumbnails': self._handle_letter_thumbnails,
            'letter.deleted': self._handle_letter_deleted,
            'letter.in_transit': self._handle_tracking_update,
            'letter.in_local_area': self._handle_tracking_update,
            'letter.processed_for_delivery': self._handle_tracking_update,
            'letter.delivered': self._handle_letter_delivered,
            'letter.returned_to_sender': self._handle_letter_returned,
            'letter.re_routed': self._handle_tracking_update,
        }

        handler = handlers.get(event_type)
        if handler:
            return handler(payload)

        logger.info(f"Unhandled Lob webhook event: {event_type}")
        return {'status': 'ignored', 'reason': f'Unknown event type: {event_type}'}

    def _get_letter_by_lob_id(self, lob_id: str):
        """Get Letter model by Lob ID."""
        from ..models import Letter
        try:
            return Letter.objects.get(lob_id=lob_id)
        except Letter.DoesNotExist:
            return None

    def _create_letter_event(self, letter, event_type: str, event_data: dict, source_id: str = ''):
        """Create a LetterEvent record."""
        from ..models import LetterEvent
        return LetterEvent.objects.create(
            letter=letter,
            event_type=event_type,
            event_data=event_data,
            source='lob_webhook',
            source_id=source_id,
        )

    def _handle_letter_created(self, payload: dict):
        """Handle letter.created webhook."""
        lob_id = payload.get('body', {}).get('id')
        letter = self._get_letter_by_lob_id(lob_id)
        if letter:
            self._create_letter_event(letter, 'submitted_to_lob', payload)
        return {'status': 'success'}

    def _handle_letter_rendered(self, payload: dict):
        """Handle letter.rendered_pdf webhook."""
        body = payload.get('body', {})
        lob_id = body.get('id')
        letter = self._get_letter_by_lob_id(lob_id)

        if letter:
            letter.lob_url = body.get('url', letter.lob_url)
            letter.save(update_fields=['lob_url'])
            self._create_letter_event(letter, 'rendered', payload)

        return {'status': 'success'}

    def _handle_letter_thumbnails(self, payload: dict):
        """Handle letter.rendered_thumbnails webhook."""
        return {'status': 'acknowledged'}

    def _handle_letter_deleted(self, payload: dict):
        """Handle letter.deleted webhook."""
        lob_id = payload.get('body', {}).get('id')
        letter = self._get_letter_by_lob_id(lob_id)

        if letter:
            letter.status = 'failed'
            letter.save(update_fields=['status'])
            self._create_letter_event(letter, 'failed', payload)

        return {'status': 'success'}

    def _handle_tracking_update(self, payload: dict):
        """Handle tracking status update webhooks."""
        body = payload.get('body', {})
        lob_id = body.get('id')
        letter = self._get_letter_by_lob_id(lob_id)

        if letter:
            tracking = body.get('tracking', {})
            status = tracking.get('status', '')

            event_type_map = {
                'In Transit': 'in_transit',
                'In Local Area': 'in_local_area',
                'Processed for Delivery': 'processed_for_delivery',
                'Re-Routed': 'in_transit',
            }

            letter.status = 'in_transit'
            letter.save(update_fields=['status'])

            event_type = event_type_map.get(status, 'in_transit')
            self._create_letter_event(letter, event_type, payload)

        return {'status': 'success'}

    def _handle_letter_delivered(self, payload: dict):
        """Handle letter.delivered webhook."""
        body = payload.get('body', {})
        lob_id = body.get('id')
        letter = self._get_letter_by_lob_id(lob_id)

        if letter:
            letter.status = 'delivered'
            letter.delivered_at = timezone.now()
            letter.save(update_fields=['status', 'delivered_at'])
            self._create_letter_event(letter, 'delivered', payload)

            # Update dispute status if needed
            dispute = letter.dispute
            if dispute.status == 'mailed':
                dispute.status = 'awaiting_response'
                dispute.save(update_fields=['status'])

        return {'status': 'success'}

    def _handle_letter_returned(self, payload: dict):
        """Handle letter.returned_to_sender webhook."""
        body = payload.get('body', {})
        lob_id = body.get('id')
        letter = self._get_letter_by_lob_id(lob_id)

        if letter:
            letter.status = 'returned'
            letter.returned_at = timezone.now()
            letter.return_reason = body.get('tracking', {}).get('return_reason', 'Unknown')
            letter.save(update_fields=['status', 'returned_at', 'return_reason'])
            self._create_letter_event(letter, 'returned_to_sender', payload)

        return {'status': 'success'}
