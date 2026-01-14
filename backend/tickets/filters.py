import django_filters
from django.db.models import Q
from django.utils import timezone
from .models import Dispute, Letter, LetterTemplate, Evidence, DisputeTask


class DisputeFilterSet(django_filters.FilterSet):
    """Filter set for Dispute queryset."""

    # Text search
    search = django_filters.CharFilter(method='filter_search')

    # Consumer filter
    consumer_id = django_filters.UUIDFilter(field_name='consumer_id')

    # Date filters
    created_after = django_filters.DateFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateFilter(field_name='created_at', lookup_expr='lte')
    submitted_after = django_filters.DateFilter(field_name='submitted_at', lookup_expr='gte')
    submitted_before = django_filters.DateFilter(field_name='submitted_at', lookup_expr='lte')

    # Due date filters
    due_before = django_filters.DateFilter(field_name='due_at', lookup_expr='lte')
    overdue = django_filters.BooleanFilter(method='filter_overdue')

    # Assignment
    assigned_to = django_filters.UUIDFilter(field_name='assigned_to_id')
    unassigned = django_filters.BooleanFilter(method='filter_unassigned')

    # Outcome filters
    has_outcome = django_filters.BooleanFilter(method='filter_has_outcome')

    class Meta:
        model = Dispute
        fields = {
            'bureau': ['exact', 'in'],
            'type': ['exact', 'in'],
            'status': ['exact', 'in'],
            'outcome': ['exact', 'in'],
        }

    def filter_search(self, queryset, name, value):
        """Search by dispute number, consumer name, or narrative."""
        if not value:
            return queryset
        return queryset.filter(
            Q(dispute_number__icontains=value) |
            Q(consumer__first_name__icontains=value) |
            Q(consumer__last_name__icontains=value) |
            Q(narrative__icontains=value)
        )

    def filter_overdue(self, queryset, name, value):
        """Filter overdue disputes."""
        now = timezone.now()
        if value is True:
            return queryset.filter(
                due_at__lt=now,
                status__in=['mailed', 'awaiting_response']
            )
        elif value is False:
            return queryset.exclude(
                due_at__lt=now,
                status__in=['mailed', 'awaiting_response']
            )
        return queryset

    def filter_unassigned(self, queryset, name, value):
        """Filter unassigned disputes."""
        if value is True:
            return queryset.filter(assigned_to__isnull=True)
        elif value is False:
            return queryset.filter(assigned_to__isnull=False)
        return queryset

    def filter_has_outcome(self, queryset, name, value):
        """Filter disputes with/without outcome."""
        if value is True:
            return queryset.exclude(outcome__isnull=True).exclude(outcome='')
        elif value is False:
            return queryset.filter(Q(outcome__isnull=True) | Q(outcome=''))
        return queryset


class LetterFilterSet(django_filters.FilterSet):
    """Filter set for Letter queryset."""

    # Dispute filter
    dispute_id = django_filters.UUIDFilter(field_name='dispute_id')

    # Date filters
    sent_after = django_filters.DateFilter(field_name='sent_at', lookup_expr='gte')
    sent_before = django_filters.DateFilter(field_name='sent_at', lookup_expr='lte')
    delivered_after = django_filters.DateFilter(field_name='delivered_at', lookup_expr='gte')
    delivered_before = django_filters.DateFilter(field_name='delivered_at', lookup_expr='lte')

    # Cost filters
    min_cost = django_filters.NumberFilter(field_name='cost_total', lookup_expr='gte')
    max_cost = django_filters.NumberFilter(field_name='cost_total', lookup_expr='lte')

    class Meta:
        model = Letter
        fields = {
            'type': ['exact', 'in'],
            'status': ['exact', 'in'],
            'recipient_type': ['exact', 'in'],
            'mail_type': ['exact', 'in'],
        }


class LetterTemplateFilterSet(django_filters.FilterSet):
    """Filter set for LetterTemplate queryset."""

    # Search
    search = django_filters.CharFilter(method='filter_search')

    class Meta:
        model = LetterTemplate
        fields = {
            'type': ['exact', 'in'],
            'is_active': ['exact'],
            'is_default': ['exact'],
        }

    def filter_search(self, queryset, name, value):
        """Search by name or description."""
        if not value:
            return queryset
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value)
        )


class EvidenceFilterSet(django_filters.FilterSet):
    """Filter set for Evidence queryset."""

    # Dispute filter
    dispute_id = django_filters.UUIDFilter(field_name='dispute_id')

    # Date filters
    uploaded_after = django_filters.DateFilter(field_name='uploaded_at', lookup_expr='gte')
    uploaded_before = django_filters.DateFilter(field_name='uploaded_at', lookup_expr='lte')

    class Meta:
        model = Evidence
        fields = {
            'evidence_type': ['exact', 'in'],
            'virus_scanned': ['exact'],
        }


class DisputeTaskFilterSet(django_filters.FilterSet):
    """Filter set for DisputeTask queryset."""

    # Dispute filter
    dispute_id = django_filters.UUIDFilter(field_name='dispute_id')

    # Assignment
    assigned_to = django_filters.UUIDFilter(field_name='assigned_to_id')
    unassigned = django_filters.BooleanFilter(method='filter_unassigned')

    # Date filters
    due_before = django_filters.DateFilter(field_name='due_at', lookup_expr='lte')
    due_after = django_filters.DateFilter(field_name='due_at', lookup_expr='gte')
    overdue = django_filters.BooleanFilter(method='filter_overdue')

    class Meta:
        model = DisputeTask
        fields = {
            'type': ['exact', 'in'],
            'status': ['exact', 'in'],
            'priority': ['exact', 'in'],
        }

    def filter_unassigned(self, queryset, name, value):
        """Filter unassigned tasks."""
        if value is True:
            return queryset.filter(assigned_to__isnull=True)
        elif value is False:
            return queryset.filter(assigned_to__isnull=False)
        return queryset

    def filter_overdue(self, queryset, name, value):
        """Filter overdue tasks."""
        now = timezone.now()
        if value is True:
            return queryset.filter(
                due_at__lt=now,
                status__in=['pending', 'in_progress']
            )
        elif value is False:
            return queryset.exclude(
                due_at__lt=now,
                status__in=['pending', 'in_progress']
            )
        return queryset
