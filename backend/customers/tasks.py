"""
Celery tasks for customers app.
"""
import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def pull_credit_reports(self, consumer_id: str, bureaus: list = None):
    """
    Pull credit reports for a consumer from SmartCredit.

    Args:
        consumer_id: UUID of the consumer
        bureaus: List of bureaus to pull (default: all three)
    """
    from .models import Consumer, SmartCreditConnection
    from .services import SmartCreditService

    if bureaus is None:
        bureaus = ['equifax', 'experian', 'transunion']

    try:
        consumer = Consumer.objects.get(id=consumer_id)
    except Consumer.DoesNotExist:
        logger.error(f"Consumer {consumer_id} not found")
        return {'status': 'error', 'message': 'Consumer not found'}

    # Get active connection
    connection = consumer.smartcredit_connections.filter(status='active').first()
    if not connection:
        logger.error(f"No active SmartCredit connection for consumer {consumer_id}")
        return {'status': 'error', 'message': 'No active connection'}

    service = SmartCreditService(tenant=consumer.tenant)
    results = {'reports': [], 'errors': []}

    for bureau in bureaus:
        try:
            raw_report = service.fetch_credit_report(connection, bureau)
            credit_report = service.parse_and_save_report(
                consumer, connection, bureau, raw_report
            )
            results['reports'].append({
                'bureau': bureau,
                'report_id': str(credit_report.id),
                'status': 'success'
            })
            logger.info(f"Successfully pulled {bureau} report for consumer {consumer_id}")
        except Exception as e:
            results['errors'].append({
                'bureau': bureau,
                'error': str(e)
            })
            logger.error(f"Failed to pull {bureau} report for consumer {consumer_id}: {e}")

    return results


@shared_task(bind=True)
def refresh_expiring_tokens(self):
    """
    Refresh SmartCredit OAuth tokens that are expiring soon.

    Runs daily to refresh tokens expiring within the next 7 days.
    """
    from .models import SmartCreditConnection
    from .services import SmartCreditService

    # Find connections expiring in the next 7 days
    expiring_threshold = timezone.now() + timedelta(days=7)
    expiring_connections = SmartCreditConnection.objects.filter(
        status='active',
        token_expires_at__lt=expiring_threshold,
        token_expires_at__gt=timezone.now()  # Not already expired
    )

    results = {'refreshed': 0, 'failed': 0, 'errors': []}

    for connection in expiring_connections:
        try:
            service = SmartCreditService(tenant=connection.consumer.tenant)
            service.refresh_token(connection)
            results['refreshed'] += 1
            logger.info(f"Refreshed token for connection {connection.id}")
        except Exception as e:
            results['failed'] += 1
            results['errors'].append({
                'connection_id': str(connection.id),
                'error': str(e)
            })
            logger.error(f"Failed to refresh token for connection {connection.id}: {e}")

    logger.info(f"Token refresh complete: {results['refreshed']} refreshed, {results['failed']} failed")
    return results


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def sync_consumer_data(self, consumer_id: str):
    """
    Sync consumer data from SmartCredit (alerts, score updates, etc.).

    Args:
        consumer_id: UUID of the consumer
    """
    from .models import Consumer

    try:
        consumer = Consumer.objects.get(id=consumer_id)
    except Consumer.DoesNotExist:
        logger.error(f"Consumer {consumer_id} not found")
        return {'status': 'error', 'message': 'Consumer not found'}

    # Get active connection
    connection = consumer.smartcredit_connections.filter(status='active').first()
    if not connection:
        return {'status': 'skipped', 'message': 'No active connection'}

    # TODO: Implement additional SmartCredit sync operations
    # - Fetch credit score updates
    # - Fetch new alerts
    # - Sync account information

    return {'status': 'success', 'consumer_id': consumer_id}


@shared_task(bind=True)
def process_smartcredit_webhook(self, webhook_id: str):
    """
    Process a SmartCredit webhook asynchronously.

    Args:
        webhook_id: UUID of the Webhook record
    """
    from tickets.models import Webhook
    from .services import SmartCreditService

    try:
        webhook = Webhook.objects.get(id=webhook_id, provider='smartcredit')
    except Webhook.DoesNotExist:
        logger.error(f"SmartCredit webhook {webhook_id} not found")
        return {'status': 'error', 'message': 'Webhook not found'}

    if webhook.status == 'completed':
        return {'status': 'skipped', 'message': 'Already processed'}

    webhook.status = 'processing'
    webhook.save()

    try:
        service = SmartCreditService()
        result = service.process_webhook(webhook.event_type, webhook.payload)

        webhook.status = 'completed'
        webhook.processed_at = timezone.now()
        webhook.save()

        return result

    except Exception as e:
        webhook.status = 'failed'
        webhook.error_message = str(e)
        webhook.retry_count += 1
        webhook.save()

        logger.error(f"Failed to process SmartCredit webhook {webhook_id}: {e}")
        raise
