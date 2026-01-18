# API Credentials Setup Guide

This guide walks you through obtaining API credentials for all third-party services used in USTAXX.

---

## 🎯 Overview

You need credentials from 4 services:
1. **SmartCredit** - Credit bureau data integration
2. **Lob** - Physical mail service for dispute letters
3. **SendGrid** - Email notifications
4. **Twilio** - SMS notifications

---

## 1️⃣ SmartCredit API Credentials

**Purpose**: Fetch credit reports from Equifax, Experian, and TransUnion

### Step 1: Sign Up for SmartCredit
1. Go to: https://www.smartcredit.com/
2. Click "Sign Up" or "Get Started"
3. Choose the **Business/Developer** plan
4. Complete the registration process

### Step 2: Access Developer Portal
1. Log in to your SmartCredit account
2. Navigate to: **Settings** → **Developer** or **API Settings**
3. You may need to contact SmartCredit sales to get developer access

### Step 3: Generate API Credentials
1. In the Developer section, look for "API Credentials" or "API Keys"
2. Click "Create New Credentials" or "Generate API Key"
3. You'll receive:
   - **Client ID** (e.g., `sc_live_abc123...`)
   - **Client Secret** (e.g., `sc_secret_xyz789...`)
   - **Webhook Secret** (for verifying webhook calls)

### Step 4: Save Your Credentials
```bash
SMARTCREDIT_CLIENT_ID=<your_client_id>
SMARTCREDIT_CLIENT_SECRET=<your_client_secret>
SMARTCREDIT_WEBHOOK_SECRET=<your_webhook_secret>
```

### Important Notes:
- SmartCredit may require business verification before granting API access
- You may need to contact their sales team: https://www.smartcredit.com/contact
- Pricing varies based on credit report volume
- They offer sandbox/test environment credentials separately

### Alternative: If SmartCredit is unavailable
Consider these alternatives:
- **Experian Connect** - https://developer.experian.com/
- **TransUnion TrueVision** - https://www.transunion.com/business/truevision
- **Equifax API** - https://developer.equifax.com/

---

## 2️⃣ Lob API Credentials

**Purpose**: Send physical dispute letters via USPS

### Step 1: Sign Up for Lob
1. Go to: https://www.lob.com/
2. Click "Sign Up" or "Get Started Free"
3. Create your account
4. Lob offers **$300 in free credits** for new accounts

### Step 2: Access Dashboard
1. Log in to: https://dashboard.lob.com/
2. Navigate to: **Settings** → **API Keys**
   - Direct link: https://dashboard.lob.com/#/settings/keys

### Step 3: Get Test API Key
1. You'll see your **Test Secret API Key** displayed
2. Click "Reveal" to see the full key
3. Format: `test_abc123...` (starts with `test_`)
4. Copy this key

### Step 4: Get Live API Key (Production)
1. On the same page, switch to **Live Mode** toggle
2. You'll see your **Live Secret API Key**
3. Format: `live_abc123...` (starts with `live_`)
4. Copy this key

### Step 5: Generate Webhook Secret
1. Navigate to: **Settings** → **Webhooks**
   - Direct link: https://dashboard.lob.com/#/settings/webhooks
2. Click "Add Webhook"
3. You'll receive a **Webhook Secret** (format: `whsec_abc123...`)
4. Save this secret

### Step 6: Save Your Credentials
```bash
LOB_API_KEY_TEST=test_<your_test_key>
LOB_API_KEY_LIVE=live_<your_live_key>
LOB_WEBHOOK_SECRET=whsec_<your_webhook_secret>
```

### Important Notes:
- Always use **Test Mode** for development
- Test mode sends letter previews without actual mail
- Live mode charges per letter sent (~$1-2 per letter)
- Monitor your usage on the dashboard

### Pricing:
- First $300 in credits free
- Letters: ~$0.60 - $2.00 per letter (depending on pages)
- Check pricing: https://www.lob.com/pricing

---

## 3️⃣ SendGrid API Credentials

**Purpose**: Send email notifications to users and admins

