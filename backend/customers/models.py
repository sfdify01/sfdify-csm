import uuid
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinLengthValidator
from auditlog.registry import auditlog

User = get_user_model()


class Tenant(models.Model):
    """Multi-tenant organization."""

    PLAN_CHOICES = [
        ('starter', 'Starter'),
        ('professional', 'Professional'),
        ('enterprise', 'Enterprise'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=100, unique=True)
    plan = models.CharField(max_length=50, choices=PLAN_CHOICES, default='starter')

    # Branding (JSON: logo_url, primary_color, letterhead_url, return_address)
    branding = models.JSONField(default=dict, blank=True)

    # Settings (JSON: notification preferences, defaults, etc.)
    settings = models.JSONField(default=dict, blank=True)

    # Integration configs (encrypted in production)
    smartcredit_config = models.JSONField(default=dict, blank=True)
    lob_config = models.JSONField(default=dict, blank=True)

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class Consumer(models.Model):
    """Consumer profile for credit dispute (replaces basic Customer)."""

    KYC_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('failed', 'Failed'),
        ('expired', 'Expired'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='consumers')

    # Identity
    first_name = models.CharField(max_length=100)
    middle_name = models.CharField(max_length=100, blank=True)
    last_name = models.CharField(max_length=100)
    suffix = models.CharField(max_length=20, blank=True)
    dob = models.DateField(verbose_name='Date of Birth')

    # SSN - encrypted in production (use django-encrypted-model-fields)
    ssn_encrypted = models.BinaryField(null=True, blank=True, editable=False)
    ssn_last4 = models.CharField(max_length=4, validators=[MinLengthValidator(4)])

    # Contact info (JSON arrays)
    addresses = models.JSONField(default=list)  # [{type, line1, line2, city, state, zip, since}]
    phones = models.JSONField(default=list)  # [{type, number, verified}]
    emails = models.JSONField(default=list)  # [{type, address, verified}]

    # KYC
    kyc_status = models.CharField(max_length=20, choices=KYC_STATUS_CHOICES, default='pending')
    kyc_verified_at = models.DateTimeField(null=True, blank=True)

    # Consent
    consent_text = models.TextField(blank=True)
    consent_at = models.DateTimeField(null=True, blank=True)
    consent_ip = models.GenericIPAddressField(null=True, blank=True)
    consent_user_agent = models.TextField(blank=True)

    # Metadata
    notes = models.TextField(blank=True)
    tags = models.JSONField(default=list)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_consumers')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tenant', 'ssn_last4']),
            models.Index(fields=['tenant', 'last_name', 'first_name']),
            models.Index(fields=['tenant', 'kyc_status']),
        ]

    def __str__(self):
        return f"{self.first_name} {self.last_name} (***{self.ssn_last4})"

    @property
    def full_name(self):
        parts = [self.first_name, self.middle_name, self.last_name, self.suffix]
        return ' '.join(p for p in parts if p)

    @property
    def current_address(self):
        for addr in self.addresses:
            if addr.get('type') == 'current':
                return addr
        return self.addresses[0] if self.addresses else None


class SmartCreditConnection(models.Model):
    """OAuth connection to SmartCredit for a consumer."""

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('revoked', 'Revoked'),
        ('error', 'Error'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    consumer = models.ForeignKey(Consumer, on_delete=models.CASCADE, related_name='smartcredit_connections')

    # OAuth tokens (encrypted in production)
    access_token = models.BinaryField()
    refresh_token = models.BinaryField(null=True, blank=True)
    token_expires_at = models.DateTimeField()

    # Scopes granted
    scopes = models.JSONField(default=list)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')

    # SmartCredit identifiers
    sc_user_id = models.CharField(max_length=100, blank=True)
    sc_subscription_id = models.CharField(max_length=100, blank=True)

    # Usage tracking
    last_pull_at = models.DateTimeField(null=True, blank=True)
    pull_count = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['consumer', 'status']),
        ]

    def __str__(self):
        return f"SmartCredit for {self.consumer} ({self.status})"


