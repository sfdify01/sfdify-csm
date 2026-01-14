# SFDIFY Credit Dispute Letter System - API Specification

## Base URL
```
Production: https://api.sfdify.com/v1
Staging:    https://api-staging.sfdify.com/v1
```

## Authentication

All API requests require authentication via JWT Bearer token.

```http
Authorization: Bearer <access_token>
X-Tenant-ID: <tenant_uuid>
```

### Authentication Endpoints

#### POST /auth/login
```json
// Request
{
  "email": "operator@tenant.com",
  "password": "secure_password",
  "totp_code": "123456"  // Optional, required if 2FA enabled
}

// Response 200
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440010",
    "email": "operator@tenant.com",
    "role": "operator",
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
  }
}

// Response 401
{
  "error": "invalid_credentials",
  "message": "Invalid email or password"
}
```

#### POST /auth/refresh
```json
// Request
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}

// Response 200
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900
}
```

---

## Consumer Endpoints

### POST /consumers
Create a new consumer profile.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "first_name": "John",
  "middle_name": "Michael",
  "last_name": "Smith",
  "suffix": null,
  "dob": "1985-03-15",
  "ssn": "123-45-6789",  // Full SSN, will be encrypted
  "addresses": [
    {
      "type": "current",
      "line1": "456 Oak Avenue",
      "line2": "Apt 7B",
      "city": "Los Angeles",
      "state": "CA",
      "zip": "90001",
      "since": "2020-01-15"
    }
  ],
  "phones": [
    {
      "type": "mobile",
      "number": "+13105551234"
    }
  ],
  "emails": [
    {
      "type": "primary",
      "address": "john.smith@email.com"
    }
  ],
  "consent": {
    "accepted": true,
    "consent_text": "I authorize SFDIFY to access my credit reports..."
  }
}

// Response 201
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "first_name": "John",
  "middle_name": "Michael",
  "last_name": "Smith",
  "ssn_last4": "6789",
  "dob": "1985-03-15",
  "addresses": [...],
  "phones": [...],
  "emails": [...],
  "kyc_status": "pending",
  "consent_at": "2024-01-15T10:25:00Z",
  "created_at": "2024-01-15T10:25:00Z"
}

// Response 400
{
  "error": "validation_error",
  "message": "Invalid request data",
  "details": {
    "ssn": ["Invalid SSN format"],
    "dob": ["Must be at least 18 years old"]
  }
}
```

### GET /consumers
List consumers with pagination and filtering.

**Required Role:** `owner`, `operator`, `viewer`

```http
GET /consumers?page=1&limit=20&search=john&kyc_status=verified
```

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "first_name": "John",
      "last_name": "Smith",
      "ssn_last4": "6789",
      "kyc_status": "verified",
      "active_disputes_count": 2,
      "created_at": "2024-01-15T10:25:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "pages": 8
  }
}
```

### GET /consumers/{id}
Get consumer details.

**Required Role:** `owner`, `operator`, `viewer`

```json
// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "first_name": "John",
  "middle_name": "Michael",
  "last_name": "Smith",
  "ssn_last4": "6789",
  "dob": "1985-03-15",
  "addresses": [
    {
      "type": "current",
      "line1": "456 Oak Avenue",
      "line2": "Apt 7B",
      "city": "Los Angeles",
      "state": "CA",
      "zip": "90001",
      "verified": true,
      "since": "2020-01-15"
    }
  ],
  "phones": [...],
  "emails": [...],
  "kyc_status": "verified",
  "smartcredit_connected": true,
  "last_report_pull": "2024-01-20T14:00:00Z",
  "statistics": {
    "total_disputes": 5,
    "active_disputes": 2,
    "resolved_disputes": 3,
    "letters_sent": 8
  },
  "created_at": "2024-01-15T10:25:00Z",
  "updated_at": "2024-01-20T14:00:00Z"
}
```

---

## SmartCredit Integration

