from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from core.permissions import HasTenantAccess, IsOperator, IsViewer
from .models import Consumer, CreditReport, Tradeline
from .serializers import (
    ConsumerListSerializer,
    ConsumerDetailSerializer,
    ConsumerCreateSerializer,
    ConsumerUpdateSerializer,
    CreditReportListSerializer,
    CreditReportDetailSerializer,
    TradelineSerializer,
    TradelineListSerializer,
    SmartCreditConnectionSerializer,
)
from .filters import ConsumerFilterSet, CreditReportFilterSet, TradelineFilterSet


class TenantFilterMixin:
    """Mixin to automatically filter queryset by tenant."""

    def get_queryset(self):
        qs = super().get_queryset()
        if hasattr(self.request, 'tenant') and self.request.tenant:
            return qs.filter(tenant=self.request.tenant)
        return qs.none()

    def perform_create(self, serializer):
        """Set tenant and created_by on creation."""
        serializer.save(
            tenant=self.request.tenant,
            created_by=self.request.user
        )


class ConsumerViewSet(TenantFilterMixin, viewsets.ModelViewSet):
    """
    Consumer CRUD with nested actions for SmartCredit and reports.

    Endpoints:
    - GET    /api/v1/consumers/                     - List consumers
    - POST   /api/v1/consumers/                     - Create consumer
    - GET    /api/v1/consumers/{id}/                - Get consumer details
    - PATCH  /api/v1/consumers/{id}/                - Update consumer
    - DELETE /api/v1/consumers/{id}/                - Delete consumer
    - POST   /api/v1/consumers/{id}/smartcredit/connect/   - Start OAuth
    - POST   /api/v1/consumers/{id}/smartcredit/callback/  - Complete OAuth
    - POST   /api/v1/consumers/{id}/reports/refresh/       - Pull new reports
    - GET    /api/v1/consumers/{id}/reports/               - List reports
    - GET    /api/v1/consumers/{id}/tradelines/            - List tradelines
    """
    queryset = Consumer.objects.select_related('tenant', 'created_by')
    permission_classes = [IsAuthenticated, HasTenantAccess]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = ConsumerFilterSet
    search_fields = ['first_name', 'last_name', 'ssn_last4']
    ordering_fields = ['created_at', 'last_name', 'first_name', 'kyc_status']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return ConsumerListSerializer
        elif self.action == 'create':
            return ConsumerCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return ConsumerUpdateSerializer
        return ConsumerDetailSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), HasTenantAccess(), IsOperator()]
        return [IsAuthenticated(), HasTenantAccess(), IsViewer()]

    @action(detail=True, methods=['post'], url_path='smartcredit/connect')
    def smartcredit_connect(self, request, pk=None):
        """
        Initiate SmartCredit OAuth flow.

        POST /api/v1/consumers/{id}/smartcredit/connect/
        {
            "redirect_uri": "https://app.example.com/callback",
            "scopes": ["reports", "tradelines", "alerts", "scores"]
        }

        Returns:
        {
            "authorization_url": "https://smartcredit.com/oauth/...",
            "state": "random_token",
            "expires_in": 600
        }
        """
        consumer = self.get_object()

        redirect_uri = request.data.get('redirect_uri')
        if not redirect_uri:
            return Response({
                'error': 'validation_error',
                'message': 'redirect_uri is required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            from .services import SmartCreditService
            service = SmartCreditService(tenant=request.tenant)
            auth_url, state, expires_at = service.initiate_oauth(
                consumer,
                redirect_uri,
                request.data.get('scopes', ['reports', 'tradelines', 'scores'])
            )

            return Response({
                'authorization_url': auth_url,
                'state': state,
                'expires_in': 600
            })
        except Exception as e:
            return Response({
                'error': 'oauth_error',
                'message': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['post'], url_path='smartcredit/callback')
    def smartcredit_callback(self, request, pk=None):
        """
        Complete OAuth flow with authorization code.

        POST /api/v1/consumers/{id}/smartcredit/callback/
        {
            "code": "authorization_code",
            "state": "random_token"
        }
        """
        consumer = self.get_object()

        code = request.data.get('code')
        state = request.data.get('state')

        if not code or not state:
            return Response({
                'error': 'validation_error',
                'message': 'code and state are required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            from .services import SmartCreditService
            service = SmartCreditService(tenant=request.tenant)
            connection = service.complete_oauth(consumer, code, state)

            serializer = SmartCreditConnectionSerializer(connection)
            return Response({
                'message': 'SmartCredit connection established',
                'connection': serializer.data
            })
        except Exception as e:
            return Response({
                'error': 'oauth_error',
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'], url_path='reports/refresh')
    def refresh_reports(self, request, pk=None):
        """
        Trigger credit report pull from SmartCredit.

        POST /api/v1/consumers/{id}/reports/refresh/
        {
            "bureaus": ["equifax", "experian", "transunion"]
        }

        Returns 202 Accepted with job_id for async processing.
        """
        consumer = self.get_object()

        bureaus = request.data.get('bureaus', ['equifax', 'experian', 'transunion'])

        # Validate bureaus
        valid_bureaus = ['equifax', 'experian', 'transunion']
        invalid = [b for b in bureaus if b not in valid_bureaus]
        if invalid:
            return Response({
                'error': 'validation_error',
                'message': f'Invalid bureaus: {invalid}'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check for active SmartCredit connection
        connection = consumer.smartcredit_connections.filter(status='active').first()
        if not connection:
            return Response({
                'error': 'no_connection',
                'message': 'Consumer does not have an active SmartCredit connection'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Synchronous report pull (TODO: move to Celery task for production)
        try:
            from .services import SmartCreditService
            service = SmartCreditService(tenant=request.tenant)

            reports = []
            errors = []

            for bureau in bureaus:
                try:
                    raw_report = service.fetch_credit_report(connection, bureau)
                    credit_report = service.parse_and_save_report(
                        consumer, connection, bureau, raw_report
                    )
                    reports.append({
                        'bureau': bureau,
                        'report_id': str(credit_report.id),
                        'status': 'success'
                    })
                except Exception as e:
                    errors.append({
                        'bureau': bureau,
                        'error': str(e)
                    })

            return Response({
                'message': 'Credit report refresh completed',
                'reports': reports,
                'errors': errors,
                'bureaus': bureaus
            }, status=status.HTTP_200_OK if reports else status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            return Response({
                'error': 'refresh_failed',
                'message': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['get'], url_path='reports')
    def list_reports(self, request, pk=None):
        """
        List credit reports for a consumer.

        GET /api/v1/consumers/{id}/reports/
        GET /api/v1/consumers/{id}/reports/?bureau=equifax
        """
        consumer = self.get_object()
        reports = consumer.credit_reports.all()

        # Apply filters
        filterset = CreditReportFilterSet(request.query_params, queryset=reports)
        queryset = filterset.qs

        # Paginate
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = CreditReportListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = CreditReportListSerializer(queryset, many=True)
        return Response({'data': serializer.data})

    @action(detail=True, methods=['get'], url_path='tradelines')
    def list_tradelines(self, request, pk=None):
        """
        List tradelines across all bureaus for a consumer.

        GET /api/v1/consumers/{id}/tradelines/
        GET /api/v1/consumers/{id}/tradelines/?bureau=equifax&dispute_status=none
        """
        consumer = self.get_object()
        tradelines = consumer.tradelines.all()

        # Apply filters
        filterset = TradelineFilterSet(request.query_params, queryset=tradelines)
        queryset = filterset.qs

        # Paginate
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = TradelineSerializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
        else:
            serializer = TradelineSerializer(queryset, many=True)
            response = Response({'data': serializer.data})

        # Add summary
        all_tradelines = consumer.tradelines.all()
        summary = {
            'total_tradelines': all_tradelines.count(),
            'by_bureau': {
                bureau: all_tradelines.filter(bureau=bureau).count()
                for bureau in ['equifax', 'experian', 'transunion']
            },
            'by_dispute_status': {
                'none': all_tradelines.filter(dispute_status='none').count(),
                'in_dispute': all_tradelines.filter(dispute_status='in_dispute').count(),
                'resolved': all_tradelines.filter(dispute_status='resolved').count(),
            },
            'with_potential_issues': all_tradelines.filter(
                past_due_amount__gt=0
            ).count(),
        }

        if hasattr(response, 'data'):
            response.data['summary'] = summary
        else:
            response.data = {'data': serializer.data, 'summary': summary}

        return response

    @action(detail=True, methods=['get'], url_path='smartcredit/status')
    def smartcredit_status(self, request, pk=None):
        """
        Get SmartCredit connection status.

        GET /api/v1/consumers/{id}/smartcredit/status/
        """
        consumer = self.get_object()
        connection = consumer.smartcredit_connections.filter(status='active').first()

        if not connection:
            return Response({
                'connected': False,
                'connection': None
            })

        serializer = SmartCreditConnectionSerializer(connection)
        return Response({
            'connected': True,
            'connection': serializer.data
        })
