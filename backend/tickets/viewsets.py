from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
import hashlib

from core.permissions import HasTenantAccess, IsOperator, IsViewer
from .models import Dispute, Letter, LetterTemplate, Evidence, DisputeTask
from .serializers import (
    DisputeListSerializer,
    DisputeDetailSerializer,
    DisputeCreateSerializer,
    DisputeUpdateSerializer,
    DisputeStatusTransitionSerializer,
    LetterListSerializer,
    LetterDetailSerializer,
    LetterCreateSerializer,
    LetterTemplateListSerializer,
    LetterTemplateDetailSerializer,
    EvidenceSerializer,
    EvidenceUploadSerializer,
    DisputeTaskSerializer,
    DisputeTaskCreateSerializer,
)
from .filters import (
    DisputeFilterSet,
    LetterFilterSet,
    LetterTemplateFilterSet,
    EvidenceFilterSet,
    DisputeTaskFilterSet,
)


class TenantFilterMixin:
    """Mixin to automatically filter queryset by tenant via consumer relationship."""

    def get_queryset(self):
        qs = super().get_queryset()
        if hasattr(self.request, 'tenant') and self.request.tenant:
            # Filter through consumer -> tenant relationship
            if hasattr(qs.model, 'consumer'):
                return qs.filter(consumer__tenant=self.request.tenant)
            elif hasattr(qs.model, 'dispute'):
                return qs.filter(dispute__consumer__tenant=self.request.tenant)
            elif hasattr(qs.model, 'tenant'):
                return qs.filter(tenant=self.request.tenant)
        return qs.none()