### POST /consumers/{id}/smartcredit/connect
Initiate SmartCredit OAuth flow.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "redirect_uri": "https://app.sfdify.com/callback/smartcredit",
  "scopes": ["reports", "tradelines", "alerts", "scores"]
}

// Response 200
{
  "authorization_url": "https://smartcredit.com/oauth/authorize?client_id=xxx&redirect_uri=xxx&state=xxx",
  "state": "random_state_token",
  "expires_in": 600
}
```

### POST /consumers/{id}/smartcredit/callback
Complete OAuth flow with authorization code.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "code": "authorization_code_from_smartcredit",
  "state": "random_state_token"
}

// Response 200
{
  "connection_id": "550e8400-e29b-41d4-a716-446655440050",
  "status": "active",
  "scopes": ["reports", "tradelines", "alerts", "scores"],
  "connected_at": "2024-01-15T10:30:00Z"
}
```

### POST /consumers/{id}/reports/refresh
Pull fresh credit reports from SmartCredit.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "bureaus": ["equifax", "experian", "transunion"]  // Optional, defaults to all
}

// Response 202 (Accepted - async operation)
{
  "job_id": "550e8400-e29b-41d4-a716-446655440060",
  "status": "queued",
  "estimated_completion": "2024-01-20T14:02:00Z"
}

// Alternative: Response 200 (if sync)
{
  "reports": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "bureau": "equifax",
      "pulled_at": "2024-01-20T14:00:00Z",
      "score": 685,
      "tradeline_count": 12
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "bureau": "experian",
      "pulled_at": "2024-01-20T14:00:05Z",
      "score": 692,
      "tradeline_count": 11
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "bureau": "transunion",
      "pulled_at": "2024-01-20T14:00:10Z",
      "score": 678,
      "tradeline_count": 13
    }
  ]
}
```

### GET /consumers/{id}/reports
List credit reports for a consumer.

**Required Role:** `owner`, `operator`, `viewer`

```http
GET /consumers/{id}/reports?bureau=equifax&from=2024-01-01&to=2024-01-31
```

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "bureau": "equifax",
      "pulled_at": "2024-01-20T14:00:00Z",
      "report_date": "2024-01-20",
      "score": 685,
      "score_factors": [
        {"code": "01", "description": "Amount owed on accounts is too high"}
      ],
      "tradeline_count": 12,
      "inquiry_count": 3,
      "public_record_count": 0
    }
  ],
  "pagination": {...}
}
```

### GET /consumers/{id}/tradelines
List tradelines across all bureaus.

**Required Role:** `owner`, `operator`, `viewer`

```http
GET /consumers/{id}/tradelines?bureau=equifax&status=negative&dispute_status=none
```

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "bureau": "equifax",
      "creditor_name": "Capital One Bank",
      "account_number_masked": "XXXX-XXXX-XXXX-5678",
      "account_type": "credit_card",
      "opened_date": "2019-06-15",
      "current_balance": 2450.00,
      "credit_limit": 5000.00,
      "payment_status": "Current",
      "account_status": "Open",
      "dispute_status": "none",
      "potential_issues": [
        {
          "code": "HIGH_UTILIZATION",
          "description": "Utilization above 30%",
          "severity": "medium"
        }
      ]
    }
  ],
  "summary": {
    "total_tradelines": 12,
    "positive": 8,
    "negative": 3,
    "neutral": 1,
    "with_potential_issues": 4
  },
  "pagination": {...}
}
```

---

## Dispute Endpoints

### POST /disputes
Create a new dispute.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "consumer_id": "550e8400-e29b-41d4-a716-446655440001",
  "tradeline_id": "550e8400-e29b-41d4-a716-446655440003",
  "bureau": "equifax",
  "type": "fcra_611_accuracy",
  "reason_codes": ["INACCURATE_BALANCE", "WRONG_PAYMENT_HISTORY"],
  "narrative": "The balance reported is incorrect...",
  "generate_ai_narrative": true  // Optional: use AI to enhance narrative
}

// Response 201
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "dispute_number": "DSP-00000042",
  "consumer_id": "550e8400-e29b-41d4-a716-446655440001",
  "tradeline_id": "550e8400-e29b-41d4-a716-446655440003",
  "bureau": "equifax",
  "type": "fcra_611_accuracy",
  "reason_codes": ["INACCURATE_BALANCE", "WRONG_PAYMENT_HISTORY"],
  "narrative": "The balance reported of $2,450.00 is incorrect...",
  "ai_generated": true,
  "status": "draft",
  "created_at": "2024-01-21T09:00:00Z"
}
```

