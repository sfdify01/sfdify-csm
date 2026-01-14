"""
Celery tasks for tickets app.
"""
import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone
from django.db.models import Q

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def render_letter_pdf(self, letter_id: str):
    """
    Render a letter to PDF using WeasyPrint.

    Args:
        letter_id: UUID of the Letter
    """
    from .models import Letter
    from .services import LetterService

    try:
        letter = Letter.objects.select_related('dispute__consumer__tenant').get(id=letter_id)
    except Letter.DoesNotExist:
        logger.error(f"Letter {letter_id} not found")
        return {'status': 'error', 'message': 'Letter not found'}

    letter.status = 'rendering'
    letter.save(update_fields=['status'])

    try:
        service = LetterService(tenant=letter.dispute.consumer.tenant)
        result = service.render_and_save(letter)

        logger.info(f"Successfully rendered PDF for letter {letter_id}")
        return {
            'status': 'success',
            'letter_id': letter_id,
            **result
        }

    except Exception as e:
        letter.status = 'failed'
        letter.save(update_fields=['status'])
        logger.error(f"Failed to render PDF for letter {letter_id}: {e}")
        raise self.retry(exc=e)


@shared_task(bind=True, max_retries=3, default_retry_delay=120)
def send_letter_via_lob(self, letter_id: str, mail_type: str = None):
    """
    Send a letter via Lob API.

    Args:
        letter_id: UUID of the Letter
        mail_type: Override mail type (optional)
    """
    from .models import Letter
    from .services import LobService

    try:
        letter = Letter.objects.select_related('dispute__consumer__tenant').get(id=letter_id)
    except Letter.DoesNotExist:
        logger.error(f"Letter {letter_id} not found")
        return {'status': 'error', 'message': 'Letter not found'}

    if letter.status != 'approved':
        logger.warning(f"Letter {letter_id} is not approved (status: {letter.status})")
        return {'status': 'skipped', 'message': 'Letter not approved'}

    if not letter.pdf_url:
        # Need to render PDF first
        render_letter_pdf.delay(letter_id)
        return {'status': 'pending', 'message': 'PDF rendering queued'}

    letter.status = 'queued'
    letter.save(update_fields=['status'])

    try:
        service = LobService(tenant=letter.dispute.consumer.tenant)
        result = service.send_letter(letter, mail_type or letter.mail_type)

        logger.info(f"Successfully sent letter {letter_id} via Lob")
        return {
            'status': 'success',
            'letter_id': letter_id,
            **result
        }

    except Exception as e:
        letter.status = 'failed'
        letter.save(update_fields=['status'])
        logger.error(f"Failed to send letter {letter_id} via Lob: {e}")
        raise self.retry(exc=e)


@shared_task(bind=True)
def check_sla_deadlines(self):
    """
    Check for disputes approaching or past SLA deadlines.

    Creates tasks and sends notifications for:
    - Disputes due within 5 days
    - Disputes past due
    """
    from .models import Dispute, DisputeTask

    now = timezone.now()
    warning_threshold = now + timedelta(days=5)

    # Find disputes approaching deadline
    approaching = Dispute.objects.filter(
        status__in=['mailed', 'awaiting_response'],
        due_at__gt=now,
        due_at__lte=warning_threshold
    )

    # Find overdue disputes
    overdue = Dispute.objects.filter(
        status__in=['mailed', 'awaiting_response'],
        due_at__lt=now
    )

    results = {
        'approaching_deadline': [],
        'overdue': [],
        'tasks_created': 0
    }

    # Process approaching deadlines
    for dispute in approaching:
        days_remaining = (dispute.due_at - now).days
        results['approaching_deadline'].append({
            'dispute_id': str(dispute.id),
            'dispute_number': dispute.dispute_number,
            'days_remaining': days_remaining
        })

        # Create follow-up task if one doesn't exist
        existing_task = DisputeTask.objects.filter(
            dispute=dispute,
            type='follow_up',
            status__in=['pending', 'in_progress']
        ).exists()

        if not existing_task:
            DisputeTask.objects.create(
                dispute=dispute,
                type='follow_up',
                title=f'SLA deadline approaching ({days_remaining} days)',
                description=f'Dispute {dispute.dispute_number} is due in {days_remaining} days.',
                due_at=dispute.due_at - timedelta(days=2),
                priority='high'
            )
            results['tasks_created'] += 1

    # Process overdue disputes
    for dispute in overdue:
        days_overdue = (now - dispute.due_at).days
        results['overdue'].append({
            'dispute_id': str(dispute.id),
            'dispute_number': dispute.dispute_number,
            'days_overdue': days_overdue
        })

        # Create escalation task if one doesn't exist
        existing_task = DisputeTask.objects.filter(
            dispute=dispute,
            type='escalate',
            status__in=['pending', 'in_progress']
        ).exists()

        if not existing_task:
            DisputeTask.objects.create(
                dispute=dispute,
                type='escalate',
                title=f'SLA deadline passed ({days_overdue} days overdue)',
                description=f'Dispute {dispute.dispute_number} is {days_overdue} days past due. '
                           f'Consider escalation to CFPB.',
                due_at=now + timedelta(days=1),
                priority='urgent'
            )
            results['tasks_created'] += 1

    logger.info(
        f"SLA check complete: {len(results['approaching_deadline'])} approaching, "
        f"{len(results['overdue'])} overdue, {results['tasks_created']} tasks created"
    )

    return results