### Step 1: Sign Up for SendGrid
1. Go to: https://sendgrid.com/
2. Click "Start for Free"
3. Complete registration (Twilio owns SendGrid now)
4. Free tier: **100 emails per day**

### Step 2: Verify Your Account
1. Verify your email address
2. Complete the account setup questionnaire

### Step 3: Create API Key
1. Log in to: https://app.sendgrid.com/
2. Navigate to: **Settings** → **API Keys**
   - Direct link: https://app.sendgrid.com/settings/api_keys
3. Click "Create API Key"

### Step 4: Configure API Key
1. **Name**: Enter a name (e.g., "USTAXX Production")
2. **Permissions**: Choose "Restricted Access"
3. Enable these permissions:
   - ✅ **Mail Send** → Full Access
   - ✅ **Stats** → Read Access (optional)
4. Click "Create & View"

### Step 5: Copy API Key
1. **IMPORTANT**: Copy the API key NOW - you won't see it again!
2. Format: `SG.abc123...` (starts with `SG.`)
3. Save it securely

### Step 6: Verify Sender Identity
1. Navigate to: **Settings** → **Sender Authentication**
2. Either:
   - **Option A**: Verify a single sender email
   - **Option B**: Authenticate your domain (recommended for production)

### Step 7: Save Your Credentials
```bash
SENDGRID_API_KEY=SG.<your_api_key>
```

### Important Notes:
- Free tier: 100 emails/day forever
- Essentials plan: $19.95/mo for 50k emails/month
- Must verify sender email or domain before sending
- Test emails in sandbox mode first

### Pricing:
- **Free**: 100 emails/day
- **Essentials**: $19.95/mo - 50k emails
- **Pro**: $89.95/mo - 1.5M emails
- Check pricing: https://sendgrid.com/pricing/

---

## 4️⃣ Twilio API Credentials

**Purpose**: Send SMS notifications for time-sensitive updates

### Step 1: Sign Up for Twilio
1. Go to: https://www.twilio.com/try-twilio
2. Click "Sign up and start building"
3. Complete registration
4. Free trial: **$15.50 in credits**

### Step 2: Verify Your Account
1. Verify your email address
2. Verify your phone number

### Step 3: Get Your Account SID and Auth Token
1. Log in to: https://console.twilio.com/
2. On the dashboard, you'll immediately see:
   - **Account SID** (starts with `AC`)
   - **Auth Token** (click "Show" to reveal)
3. Copy both values

### Step 4: Get a Phone Number
1. In the console, navigate to: **Phone Numbers** → **Manage** → **Buy a Number**
   - Direct link: https://console.twilio.com/us1/develop/phone-numbers/manage/search
2. Choose your country (United States)
3. Select capabilities: ✅ SMS
4. Click "Search"
5. Choose a phone number and click "Buy"
6. Confirm the purchase (uses trial credits)

### Step 5: Copy Your Phone Number
1. Navigate to: **Phone Numbers** → **Manage** → **Active Numbers**
2. Click on your purchased number
3. Copy the phone number (format: `+15551234567`)

### Step 6: Save Your Credentials
```bash
TWILIO_ACCOUNT_SID=AC<your_account_sid>
TWILIO_AUTH_TOKEN=<your_auth_token>
TWILIO_FROM_NUMBER=+1<your_phone_number>
```

### Important Notes:
- Trial accounts can only send SMS to verified numbers
- To remove restrictions, upgrade your account (add payment method)
- SMS cost: ~$0.0075 - $0.01 per message in US
- International SMS costs vary by country

### Upgrading from Trial:
1. Go to: https://console.twilio.com/us1/billing/manage-billing/upgrade-account
2. Add a payment method
3. This removes trial restrictions (send to any number)

### Pricing:
- **Trial**: $15.50 in free credits
- **SMS**: ~$0.0075/message (US)
- **Phone Number**: ~$1.15/month
- Check pricing: https://www.twilio.com/sms/pricing

---

## ✅ Setup Checklist

Once you have all credentials, create your `.env` file:

```bash
cd functions
cp .env.example .env
```

