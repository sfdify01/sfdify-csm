"""
Webhook endpoint views for external services.
"""
import json
import logging

from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from tickets.models import Webhook

logger = logging.getLogger(__name__)


class WebhookBaseView(APIView):
    """Base view for webhook endpoints."""

    permission_classes = [AllowAny]  # Webhooks authenticate via signatures
    provider = None

    def get_idempotency_key(self, request, payload: dict) -> str:
        """Extract or generate idempotency key from request/payload."""
        raise NotImplementedError

    def get_event_type(self, request, payload: dict) -> str:
        """Extract event type from request/payload."""
        raise NotImplementedError

    def verify_signature(self, request) -> bool:
        """Verify webhook signature."""
        raise NotImplementedError

    def process_webhook(self, event_type: str, payload: dict) -> dict:
        """Process the webhook payload."""
        raise NotImplementedError

    def post(self, request, *args, **kwargs):
        """Handle webhook POST request."""
        # Parse payload
        try:
            payload = request.data if isinstance(request.data, dict) else json.loads(request.body)
        except (json.JSONDecodeError, ValueError) as e:
            logger.error(f"Invalid webhook payload: {e}")
            return Response({'error': 'Invalid payload'}, status=status.HTTP_400_BAD_REQUEST)

        # Get event info
        event_type = self.get_event_type(request, payload)
        idempotency_key = self.get_idempotency_key(request, payload)

        # Check for duplicate
        existing = Webhook.objects.filter(
            provider=self.provider,
            idempotency_key=idempotency_key
        ).first()

        if existing and existing.status == 'completed':
            logger.info(f"Duplicate webhook ignored: {self.provider}/{idempotency_key}")
            return Response({'status': 'duplicate'}, status=status.HTTP_200_OK)

        # Verify signature
        if not self.verify_signature(request):
            logger.warning(f"Invalid webhook signature: {self.provider}/{event_type}")
            return Response({'error': 'Invalid signature'}, status=status.HTTP_401_UNAUTHORIZED)

        # Store webhook record
        webhook = Webhook.objects.create(
            provider=self.provider,
            event_type=event_type,
            payload=payload,
            headers=dict(request.headers),
            idempotency_key=idempotency_key,
            status='processing',
        )

        # Process webhook
        try:
            result = self.process_webhook(event_type, payload)
            webhook.status = 'completed'
            webhook.processed_at = timezone.now()
            webhook.save()

            return Response(result, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Webhook processing failed: {self.provider}/{event_type}: {e}")
            webhook.status = 'failed'
            webhook.error_message = str(e)
            webhook.save()

            return Response(
                {'error': 'Processing failed', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class LobWebhookView(WebhookBaseView):
    """
    Handle Lob webhook events.

    Lob sends webhooks for letter tracking events:
    - letter.created
    - letter.rendered_pdf
    - letter.rendered_thumbnails
    - letter.deleted
    - letter.in_transit
    - letter.in_local_area
    - letter.processed_for_delivery
    - letter.delivered
    - letter.returned_to_sender
    - letter.re_routed
    """

    provider = 'lob'

    def get_idempotency_key(self, request, payload: dict) -> str:
        """Get idempotency key from Lob webhook."""
        return payload.get('id', '') or request.headers.get('Lob-Event-Id', '')

    def get_event_type(self, request, payload: dict) -> str:
        """Get event type from Lob webhook."""
        return payload.get('event_type', {}).get('id', 'unknown')

    def verify_signature(self, request) -> bool:
        """Verify Lob webhook signature."""
        from tickets.services import LobService

        signature = request.headers.get('Lob-Signature', '')
        timestamp = request.headers.get('Lob-Signature-Timestamp', '')

        if not signature or not timestamp:
            logger.warning("Missing Lob signature headers")
            # In development, allow unsigned webhooks
            from django.conf import settings
            return getattr(settings, 'LOB_TEST_MODE', False)

        service = LobService()
        return service.verify_webhook_signature(request.body, signature, timestamp)

    def process_webhook(self, event_type: str, payload: dict) -> dict:
        """Process Lob webhook."""
        from tickets.services import LobService

        service = LobService()
        return service.process_webhook(event_type, payload)


class SmartCreditWebhookView(WebhookBaseView):
    """
    Handle SmartCredit webhook events.

    SmartCredit sends webhooks for:
    - report.ready - New credit report available
    - connection.expired - OAuth token expired
    - alert.new - Credit monitoring alert
    """

    provider = 'smartcredit'

    def get_idempotency_key(self, request, payload: dict) -> str:
        """Get idempotency key from SmartCredit webhook."""
        return payload.get('event_id', '') or request.headers.get('X-SmartCredit-Event-Id', '')

    def get_event_type(self, request, payload: dict) -> str:
        """Get event type from SmartCredit webhook."""
        return payload.get('event_type', 'unknown')

    def verify_signature(self, request) -> bool:
        """Verify SmartCredit webhook signature."""
        from customers.services import SmartCreditService

        signature = request.headers.get('X-SmartCredit-Signature', '')

        if not signature:
            logger.warning("Missing SmartCredit signature header")
            # In development, allow unsigned webhooks
            from django.conf import settings
            return getattr(settings, 'DEBUG', False)

        service = SmartCreditService()
        return service.verify_webhook_signature(request.body, signature)

    def process_webhook(self, event_type: str, payload: dict) -> dict:
        """Process SmartCredit webhook."""
        from customers.services import SmartCreditService

        service = SmartCreditService()
        return service.process_webhook(event_type, payload)


class StripeWebhookView(WebhookBaseView):
    """
    Handle Stripe webhook events for billing.

    Placeholder for future Stripe integration.
    """

    provider = 'stripe'

    def get_idempotency_key(self, request, payload: dict) -> str:
        """Get idempotency key from Stripe webhook."""
        return payload.get('id', '')

    def get_event_type(self, request, payload: dict) -> str:
        """Get event type from Stripe webhook."""
        return payload.get('type', 'unknown')

    def verify_signature(self, request) -> bool:
        """Verify Stripe webhook signature."""
        # TODO: Implement Stripe signature verification
        from django.conf import settings
        return getattr(settings, 'DEBUG', False)

    def process_webhook(self, event_type: str, payload: dict) -> dict:
        """Process Stripe webhook."""
        logger.info(f"Stripe webhook received: {event_type}")
        return {'status': 'acknowledged', 'event_type': event_type}