@shared_task(bind=True)
def process_lob_webhook(self, webhook_id: str):
    """
    Process a Lob webhook asynchronously.

    Args:
        webhook_id: UUID of the Webhook record
    """
    from .models import Webhook
    from .services import LobService

    try:
        webhook = Webhook.objects.get(id=webhook_id, provider='lob')
    except Webhook.DoesNotExist:
        logger.error(f"Lob webhook {webhook_id} not found")
        return {'status': 'error', 'message': 'Webhook not found'}

    if webhook.status == 'completed':
        return {'status': 'skipped', 'message': 'Already processed'}

    webhook.status = 'processing'
    webhook.save()

    try:
        service = LobService()
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

        logger.error(f"Failed to process Lob webhook {webhook_id}: {e}")
        raise


@shared_task(bind=True)
def cleanup_old_webhooks(self):
    """
    Clean up old webhook records (older than 90 days).
    """
    from .models import Webhook

    cutoff = timezone.now() - timedelta(days=90)

    # Delete completed webhooks older than 90 days
    deleted_count, _ = Webhook.objects.filter(
        status='completed',
        received_at__lt=cutoff
    ).delete()

    # Also delete old failed webhooks
    failed_deleted, _ = Webhook.objects.filter(
        status='failed',
        received_at__lt=cutoff
    ).delete()

    total_deleted = deleted_count + failed_deleted
    logger.info(f"Cleaned up {total_deleted} old webhook records")

    return {
        'status': 'success',
        'deleted_count': total_deleted
    }


@shared_task(bind=True)
def send_sla_notifications(self):
    """
    Send email/SMS notifications for SLA-related events.
    """
    # TODO: Implement notification sending
    # - Email notifications for approaching deadlines
    # - SMS alerts for urgent items
    # - Slack/Teams integration for team notifications

    logger.info("SLA notifications task - not yet implemented")
    return {'status': 'not_implemented'}


@shared_task(bind=True, max_retries=2, default_retry_delay=300)
def generate_dispute_report(self, dispute_id: str, report_type: str = 'full'):
    """
    Generate a detailed report for a dispute.

    Args:
        dispute_id: UUID of the Dispute
        report_type: Type of report (full, summary, timeline)
    """
    from .models import Dispute

    try:
        dispute = Dispute.objects.select_related(
            'consumer', 'tradeline'
        ).prefetch_related(
            'letters', 'evidence', 'tasks'
        ).get(id=dispute_id)
    except Dispute.DoesNotExist:
        logger.error(f"Dispute {dispute_id} not found")
        return {'status': 'error', 'message': 'Dispute not found'}

    # TODO: Implement report generation
    # - Full dispute history
    # - Letter timeline
    # - Evidence summary
    # - SLA compliance metrics

    return {
        'status': 'success',
        'dispute_id': dispute_id,
        'report_type': report_type,
        'message': 'Report generation not yet implemented'
    }
