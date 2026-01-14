"""
Pytest configuration and fixtures for SFDIFY SCM tests.
"""
import pytest
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


@pytest.fixture
def api_client():
    """Return an API client instance."""
    return APIClient()


@pytest.fixture
def user(db):
    """Create a test user."""
    return User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )


@pytest.fixture
def admin_user(db):
    """Create an admin user."""
    return User.objects.create_superuser(
        username='admin',
        email='admin@example.com',
        password='adminpass123',
        first_name='Admin',
        last_name='User'
    )


@pytest.fixture
def authenticated_client(api_client, user):
    """Return an authenticated API client."""
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client


@pytest.fixture
def admin_client(api_client, admin_user):
    """Return an admin authenticated API client."""
    refresh = RefreshToken.for_user(admin_user)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client


@pytest.fixture
def tenant(db):
    """Create a test tenant."""
    from customers.models import Tenant
    return Tenant.objects.create(
        name='Test Company',
        slug='test-company',
        plan='professional',
        is_active=True
    )


@pytest.fixture
def consumer(db, tenant, user):
    """Create a test consumer."""
    from customers.models import Consumer
    from datetime import date
    return Consumer.objects.create(
        tenant=tenant,
        first_name='John',
        last_name='Doe',
        dob=date(1985, 5, 15),
        ssn_last4='1234',
        addresses=[{
            'type': 'current',
            'line1': '123 Main St',
            'city': 'Anytown',
            'state': 'CA',
            'zip': '90210'
        }],
        phones=[{
            'type': 'mobile',
            'number': '555-123-4567'
        }],
        emails=[{
            'type': 'primary',
            'address': 'john.doe@example.com'
        }],
        created_by=user
    )


@pytest.fixture
def tradeline(db, consumer):
    """Create a test tradeline."""
    from customers.models import Tradeline
    from datetime import date
    from decimal import Decimal
    return Tradeline.objects.create(
        consumer=consumer,
        bureau='equifax',
        creditor_name='Test Bank',
        account_number_masked='XXXX-XXXX-1234',
        account_type='credit_card',
        opened_date=date(2020, 1, 1),
        current_balance=Decimal('1500.00'),
        credit_limit=Decimal('5000.00'),
        account_status='open',
        dispute_status='none'
    )


@pytest.fixture
def dispute(db, consumer, tradeline, user):
    """Create a test dispute."""
    from tickets.models import Dispute
    return Dispute.objects.create(
        consumer=consumer,
        tradeline=tradeline,
        bureau='equifax',
        type='fcra_611_accuracy',
        reason_codes=['INACCURATE_BALANCE'],
        narrative='The reported balance is incorrect.',
        status='draft',
        created_by=user
    )


@pytest.fixture
def letter_template(db, tenant):
    """Create a test letter template."""
    from tickets.models import LetterTemplate
    return LetterTemplate.objects.create(
        tenant=tenant,
        name='Test FCRA 611 Template',
        slug='test-fcra-611',
        type='fcra_611_accuracy',
        description='Test template for FCRA 611 disputes',
        body_html='<p>Dear {{ recipient.name }},</p><p>{{ dispute.narrative }}</p>',
        variables=[
            {'name': 'recipient.name', 'required': True},
            {'name': 'dispute.narrative', 'required': True}
        ],
        is_active=True
    )


@pytest.fixture
def letter(db, dispute, letter_template, user):
    """Create a test letter."""
    from tickets.models import Letter
    return Letter.objects.create(
        dispute=dispute,
        template=letter_template,
        type='fcra_611_accuracy',
        subject='Credit Dispute',
        body_html='<p>Test letter content</p>',
        recipient_type='bureau',
        recipient_name='Equifax',
        recipient_address={
            'line1': 'P.O. Box 740256',
            'city': 'Atlanta',
            'state': 'GA',
            'zip': '30374-0256'
        },
        return_address={
            'line1': '123 Main St',
            'city': 'Anytown',
            'state': 'CA',
            'zip': '90210'
        },
        status='draft',
        created_by=user
    )


@pytest.fixture
def tenant_client(authenticated_client, tenant):
    """Return an authenticated client with tenant header."""
    authenticated_client.credentials(
        HTTP_AUTHORIZATION=authenticated_client._credentials.get('HTTP_AUTHORIZATION', ''),
        HTTP_X_TENANT_ID=str(tenant.id)
    )
    return authenticated_client
