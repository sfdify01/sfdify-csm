"""
Integration tests for Consumer API.
"""
import pytest
from django.urls import reverse
from rest_framework import status


@pytest.mark.django_db
class TestConsumerListAPI:
    """Tests for consumer list endpoint."""

    def test_list_consumers_unauthenticated(self, api_client):
        """Test that unauthenticated access is denied."""
        response = api_client.get('/api/v1/consumers/')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_consumers_authenticated(self, tenant_client, consumer):
        """Test listing consumers with authentication."""
        response = tenant_client.get('/api/v1/consumers/')
        assert response.status_code == status.HTTP_200_OK
        # Should include the consumer we created
        assert response.data['count'] >= 1

    def test_list_consumers_filters(self, tenant_client, consumer):
        """Test filtering consumers."""
        response = tenant_client.get(
            '/api/v1/consumers/',
            {'search': consumer.first_name}
        )
        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestConsumerDetailAPI:
    """Tests for consumer detail endpoint."""

    def test_get_consumer_detail(self, tenant_client, consumer):
        """Test getting consumer details."""
        response = tenant_client.get(f'/api/v1/consumers/{consumer.id}/')
        assert response.status_code == status.HTTP_200_OK
        assert response.data['first_name'] == consumer.first_name
        assert response.data['last_name'] == consumer.last_name
        # SSN should be masked to last 4
        assert response.data['ssn_last4'] == consumer.ssn_last4

    def test_get_consumer_not_found(self, tenant_client):
        """Test getting non-existent consumer."""
        import uuid
        response = tenant_client.get(f'/api/v1/consumers/{uuid.uuid4()}/')
        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
class TestConsumerCreateAPI:
    """Tests for consumer creation endpoint."""

    def test_create_consumer_success(self, tenant_client, tenant, user):
        """Test creating a consumer."""
        data = {
            'first_name': 'Jane',
            'last_name': 'Smith',
            'dob': '1990-01-15',
            'ssn': '123-45-6789',
            'addresses': [{
                'type': 'current',
                'line1': '456 Oak Ave',
                'city': 'Springfield',
                'state': 'IL',
                'zip': '62701'
            }],
            'consent': {
                'accepted': True,
                'consent_text': 'I consent to credit pulls.'
            }
        }
        response = tenant_client.post('/api/v1/consumers/', data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data['first_name'] == 'Jane'
        assert response.data['ssn_last4'] == '6789'

    def test_create_consumer_invalid_ssn(self, tenant_client, tenant):
        """Test creating consumer with invalid SSN."""
        data = {
            'first_name': 'Jane',
            'last_name': 'Smith',
            'dob': '1990-01-15',
            'ssn': '000-00-0000',
            'addresses': [{
                'type': 'current',
                'line1': '456 Oak Ave',
                'city': 'Springfield',
                'state': 'IL',
                'zip': '62701'
            }],
            'consent': {
                'accepted': True,
                'consent_text': 'I consent.'
            }
        }
        response = tenant_client.post('/api/v1/consumers/', data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_consumer_no_consent(self, tenant_client, tenant):
        """Test creating consumer without consent."""
        data = {
            'first_name': 'Jane',
            'last_name': 'Smith',
            'dob': '1990-01-15',
            'ssn': '123-45-6789',
            'addresses': [{
                'type': 'current',
                'line1': '456 Oak Ave',
                'city': 'Springfield',
                'state': 'IL',
                'zip': '62701'
            }],
            'consent': {
                'accepted': False,
                'consent_text': 'I do not consent.'
            }
        }
        response = tenant_client.post('/api/v1/consumers/', data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestConsumerUpdateAPI:
    """Tests for consumer update endpoint."""

    def test_update_consumer_partial(self, tenant_client, consumer):
        """Test partial update of consumer."""
        data = {
            'first_name': 'Johnny'
        }
        response = tenant_client.patch(
            f'/api/v1/consumers/{consumer.id}/',
            data,
            format='json'
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data['first_name'] == 'Johnny'

    def test_update_consumer_kyc_status(self, tenant_client, consumer):
        """Test updating KYC status."""
        data = {
            'kyc_status': 'verified'
        }
        response = tenant_client.patch(
            f'/api/v1/consumers/{consumer.id}/',
            data,
            format='json'
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data['kyc_status'] == 'verified'
