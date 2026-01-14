from django.contrib import admin
from .models import AgentProfile, SLAPolicy, Tag


@admin.register(AgentProfile)
class AgentProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'department', 'is_available', 'max_tickets']
    list_filter = ['role', 'is_available', 'department']
    search_fields = ['user__username', 'user__email', 'department']


@admin.register(SLAPolicy)
class SLAPolicyAdmin(admin.ModelAdmin):
    list_display = ['name', 'priority', 'first_response_time', 'resolution_time', 'is_active']
    list_filter = ['priority', 'is_active']
    search_fields = ['name', 'description']


@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ['name', 'color']
    search_fields = ['name']