Then edit `functions/.env` and fill in your actual values:

```bash
# SmartCredit
SMARTCREDIT_CLIENT_ID=<your_actual_value>
SMARTCREDIT_CLIENT_SECRET=<your_actual_value>
SMARTCREDIT_WEBHOOK_SECRET=<your_actual_value>

# Lob
LOB_API_KEY_TEST=test_<your_actual_value>
LOB_API_KEY_LIVE=live_<your_actual_value>
LOB_WEBHOOK_SECRET=whsec_<your_actual_value>

# SendGrid
SENDGRID_API_KEY=SG.<your_actual_value>

# Twilio
TWILIO_ACCOUNT_SID=AC<your_actual_value>
TWILIO_AUTH_TOKEN=<your_actual_value>
TWILIO_FROM_NUMBER=+1<your_actual_value>
```

---

## 🧪 Testing Your Credentials

### Test Locally with Emulators

```bash
cd functions
npm run emulators
```

The emulators will use your `.env` file automatically.

### Test Individual Services

#### Test Lob:
```bash
curl https://api.lob.com/v1/us_verifications \
  -u "test_YOUR_KEY:" \
  -d "primary_line=185 Berry St" \
  -d "city=San Francisco" \
  -d "state=CA" \
  -d "zip_code=94107"
```

#### Test SendGrid:
```bash
curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer YOUR_API_KEY" \
  --header "Content-Type: application/json" \
  --data '{"personalizations":[{"to":[{"email":"test@example.com"}]}],"from":{"email":"test@example.com"},"subject":"Test","content":[{"type":"text/plain","value":"Test email"}]}'
```

#### Test Twilio:
```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT_SID/Messages.json" \
  --data-urlencode "Body=Test message" \
  --data-urlencode "From=YOUR_TWILIO_NUMBER" \
  --data-urlencode "To=YOUR_PHONE_NUMBER" \
  -u YOUR_ACCOUNT_SID:YOUR_AUTH_TOKEN
```

---

## 💰 Cost Estimate

For a small-medium credit repair business:

| Service | Free Tier | Monthly Cost (Est.) |
|---------|-----------|---------------------|
| SmartCredit | None | $100-500 (pay per report) |
| Lob | $300 credit | $50-200 (per letter volume) |
| SendGrid | 100/day | Free - $20 |
| Twilio | $15.50 credit | $10-50 |
| **Total** | | **$160-770/month** |

---

## 🔒 Security Best Practices

1. **Never commit `.env` to git** (already in `.gitignore`)
2. **Use test keys for development**
3. **Rotate keys regularly** (every 90 days)
4. **Use Firebase Secrets for production**:
   ```bash
   cd functions
   ./setup-secrets.sh
   ```
5. **Restrict API key permissions** to minimum required
6. **Monitor API usage** for unusual activity

---

## 🆘 Troubleshooting

### SmartCredit Access Issues
- Contact their sales team directly
- May require business verification documents
- Consider alternatives if access is delayed

### Lob Test Mode Not Working
- Ensure you're using `test_` prefix key
- Check you haven't exceeded free tier limits
- Verify address format is correct

### SendGrid Emails Not Sending
- Verify sender email address first
- Check daily limit (100 for free tier)
- Review Activity Feed for error messages

### Twilio SMS Not Sending (Trial)
- Trial accounts can only send to verified numbers
- Add recipient to verified numbers in console
- Or upgrade account to remove restrictions

---

## 📞 Support Contacts

- **SmartCredit**: https://www.smartcredit.com/contact
- **Lob Support**: support@lob.com
- **SendGrid Support**: https://support.sendgrid.com/
- **Twilio Support**: https://support.twilio.com/

---

## Next Steps

After obtaining all credentials:

1. ✅ Fill in `functions/.env` file
2. ✅ Test with Firebase emulators: `npm run emulators`
3. ✅ Set up Firebase Secrets: `./setup-secrets.sh`
4. ✅ Deploy functions: `firebase deploy --only functions`

See `DEPLOYMENT_CHECKLIST.md` for full deployment instructions.