class DisputeViewSet(TenantFilterMixin, viewsets.ModelViewSet):
    """
    Dispute CRUD with nested actions for letters, evidence, and tasks.

    Endpoints:
    - GET    /api/v1/disputes/                     - List disputes
    - POST   /api/v1/disputes/                     - Create dispute
    - GET    /api/v1/disputes/{id}/                - Get dispute details
    - PATCH  /api/v1/disputes/{id}/                - Update dispute
    - DELETE /api/v1/disputes/{id}/                - Delete dispute
    - POST   /api/v1/disputes/{id}/letters/        - Generate letter
    - GET    /api/v1/disputes/{id}/letters/        - List letters
    - POST   /api/v1/disputes/{id}/evidence/       - Upload evidence
    - GET    /api/v1/disputes/{id}/evidence/       - List evidence
    - POST   /api/v1/disputes/{id}/tasks/          - Create task
    - GET    /api/v1/disputes/{id}/tasks/          - List tasks
    - POST   /api/v1/disputes/{id}/transition/     - Status transition
    """
    queryset = Dispute.objects.select_related(
        'consumer', 'tradeline', 'created_by', 'assigned_to'
    ).prefetch_related('letters', 'evidence', 'tasks')
    permission_classes = [IsAuthenticated, HasTenantAccess]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = DisputeFilterSet
    search_fields = ['dispute_number', 'consumer__first_name', 'consumer__last_name', 'narrative']
    ordering_fields = ['created_at', 'submitted_at', 'due_at', 'status']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return DisputeListSerializer
        elif self.action == 'create':
            return DisputeCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return DisputeUpdateSerializer
        return DisputeDetailSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), HasTenantAccess(), IsOperator()]
        return [IsAuthenticated(), HasTenantAccess(), IsViewer()]

    @action(detail=True, methods=['post'], url_path='letters')
    def create_letter(self, request, pk=None):
        """
        Generate a letter for this dispute.

        POST /api/v1/disputes/{id}/letters/
        {
            "template_id": "uuid",
            "type": "fcra_609_request",
            "recipient_type": "bureau",
            "recipient_name": "Equifax",
            "recipient_address": {...},
            "return_address": {...},
            "mail_type": "certified"
        }
        """
        dispute = self.get_object()

        serializer = LetterCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        letter = serializer.save(
            dispute=dispute,
            created_by=request.user
        )

        return Response(
            LetterDetailSerializer(letter).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['get'], url_path='letters')
    def list_letters(self, request, pk=None):
        """
        List letters for this dispute.

        GET /api/v1/disputes/{id}/letters/
        """
        dispute = self.get_object()
        letters = dispute.letters.all()

        # Apply filters
        filterset = LetterFilterSet(request.query_params, queryset=letters)
        queryset = filterset.qs

        # Paginate
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = LetterListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = LetterListSerializer(queryset, many=True)
        return Response({'data': serializer.data})

    @action(
        detail=True,
        methods=['post'],
        url_path='evidence',
        parser_classes=[MultiPartParser, FormParser]
    )
    def upload_evidence(self, request, pk=None):
        """
        Upload evidence for this dispute.

        POST /api/v1/disputes/{id}/evidence/
        (multipart/form-data)
        - file: binary
        - evidence_type: string
        - description: string (optional)
        """
        dispute = self.get_object()

        serializer = EvidenceUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        uploaded_file = serializer.validated_data['file']

        # Calculate checksum
        file_content = uploaded_file.read()
        checksum = hashlib.sha256(file_content).hexdigest()
        uploaded_file.seek(0)  # Reset file pointer

        # TODO: Upload to S3 and get URL
        # For now, store placeholder
        file_url = f"https://s3.amazonaws.com/placeholder/{uploaded_file.name}"

        evidence = Evidence.objects.create(
            dispute=dispute,
            filename=f"{dispute.dispute_number}_{uploaded_file.name}",
            original_filename=uploaded_file.name,
            file_url=file_url,
            file_size=uploaded_file.size,
            mime_type=uploaded_file.content_type or 'application/octet-stream',
            checksum_sha256=checksum,
            evidence_type=serializer.validated_data['evidence_type'],
            description=serializer.validated_data.get('description', ''),
            source='user_upload',
            uploaded_by=request.user
        )

        return Response(
            EvidenceSerializer(evidence).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['get'], url_path='evidence')
    def list_evidence(self, request, pk=None):
        """
        List evidence for this dispute.

        GET /api/v1/disputes/{id}/evidence/
        """
        dispute = self.get_object()
        evidence = dispute.evidence.all()

        # Apply filters
        filterset = EvidenceFilterSet(request.query_params, queryset=evidence)
        queryset = filterset.qs

        # Paginate
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = EvidenceSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = EvidenceSerializer(queryset, many=True)
        return Response({'data': serializer.data})

    @action(detail=True, methods=['post'], url_path='tasks')
    def create_task(self, request, pk=None):
        """
        Create a task for this dispute.

        POST /api/v1/disputes/{id}/tasks/
        {
            "type": "follow_up",
            "title": "Follow up with bureau",
            "description": "...",
            "due_at": "2025-02-15T12:00:00Z",
            "priority": "high"
        }
        """
        dispute = self.get_object()

        serializer = DisputeTaskCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        task = serializer.save(dispute=dispute)

        return Response(
            DisputeTaskSerializer(task).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['get'], url_path='tasks')
    def list_tasks(self, request, pk=None):
        """
        List tasks for this dispute.

        GET /api/v1/disputes/{id}/tasks/
        """
        dispute = self.get_object()
        tasks = dispute.tasks.all()

        # Apply filters
        filterset = DisputeTaskFilterSet(request.query_params, queryset=tasks)
        queryset = filterset.qs

        # Paginate
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = DisputeTaskSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = DisputeTaskSerializer(queryset, many=True)
        return Response({'data': serializer.data})

    @action(detail=True, methods=['post'], url_path='transition')
    def status_transition(self, request, pk=None):
        """
        Perform status transition on dispute.

        POST /api/v1/disputes/{id}/transition/
        {
            "status": "approved",
            "notes": "Ready for mailing"
        }
        """
        dispute = self.get_object()

        serializer = DisputeStatusTransitionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']

        # Use update serializer for validation
        update_serializer = DisputeUpdateSerializer(
            dispute,
            data={'status': new_status},
            partial=True,
            context={'request': request}
        )
        update_serializer.is_valid(raise_exception=True)
        updated_dispute = update_serializer.save()

        return Response(DisputeDetailSerializer(updated_dispute).data)


