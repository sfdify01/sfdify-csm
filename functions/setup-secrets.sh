#!/bin/bash
# ============================================================================
# Firebase Environment Secrets Setup Script
# ============================================================================
# This script helps you configure Firebase environment secrets for production.
# For local development, use a .env file instead.
# ============================================================================

set -e

PROJECT_ID="ustaxx-csm"

echo "========================================="
echo "Firebase Secrets Configuration"
echo "========================================="
echo "Project: $PROJECT_ID"
echo "========================================="
echo ""
echo "IMPORTANT: Firebase is migrating from functions.config() to params."
echo "This script will guide you through setting up secrets properly."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI is not installed."
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

echo "Select configuration mode:"
echo "1) Interactive setup (recommended)"
echo "2) Batch setup from .env file"
read -p "Enter choice [1-2]: " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo "========================================="
    echo "Interactive Secret Setup"
    echo "========================================="

    # SmartCredit Configuration
    echo ""
    echo "--- SmartCredit API Configuration ---"
    read -p "SmartCredit Client ID: " SMARTCREDIT_CLIENT_ID
    read -p "SmartCredit Client Secret: " SMARTCREDIT_CLIENT_SECRET
    read -p "SmartCredit Webhook Secret: " SMARTCREDIT_WEBHOOK_SECRET

    firebase functions:secrets:set SMARTCREDIT_CLIENT_ID --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_CLIENT_ID")
    firebase functions:secrets:set SMARTCREDIT_CLIENT_SECRET --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_CLIENT_SECRET")
    firebase functions:secrets:set SMARTCREDIT_WEBHOOK_SECRET --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_WEBHOOK_SECRET")

    # Lob Configuration
    echo ""
    echo "--- Lob API Configuration ---"
    read -p "Lob Test API Key: " LOB_API_KEY_TEST
    read -p "Lob Live API Key (press Enter to skip): " LOB_API_KEY_LIVE
    read -p "Lob Webhook Secret: " LOB_WEBHOOK_SECRET

    firebase functions:secrets:set LOB_API_KEY_TEST --project=$PROJECT_ID --data-file <(echo -n "$LOB_API_KEY_TEST")
    if [ -n "$LOB_API_KEY_LIVE" ]; then
        firebase functions:secrets:set LOB_API_KEY_LIVE --project=$PROJECT_ID --data-file <(echo -n "$LOB_API_KEY_LIVE")
    fi
    firebase functions:secrets:set LOB_WEBHOOK_SECRET --project=$PROJECT_ID --data-file <(echo -n "$LOB_WEBHOOK_SECRET")

    # SendGrid Configuration
    echo ""
    echo "--- SendGrid Configuration ---"
    read -p "SendGrid API Key: " SENDGRID_API_KEY
    firebase functions:secrets:set SENDGRID_API_KEY --project=$PROJECT_ID --data-file <(echo -n "$SENDGRID_API_KEY")

    # Twilio Configuration
    echo ""
    echo "--- Twilio Configuration ---"
    read -p "Twilio Account SID: " TWILIO_ACCOUNT_SID
    read -p "Twilio Auth Token: " TWILIO_AUTH_TOKEN
    read -p "Twilio From Number (e.g., +1234567890): " TWILIO_FROM_NUMBER

    firebase functions:secrets:set TWILIO_ACCOUNT_SID --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_ACCOUNT_SID")
    firebase functions:secrets:set TWILIO_AUTH_TOKEN --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_AUTH_TOKEN")
    firebase functions:secrets:set TWILIO_FROM_NUMBER --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_FROM_NUMBER")

elif [ "$choice" = "2" ]; then
    if [ ! -f ".env" ]; then
        echo "Error: .env file not found."
        echo "Create one from .env.example and fill in your values."
        exit 1
    fi

    echo "Loading secrets from .env file..."
    source .env

    # Set all secrets
    firebase functions:secrets:set SMARTCREDIT_CLIENT_ID --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_CLIENT_ID")
    firebase functions:secrets:set SMARTCREDIT_CLIENT_SECRET --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_CLIENT_SECRET")
    firebase functions:secrets:set SMARTCREDIT_WEBHOOK_SECRET --project=$PROJECT_ID --data-file <(echo -n "$SMARTCREDIT_WEBHOOK_SECRET")
    firebase functions:secrets:set LOB_API_KEY_TEST --project=$PROJECT_ID --data-file <(echo -n "$LOB_API_KEY_TEST")
    firebase functions:secrets:set LOB_WEBHOOK_SECRET --project=$PROJECT_ID --data-file <(echo -n "$LOB_WEBHOOK_SECRET")
    firebase functions:secrets:set SENDGRID_API_KEY --project=$PROJECT_ID --data-file <(echo -n "$SENDGRID_API_KEY")
    firebase functions:secrets:set TWILIO_ACCOUNT_SID --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_ACCOUNT_SID")
    firebase functions:secrets:set TWILIO_AUTH_TOKEN --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_AUTH_TOKEN")
    firebase functions:secrets:set TWILIO_FROM_NUMBER --project=$PROJECT_ID --data-file <(echo -n "$TWILIO_FROM_NUMBER")

    if [ -n "$LOB_API_KEY_LIVE" ]; then
        firebase functions:secrets:set LOB_API_KEY_LIVE --project=$PROJECT_ID --data-file <(echo -n "$LOB_API_KEY_LIVE")
    fi
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo "Secrets have been configured in Firebase."
echo ""
echo "Next steps:"
echo "1. Update your functions to use Firebase Secrets"
echo "2. Deploy your functions: npm run deploy"
echo "========================================="