### GET /disputes
List disputes with filtering.

**Required Role:** `owner`, `operator`, `viewer`

```http
GET /disputes?consumer_id=xxx&status=awaiting_response&bureau=equifax
```

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "dispute_number": "DSP-00000042",
      "consumer": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "John M. Smith"
      },
      "bureau": "equifax",
      "type": "fcra_611_accuracy",
      "status": "awaiting_response",
      "due_at": "2024-02-20T09:00:00Z",
      "days_remaining": 25,
      "letters_count": 1,
      "created_at": "2024-01-21T09:00:00Z"
    }
  ],
  "summary": {
    "total": 50,
    "by_status": {
      "draft": 5,
      "pending_review": 3,
      "awaiting_response": 25,
      "resolved": 17
    }
  },
  "pagination": {...}
}
```

### GET /disputes/{id}
Get full dispute details.

**Required Role:** `owner`, `operator`, `viewer`, `auditor`

```json
// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "dispute_number": "DSP-00000042",
  "consumer": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "John M. Smith",
    "ssn_last4": "6789",
    "current_address": {...}
  },
  "tradeline": {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "creditor_name": "Capital One Bank",
    "account_number_masked": "XXXX-XXXX-XXXX-5678",
    "current_balance": 2450.00
  },
  "bureau": "equifax",
  "type": "fcra_611_accuracy",
  "reason_codes": ["INACCURATE_BALANCE", "WRONG_PAYMENT_HISTORY"],
  "narrative": "The balance reported of $2,450.00 is incorrect...",
  "status": "awaiting_response",
  "timeline": {
    "created_at": "2024-01-21T09:00:00Z",
    "submitted_at": "2024-01-21T14:00:00Z",
    "due_at": "2024-02-20T14:00:00Z",
    "days_remaining": 25
  },
  "letters": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "type": "fcra_611_accuracy",
      "status": "delivered",
      "sent_at": "2024-01-21T14:00:00Z",
      "delivered_at": "2024-01-26T15:30:00Z"
    }
  ],
  "evidence": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440006",
      "filename": "capital-one-statement.pdf",
      "evidence_type": "bank_statement",
      "uploaded_at": "2024-01-21T09:15:00Z"
    }
  ],
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440007",
      "type": "check_response",
      "title": "Check bureau response",
      "due_at": "2024-02-21T09:00:00Z",
      "status": "pending"
    }
  ],
  "audit_trail": [
    {
      "action": "created",
      "actor": "John Operator",
      "timestamp": "2024-01-21T09:00:00Z"
    },
    {
      "action": "letter_sent",
      "actor": "system",
      "timestamp": "2024-01-21T14:00:00Z",
      "details": {"letter_id": "..."}
    }
  ]
}
```

### PATCH /disputes/{id}
Update dispute status or details.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "status": "resolved",
  "outcome": "corrected",
  "outcome_details": {
    "bureau_confirmation": "EQ-CONF-123456",
    "correction_type": "balance_updated",
    "new_balance": 1850.00
  },
  "bureau_response": "Investigation complete. Account updated."
}

// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "status": "resolved",
  "outcome": "corrected",
  "closed_at": "2024-02-18T10:00:00Z",
  ...
}
```

---

## Letter Endpoints

### POST /disputes/{id}/letters
Generate a letter for a dispute.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "type": "fcra_611_accuracy",
  "template_id": "550e8400-e29b-41d4-a716-446655440020",  // Optional
  "recipient_type": "bureau",
  "mail_type": "certified_return_receipt",
  "include_evidence": true,
  "custom_variables": {  // Optional overrides
    "additional_text": "Please expedite this investigation."
  }
}

