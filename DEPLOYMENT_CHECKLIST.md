# USTAXX Cloud Functions Deployment Checklist

## ✅ Pre-Deployment Setup

### 1. Enable Required GCP Services

```bash
# Enable Cloud KMS for PII encryption
gcloud services enable cloudkms.googleapis.com --project=ustaxx-csm

# Enable Cloud Functions
gcloud services enable cloudfunctions.googleapis.com --project=ustaxx-csm

# Enable Cloud Build (required for functions deployment)
gcloud services enable cloudbuild.googleapis.com --project=ustaxx-csm

# Enable Secret Manager
gcloud services enable secretmanager.googleapis.com --project=ustaxx-csm

# Verify services are enabled
gcloud services list --enabled --project=ustaxx-csm | grep -E "(kms|functions|build|secret)"
```

### 2. Set Up Cloud KMS

Run the automated setup script:

```bash
cd functions
./setup-kms.sh
```

This will:
- Create a Cloud KMS key ring named `ustaxx-pii`
- Create a crypto key for PII encryption
- Set up proper IAM permissions
- Configure automatic key rotation (90 days)

### 3. Configure Firebase Secrets

You need to obtain and configure API keys for the following services:

#### SmartCredit (Credit Bureau Integration)
- Sign up at: https://www.smartcredit.com/developer
- Required keys:
  - ✅ Client ID
  - ✅ Client Secret
  - ✅ Webhook Secret

#### Lob (Mail Service for Physical Letters)
- Sign up at: https://www.lob.com
- Dashboard: https://dashboard.lob.com/#/settings/keys
- Required keys:
  - ✅ Test API Key (for development)
  - ✅ Live API Key (for production)
  - ✅ Webhook Secret

#### SendGrid (Email Notifications)
- Sign up at: https://sendgrid.com
- Dashboard: https://app.sendgrid.com/settings/api_keys
- Required:
  - ✅ API Key

#### Twilio (SMS Notifications)
- Sign up at: https://www.twilio.com
- Console: https://console.twilio.com/
- Required:
  - ✅ Account SID
  - ✅ Auth Token
  - ✅ From Phone Number

### 4. Configure Secrets in Firebase

Option A: Use the interactive setup script:
```bash
cd functions
./setup-secrets.sh
```

Option B: Manual setup:
```bash
# Create a .env file from the example
cp functions/.env.example functions/.env

# Edit the .env file with your API keys
# Then use the script to upload them
cd functions
./setup-secrets.sh  # Choose option 2 for batch setup
```

### 5. Verify Function Configuration

```bash
# Build the functions
cd functions
npm run build

# Check for TypeScript errors
npm run lint

# Run tests (if available)
npm test
```

## 🚀 Deployment

### First Deployment

```bash
# From the project root
firebase deploy --only functions --project=ustaxx-csm
```

This will:
1. Build your TypeScript code
2. Upload functions to Firebase
3. Deploy all function groups
4. Set up HTTP endpoints
5. Configure scheduled functions

### Deploy Specific Function Groups

```bash
# Deploy only consumer functions
firebase deploy --only functions:consumersCreate,functions:consumersGet,functions:consumersUpdate

# Deploy only scheduled functions
firebase deploy --only functions:scheduledSlaChecker,functions:scheduledReportRefresh

# Deploy only webhooks
firebase deploy --only functions:webhooksLob,functions:webhooksSmartCredit
```

### Verify Deployment

1. Check Firebase Console:
   - https://console.firebase.google.com/project/ustaxx-csm/functions

2. Test a function:
```bash
# Using Firebase CLI
firebase functions:shell

# Or test an HTTP function
curl -X POST https://us-central1-ustaxx-csm.cloudfunctions.net/consumersGet \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"consumerId": "test-id"}'
```

3. Check logs:
```bash
firebase functions:log --project=ustaxx-csm
```

## 📊 Post-Deployment

### 1. Configure Webhooks

After deployment, you'll need to register webhook URLs with external services:

#### Lob Webhooks

**Dashboard:** https://dashboard.lob.com/webhooks

**Webhook Configuration:**
1. Click "Create Webhook"
2. Enter Webhook URL: `https://us-central1-ustaxx-csm.cloudfunctions.net/webhooksLob`
3. Select API version: `2024-01-01`
4. Subscribe to the following events:

**Standard Letter Events (Required):**
- `letter.created` - Letter created in Lob system
- `letter.rendered_pdf` - PDF rendered and ready
- `letter.rendered_thumbnails` - Thumbnails generated
- `letter.mailed` - Letter mailed by USPS
- `letter.in_transit` - Letter in transit
- `letter.in_local_area` - Letter in local delivery area
- `letter.processed_for_delivery` - Letter processed for delivery
- `letter.re-routed` - Letter re-routed
- `letter.delivered` - Letter delivered
- `letter.returned_to_sender` - Letter returned to sender
- `letter.failed` - Letter delivery failed

**Certified Mail Events (Required for certified letters):**
- `letter.certified.mailed` - Certified letter mailed
- `letter.certified.in_transit` - Certified letter in transit
- `letter.certified.in_local_area` - Certified letter in local area
- `letter.certified.processed_for_delivery` - Certified letter processed
- `letter.certified.re-routed` - Certified letter re-routed
- `letter.certified.delivered` - Certified letter delivered
- `letter.certified.returned_to_sender` - Certified letter returned
- `letter.certified.pickup_available` - Certified letter available for pickup
- `letter.certified.issue` - Certified letter has an issue

