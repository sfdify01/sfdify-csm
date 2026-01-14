from django.contrib import admin
from .models import Customer, CustomerInteraction


class CustomerInteractionInline(admin.TabularInline):
    model = CustomerInteraction
    extra = 0
    readonly_fields = ['created_at']


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ['name', 'email', 'company', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'email', 'company']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [CustomerInteractionInline]


@admin.register(CustomerInteraction)
class CustomerInteractionAdmin(admin.ModelAdmin):
    list_display = ['customer', 'channel', 'subject', 'agent', 'created_at']
    list_filter = ['channel', 'created_at']
    search_fields = ['subject', 'content', 'customer__name']
    readonly_fields = ['created_at']
