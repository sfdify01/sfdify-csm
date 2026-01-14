from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class AgentProfile(models.Model):
    """Extended profile for support agents."""

    ROLE_CHOICES = [
        ('agent', 'Support Agent'),
        ('supervisor', 'Supervisor'),
        ('admin', 'Administrator'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='agent_profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='agent')
    department = models.CharField(max_length=100, blank=True)
    is_available = models.BooleanField(default=True)
    max_tickets = models.PositiveIntegerField(default=10)

    def __str__(self):
        return f"{self.user.username} - {self.role}"


class SLAPolicy(models.Model):
    """Service Level Agreement policies."""

    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    # Response times in hours
    first_response_time = models.PositiveIntegerField(help_text="Hours until first response")
    resolution_time = models.PositiveIntegerField(help_text="Hours until resolution")

    # Which priorities this applies to
    priority = models.CharField(max_length=20)

    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "SLA Policy"
        verbose_name_plural = "SLA Policies"

    def __str__(self):
        return f"{self.name} ({self.priority})"


class Tag(models.Model):
    """Tags for categorizing tickets and customers."""

    name = models.CharField(max_length=50, unique=True)
    color = models.CharField(max_length=7, default='#6B7280')  # Hex color

    def __str__(self):
        return self.name
