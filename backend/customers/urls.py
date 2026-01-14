from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .viewsets import ConsumerViewSet

router = DefaultRouter()
router.register(r'consumers', ConsumerViewSet, basename='consumer')

app_name = 'customers'

urlpatterns = [
    path('', include(router.urls)),
]
