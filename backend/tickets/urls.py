from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .viewsets import (
    DisputeViewSet,
    LetterViewSet,
    LetterTemplateViewSet,
    DisputeTaskViewSet,
)

router = DefaultRouter()
router.register(r'disputes', DisputeViewSet, basename='dispute')
router.register(r'letters', LetterViewSet, basename='letter')
router.register(r'templates', LetterTemplateViewSet, basename='template')
router.register(r'tasks', DisputeTaskViewSet, basename='task')

app_name = 'tickets'

urlpatterns = [
    path('', include(router.urls)),
]
