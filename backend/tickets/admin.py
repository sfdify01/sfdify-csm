from django.contrib import admin
from .models import Ticket, TicketComment, TicketAttachment


class TicketCommentInline(admin.TabularInline):
    model = TicketComment
    extra = 0
    readonly_fields = ['created_at']


class TicketAttachmentInline(admin.TabularInline):
    model = TicketAttachment
    extra = 0
    readonly_fields = ['uploaded_at']


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ['ticket_number', 'subject', 'customer', 'status', 'priority', 'assigned_to', 'created_at']
    list_filter = ['status', 'priority', 'category', 'created_at']
    search_fields = ['ticket_number', 'subject', 'description', 'customer__name']
    readonly_fields = ['ticket_number', 'created_at', 'updated_at']
    raw_id_fields = ['customer', 'assigned_to', 'created_by']
    inlines = [TicketCommentInline, TicketAttachmentInline]

    fieldsets = (
        (None, {
            'fields': ('ticket_number', 'subject', 'description')
        }),
        ('Classification', {
            'fields': ('status', 'priority', 'category')
        }),
        ('Assignment', {
            'fields': ('customer', 'assigned_to', 'created_by')
        }),
        ('SLA', {
            'fields': ('due_date', 'first_response_at', 'resolved_at')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(TicketComment)
class TicketCommentAdmin(admin.ModelAdmin):
    list_display = ['ticket', 'author', 'is_internal', 'created_at']
    list_filter = ['is_internal', 'created_at']
    search_fields = ['content', 'ticket__ticket_number']
    readonly_fields = ['created_at']


@admin.register(TicketAttachment)
class TicketAttachmentAdmin(admin.ModelAdmin):
    list_display = ['filename', 'ticket', 'uploaded_by', 'uploaded_at']
    list_filter = ['uploaded_at']
    search_fields = ['filename', 'ticket__ticket_number']
    readonly_fields = ['uploaded_at']
