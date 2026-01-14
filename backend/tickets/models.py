import uuid
from django.db import models
from django.contrib.auth import get_user_model
from auditlog.registry import auditlog

User = get_user_model()


# =============================================================================
# CREDIT DISPUTE MODELS
# =============================================================================

class Dispute(models.Model):
    """Credit dispute for a tradeline."""

    TYPE_CHOICES = [
        ('fcra_609_request', 'FCRA 609 Information Request'),
        ('fcra_611_accuracy', 'FCRA 611 Dispute of Accuracy'),
        ('method_verification', 'Method of Verification Request'),
        ('reinvestigation', 'Reinvestigation Follow-up'),
        ('goodwill_adjustment', 'Goodwill Adjustment Request'),
        ('pay_for_delete', 'Pay for Delete Offer'),
        ('identity_theft_605b', 'Identity Theft Block (605B)'),
        ('cfpb_complaint', 'CFPB Complaint Package'),
        ('generic_dispute', 'Generic Dispute'),
    ]

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending_review', 'Pending Review'),
        ('approved', 'Approved'),
        ('mailed', 'Mailed'),
        ('awaiting_response', 'Awaiting Response'),
        ('responded', 'Bureau Responded'),
        ('resolved', 'Resolved'),
        ('escalated', 'Escalated'),
        ('closed', 'Closed'),
    ]

    OUTCOME_CHOICES = [
        ('deleted', 'Deleted'),
        ('corrected', 'Corrected'),
        ('verified', 'Verified as Accurate'),
        ('no_response', 'No Response'),
        ('partial_correction', 'Partial Correction'),
        ('rejected', 'Rejected'),
        ('escalated', 'Escalated to CFPB'),
    ]

    BUREAU_CHOICES = [
        ('equifax', 'Equifax'),
        ('experian', 'Experian'),
        ('transunion', 'TransUnion'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    consumer = models.ForeignKey('customers.Consumer', on_delete=models.CASCADE, related_name='disputes')
    tradeline = models.ForeignKey('customers.Tradeline', on_delete=models.SET_NULL, null=True, blank=True, related_name='disputes')

    # Identification
    dispute_number = models.CharField(max_length=20, unique=True, editable=False)
    bureau = models.CharField(max_length=20, choices=BUREAU_CHOICES)

    # Classification
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    reason_codes = models.JSONField(default=list)  # ["INACCURATE_BALANCE", "WRONG_DATES"]

    # Content
    narrative = models.TextField(blank=True)
    ai_generated = models.BooleanField(default=False)
    ai_reviewed = models.BooleanField(default=False)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')

    # Timeline
    created_at = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField(null=True, blank=True)
    due_at = models.DateTimeField(null=True, blank=True)  # 30 days from submission
    extended_due_at = models.DateTimeField(null=True, blank=True)  # 45 days if additional info
    responded_at = models.DateTimeField(null=True, blank=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    # Outcome
    outcome = models.CharField(max_length=50, choices=OUTCOME_CHOICES, null=True, blank=True)
    outcome_details = models.JSONField(default=dict, blank=True)
    bureau_response = models.TextField(blank=True)

    # Assignment
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_disputes')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_disputes')

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['consumer', 'bureau']),
            models.Index(fields=['status']),
            models.Index(fields=['due_at']),
            models.Index(fields=['assigned_to']),
        ]

    def __str__(self):
        return f"{self.dispute_number} - {self.bureau}"

    def save(self, *args, **kwargs):
        if not self.dispute_number:
            last = Dispute.objects.order_by('-created_at').first()
            if last and last.dispute_number:
                try:
                    last_num = int(last.dispute_number.replace('DSP-', ''))
                    self.dispute_number = f"DSP-{last_num + 1:08d}"
                except ValueError:
                    self.dispute_number = "DSP-00000001"
            else:
                self.dispute_number = "DSP-00000001"
        super().save(*args, **kwargs)


class LetterTemplate(models.Model):
    """Reusable letter template."""

    TYPE_CHOICES = Dispute.TYPE_CHOICES

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey('customers.Tenant', on_delete=models.CASCADE, null=True, blank=True, related_name='letter_templates')

    # Template info
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=100)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    description = models.TextField(blank=True)

    # Content
    subject_template = models.CharField(max_length=255, blank=True)
    body_html = models.TextField()
    body_text = models.TextField(blank=True)

    # Variables metadata
    variables = models.JSONField(default=list)  # [{name, required, description}]

    # Versioning
    version = models.PositiveIntegerField(default=1)
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False)

    # Compliance
    fcra_sections = models.JSONField(default=list)  # ["609", "611"]
    disclaimer = models.TextField(blank=True)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['type', 'name']
        indexes = [
            models.Index(fields=['tenant', 'type']),
        ]

    def __str__(self):
        return f"{self.name} (v{self.version})"