class LetterViewSet(TenantFilterMixin, viewsets.ModelViewSet):
    """
    Letter viewset for viewing and managing letters.

    Endpoints:
    - GET    /api/v1/letters/              - List all letters
    - GET    /api/v1/letters/{id}/         - Get letter details
    - GET    /api/v1/letters/{id}/preview/ - Preview PDF
    - POST   /api/v1/letters/{id}/approve/ - Approve letter
    - POST   /api/v1/letters/{id}/send/    - Send via Lob
    """
    queryset = Letter.objects.select_related(
        'dispute', 'template', 'created_by', 'approved_by'
    ).prefetch_related('events')
    permission_classes = [IsAuthenticated, HasTenantAccess]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = LetterFilterSet
    ordering_fields = ['created_at', 'sent_at', 'delivered_at', 'status']
    ordering = ['-created_at']
    http_method_names = ['get', 'head', 'options']  # Read-only at this level

    def get_serializer_class(self):
        if self.action == 'list':
            return LetterListSerializer
        return LetterDetailSerializer

    @action(detail=True, methods=['get'], url_path='preview')
    def preview(self, request, pk=None):
        """
        Preview letter PDF.

        GET /api/v1/letters/{id}/preview/
        GET /api/v1/letters/{id}/preview/?render=true  - Force re-render

        Returns PDF URL or renders on-demand.
        """
        letter = self.get_object()
        force_render = request.query_params.get('render', '').lower() == 'true'

        if letter.pdf_url and not force_render:
            return Response({
                'pdf_url': letter.pdf_url,
                'rendered_at': letter.rendered_at,
                'render_version': letter.render_version
            })

        # Render PDF using LetterService
        try:
            from .services import LetterService
            service = LetterService(tenant=getattr(request, 'tenant', None))
            result = service.render_and_save(letter)
            return Response(result)
        except ImportError as e:
            return Response({
                'error': 'dependency_missing',
                'message': f'WeasyPrint is not installed: {str(e)}'
            }, status=status.HTTP_501_NOT_IMPLEMENTED)
        except Exception as e:
            return Response({
                'error': 'render_failed',
                'message': f'Failed to render PDF: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['post'], url_path='approve')
    def approve(self, request, pk=None):
        """
        Approve letter for sending.

        POST /api/v1/letters/{id}/approve/
        """
        letter = self.get_object()

        if letter.status not in ['draft', 'pending_approval']:
            return Response({
                'error': 'invalid_status',
                'message': f'Cannot approve letter with status "{letter.status}"'
            }, status=status.HTTP_400_BAD_REQUEST)

        letter.status = 'approved'
        letter.approved_by = request.user
        letter.approved_at = timezone.now()
        letter.save()

        return Response(LetterDetailSerializer(letter).data)

    @action(detail=True, methods=['post'], url_path='send')
    def send(self, request, pk=None):
        """
        Send letter via Lob.

        POST /api/v1/letters/{id}/send/
        {
            "mail_type": "certified"  // optional override
        }
        """
        letter = self.get_object()

        if letter.status != 'approved':
            return Response({
                'error': 'invalid_status',
                'message': f'Letter must be approved before sending (current: "{letter.status}")'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Override mail type if provided
        mail_type = request.data.get('mail_type', letter.mail_type)

        try:
            from .services import LobService
            service = LobService(tenant=getattr(request, 'tenant', None))
            result = service.send_letter(letter, mail_type)

            return Response({
                'message': 'Letter sent successfully',
                'letter_id': str(letter.id),
                **result
            })
        except Exception as e:
            return Response({
                'error': 'send_failed',
                'message': str(e),
                'letter_id': str(letter.id),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LetterTemplateViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Letter template viewset (read-only for API users).

    Endpoints:
    - GET    /api/v1/templates/         - List templates
    - GET    /api/v1/templates/{id}/    - Get template details
    """
    queryset = LetterTemplate.objects.filter(is_active=True)
    permission_classes = [IsAuthenticated, HasTenantAccess]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = LetterTemplateFilterSet
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'type', 'created_at']
    ordering = ['type', 'name']

    def get_queryset(self):
        """Filter templates by tenant or global (tenant=null)."""
        qs = super().get_queryset()
        if hasattr(self.request, 'tenant') and self.request.tenant:
            from django.db.models import Q
            return qs.filter(
                Q(tenant=self.request.tenant) | Q(tenant__isnull=True)
            )
        return qs.filter(tenant__isnull=True)

    def get_serializer_class(self):
        if self.action == 'list':
            return LetterTemplateListSerializer
        return LetterTemplateDetailSerializer


class DisputeTaskViewSet(TenantFilterMixin, viewsets.ModelViewSet):
    """
    Dispute task viewset for task management.

    Endpoints:
    - GET    /api/v1/tasks/              - List all tasks
    - GET    /api/v1/tasks/{id}/         - Get task details
    - PATCH  /api/v1/tasks/{id}/         - Update task
    - POST   /api/v1/tasks/{id}/complete/- Complete task
    """
    queryset = DisputeTask.objects.select_related(
        'dispute', 'assigned_to', 'completed_by'
    )
    permission_classes = [IsAuthenticated, HasTenantAccess]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = DisputeTaskFilterSet
    search_fields = ['title', 'description']
    ordering_fields = ['due_at', 'priority', 'status', 'created_at']
    ordering = ['due_at']

    def get_serializer_class(self):
        if self.action == 'create':
            return DisputeTaskCreateSerializer
        return DisputeTaskSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'complete']:
            return [IsAuthenticated(), HasTenantAccess(), IsOperator()]
        return [IsAuthenticated(), HasTenantAccess(), IsViewer()]

    @action(detail=True, methods=['post'], url_path='complete')
    def complete(self, request, pk=None):
        """
        Mark task as completed.

        POST /api/v1/tasks/{id}/complete/
        {
            "notes": "Completed successfully"
        }
        """
        task = self.get_object()

        if task.status == 'completed':
            return Response({
                'error': 'already_completed',
                'message': 'Task is already completed'
            }, status=status.HTTP_400_BAD_REQUEST)

        task.status = 'completed'
        task.completed_at = timezone.now()
        task.completed_by = request.user
        task.completion_notes = request.data.get('notes', '')
        task.save()

        return Response(DisputeTaskSerializer(task).data)
