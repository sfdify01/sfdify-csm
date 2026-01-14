"""
URL configuration for SFDIFY SCM project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # API v1
    path('api/v1/auth/', include('authentication.urls')),
    path('api/v1/', include('customers.urls')),
    path('api/v1/', include('tickets.urls')),

    # Webhooks (external service callbacks)
    path('api/v1/webhooks/', include('webhooks.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
