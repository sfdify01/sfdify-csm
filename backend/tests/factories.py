"""
Model factories for testing.
"""
import factory
from factory.django import DjangoModelFactory
from django.contrib.auth import get_user_model
from datetime import date, timedelta
from decimal import Decimal
import uuid

User = get_user_model()


class UserFactory(DjangoModelFactory):
    """Factory for User model."""

    class Meta:
        model = User

    username = factory.Sequence(lambda n: f'user{n}')
    email = factory.LazyAttribute(lambda obj: f'{obj.username}@example.com')
    password = factory.PostGenerationMethodCall('set_password', 'testpass123')
    first_name = factory.Faker('first_name')
    last_name = factory.Faker('last_name')
    is_active = True


class TenantFactory(DjangoModelFactory):
    """Factory for Tenant model."""

    class Meta:
        model = 'customers.Tenant'

    name = factory.Sequence(lambda n: f'Test Company {n}')
    slug = factory.LazyAttribute(lambda obj: obj.name.lower().replace(' ', '-'))
    plan = 'professional'
    is_active = True


class ConsumerFactory(DjangoModelFactory):
    """Factory for Consumer model."""

    class Meta:
        model = 'customers.Consumer'

    tenant = factory.SubFactory(TenantFactory)
    first_name = factory.Faker('first_name')
    last_name = factory.Faker('last_name')
    dob = factory.LazyFunction(lambda: date.today() - timedelta(days=365*30))
    ssn_last4 = factory.Sequence(lambda n: f'{n:04d}'[-4:])
    addresses = factory.LazyFunction(lambda: [{
        'type': 'current',
        'line1': '123 Main St',
        'city': 'Anytown',
        'state': 'CA',
        'zip': '90210'
    }])
    phones = factory.LazyFunction(lambda: [{
        'type': 'mobile',
        'number': '555-123-4567'
    }])
    emails = factory.LazyAttribute(lambda obj: [{
        'type': 'primary',
        'address': f'{obj.first_name.lower()}.{obj.last_name.lower()}@example.com'
    }])
    kyc_status = 'pending'
    created_by = factory.SubFactory(UserFactory)


class TradelineFactory(DjangoModelFactory):
    """Factory for Tradeline model."""

    class Meta:
        model = 'customers.Tradeline'

    consumer = factory.SubFactory(ConsumerFactory)
    bureau = factory.Iterator(['equifax', 'experian', 'transunion'])
    creditor_name = factory.Faker('company')
    account_number_masked = factory.Sequence(lambda n: f'XXXX-XXXX-{n:04d}')
    account_type = 'credit_card'
    opened_date = factory.LazyFunction(lambda: date.today() - timedelta(days=365))
    current_balance = factory.LazyFunction(lambda: Decimal('1500.00'))
    credit_limit = factory.LazyFunction(lambda: Decimal('5000.00'))
    account_status = 'open'
    payment_status = 'current'
    dispute_status = 'none'


class CreditReportFactory(DjangoModelFactory):
    """Factory for CreditReport model."""

    class Meta:
        model = 'customers.CreditReport'

    consumer = factory.SubFactory(ConsumerFactory)
    bureau = factory.Iterator(['equifax', 'experian', 'transunion'])
    score = factory.LazyFunction(lambda: 720)
    tradeline_count = 5
    inquiry_count = 2
    public_record_count = 0


class DisputeFactory(DjangoModelFactory):
    """Factory for Dispute model."""

    class Meta:
        model = 'tickets.Dispute'

    consumer = factory.SubFactory(ConsumerFactory)
    tradeline = factory.SubFactory(TradelineFactory)
    bureau = factory.LazyAttribute(lambda obj: obj.tradeline.bureau if obj.tradeline else 'equifax')
    type = 'fcra_611_accuracy'
    reason_codes = factory.LazyFunction(lambda: ['INACCURATE_BALANCE'])
    narrative = factory.Faker('paragraph')
    status = 'draft'
    created_by = factory.SubFactory(UserFactory)


class LetterTemplateFactory(DjangoModelFactory):
    """Factory for LetterTemplate model."""

    class Meta:
        model = 'tickets.LetterTemplate'

    tenant = factory.SubFactory(TenantFactory)
    name = factory.Sequence(lambda n: f'Template {n}')
    slug = factory.LazyAttribute(lambda obj: obj.name.lower().replace(' ', '-'))
    type = 'fcra_611_accuracy'
    description = factory.Faker('sentence')
    body_html = '<p>{{ consumer.full_name }}</p><p>{{ dispute.narrative }}</p>'
    is_active = True


class LetterFactory(DjangoModelFactory):
    """Factory for Letter model."""

    class Meta:
        model = 'tickets.Letter'

    dispute = factory.SubFactory(DisputeFactory)
    template = factory.SubFactory(LetterTemplateFactory)
    type = factory.LazyAttribute(lambda obj: obj.dispute.type if obj.dispute else 'fcra_611_accuracy')
    subject = 'Credit Dispute Letter'
    body_html = '<p>Test letter content</p>'
    recipient_type = 'bureau'
    recipient_name = 'Equifax'
    recipient_address = factory.LazyFunction(lambda: {
        'line1': 'P.O. Box 740256',
        'city': 'Atlanta',
        'state': 'GA',
        'zip': '30374-0256'
    })
    return_address = factory.LazyFunction(lambda: {
        'line1': '123 Main St',
        'city': 'Anytown',
        'state': 'CA',
        'zip': '90210'
    })
    status = 'draft'
    created_by = factory.SubFactory(UserFactory)


class EvidenceFactory(DjangoModelFactory):
    """Factory for Evidence model."""

    class Meta:
        model = 'tickets.Evidence'

    dispute = factory.SubFactory(DisputeFactory)
    filename = factory.Sequence(lambda n: f'evidence_{n}.pdf')
    original_filename = factory.LazyAttribute(lambda obj: obj.filename)
    file_url = factory.LazyAttribute(lambda obj: f'https://s3.example.com/evidence/{obj.filename}')
    file_size = 1024
    mime_type = 'application/pdf'
    checksum_sha256 = factory.LazyFunction(lambda: 'a' * 64)
    evidence_type = 'correspondence'
    uploaded_by = factory.SubFactory(UserFactory)


class DisputeTaskFactory(DjangoModelFactory):
    """Factory for DisputeTask model."""

    class Meta:
        model = 'tickets.DisputeTask'

    dispute = factory.SubFactory(DisputeFactory)
    type = 'follow_up'
    title = factory.Faker('sentence')
    description = factory.Faker('paragraph')
    due_at = factory.LazyFunction(lambda: date.today() + timedelta(days=7))
    priority = 'normal'
    status = 'pending'
