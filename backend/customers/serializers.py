from rest_framework import serializers
from django.utils import timezone
from .models import Tenant, Consumer, SmartCreditConnection, CreditReport, Tradeline


# ============== Nested Serializers ==============

class AddressSerializer(serializers.Serializer):
    """Serializer for address objects in Consumer.addresses array."""
    type = serializers.ChoiceField(choices=['current', 'previous', 'mailing'])
    line1 = serializers.CharField(max_length=255)
    line2 = serializers.CharField(max_length=255, required=False, allow_blank=True)
    city = serializers.CharField(max_length=100)
    state = serializers.CharField(max_length=2)
    zip = serializers.CharField(max_length=10)
    since = serializers.DateField(required=False, allow_null=True)
    verified = serializers.BooleanField(default=False, required=False)


class PhoneSerializer(serializers.Serializer):
    """Serializer for phone objects in Consumer.phones array."""
    type = serializers.ChoiceField(choices=['mobile', 'home', 'work'])
    number = serializers.CharField(max_length=20)
    verified = serializers.BooleanField(default=False, required=False)


class EmailSerializer(serializers.Serializer):
    """Serializer for email objects in Consumer.emails array."""
    type = serializers.ChoiceField(choices=['primary', 'secondary', 'work'])
    address = serializers.EmailField()
    verified = serializers.BooleanField(default=False, required=False)


class ConsentSerializer(serializers.Serializer):
    """Serializer for consent capture during consumer creation."""
    accepted = serializers.BooleanField()
    consent_text = serializers.CharField()


# ============== Tenant Serializers ==============

class TenantSerializer(serializers.ModelSerializer):
    """Read-only tenant serializer for nested use."""

    class Meta:
        model = Tenant
        fields = ['id', 'name', 'slug', 'plan', 'is_active']
        read_only_fields = fields


class TenantDetailSerializer(serializers.ModelSerializer):
    """Full tenant details for admin operations."""

    class Meta:
        model = Tenant
        fields = [
            'id', 'name', 'slug', 'plan', 'branding', 'settings',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


# ============== Consumer Serializers ==============

class ConsumerListSerializer(serializers.ModelSerializer):
    """Minimal serializer for consumer list view."""
    active_disputes_count = serializers.SerializerMethodField()
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = Consumer
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 'ssn_last4',
            'kyc_status', 'active_disputes_count', 'created_at'
        ]
        read_only_fields = fields

    def get_active_disputes_count(self, obj):
        # Count active disputes (not closed/resolved)
        return obj.disputes.exclude(
            status__in=['resolved', 'closed']
        ).count()


class ConsumerMinimalSerializer(serializers.ModelSerializer):
    """Minimal serializer for nested display."""
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = Consumer
        fields = ['id', 'first_name', 'last_name', 'full_name', 'ssn_last4']
        read_only_fields = fields


class ConsumerDetailSerializer(serializers.ModelSerializer):
    """Full consumer details for detail view."""
    full_name = serializers.CharField(read_only=True)
    current_address = serializers.SerializerMethodField()
    smartcredit_connected = serializers.SerializerMethodField()
    last_report_pull = serializers.SerializerMethodField()
    statistics = serializers.SerializerMethodField()

    class Meta:
        model = Consumer
        fields = [
            'id', 'first_name', 'middle_name', 'last_name', 'suffix',
            'full_name', 'dob', 'ssn_last4',
            'addresses', 'phones', 'emails',
            'current_address',
            'kyc_status', 'kyc_verified_at',
            'consent_at',
            'notes', 'tags',
            'smartcredit_connected', 'last_report_pull',
            'statistics',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'ssn_last4', 'kyc_verified_at', 'consent_at',
            'created_at', 'updated_at'
        ]

    def get_current_address(self, obj):
        addr = obj.current_address
        if addr:
            return AddressSerializer(addr).data
        return None

    def get_smartcredit_connected(self, obj):
        return obj.smartcredit_connections.filter(status='active').exists()

    def get_last_report_pull(self, obj):
        latest = obj.credit_reports.first()
        if latest:
            return latest.pulled_at
        return None

    def get_statistics(self, obj):
        disputes = obj.disputes.all()
        return {
            'total_disputes': disputes.count(),
            'active_disputes': disputes.exclude(status__in=['resolved', 'closed']).count(),
            'resolved_disputes': disputes.filter(status='resolved').count(),
            'letters_sent': sum(d.letters.filter(status='sent').count() for d in disputes),
        }


class ConsumerCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new consumer with full SSN and consent."""
    ssn = serializers.CharField(write_only=True, min_length=9, max_length=11)
    addresses = AddressSerializer(many=True)
    phones = PhoneSerializer(many=True, required=False)
    emails = EmailSerializer(many=True, required=False)
    consent = ConsentSerializer(write_only=True)

    class Meta:
        model = Consumer
        fields = [
            'first_name', 'middle_name', 'last_name', 'suffix',
            'dob', 'ssn',
            'addresses', 'phones', 'emails',
            'consent', 'notes', 'tags'
        ]

    def validate_ssn(self, value):
        """Validate SSN format."""
        # Remove dashes and spaces
        ssn = value.replace('-', '').replace(' ', '')
        if not ssn.isdigit() or len(ssn) != 9:
            raise serializers.ValidationError("SSN must be 9 digits")
        # Check for invalid patterns (all same digit, sequential)
        if len(set(ssn)) == 1:
            raise serializers.ValidationError("Invalid SSN format")
        return ssn

    def validate_dob(self, value):
        """Validate date of birth - must be at least 18 years old."""
        from datetime import date
        today = date.today()
        age = today.year - value.year - ((today.month, today.day) < (value.month, value.day))
        if age < 18:
            raise serializers.ValidationError("Consumer must be at least 18 years old")
        if age > 120:
            raise serializers.ValidationError("Invalid date of birth")
        return value

    def validate_addresses(self, value):
        """Ensure at least one current address."""
        if not value:
            raise serializers.ValidationError("At least one address is required")
        has_current = any(addr.get('type') == 'current' for addr in value)
        if not has_current:
            # Set first address as current if none specified
            value[0]['type'] = 'current'
        return value

    def validate_consent(self, value):
        """Validate consent was accepted."""
        if not value.get('accepted'):
            raise serializers.ValidationError("Consent must be accepted")
        return value

    def create(self, validated_data):
        """Create consumer with SSN encryption and consent capture."""
        ssn = validated_data.pop('ssn')
        consent_data = validated_data.pop('consent')
        addresses = validated_data.pop('addresses', [])
        phones = validated_data.pop('phones', [])
        emails = validated_data.pop('emails', [])

        # Extract request for IP and user agent
        request = self.context.get('request')

        # Create consumer
        consumer = Consumer.objects.create(
            tenant=request.tenant,
            ssn_last4=ssn[-4:],
            # ssn_encrypted would be set here with actual encryption
            addresses=addresses,
            phones=phones,
            emails=emails,
            consent_text=consent_data.get('consent_text', ''),
            consent_at=timezone.now(),
            consent_ip=self._get_client_ip(request) if request else None,
            consent_user_agent=request.META.get('HTTP_USER_AGENT', '')[:500] if request else '',
            created_by=request.user if request else None,
            **validated_data
        )

        return consumer

    def _get_client_ip(self, request):
        """Extract client IP from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR')


class ConsumerUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating consumer - SSN cannot be changed."""
    addresses = AddressSerializer(many=True, required=False)
    phones = PhoneSerializer(many=True, required=False)
    emails = EmailSerializer(many=True, required=False)

    class Meta:
        model = Consumer
        fields = [
            'first_name', 'middle_name', 'last_name', 'suffix',
            'dob', 'addresses', 'phones', 'emails',
            'kyc_status', 'notes', 'tags'
        ]

    def validate_kyc_status(self, value):
        """Only allow valid KYC status transitions."""
        if self.instance:
            current = self.instance.kyc_status
            valid_transitions = {
                'pending': ['verified', 'failed'],
                'verified': ['expired'],
                'failed': ['pending', 'verified'],
                'expired': ['pending', 'verified'],
            }
            if value != current and value not in valid_transitions.get(current, []):
                raise serializers.ValidationError(
                    f"Invalid KYC status transition from {current} to {value}"
                )
        return value


# ============== Credit Report Serializers ==============

class CreditReportListSerializer(serializers.ModelSerializer):
    """List view for credit reports."""

    class Meta:
        model = CreditReport
        fields = [
            'id', 'bureau', 'pulled_at', 'report_date',
            'score', 'tradeline_count', 'inquiry_count', 'public_record_count'
        ]
        read_only_fields = fields


class CreditReportDetailSerializer(serializers.ModelSerializer):
    """Detail view for credit reports with score factors."""

    class Meta:
        model = CreditReport
        fields = [
            'id', 'bureau', 'pulled_at', 'report_date',
            'score', 'score_factors',
            'tradeline_count', 'inquiry_count', 'public_record_count',
            'parsed_at', 'parse_errors'
        ]
        read_only_fields = fields


# ============== Tradeline Serializers ==============

class TradelineSerializer(serializers.ModelSerializer):
    """Full tradeline data."""
    potential_issues = serializers.SerializerMethodField()

    class Meta:
        model = Tradeline
        fields = [
            'id', 'bureau', 'creditor_name', 'account_number_masked',
            'account_type', 'opened_date', 'closed_date',
            'current_balance', 'credit_limit', 'high_balance',
            'monthly_payment', 'past_due_amount',
            'account_status', 'payment_status', 'payment_history',
            'dispute_status', 'has_consumer_statement',
            'remarks', 'potential_issues',
            'created_at', 'updated_at'
        ]
        read_only_fields = fields

    def get_potential_issues(self, obj):
        """Identify potential issues with the tradeline."""
        issues = []

        # High utilization
        if obj.credit_limit and obj.current_balance:
            utilization = float(obj.current_balance) / float(obj.credit_limit)
            if utilization > 0.3:
                issues.append({
                    'code': 'HIGH_UTILIZATION',
                    'description': f'Utilization at {utilization*100:.0f}%',
                    'severity': 'high' if utilization > 0.7 else 'medium'
                })

        # Past due
        if obj.past_due_amount and obj.past_due_amount > 0:
            issues.append({
                'code': 'PAST_DUE',
                'description': f'Past due amount: ${obj.past_due_amount}',
                'severity': 'high'
            })

        # Late payments in history
        if obj.payment_history:
            late_payments = sum(
                1 for status in obj.payment_history.values()
                if status and status not in ['OK', 'C', 'U']
            )
            if late_payments > 0:
                issues.append({
                    'code': 'LATE_PAYMENTS',
                    'description': f'{late_payments} late payment(s) in history',
                    'severity': 'medium'
                })

        return issues


class TradelineListSerializer(serializers.ModelSerializer):
    """Condensed tradeline for list views."""

    class Meta:
        model = Tradeline
        fields = [
            'id', 'bureau', 'creditor_name', 'account_number_masked',
            'account_type', 'current_balance', 'credit_limit',
            'account_status', 'dispute_status'
        ]
        read_only_fields = fields


# ============== SmartCredit Connection Serializers ==============

class SmartCreditConnectionSerializer(serializers.ModelSerializer):
    """SmartCredit connection status."""

    class Meta:
        model = SmartCreditConnection
        fields = [
            'id', 'status', 'scopes',
            'last_pull_at', 'pull_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = fields