5. Copy the **Webhook Secret** from the webhook settings
6. Store the secret in Firebase:
   ```bash
   firebase functions:secrets:set LOB_WEBHOOK_SECRET
   # Paste the webhook secret when prompted
   ```

**Webhook Signature Verification:**
- Lob uses HMAC-SHA256 signature verification
- Header format: `lob-signature: t=timestamp,v1=signature`
- The system validates both signature and timestamp freshness (5 minute window)

#### SmartCredit Webhooks
- Contact SmartCredit support to register webhook
- Webhook URL: `https://us-central1-ustaxx-csm.cloudfunctions.net/webhooksSmartCredit`
- Events: Credit report updates, connection status changes

### 2. Set Up Monitoring

1. Enable Error Reporting:
   - https://console.cloud.google.com/errors?project=ustaxx-csm

2. Set up Alerts:
   - Go to Cloud Console > Monitoring > Alerting
   - Create alerts for:
     - Function execution errors
     - Function timeouts
     - High memory usage
     - Unusual invocation rates

3. Set up Budget Alerts:
   - Go to Cloud Console > Billing > Budgets & alerts
   - Create budget alert for Cloud Functions usage

### 3. Test Key Workflows

```bash
# Test consumer creation
# Test dispute creation
# Test letter generation
# Test evidence upload
# Test scheduled functions (check logs)
```

#### Testing Lob Integration

1. **Test Address Verification:**
   ```bash
   firebase functions:shell
   > lobService.verifyAddress({name: "Test", addressLine1: "1600 Pennsylvania Ave", city: "Washington", state: "DC", zipCode: "20500"})
   ```
   - Expected: Returns deliverability status and standardized address

2. **Test Letter Creation (Test Mode):**
   - Create a dispute in the frontend
   - Generate and approve a letter
   - Send the letter (uses test API key)
   - Verify letter appears in Lob Dashboard: https://dashboard.lob.com/letters

3. **Test Webhook Processing:**
   - In Lob Dashboard, go to Webhooks
   - Use "Send Test Webhook" feature
   - Check Firebase logs:
     ```bash
     firebase functions:log --only webhooksLob
     ```
   - Verify webhook was received and processed

4. **Verify Address Verification Enforcement:**
   - Try sending a letter with an invalid address
   - Expected: Error message "Recipient address is undeliverable"

5. **End-to-End Flow:**
   - Create dispute → Generate letter → Approve → Send
   - Monitor Firestore for status updates: queued → sent → delivered
   - Verify webhook events are received and processed

### 4. Configure Firestore Security Rules

Ensure your Firestore rules are deployed:
```bash
firebase deploy --only firestore:rules --project=ustaxx-csm
```

### 5. Configure Storage Security Rules

Deploy storage rules:
```bash
firebase deploy --only storage --project=ustaxx-csm
```

## 🔧 Troubleshooting

### Common Issues

#### 1. "Permission denied" during deployment
```bash
# Re-authenticate
firebase login --reauth

# Check you have the right project selected
firebase use ustaxx-csm
```

#### 2. "Cloud Build has not been used in project"
```bash
# Enable Cloud Build
gcloud services enable cloudbuild.googleapis.com --project=ustaxx-csm
```

#### 3. "KMS key not found"
```bash
# Run the KMS setup script again
cd functions
./setup-kms.sh
```

#### 4. "Secret not found" errors in logs
```bash
# List all secrets
firebase functions:secrets:access --project=ustaxx-csm

# Re-run secret setup
cd functions
./setup-secrets.sh
```

#### 5. TypeScript build errors
```bash
# Clean and rebuild
cd functions
rm -rf lib/
npm run build
```

## 💰 Cost Monitoring

### Expected Monthly Costs (Light Usage)

- **Cloud Functions**: ~$10-50/month
  - 2M invocations free tier
  - Compute time based on usage

- **Cloud KMS**: ~$1/month
  - $0.06 per key version per month
  - $0.03 per 10,000 operations

- **Secret Manager**: ~$1/month
  - $0.06 per secret per month

- **Total Estimated**: $12-52/month (varies with usage)

### Cost Optimization Tips

1. Use appropriate memory allocation (don't over-allocate)
2. Set reasonable timeouts
3. Implement caching where possible
4. Use Firestore queries efficiently
5. Monitor and optimize cold starts

## 📝 Next Steps

After successful deployment:

1. ✅ Test all critical functions
2. ✅ Configure webhook endpoints
3. ✅ Set up monitoring and alerts
4. ✅ Document function endpoints for frontend team
5. ✅ Set up CI/CD pipeline (optional)
6. ✅ Create runbook for common operations

## 🔗 Quick Links

- [Firebase Console](https://console.firebase.google.com/project/ustaxx-csm)
- [GCP Console](https://console.cloud.google.com/home/dashboard?project=ustaxx-csm)
- [Functions Dashboard](https://console.firebase.google.com/project/ustaxx-csm/functions)
- [Function Logs](https://console.firebase.google.com/project/ustaxx-csm/functions/logs)
- [Error Reporting](https://console.cloud.google.com/errors?project=ustaxx-csm)
- [Cloud KMS](https://console.cloud.google.com/security/kms/keyrings?project=ustaxx-csm)

## 📞 Support

For issues:
1. Check function logs: `firebase functions:log`
2. Review error reporting in GCP Console
3. Check deployment status in Firebase Console
4. Review this checklist for missed steps
