#!/bin/bash
# ============================================================================
# Cloud KMS Setup Script for PII Encryption
# ============================================================================
# This script creates a Cloud KMS key ring and crypto key for encrypting
# Personally Identifiable Information (PII) in the USTAXX system.
# ============================================================================

set -e

# Configuration
PROJECT_ID="ustaxx-csm"
LOCATION="global"
KEY_RING="ustaxx-pii"
CRYPTO_KEY="pii-encryption-key"

echo "========================================="
echo "Cloud KMS Setup for USTAXX"
echo "========================================="
echo "Project: $PROJECT_ID"
echo "Location: $LOCATION"
echo "Key Ring: $KEY_RING"
echo "Crypto Key: $CRYPTO_KEY"
echo "========================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed."
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set the project
echo "Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable Cloud KMS API
echo "Enabling Cloud KMS API..."
gcloud services enable cloudkms.googleapis.com --project=$PROJECT_ID

# Create key ring (if it doesn't exist)
echo "Creating key ring..."
if gcloud kms keyrings describe $KEY_RING --location=$LOCATION &> /dev/null; then
    echo "Key ring '$KEY_RING' already exists."
else
    gcloud kms keyrings create $KEY_RING --location=$LOCATION
    echo "Key ring '$KEY_RING' created successfully."
fi

# Create crypto key (if it doesn't exist)
echo "Creating crypto key..."
if gcloud kms keys describe $CRYPTO_KEY --keyring=$KEY_RING --location=$LOCATION &> /dev/null; then
    echo "Crypto key '$CRYPTO_KEY' already exists."
else
    gcloud kms keys create $CRYPTO_KEY \
        --keyring=$KEY_RING \
        --location=$LOCATION \
        --purpose=encryption \
        --rotation-period=90d \
        --next-rotation-time=$(date -u -d "+90 days" +%Y-%m-%dT%H:%M:%SZ)
    echo "Crypto key '$CRYPTO_KEY' created successfully."
fi

# Grant permissions to Cloud Functions service account
echo "Granting permissions to Cloud Functions service account..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="$PROJECT_NUMBER@cloudservices.gserviceaccount.com"

gcloud kms keys add-iam-policy-binding $CRYPTO_KEY \
    --keyring=$KEY_RING \
    --location=$LOCATION \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

echo "========================================="
echo "Cloud KMS Setup Complete!"
echo "========================================="
echo "Key Name:"
echo "projects/$PROJECT_ID/locations/$LOCATION/keyRings/$KEY_RING/cryptoKeys/$CRYPTO_KEY"
echo "========================================="
