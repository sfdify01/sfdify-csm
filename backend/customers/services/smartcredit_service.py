"""
SmartCredit OAuth and API integration service.
"""
import hashlib
import hmac
import json
import logging
import secrets
from datetime import datetime, timedelta
from typing import Optional
from urllib.parse import urlencode

import requests
from django.conf import settings
from django.utils import timezone

from .encryption_service import EncryptionService

logger = logging.getLogger(__name__)


class SmartCreditError(Exception):
    """Base exception for SmartCredit errors."""
    pass


class SmartCreditAuthError(SmartCreditError):
    """Authentication/OAuth error."""
    pass


class SmartCreditAPIError(SmartCreditError):
    """API call error."""

    def __init__(self, message: str, status_code: int = None, response: dict = None):
        super().__init__(message)
        self.status_code = status_code
        self.response = response


class SmartCreditService:
    """
    Service for SmartCredit OAuth flow and API operations.

    SmartCredit provides consumer credit data via OAuth2.
    """

    BASE_URL = "https://api.smartcredit.com"
    AUTH_URL = "https://smartcredit.com/oauth"

    def __init__(self, tenant=None):
        """
        Initialize SmartCredit service.

        Args:
            tenant: Tenant model instance for multi-tenant configuration
        """
        self.tenant = tenant
        self.encryption = EncryptionService()

        # Get credentials from tenant settings or global settings
        if tenant and tenant.settings.get('smartcredit'):
            sc_settings = tenant.settings['smartcredit']
            self.client_id = sc_settings.get('client_id')
            self.client_secret = sc_settings.get('client_secret')
        else:
            self.client_id = getattr(settings, 'SMARTCREDIT_CLIENT_ID', None)
            self.client_secret = getattr(settings, 'SMARTCREDIT_CLIENT_SECRET', None)

        self.webhook_secret = getattr(settings, 'SMARTCREDIT_WEBHOOK_SECRET', None)

    def _get_headers(self, access_token: str = None) -> dict:
        """Get headers for API requests."""
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'SFDIFY-CreditDispute/1.0',
        }
        if access_token:
            headers['Authorization'] = f'Bearer {access_token}'
        return headers

    # ==================== OAuth Flow ====================

    def initiate_oauth(
        self,
        consumer,
        redirect_uri: str,
        scopes: list = None
    ) -> tuple[str, str, datetime]:
        """
        Initiate OAuth flow for a consumer.

        Args:
            consumer: Consumer model instance
            redirect_uri: URL to redirect after authorization
            scopes: List of requested scopes (default: reports, tradelines)

        Returns:
            Tuple of (authorization_url, state_token, expires_at)
        """
        if not self.client_id:
            raise SmartCreditAuthError("SmartCredit client_id not configured")

        # Generate secure state token
        state = secrets.token_urlsafe(32)

        # Default scopes
        if scopes is None:
            scopes = ['reports', 'tradelines', 'scores']

        # Build authorization URL
        params = {
            'client_id': self.client_id,
            'response_type': 'code',
            'redirect_uri': redirect_uri,
            'scope': ' '.join(scopes),
            'state': state,
            # Include consumer identifier for pre-fill
            'consumer_id': str(consumer.id),
        }

        auth_url = f"{self.AUTH_URL}/authorize?{urlencode(params)}"
        expires_at = timezone.now() + timedelta(minutes=10)

        # Store state in consumer's pending connection
        from ..models import SmartCreditConnection
        SmartCreditConnection.objects.update_or_create(
            consumer=consumer,
            status='pending',
            defaults={
                'oauth_state': state,
                'oauth_state_expires': expires_at,
                'scopes': scopes,
            }
        )

        return auth_url, state, expires_at

    def complete_oauth(
        self,
        consumer,
        code: str,
        state: str
    ):
        """
        Complete OAuth flow by exchanging code for tokens.

        Args:
            consumer: Consumer model instance
            code: Authorization code from callback
            state: State token to verify

        Returns:
            SmartCreditConnection model instance
        """
        from ..models import SmartCreditConnection

        # Verify state token
        try:
            connection = SmartCreditConnection.objects.get(
                consumer=consumer,
                status='pending',
                oauth_state=state,
            )
        except SmartCreditConnection.DoesNotExist:
            raise SmartCreditAuthError("Invalid or expired state token")

        if connection.oauth_state_expires and connection.oauth_state_expires < timezone.now():
            raise SmartCreditAuthError("OAuth state token has expired")

        # Exchange code for tokens
        token_url = f"{self.AUTH_URL}/token"
        payload = {
            'grant_type': 'authorization_code',
            'code': code,
            'client_id': self.client_id,
            'client_secret': self.client_secret,
        }

        try:
            response = requests.post(
                token_url,
                json=payload,
                headers=self._get_headers(),
                timeout=30
            )
            response.raise_for_status()
            token_data = response.json()
        except requests.RequestException as e:
            logger.error(f"SmartCredit token exchange failed: {e}")
            raise SmartCreditAuthError(f"Failed to exchange code for tokens: {e}")

        # Encrypt tokens before storage
        access_token_encrypted = self.encryption.encrypt(token_data['access_token'])
        refresh_token_encrypted = self.encryption.encrypt(token_data['refresh_token'])

        # Calculate expiration
        expires_in = token_data.get('expires_in', 3600)
        token_expires = timezone.now() + timedelta(seconds=expires_in)

        # Update connection
        connection.status = 'active'
        connection.access_token_encrypted = access_token_encrypted
        connection.refresh_token_encrypted = refresh_token_encrypted
        connection.token_expires_at = token_expires
        connection.oauth_state = None  # Clear state
        connection.oauth_state_expires = None
        connection.save()

        logger.info(f"SmartCredit OAuth completed for consumer {consumer.id}")
        return connection

    def refresh_token(self, connection) -> bool:
        """
        Refresh an expired access token.

        Args:
            connection: SmartCreditConnection model instance

        Returns:
            True if refresh successful
        """
        if not connection.refresh_token_encrypted:
            raise SmartCreditAuthError("No refresh token available")

        refresh_token = self.encryption.decrypt(connection.refresh_token_encrypted)

        token_url = f"{self.AUTH_URL}/token"
        payload = {
            'grant_type': 'refresh_token',
            'refresh_token': refresh_token,
            'client_id': self.client_id,
            'client_secret': self.client_secret,
        }

        try:
            response = requests.post(
                token_url,
                json=payload,
                headers=self._get_headers(),
                timeout=30
            )
            response.raise_for_status()
            token_data = response.json()
        except requests.RequestException as e:
            logger.error(f"SmartCredit token refresh failed: {e}")
            connection.status = 'expired'
            connection.save()
            raise SmartCreditAuthError(f"Failed to refresh token: {e}")

        # Update tokens
        connection.access_token_encrypted = self.encryption.encrypt(token_data['access_token'])
        if 'refresh_token' in token_data:
            connection.refresh_token_encrypted = self.encryption.encrypt(token_data['refresh_token'])

        expires_in = token_data.get('expires_in', 3600)
        connection.token_expires_at = timezone.now() + timedelta(seconds=expires_in)
        connection.save()

        return True

    def _get_access_token(self, connection) -> str:
        """Get valid access token, refreshing if needed."""
        if connection.token_expires_at and connection.token_expires_at < timezone.now():
            self.refresh_token(connection)

        return self.encryption.decrypt(connection.access_token_encrypted)

    # ==================== Credit Report API ====================

    def fetch_credit_report(self, connection, bureau: str) -> dict:
        """
        Fetch credit report from SmartCredit.

        Args:
            connection: SmartCreditConnection model instance
            bureau: Bureau name (equifax, experian, transunion)

        Returns:
            Parsed credit report data
        """
        access_token = self._get_access_token(connection)

        url = f"{self.BASE_URL}/v1/reports/{bureau}"

        try:
            response = requests.get(
                url,
                headers=self._get_headers(access_token),
                timeout=60
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"SmartCredit report fetch failed: {e}")
            raise SmartCreditAPIError(
                f"Failed to fetch {bureau} report",
                status_code=getattr(e.response, 'status_code', None) if hasattr(e, 'response') else None
            )

    def fetch_all_reports(self, connection) -> dict:
        """
        Fetch reports from all three bureaus.

        Args:
            connection: SmartCreditConnection model instance

        Returns:
            Dict with bureau names as keys and report data as values
        """
        reports = {}
        errors = {}

        for bureau in ['equifax', 'experian', 'transunion']:
            try:
                reports[bureau] = self.fetch_credit_report(connection, bureau)
            except SmartCreditAPIError as e:
                errors[bureau] = str(e)
                logger.warning(f"Failed to fetch {bureau} report: {e}")

        if not reports:
            raise SmartCreditAPIError(f"Failed to fetch any reports: {errors}")

        return reports

    def parse_and_save_report(self, consumer, connection, bureau: str, raw_report: dict):
        """
        Parse raw report data and save to database.

        Args:
            consumer: Consumer model instance
            connection: SmartCreditConnection model instance
            bureau: Bureau name
            raw_report: Raw report data from API

        Returns:
            CreditReport model instance
        """
        from ..models import CreditReport, Tradeline

        # Extract report metadata
        report_data = raw_report.get('report', {})
        score_data = raw_report.get('scores', {})

        # Create credit report record
        credit_report = CreditReport.objects.create(
            consumer=consumer,
            smartcredit_connection=connection,
            bureau=bureau,
            pulled_at=timezone.now(),
            report_date=self._parse_date(report_data.get('report_date')),
            score=score_data.get('score'),
            score_factors=score_data.get('factors', []),
            raw_report=raw_report,
            tradeline_count=len(report_data.get('tradelines', [])),
            inquiry_count=len(report_data.get('inquiries', [])),
            public_record_count=len(report_data.get('public_records', [])),
        )

        # Parse and save tradelines
        for tl_data in report_data.get('tradelines', []):
            self._parse_tradeline(consumer, credit_report, bureau, tl_data)

        # Update connection stats
        connection.last_pull_at = timezone.now()
        connection.pull_count = (connection.pull_count or 0) + 1
        connection.save()

        return credit_report

    def _parse_tradeline(self, consumer, credit_report, bureau: str, tl_data: dict):
        """Parse and save a single tradeline."""
        from ..models import Tradeline

        # Map API fields to model fields
        tradeline = Tradeline.objects.create(
            consumer=consumer,
            credit_report=credit_report,
            bureau=bureau,
            creditor_name=tl_data.get('creditor_name', ''),
            account_number_masked=self._mask_account(tl_data.get('account_number', '')),
            account_type=tl_data.get('account_type', ''),
            opened_date=self._parse_date(tl_data.get('opened_date')),
            closed_date=self._parse_date(tl_data.get('closed_date')),
            current_balance=tl_data.get('balance'),
            credit_limit=tl_data.get('credit_limit'),
            high_balance=tl_data.get('high_balance'),
            monthly_payment=tl_data.get('monthly_payment'),
            past_due_amount=tl_data.get('past_due'),
            account_status=tl_data.get('status', ''),
            payment_status=tl_data.get('payment_status', ''),
            payment_history=tl_data.get('payment_history', {}),
            remarks=tl_data.get('remarks', ''),
            dispute_status='none',
        )

        return tradeline

    def _parse_date(self, date_str: str) -> Optional[datetime]:
        """Parse date string from API."""
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            try:
                return datetime.strptime(date_str, '%m/%d/%Y').date()
            except ValueError:
                return None

    def _mask_account(self, account_number: str) -> str:
        """Mask account number for storage."""
        if not account_number:
            return ''
        if len(account_number) <= 4:
            return 'X' * len(account_number)
        return 'X' * (len(account_number) - 4) + account_number[-4:]

    # ==================== Webhook Handling ====================

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """
        Verify SmartCredit webhook signature.

        Args:
            payload: Raw request body bytes
            signature: Signature from X-SmartCredit-Signature header

        Returns:
            True if signature is valid
        """
        if not self.webhook_secret:
            logger.warning("SmartCredit webhook secret not configured")
            return False

        expected = hmac.new(
            self.webhook_secret.encode('utf-8'),
            payload,
            hashlib.sha256
        ).hexdigest()

        return hmac.compare_digest(expected, signature)

    def process_webhook(self, event_type: str, payload: dict):
        """
        Process incoming SmartCredit webhook.

        Args:
            event_type: Webhook event type
            payload: Webhook payload data

        Returns:
            Processing result
        """
        handlers = {
            'report.ready': self._handle_report_ready,
            'connection.expired': self._handle_connection_expired,
            'alert.new': self._handle_new_alert,
        }

        handler = handlers.get(event_type)
        if handler:
            return handler(payload)

        logger.info(f"Unhandled SmartCredit webhook event: {event_type}")
        return {'status': 'ignored', 'reason': f'Unknown event type: {event_type}'}

    def _handle_report_ready(self, payload: dict):
        """Handle report.ready webhook event."""
        consumer_id = payload.get('consumer_id')
        bureau = payload.get('bureau')

        if not consumer_id or not bureau:
            return {'status': 'error', 'reason': 'Missing consumer_id or bureau'}

        from ..models import Consumer, SmartCreditConnection

        try:
            consumer = Consumer.objects.get(id=consumer_id)
            connection = SmartCreditConnection.objects.get(
                consumer=consumer,
                status='active'
            )

            # Fetch and save the new report
            raw_report = self.fetch_credit_report(connection, bureau)
            credit_report = self.parse_and_save_report(consumer, connection, bureau, raw_report)

            return {
                'status': 'success',
                'report_id': str(credit_report.id)
            }
        except Exception as e:
            logger.error(f"Failed to process report.ready webhook: {e}")
            return {'status': 'error', 'reason': str(e)}

    def _handle_connection_expired(self, payload: dict):
        """Handle connection.expired webhook event."""
        from ..models import SmartCreditConnection

        connection_id = payload.get('connection_id')
        if connection_id:
            SmartCreditConnection.objects.filter(id=connection_id).update(status='expired')

        return {'status': 'success'}

    def _handle_new_alert(self, payload: dict):
        """Handle alert.new webhook event."""
        # TODO: Implement alert handling (credit monitoring alerts)
        logger.info(f"New SmartCredit alert: {payload}")
        return {'status': 'acknowledged'}
