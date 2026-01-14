from django.urls import path
from .views import LobWebhookView, SmartCreditWebhookView, StripeWebhookView

app_name = 'webhooks'

urlpatterns = [
    path('lob/', LobWebhookView.as_view(), name='lob-webhook'),
    path('smartcredit/', SmartCreditWebhookView.as_view(), name='smartcredit-webhook'),
    path('stripe/', StripeWebhookView.as_view(), name='stripe-webhook'),
]