class Letter(models.Model):
    """Generated letter for a dispute."""

    TYPE_CHOICES = Dispute.TYPE_CHOICES
    RECIPIENT_TYPE_CHOICES = [
        ('bureau', 'Credit Bureau'),
        ('creditor', 'Creditor'),
        ('collector', 'Collection Agency'),
        ('cfpb', 'CFPB'),
    ]
    MAIL_TYPE_CHOICES = [
        ('first_class', 'First Class'),
        ('certified', 'Certified Mail'),
        ('certified_return_receipt', 'Certified Mail with Return Receipt'),
    ]
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending_approval', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rendering', 'Rendering PDF'),
        ('queued', 'Queued for Mailing'),
        ('sent', 'Sent'),
        ('in_transit', 'In Transit'),
        ('delivered', 'Delivered'),
        ('returned', 'Returned to Sender'),
        ('failed', 'Failed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='letters')
    template = models.ForeignKey(LetterTemplate, on_delete=models.SET_NULL, null=True, blank=True)

    # Letter content
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    subject = models.CharField(max_length=255, blank=True)
    body_html = models.TextField()
    body_text = models.TextField(blank=True)

    # Rendered output
    pdf_url = models.URLField(max_length=500, blank=True)
    pdf_hash = models.CharField(max_length=64, blank=True)
    render_version = models.PositiveIntegerField(default=1)
    rendered_at = models.DateTimeField(null=True, blank=True)

    # Recipient
    recipient_type = models.CharField(max_length=20, choices=RECIPIENT_TYPE_CHOICES)
    recipient_name = models.CharField(max_length=255)
    recipient_address = models.JSONField()  # {line1, line2, city, state, zip}

    # Return address
    return_address = models.JSONField()

    # Lob integration
    lob_id = models.CharField(max_length=100, blank=True)
    lob_url = models.URLField(max_length=500, blank=True)
    mail_type = models.CharField(max_length=50, choices=MAIL_TYPE_CHOICES, null=True, blank=True)
    tracking_number = models.CharField(max_length=100, blank=True)
    carrier = models.CharField(max_length=50, blank=True)

    # Costs
    cost_printing = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    cost_postage = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    cost_total = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    # Workflow
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_letters')
    approved_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    expected_delivery = models.DateField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    returned_at = models.DateTimeField(null=True, blank=True)
    return_reason = models.CharField(max_length=100, blank=True)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_letters')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['dispute']),
            models.Index(fields=['status']),
            models.Index(fields=['lob_id']),
            models.Index(fields=['sent_at']),
        ]

    def __str__(self):
        return f"Letter for {self.dispute.dispute_number}"


