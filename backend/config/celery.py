"""
Celery configuration for SFDIFY SCM project.
"""
import os
from celery import Celery
from celery.schedules import crontab

# Set the default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Create Celery app
app = Celery('sfdify_scm')

# Load config from Django settings, using CELERY_ namespace
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks in all installed apps
app.autodiscover_tasks()

# Configure task queues
app.conf.task_queues = {
    'default': {
        'exchange': 'default',
        'routing_key': 'default',
    },
    'credit_pull': {
        'exchange': 'credit',
        'routing_key': 'credit.pull',
    },
    'pdf_render': {
        'exchange': 'pdf',
        'routing_key': 'pdf.render',
    },
    'mail_send': {
        'exchange': 'mail',
        'routing_key': 'mail.send',
    },
    'sla_check': {
        'exchange': 'sla',
        'routing_key': 'sla.check',
    },
    'webhook_proc': {
        'exchange': 'webhook',
        'routing_key': 'webhook.process',
    },
}

# Task routing
app.conf.task_routes = {
    'customers.tasks.pull_credit_reports': {'queue': 'credit_pull'},
    'customers.tasks.refresh_expired_tokens': {'queue': 'credit_pull'},
    'tickets.tasks.render_letter_pdf': {'queue': 'pdf_render'},
    'tickets.tasks.send_letter_via_lob': {'queue': 'mail_send'},
    'tickets.tasks.check_sla_deadlines': {'queue': 'sla_check'},
    'tickets.tasks.process_webhook': {'queue': 'webhook_proc'},
}

# Celery Beat schedule (periodic tasks)
app.conf.beat_schedule = {
    # Check SLA deadlines every hour
    'check-sla-deadlines-hourly': {
        'task': 'tickets.tasks.check_sla_deadlines',
        'schedule': crontab(minute=0),  # Every hour at minute 0
        'options': {'queue': 'sla_check'},
    },
    # Refresh expiring OAuth tokens daily at 3 AM
    'refresh-expiring-tokens-daily': {
        'task': 'customers.tasks.refresh_expiring_tokens',
        'schedule': crontab(hour=3, minute=0),
        'options': {'queue': 'credit_pull'},
    },
    # Clean up old webhooks weekly
    'cleanup-old-webhooks-weekly': {
        'task': 'tickets.tasks.cleanup_old_webhooks',
        'schedule': crontab(hour=4, minute=0, day_of_week=0),  # Sunday 4 AM
        'options': {'queue': 'default'},
    },
}

# Task settings
app.conf.task_acks_late = True  # Acknowledge after task completion
app.conf.task_reject_on_worker_lost = True  # Reject tasks if worker dies
app.conf.task_time_limit = 600  # 10 minute hard limit
app.conf.task_soft_time_limit = 540  # 9 minute soft limit
app.conf.worker_prefetch_multiplier = 1  # One task at a time per worker


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task to verify Celery is working."""
    print(f'Request: {self.request!r}')
