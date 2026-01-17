# SFDIFY Cloud Functions

Firebase Cloud Functions for the SFDIFY Credit Dispute System.

## Overview

This directory contains all serverless Cloud Functions for SFDIFY, organized by domain:

- **Consumers**: Consumer profile and credit report management
- **Disputes**: Dispute case creation and workflow
- **Letters**: Dispute letter generation and sending
- **Evidence**: Document upload and management
- **Admin**: Analytics, billing, and system administration
- **Users**: User management and authentication
- **Tenants**: Multi-tenant organization management
- **Auth**: Public authentication and signup flows
- **Webhooks**: External service integrations (Lob, SmartCredit)
- **Scheduled**: Cron jobs for SLA checks, billing, cleanup
- **Triggers**: Firestore event handlers

## Prerequisites

- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- Google Cloud SDK (gcloud): [Install here](https://cloud.google.com/sdk/docs/install)
- Firebase Blaze (pay-as-you-go) plan

## Initial Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Environment Variables

For local development, create a `.env` file:

```bash
cp .env.example .env
# Edit .env and fill in your API keys
```

For production, use Firebase Secrets (see Configuration section below).

### 3. Set Up Cloud KMS for PII Encryption

Cloud KMS is required for encrypting personally identifiable information (PII):

```bash
./setup-kms.sh
```

This creates:
- Key ring: `sfdify-pii`
- Crypto key: `pii-encryption-key`
- Proper IAM permissions for Cloud Functions

### 4. Configure Firebase Secrets

Set up production secrets using the helper script:

```bash
./setup-secrets.sh
```

Or manually with Firebase CLI:

```bash
# SmartCredit API
firebase functions:secrets:set SMARTCREDIT_CLIENT_ID
firebase functions:secrets:set SMARTCREDIT_CLIENT_SECRET
firebase functions:secrets:set SMARTCREDIT_WEBHOOK_SECRET

# Lob Mail Service
firebase functions:secrets:set LOB_API_KEY_TEST
firebase functions:secrets:set LOB_API_KEY_LIVE
firebase functions:secrets:set LOB_WEBHOOK_SECRET

# SendGrid Email
firebase functions:secrets:set SENDGRID_API_KEY

# Twilio SMS
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_FROM_NUMBER
```

## Configuration

### Required API Keys

#### SmartCredit (Credit Bureau Integration)
- **Purpose**: Fetch credit reports from all 3 bureaus
- **Get Keys**: https://www.smartcredit.com/developer
- **Required**:
  - Client ID
  - Client Secret
  - Webhook Secret (for status updates)

#### Lob (Mail Service)
- **Purpose**: Send physical dispute letters via USPS
- **Get Keys**: https://dashboard.lob.com/#/settings/keys
- **Required**:
  - Test API Key (for development)
  - Live API Key (for production)
  - Webhook Secret (for delivery tracking)

#### SendGrid (Email Notifications)
- **Purpose**: Send email notifications to users and admins
- **Get Keys**: https://app.sendgrid.com/settings/api_keys
- **Required**: API Key

#### Twilio (SMS Notifications)
- **Purpose**: Send SMS alerts for time-sensitive updates
- **Get Keys**: https://console.twilio.com/
- **Required**:
  - Account SID
  - Auth Token
  - From Phone Number

### Firebase Project Configuration

Ensure your Firebase project has these services enabled:
- Cloud Functions (2nd gen)
- Cloud Firestore
- Cloud Storage
- Authentication
- Cloud KMS API

Enable services:
```bash
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
```

## Development

### Local Development with Emulators

Start the Firebase emulators:

```bash
npm run emulators
```

This starts:
- Functions emulator: http://localhost:5001
- Firestore emulator: http://localhost:8080
- Auth emulator: http://localhost:9099
- Storage emulator: http://localhost:9199
- Pub/Sub emulator: http://localhost:8085
- Emulator UI: http://localhost:4000

### Build TypeScript

```bash
npm run build
```

For watch mode:
```bash
npm run build:watch
```

### Run Tests

```bash
npm test
```

For watch mode:
```bash
npm test:watch
```

### Linting

```bash
npm run lint
npm run lint:fix
```

## Deployment

### Deploy All Functions

```bash
npm run deploy
```

Or using Firebase CLI directly:
```bash
firebase deploy --only functions
```

### Deploy Specific Function Groups

```bash
# Deploy only consumer functions
firebase deploy --only functions:consumersCreate,functions:consumersGet

# Deploy only scheduled functions
firebase deploy --only functions:scheduledSlaChecker
```

### Deploy to Staging

```bash
firebase deploy --only functions --project staging
```

## Function Architecture

### HTTP Functions

Most functions are HTTP-callable functions with the following structure:

```typescript
export const functionName = onCall(
  { region: "us-central1" },
  async (request) => {
    // Authentication check
    // Input validation
    // Business logic
    // Return result
  }
);
```

### Scheduled Functions

Cron jobs run on schedules defined in the function:

```typescript
export const scheduledFunction = onSchedule(
  { schedule: "every 5 minutes" },
  async (event) => {
    // Scheduled task logic
  }
);
```

### Firestore Triggers

Event-driven functions that respond to Firestore changes:

```typescript
export const onDocumentCreate = onDocumentCreated(
  "collection/{docId}",
  async (event) => {
    // React to document creation
  }
);
```

## Security

### Authentication

All HTTP functions require authentication except public auth endpoints:
- `authSignUp`
- `authCompleteGoogleSignUp`
- `authCheckStatus`

### Authorization

Functions check user roles and tenant membership:
- **Admin**: Full system access
- **Manager**: Tenant-wide access
- **Staff**: Limited access within tenant
- **User**: Own data only

### PII Encryption

Sensitive data is encrypted using Cloud KMS before storage:
- SSN (last 4 digits)
- Date of birth
- Full names
- Access tokens

See `utils/encryption.ts` for implementation.

## Monitoring

### View Logs

```bash
npm run logs
```

Or in Firebase Console: https://console.firebase.google.com/project/ustaxx-csm/functions/logs

### Error Reporting

Errors are automatically reported to Cloud Error Reporting.

View errors: https://console.cloud.google.com/errors

### Performance Monitoring

Monitor function performance in Firebase Console:
https://console.firebase.google.com/project/ustaxx-csm/functions/dashboard

## Cost Optimization

### Current Configuration

- Region: `us-central1` (lowest cost)
- Memory: 256MB (default, adequate for most functions)
- Timeout: 60s (default)

### Blaze Plan Pricing

- **Invocations**: First 2 million/month free, then $0.40/million
- **Compute time**: First 400,000 GB-seconds free, then $0.0000025/GB-second
- **Networking**: First 5GB/month free, then $0.12/GB

### Cost-Saving Tips

1. Use scheduled functions sparingly
2. Optimize function memory allocation
3. Implement proper caching
4. Use Firestore queries efficiently
5. Batch operations where possible

## Troubleshooting

### Build Errors

```bash
# Clear build cache
rm -rf lib/
npm run build
```

### Deployment Failures

```bash
# Check function logs
firebase functions:log

# Validate configuration
firebase functions:config:get
```

### Emulator Issues

```bash
# Clear emulator data
rm -rf .firebase/

# Restart emulators
npm run emulators
```

### Secret Access Issues

```bash
# List all secrets
firebase functions:secrets:access --project=ustaxx-csm

# Grant service account access
gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:PROJECT_ID@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)
- [Firebase Secrets Manager](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [Cloud KMS Documentation](https://cloud.google.com/kms/docs)

## Support

For issues or questions:
- Check the logs: `npm run logs`
- Review error reporting in Firebase Console
- Contact the development team
