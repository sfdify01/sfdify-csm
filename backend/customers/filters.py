import django_filters
from django.db import models
from .models import Consumer, CreditReport, Tradeline


class ConsumerFilterSet(django_filters.FilterSet):
    """Filter set for Consumer queryset."""

    # Text search
    search = django_filters.CharFilter(method='filter_search')

    # Date filters
    created_after = django_filters.DateFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateFilter(field_name='created_at', lookup_expr='lte')

    # Has SmartCredit connection
    smartcredit_connected = django_filters.BooleanFilter(method='filter_smartcredit')

    # Has active disputes
    has_active_disputes = django_filters.BooleanFilter(method='filter_active_disputes')

    class Meta:
        model = Consumer
        fields = {
            'kyc_status': ['exact', 'in'],
            'ssn_last4': ['exact'],
        }

    def filter_search(self, queryset, name, value):
        """Search by name, SSN last 4, or email."""
        if not value:
            return queryset

        return queryset.filter(
            models.Q(first_name__icontains=value) |
            models.Q(last_name__icontains=value) |
            models.Q(ssn_last4__contains=value)
        )

    def filter_smartcredit(self, queryset, name, value):
        """Filter by SmartCredit connection status."""
        if value is True:
            return queryset.filter(
                smartcredit_connections__status='active'
            ).distinct()
        elif value is False:
            return queryset.exclude(
                smartcredit_connections__status='active'
            )
        return queryset

    def filter_active_disputes(self, queryset, name, value):
        """Filter by active disputes."""
        from django.db.models import Q
        if value is True:
            return queryset.filter(
                disputes__status__in=['draft', 'pending_review', 'approved', 'mailed', 'awaiting_response']
            ).distinct()
        elif value is False:
            return queryset.exclude(
                disputes__status__in=['draft', 'pending_review', 'approved', 'mailed', 'awaiting_response']
            )
        return queryset


class CreditReportFilterSet(django_filters.FilterSet):
    """Filter set for CreditReport queryset."""

    # Date range
    from_date = django_filters.DateFilter(field_name='pulled_at', lookup_expr='gte')
    to_date = django_filters.DateFilter(field_name='pulled_at', lookup_expr='lte')

    # Score range
    min_score = django_filters.NumberFilter(field_name='score', lookup_expr='gte')
    max_score = django_filters.NumberFilter(field_name='score', lookup_expr='lte')

    class Meta:
        model = CreditReport
        fields = {
            'bureau': ['exact', 'in'],
        }


class TradelineFilterSet(django_filters.FilterSet):
    """Filter set for Tradeline queryset."""

    # Text search
    search = django_filters.CharFilter(method='filter_search')

    # Status filters
    status = django_filters.ChoiceFilter(
        field_name='account_status',
        choices=[
            ('open', 'Open'),
            ('closed', 'Closed'),
            ('collection', 'Collection'),
        ]
    )

    # Negative items
    is_negative = django_filters.BooleanFilter(method='filter_negative')

    # Balance range
    min_balance = django_filters.NumberFilter(field_name='current_balance', lookup_expr='gte')
    max_balance = django_filters.NumberFilter(field_name='current_balance', lookup_expr='lte')

    class Meta:
        model = Tradeline
        fields = {
            'bureau': ['exact', 'in'],
            'dispute_status': ['exact', 'in'],
            'account_type': ['exact'],
        }

    def filter_search(self, queryset, name, value):
        """Search by creditor name or account number."""
        if not value:
            return queryset

        from django.db.models import Q
        return queryset.filter(
            Q(creditor_name__icontains=value) |
            Q(account_number_masked__icontains=value)
        )

    def filter_negative(self, queryset, name, value):
        """Filter negative items (late payments, collections, etc.)."""
        from django.db.models import Q
        if value is True:
            return queryset.filter(
                Q(past_due_amount__gt=0) |
                Q(account_status__icontains='collection') |
                Q(account_status__icontains='charge') |
                Q(payment_status__icontains='late')
            )
        elif value is False:
            return queryset.exclude(
                Q(past_due_amount__gt=0) |
                Q(account_status__icontains='collection') |
                Q(account_status__icontains='charge') |
                Q(payment_status__icontains='late')
            )
        return queryset