// Response 201
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "dispute_id": "550e8400-e29b-41d4-a716-446655440004",
  "type": "fcra_611_accuracy",
  "subject": "Dispute of Inaccurate Information - Account XXXX5678",
  "recipient_name": "Equifax Information Services LLC",
  "recipient_address": {...},
  "mail_type": "certified_return_receipt",
  "status": "draft",
  "preview_url": "https://api.sfdify.com/v1/letters/xxx/preview",
  "estimated_cost": {
    "printing": 1.50,
    "postage": 7.75,
    "total": 9.25
  },
  "created_at": "2024-01-21T09:30:00Z"
}
```

### GET /letters/{id}
Get letter details.

**Required Role:** `owner`, `operator`, `viewer`, `auditor`

```json
// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "dispute_id": "550e8400-e29b-41d4-a716-446655440004",
  "type": "fcra_611_accuracy",
  "subject": "Dispute of Inaccurate Information - Account XXXX5678",
  "body_html": "<html>...</html>",
  "recipient_type": "bureau",
  "recipient_name": "Equifax Information Services LLC",
  "recipient_address": {
    "line1": "P.O. Box 740256",
    "city": "Atlanta",
    "state": "GA",
    "zip": "30374"
  },
  "return_address": {...},
  "mail_type": "certified_return_receipt",
  "status": "delivered",
  "pdf_url": "https://s3.../letters/ltr-xxx.pdf",
  "lob_id": "ltr_abc123def456",
  "tracking_number": "9400111899223456789012",
  "carrier": "USPS",
  "costs": {
    "printing": 1.50,
    "postage": 7.75,
    "total": 9.25
  },
  "timeline": {
    "created_at": "2024-01-21T09:30:00Z",
    "approved_at": "2024-01-21T11:00:00Z",
    "sent_at": "2024-01-21T14:00:00Z",
    "delivered_at": "2024-01-26T15:30:00Z"
  },
  "events": [
    {
      "type": "created",
      "timestamp": "2024-01-21T09:30:00Z"
    },
    {
      "type": "approved",
      "timestamp": "2024-01-21T11:00:00Z",
      "actor": "John Operator"
    },
    {
      "type": "mailed",
      "timestamp": "2024-01-21T14:00:00Z",
      "source": "lob_webhook"
    },
    {
      "type": "delivered",
      "timestamp": "2024-01-26T15:30:00Z",
      "source": "lob_webhook"
    }
  ],
  "evidence_attached": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440006",
      "filename": "capital-one-statement.pdf",
      "page_numbers": "2-3"
    }
  ]
}
```

### GET /letters/{id}/preview
Get letter preview (PDF or HTML).

**Required Role:** `owner`, `operator`, `viewer`

```http
GET /letters/{id}/preview?format=pdf
Accept: application/pdf
```

Returns binary PDF or HTML based on format parameter.

### POST /letters/{id}/approve
Approve letter for sending.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "comment": "Reviewed and approved for mailing"
}

// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "status": "approved",
  "approved_by": "550e8400-e29b-41d4-a716-446655440010",
  "approved_at": "2024-01-21T11:00:00Z"
}
```

### POST /letters/{id}/send
Send approved letter via Lob.

**Required Role:** `owner`, `operator`

```json
// Request
{
  "mail_type": "certified_return_receipt",  // Override if different
  "scheduled_date": "2024-01-22"  // Optional: schedule for future
}

// Response 202 (Accepted)
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "status": "queued",
  "job_id": "550e8400-e29b-41d4-a716-446655440070",
  "estimated_send_time": "2024-01-21T14:00:00Z"
}

// Alternative: Response 200 (immediate)
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "status": "sent",
  "lob_id": "ltr_abc123def456",
  "tracking_number": "9400111899223456789012",
  "expected_delivery": "2024-01-28",
  "costs": {
    "printing": 1.50,
    "postage": 7.75,
    "total": 9.25
  }
}
```