class CreditReport(models.Model):
    """Credit report pulled from SmartCredit."""

    BUREAU_CHOICES = [
        ('equifax', 'Equifax'),
        ('experian', 'Experian'),
        ('transunion', 'TransUnion'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    consumer = models.ForeignKey(Consumer, on_delete=models.CASCADE, related_name='credit_reports')
    connection = models.ForeignKey(SmartCreditConnection, on_delete=models.SET_NULL, null=True, blank=True)

    # Report metadata
    pulled_at = models.DateTimeField(auto_now_add=True)
    bureau = models.CharField(max_length=20, choices=BUREAU_CHOICES)
    report_date = models.DateField(null=True, blank=True)

    # Raw data (encrypted at rest)
    raw_json = models.JSONField()
    raw_json_hash = models.CharField(max_length=64)  # SHA-256

    # Parsed summary
    score = models.PositiveIntegerField(null=True, blank=True)
    score_factors = models.JSONField(default=list)
    tradeline_count = models.PositiveIntegerField(default=0)
    inquiry_count = models.PositiveIntegerField(default=0)
    public_record_count = models.PositiveIntegerField(default=0)

    # Processing
    parsed_at = models.DateTimeField(null=True, blank=True)
    parse_errors = models.JSONField(default=list)

    class Meta:
        ordering = ['-pulled_at']
        indexes = [
            models.Index(fields=['consumer', 'bureau']),
            models.Index(fields=['consumer', 'pulled_at']),
        ]

    def __str__(self):
        return f"{self.consumer} - {self.bureau} ({self.pulled_at.date()})"


class Tradeline(models.Model):
    """Individual tradeline from a credit report."""

    BUREAU_CHOICES = CreditReport.BUREAU_CHOICES
    DISPUTE_STATUS_CHOICES = [
        ('none', 'No Dispute'),
        ('in_dispute', 'In Dispute'),
        ('resolved', 'Resolved'),
        ('verified', 'Verified as Accurate'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report = models.ForeignKey(CreditReport, on_delete=models.CASCADE, related_name='tradelines')
    consumer = models.ForeignKey(Consumer, on_delete=models.CASCADE, related_name='tradelines')

    # Bureau identification
    bureau = models.CharField(max_length=20, choices=BUREAU_CHOICES)
    bureau_item_id = models.CharField(max_length=100, blank=True)

    # Creditor info
    creditor_name = models.CharField(max_length=255)
    creditor_address = models.JSONField(default=dict, blank=True)
    account_number_masked = models.CharField(max_length=50, blank=True)
    account_type = models.CharField(max_length=50, blank=True)

    # Dates
    opened_date = models.DateField(null=True, blank=True)
    closed_date = models.DateField(null=True, blank=True)
    last_activity_date = models.DateField(null=True, blank=True)

    # Financial
    original_balance = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    current_balance = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    credit_limit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    high_balance = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    monthly_payment = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    past_due_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    # Status
    account_status = models.CharField(max_length=50, blank=True)
    payment_status = models.CharField(max_length=50, blank=True)
    payment_history = models.JSONField(default=dict)  # {"2024-01": "OK", "2023-12": "30"}

    # Dispute tracking
    dispute_status = models.CharField(max_length=20, choices=DISPUTE_STATUS_CHOICES, default='none')
    has_consumer_statement = models.BooleanField(default=False)

    # Remarks
    remarks = models.JSONField(default=list)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['consumer', 'bureau']),
            models.Index(fields=['consumer', 'creditor_name']),
            models.Index(fields=['consumer', 'dispute_status']),
        ]

    def __str__(self):
        return f"{self.creditor_name} - {self.account_number_masked}"


# Keep legacy Customer for backwards compatibility (can remove later)
class Customer(models.Model):
    """Legacy Customer model - use Consumer for new features."""

    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=50, blank=True)
    company = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_customers')

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.email})"


class CustomerInteraction(models.Model):
    """Log of interactions with a customer."""

    CHANNEL_CHOICES = [
        ('email', 'Email'),
        ('phone', 'Phone'),
        ('chat', 'Chat'),
        ('portal', 'Portal'),
        ('social', 'Social Media'),
    ]

    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='interactions')
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES)
    subject = models.CharField(max_length=255)
    content = models.TextField()
    agent = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='handled_interactions')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.name} - {self.subject}"


# Register models for audit logging
auditlog.register(Tenant)
auditlog.register(Consumer)
auditlog.register(CreditReport)
auditlog.register(Tradeline)
auditlog.register(Customer)
auditlog.register(CustomerInteraction)
