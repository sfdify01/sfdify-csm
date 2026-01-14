from rest_framework import serializers
from django.utils import timezone
from datetime import timedelta

from customers.serializers import ConsumerMinimalSerializer, TradelineListSerializer
from .models import (
    Dispute, LetterTemplate, Letter, LetterEvent, Evidence, DisputeTask
)


# ============== Letter Template Serializers ==============

class LetterTemplateListSerializer(serializers.ModelSerializer):
    """List view for letter templates."""

    class Meta:
        model = LetterTemplate
        fields = [
            'id', 'name', 'slug', 'type', 'description',
            'version', 'is_active', 'is_default', 'fcra_sections'
        ]
        read_only_fields = fields


class LetterTemplateDetailSerializer(serializers.ModelSerializer):
    """Detail view for letter templates with full content."""

    class Meta:
        model = LetterTemplate
        fields = [
            'id', 'name', 'slug', 'type', 'description',
            'subject_template', 'body_html', 'body_text',
            'variables', 'version', 'is_active', 'is_default',
            'fcra_sections', 'disclaimer',
            'created_at', 'updated_at'
        ]
        read_only_fields = fields


# ============== Letter Event Serializers ==============

class LetterEventSerializer(serializers.ModelSerializer):
    """Letter event/tracking data."""

    class Meta:
        model = LetterEvent
        fields = [
            'id', 'event_type', 'event_data', 'source', 'source_id', 'created_at'
        ]
        read_only_fields = fields


# ============== Letter Serializers ==============

class LetterListSerializer(serializers.ModelSerializer):
    """List view for letters."""
    dispute_number = serializers.CharField(source='dispute.dispute_number', read_only=True)

    class Meta:
        model = Letter
        fields = [
            'id', 'dispute_number', 'type', 'subject', 'recipient_type',
            'recipient_name', 'status', 'mail_type',
            'sent_at', 'expected_delivery', 'delivered_at',
            'cost_total', 'created_at'
        ]
        read_only_fields = fields


class LetterDetailSerializer(serializers.ModelSerializer):
    """Detail view for letters with full content and events."""
    dispute_number = serializers.CharField(source='dispute.dispute_number', read_only=True)
    events = LetterEventSerializer(many=True, read_only=True)
    template_name = serializers.CharField(source='template.name', read_only=True, allow_null=True)

    class Meta:
        model = Letter
        fields = [
            'id', 'dispute', 'dispute_number', 'template', 'template_name',
            'type', 'subject', 'body_html', 'body_text',
            'pdf_url', 'pdf_hash', 'render_version', 'rendered_at',
            'recipient_type', 'recipient_name', 'recipient_address',
            'return_address',
            'lob_id', 'lob_url', 'mail_type', 'tracking_number', 'carrier',
            'cost_printing', 'cost_postage', 'cost_total',
            'status', 'approved_by', 'approved_at',
            'sent_at', 'expected_delivery', 'delivered_at',
            'returned_at', 'return_reason',
            'events',
            'created_at', 'updated_at'
        ]
        read_only_fields = fields


class LetterCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new letter."""
    template_id = serializers.UUIDField(required=False, allow_null=True)

    class Meta:
        model = Letter
        fields = [
            'template_id', 'type', 'subject',
            'body_html', 'body_text',
            'recipient_type', 'recipient_name', 'recipient_address',
            'return_address', 'mail_type'
        ]

    def validate_recipient_address(self, value):
        """Validate recipient address structure."""
        required_fields = ['line1', 'city', 'state', 'zip']
        for field in required_fields:
            if field not in value or not value[field]:
                raise serializers.ValidationError(f"Missing required field: {field}")
        return value

    def validate_return_address(self, value):
        """Validate return address structure."""
        required_fields = ['line1', 'city', 'state', 'zip']
        for field in required_fields:
            if field not in value or not value[field]:
                raise serializers.ValidationError(f"Missing required field: {field}")
        return value

    def create(self, validated_data):
        template_id = validated_data.pop('template_id', None)
        if template_id:
            validated_data['template_id'] = template_id
        return super().create(validated_data)


# ============== Evidence Serializers ==============

class EvidenceSerializer(serializers.ModelSerializer):
    """Evidence/attachment serializer."""

    class Meta:
        model = Evidence
        fields = [
            'id', 'filename', 'original_filename', 'file_url',
            'file_size', 'mime_type', 'evidence_type', 'description',
            'source', 'virus_scanned', 'virus_scan_result',
            'uploaded_by', 'uploaded_at'
        ]
        read_only_fields = [
            'id', 'filename', 'file_url', 'file_size', 'mime_type',
            'checksum_sha256', 'virus_scanned', 'virus_scan_result',
            'uploaded_by', 'uploaded_at'
        ]


class EvidenceUploadSerializer(serializers.Serializer):
    """Serializer for evidence upload."""
    file = serializers.FileField()
    evidence_type = serializers.ChoiceField(choices=Evidence.EVIDENCE_TYPE_CHOICES)
    description = serializers.CharField(required=False, allow_blank=True)


# ============== Dispute Task Serializers ==============

class DisputeTaskSerializer(serializers.ModelSerializer):
    """Task serializer."""
    assigned_to_name = serializers.CharField(
        source='assigned_to.get_full_name', read_only=True, allow_null=True
    )

    class Meta:
        model = DisputeTask
        fields = [
            'id', 'type', 'title', 'description',
            'due_at', 'reminder_at', 'status', 'priority',
            'assigned_to', 'assigned_to_name',
            'completed_at', 'completed_by', 'completion_notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'completed_at', 'completed_by', 'created_at', 'updated_at']


class DisputeTaskCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating dispute tasks."""

    class Meta:
        model = DisputeTask
        fields = [
            'type', 'title', 'description',
            'due_at', 'reminder_at', 'priority', 'assigned_to'
        ]