---

## Evidence Endpoints

### POST /disputes/{id}/evidence
Upload evidence file.

**Required Role:** `owner`, `operator`

```http
POST /disputes/{id}/evidence
Content-Type: multipart/form-data

file: <binary>
evidence_type: bank_statement
description: Capital One statement showing correct balance
```

```json
// Response 201
{
  "id": "550e8400-e29b-41d4-a716-446655440006",
  "dispute_id": "550e8400-e29b-41d4-a716-446655440004",
  "filename": "evidence-xxx-capital-one-statement.pdf",
  "original_filename": "CapitalOne_Statement.pdf",
  "file_size": 245678,
  "mime_type": "application/pdf",
  "evidence_type": "bank_statement",
  "description": "Capital One statement showing correct balance",
  "checksum_sha256": "e3b0c44298fc...",
  "virus_scan_status": "pending",
  "uploaded_at": "2024-01-21T09:15:00Z"
}
```

### GET /disputes/{id}/evidence
List evidence for a dispute.

**Required Role:** `owner`, `operator`, `viewer`, `auditor`

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440006",
      "filename": "capital-one-statement.pdf",
      "evidence_type": "bank_statement",
      "description": "Capital One statement showing correct balance",
      "file_size": 245678,
      "virus_scanned": true,
      "virus_scan_result": "clean",
      "download_url": "https://api.sfdify.com/v1/evidence/xxx/download",
      "uploaded_at": "2024-01-21T09:15:00Z"
    }
  ]
}
```

### GET /evidence/{id}/download
Download evidence file.

**Required Role:** `owner`, `operator`, `viewer`, `auditor`

Returns binary file with appropriate Content-Type header.

---

## Webhook Endpoints

### POST /webhooks/lob
Receive Lob delivery events.

```json
// Lob Webhook Payload
{
  "id": "evt_abc123",
  "event_type": {
    "id": "letter.delivered"
  },
  "body": {
    "id": "ltr_abc123def456",
    "tracking_events": [
      {
        "id": "evnt_xyz",
        "type": "delivered",
        "name": "Delivered",
        "time": "2024-01-26T15:30:00Z",
        "location": "LOS ANGELES, CA 90001"
      }
    ]
  }
}

// Response 200
{
  "received": true,
  "processed": true
}
```

### POST /webhooks/smartcredit
Receive SmartCredit events (report updates, alerts).

```json
// SmartCredit Webhook Payload
{
  "event_id": "sc_evt_123",
  "event_type": "report_updated",
  "consumer_id": "sc_user_456",
  "data": {
    "bureau": "equifax",
    "changes": ["new_inquiry", "balance_change"]
  },
  "timestamp": "2024-01-25T10:00:00Z"
}