class LetterEvent(models.Model):
    """Events/status changes for a letter."""

    EVENT_TYPE_CHOICES = [
        ('created', 'Created'),
        ('rendered', 'PDF Rendered'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('submitted_to_lob', 'Submitted to Lob'),
        ('mailed', 'Mailed'),
        ('in_transit', 'In Transit'),
        ('in_local_area', 'In Local Area'),
        ('processed_for_delivery', 'Processed for Delivery'),
        ('delivered', 'Delivered'),
        ('returned_to_sender', 'Returned to Sender'),
        ('failed', 'Failed'),
    ]
    SOURCE_CHOICES = [
        ('system', 'System'),
        ('lob_webhook', 'Lob Webhook'),
        ('user', 'User Action'),
        ('smartcredit_webhook', 'SmartCredit Webhook'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    letter = models.ForeignKey(Letter, on_delete=models.CASCADE, related_name='events')

    event_type = models.CharField(max_length=50, choices=EVENT_TYPE_CHOICES)
    event_data = models.JSONField(default=dict, blank=True)

    source = models.CharField(max_length=50, choices=SOURCE_CHOICES)
    source_id = models.CharField(max_length=100, blank=True)  # Lob event ID, etc.

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['letter', 'event_type']),
        ]

    def __str__(self):
        return f"{self.letter} - {self.event_type}"


class Evidence(models.Model):
    """Evidence/attachments for a dispute."""

    EVIDENCE_TYPE_CHOICES = [
        ('identity_document', 'Identity Document'),
        ('utility_bill', 'Utility Bill'),
        ('bank_statement', 'Bank Statement'),
        ('payment_receipt', 'Payment Receipt'),
        ('court_document', 'Court Document'),
        ('police_report', 'Police Report'),
        ('ftc_affidavit', 'FTC Identity Theft Affidavit'),
        ('correspondence', 'Correspondence'),
        ('credit_report', 'Credit Report'),
        ('screenshot', 'Screenshot'),
        ('other', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='evidence')

    # File info
    filename = models.CharField(max_length=255)
    original_filename = models.CharField(max_length=255)
    file_url = models.URLField(max_length=500)
    file_size = models.PositiveIntegerField()
    mime_type = models.CharField(max_length=100)

    # Integrity
    checksum_sha256 = models.CharField(max_length=64)
    virus_scanned = models.BooleanField(default=False)
    virus_scan_result = models.CharField(max_length=50, blank=True)

    # Classification
    evidence_type = models.CharField(max_length=50, choices=EVIDENCE_TYPE_CHOICES)
    description = models.TextField(blank=True)
    source = models.CharField(max_length=50, blank=True)  # consumer_upload, smartcredit

    # OCR
    ocr_text = models.TextField(blank=True)
    ocr_processed = models.BooleanField(default=False)

    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-uploaded_at']
        verbose_name_plural = 'Evidence'
        indexes = [
            models.Index(fields=['dispute', 'evidence_type']),
        ]

    def __str__(self):
        return f"{self.filename} ({self.evidence_type})"


class DisputeTask(models.Model):
    """Tasks/reminders for a dispute."""

    TYPE_CHOICES = [
        ('review_letter', 'Review Letter'),
        ('send_letter', 'Send Letter'),
        ('follow_up', 'Follow Up'),
        ('check_response', 'Check Bureau Response'),
        ('reinvestigate', 'Reinvestigation'),
        ('escalate', 'Escalate'),
        ('gather_evidence', 'Gather Evidence'),
        ('contact_consumer', 'Contact Consumer'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='tasks')

    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)

    due_at = models.DateTimeField()
    reminder_at = models.DateTimeField(null=True, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='normal')

    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tasks')

    completed_at = models.DateTimeField(null=True, blank=True)
    completed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='completed_tasks')
    completion_notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['due_at']
        indexes = [
            models.Index(fields=['dispute']),
            models.Index(fields=['assigned_to', 'status']),
            models.Index(fields=['due_at']),
        ]

    def __str__(self):
        return f"{self.title} - {self.dispute.dispute_number}"


class Webhook(models.Model):
    """Incoming webhooks from external services."""

    PROVIDER_CHOICES = [
        ('lob', 'Lob'),
        ('smartcredit', 'SmartCredit'),
        ('stripe', 'Stripe'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('skipped', 'Skipped (Duplicate)'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    provider = models.CharField(max_length=50, choices=PROVIDER_CHOICES)
    event_type = models.CharField(max_length=100)

    payload = models.JSONField()
    headers = models.JSONField(default=dict, blank=True)

    idempotency_key = models.CharField(max_length=255)

    received_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    error_message = models.TextField(blank=True)
    retry_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-received_at']
        indexes = [
            models.Index(fields=['provider', 'idempotency_key']),
            models.Index(fields=['status']),
        ]
        unique_together = [['provider', 'idempotency_key']]

    def __str__(self):
        return f"{self.provider} - {self.event_type}"


# =============================================================================
# LEGACY TICKET MODELS (Keep for backwards compatibility)
# =============================================================================

class Ticket(models.Model):
    """Support ticket for customer service."""

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]

    STATUS_CHOICES = [
        ('new', 'New'),
        ('open', 'Open'),
        ('pending', 'Pending'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    CATEGORY_CHOICES = [
        ('general', 'General Inquiry'),
        ('technical', 'Technical Support'),
        ('billing', 'Billing'),
        ('complaint', 'Complaint'),
        ('feedback', 'Feedback'),
    ]

    ticket_number = models.CharField(max_length=20, unique=True, editable=False)
    subject = models.CharField(max_length=255)
    description = models.TextField()

    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='general')

    customer = models.ForeignKey('customers.Customer', on_delete=models.CASCADE, related_name='tickets')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tickets')
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_tickets')

    due_date = models.DateTimeField(null=True, blank=True)
    first_response_at = models.DateTimeField(null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.ticket_number} - {self.subject}"

    def save(self, *args, **kwargs):
        if not self.ticket_number:
            last_ticket = Ticket.objects.order_by('-id').first()
            if last_ticket:
                last_num = int(last_ticket.ticket_number.replace('TKT-', ''))
                self.ticket_number = f"TKT-{last_num + 1:06d}"
            else:
                self.ticket_number = "TKT-000001"
        super().save(*args, **kwargs)


class TicketComment(models.Model):
    """Comments/replies on a ticket."""

    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='ticket_comments')
    content = models.TextField()
    is_internal = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Comment on {self.ticket.ticket_number}"


class TicketAttachment(models.Model):
    """File attachments for tickets."""

    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='ticket_attachments/')
    filename = models.CharField(max_length=255)
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.filename


# Register models for audit logging
auditlog.register(Dispute)
auditlog.register(Letter)
auditlog.register(LetterEvent)
auditlog.register(Evidence)
auditlog.register(DisputeTask)
auditlog.register(Ticket)
auditlog.register(TicketComment)