# ============== Dispute Serializers ==============

class DisputeListSerializer(serializers.ModelSerializer):
    """Minimal serializer for dispute list view."""
    consumer_name = serializers.CharField(source='consumer.full_name', read_only=True)
    days_remaining = serializers.SerializerMethodField()
    letters_count = serializers.SerializerMethodField()

    class Meta:
        model = Dispute
        fields = [
            'id', 'dispute_number', 'consumer', 'consumer_name',
            'bureau', 'type', 'status', 'outcome',
            'days_remaining', 'letters_count',
            'created_at', 'submitted_at', 'due_at'
        ]
        read_only_fields = fields

    def get_days_remaining(self, obj):
        """Calculate days remaining until due date."""
        if not obj.due_at:
            return None
        delta = obj.due_at - timezone.now()
        return max(0, delta.days)

    def get_letters_count(self, obj):
        return obj.letters.count()


class DisputeDetailSerializer(serializers.ModelSerializer):
    """Full dispute details for detail view."""
    consumer = ConsumerMinimalSerializer(read_only=True)
    tradeline = TradelineListSerializer(read_only=True)
    letters = LetterListSerializer(many=True, read_only=True)
    evidence = EvidenceSerializer(many=True, read_only=True)
    tasks = DisputeTaskSerializer(many=True, read_only=True)
    days_remaining = serializers.SerializerMethodField()
    assigned_to_name = serializers.CharField(
        source='assigned_to.get_full_name', read_only=True, allow_null=True
    )
    created_by_name = serializers.CharField(
        source='created_by.get_full_name', read_only=True, allow_null=True
    )

    class Meta:
        model = Dispute
        fields = [
            'id', 'dispute_number', 'consumer', 'tradeline', 'bureau',
            'type', 'reason_codes', 'narrative',
            'ai_generated', 'ai_reviewed',
            'status', 'outcome', 'outcome_details', 'bureau_response',
            'created_at', 'submitted_at', 'due_at', 'extended_due_at',
            'responded_at', 'closed_at',
            'days_remaining',
            'created_by', 'created_by_name', 'assigned_to', 'assigned_to_name',
            'letters', 'evidence', 'tasks',
            'updated_at'
        ]
        read_only_fields = fields

    def get_days_remaining(self, obj):
        """Calculate days remaining until due date."""
        if not obj.due_at:
            return None
        delta = obj.due_at - timezone.now()
        return max(0, delta.days)


class DisputeCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new dispute."""

    class Meta:
        model = Dispute
        fields = [
            'consumer', 'tradeline', 'bureau',
            'type', 'reason_codes', 'narrative',
            'assigned_to'
        ]

    def validate(self, attrs):
        """Validate consumer and tradeline ownership."""
        consumer = attrs.get('consumer')
        tradeline = attrs.get('tradeline')
        request = self.context.get('request')

        # Validate consumer belongs to tenant
        if request and hasattr(request, 'tenant'):
            if consumer.tenant != request.tenant:
                raise serializers.ValidationError({
                    'consumer': 'Consumer does not belong to this tenant'
                })

        # Validate tradeline belongs to consumer
        if tradeline and tradeline.consumer != consumer:
            raise serializers.ValidationError({
                'tradeline': 'Tradeline does not belong to this consumer'
            })

        # Validate bureau matches tradeline if provided
        if tradeline and attrs.get('bureau') != tradeline.bureau:
            raise serializers.ValidationError({
                'bureau': f'Bureau must match tradeline bureau ({tradeline.bureau})'
            })

        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        validated_data['created_by'] = request.user if request else None
        return super().create(validated_data)


class DisputeUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating dispute - limited fields."""

    class Meta:
        model = Dispute
        fields = [
            'narrative', 'reason_codes',
            'status', 'outcome', 'outcome_details', 'bureau_response',
            'assigned_to'
        ]

    def validate_status(self, value):
        """Validate status transitions."""
        if self.instance:
            current = self.instance.status
            valid_transitions = {
                'draft': ['pending_review', 'closed'],
                'pending_review': ['approved', 'draft', 'closed'],
                'approved': ['mailed', 'draft', 'closed'],
                'mailed': ['awaiting_response', 'closed'],
                'awaiting_response': ['responded', 'escalated', 'closed'],
                'responded': ['resolved', 'escalated', 'closed'],
                'escalated': ['resolved', 'closed'],
                'resolved': ['closed'],
                'closed': [],  # Cannot transition from closed
            }
            if value != current and value not in valid_transitions.get(current, []):
                raise serializers.ValidationError(
                    f"Invalid status transition from '{current}' to '{value}'"
                )
        return value

    def update(self, instance, validated_data):
        """Handle status-related date updates."""
        new_status = validated_data.get('status')

        if new_status and new_status != instance.status:
            now = timezone.now()

            if new_status == 'mailed' and not instance.submitted_at:
                validated_data['submitted_at'] = now
                # Set 30-day due date per FCRA
                validated_data['due_at'] = now + timedelta(days=30)

            elif new_status == 'responded' and not instance.responded_at:
                validated_data['responded_at'] = now

            elif new_status in ['resolved', 'closed'] and not instance.closed_at:
                validated_data['closed_at'] = now

        return super().update(instance, validated_data)


class DisputeStatusTransitionSerializer(serializers.Serializer):
    """Serializer for status transition action."""
    status = serializers.ChoiceField(choices=Dispute.STATUS_CHOICES)
    notes = serializers.CharField(required=False, allow_blank=True)