// Response 200
{
  "received": true,
  "processed": true
}
```

---

## Template Endpoints

### GET /templates
List available letter templates.

**Required Role:** `owner`, `operator`

```json
// Response 200
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440020",
      "name": "FCRA 611 Accuracy Dispute",
      "type": "fcra_611_accuracy",
      "description": "Standard dispute letter for inaccurate information",
      "is_default": true,
      "fcra_sections": ["611"],
      "variables": [
        {"name": "consumer_name", "required": true},
        {"name": "account_number_masked", "required": true},
        {"name": "creditor_name", "required": true},
        {"name": "dispute_reason", "required": true}
      ],
      "version": 3,
      "updated_at": "2024-01-10T08:00:00Z"
    }
  ]
}
```

### GET /templates/{id}
Get template with full content.

**Required Role:** `owner`, `operator`

```json
// Response 200
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "name": "FCRA 611 Accuracy Dispute",
  "type": "fcra_611_accuracy",
  "subject_template": "Dispute of Inaccurate Information - {{creditor_name}} Account {{account_number_masked}}",
  "body_html": "<!DOCTYPE html>...",
  "body_text": "...",
  "variables": [...],
  "fcra_sections": ["611"],
  "disclaimer": "This letter is for informational purposes...",
  "version": 3
}
```

---

## Admin/Analytics Endpoints

### GET /analytics/overview
Dashboard overview statistics.

**Required Role:** `owner`

```json
// Response 200
{
  "period": {
    "start": "2024-01-01",
    "end": "2024-01-31"
  },
  "consumers": {
    "total": 1250,
    "new_this_period": 85,
    "with_active_disputes": 420
  },
  "disputes": {
    "total": 3500,
    "by_status": {
      "draft": 120,
      "awaiting_response": 890,
      "resolved": 2200,
      "escalated": 50
    },
    "by_outcome": {
      "deleted": 980,
      "corrected": 650,
      "verified": 420,
      "no_response": 150
    },
    "success_rate": 0.73
  },
  "letters": {
    "total_sent": 4200,
    "by_mail_type": {
      "first_class": 1500,
      "certified": 2000,
      "certified_return_receipt": 700
    },
    "delivery_rate": 0.98
  },
  "costs": {
    "total_postage": 28500.00,
    "total_printing": 6300.00,
    "average_per_letter": 8.29
  },
  "sla": {
    "on_time_responses": 0.85,
    "overdue_disputes": 45
  }
}
```

### GET /analytics/disputes
Detailed dispute analytics.

**Required Role:** `owner`

```http
GET /analytics/disputes?from=2024-01-01&to=2024-01-31&group_by=bureau
```

```json
// Response 200
{
  "period": {...},
  "data": [
    {
      "bureau": "equifax",
      "total": 1200,
      "outcomes": {
        "deleted": 350,
        "corrected": 220,
        "verified": 180
      },
      "average_resolution_days": 28,
      "success_rate": 0.72
    },
    {
      "bureau": "experian",
      "total": 1150,
      ...
    }
  ]
}
```

---

## Error Responses

All endpoints return consistent error responses:

```json
// 400 Bad Request
{
  "error": "validation_error",
  "message": "Invalid request data",
  "details": {
    "field_name": ["Error description"]
  },
  "request_id": "req_abc123"
}

// 401 Unauthorized
{
  "error": "unauthorized",
  "message": "Invalid or expired token",
  "request_id": "req_abc123"
}

// 403 Forbidden
{
  "error": "forbidden",
  "message": "Insufficient permissions for this action",
  "required_role": "operator",
  "your_role": "viewer",
  "request_id": "req_abc123"
}

// 404 Not Found
{
  "error": "not_found",
  "message": "Resource not found",
  "resource": "dispute",
  "id": "550e8400-...",
  "request_id": "req_abc123"
}

// 409 Conflict
{
  "error": "conflict",
  "message": "Letter already sent",
  "request_id": "req_abc123"
}

// 429 Too Many Requests
{
  "error": "rate_limited",
  "message": "Too many requests",
  "retry_after": 60,
  "request_id": "req_abc123"
}

// 500 Internal Server Error
{
  "error": "internal_error",
  "message": "An unexpected error occurred",
  "request_id": "req_abc123"
}
```

---

## Rate Limits

| Endpoint Pattern | Limit |
|-----------------|-------|
| `/auth/*` | 10/minute per IP |
| `POST /consumers/*/reports/refresh` | 10/hour per consumer |
| `POST /letters/*/send` | 100/hour per tenant |
| `POST /webhooks/*` | 1000/minute per provider |
| All other endpoints | 100/minute per user |

Rate limit headers included in all responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1706097600
```

---

## Pagination

All list endpoints support pagination:

```http
GET /disputes?page=2&limit=50
```

Response includes pagination metadata:
```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "limit": 50,
    "total": 250,
    "pages": 5,
    "has_next": true,
    "has_prev": true
  }
}
```

---

## Filtering & Sorting

List endpoints support filtering and sorting:

```http
GET /disputes?status=awaiting_response&bureau=equifax&sort=-created_at
```

- Prefix with `-` for descending order
- Multiple filters are AND-ed together
- Use `search` parameter for full-text search where supported
