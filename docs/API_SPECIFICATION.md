# SFDIFY Credit Dispute System - API Specification

## Base URL
```
Production: https://api.sfdify.com/v1
Staging: https://staging-api.sfdify.com/v1
Development: http://localhost:8000/v1
```

## Authentication
All API requests require authentication using Bearer tokens.

```http
Authorization: Bearer {access_token}
```

### Authentication Endpoints

#### POST /auth/login
Login with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd",
  "tenant_id": "tenant-uuid"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "token_type": "Bearer",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "role": "operator",
    "tenant_id": "tenant-uuid"
  }
}
```

#### POST /auth/refresh
Refresh access token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## Consumer Endpoints

### POST /consumers
Create a new consumer.

**Request:**
```json
{
  "first_name": "John",
  "middle_name": "Robert",
  "last_name": "Doe",
  "suffix": "Jr.",
  "date_of_birth": "1985-05-15",
  "ssn_last4": "1234",
  "addresses": [
    {
      "type": "current",
      "street1": "123 Main Street",
      "street2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "zip": "10001",
      "country": "US",
      "is_current": true,
      "moved_in_date": "2020-01-15"
    }
  ],
  "phones": [
    {
      "type": "mobile",
      "number": "+1-555-123-4567",
      "is_primary": true
    }
  ],
  "emails": [
    {
      "email": "john.doe@email.com",
      "is_primary": true
    }
  ],
  "consent_at": "2026-01-12T10:30:00Z",
  "consent_ip": "192.168.1.100"
}
```

**Response (201 Created):**
```json
{
  "id": "consumer-uuid",
  "tenant_id": "tenant-uuid",
  "first_name": "John",
  "last_name": "Doe",
  "date_of_birth": "1985-05-15",
  "ssn_last4": "1234",
  "kyc_status": "pending",
  "status": "active",
  "created_at": "2026-01-12T10:30:00Z",
  "updated_at": "2026-01-12T10:30:00Z"
}
```

### GET /consumers/{id}
Retrieve consumer details.

**Response (200 OK):**
```json
{
  "id": "consumer-uuid",
  "tenant_id": "tenant-uuid",
  "first_name": "John",
  "middle_name": "Robert",
  "last_name": "Doe",
  "full_name": "John Robert Doe Jr.",
  "date_of_birth": "1985-05-15",
  "age": 41,
  "ssn_last4": "1234",
  "addresses": [...],
  "phones": [...],
  "emails": [...],
  "smartcredit_connection_id": "sc-connection-123",
  "smartcredit_connected_at": "2026-01-12T11:00:00Z",
  "kyc_status": "verified",
  "status": "active",
  "created_at": "2026-01-12T10:30:00Z"
}
```

### POST /consumers/{id}/smartcredit/connect
Initiate SmartCredit OAuth connection.

**Request:**
```json
{
  "return_url": "https://app.sfdify.com/consumers/connected"
}
```

**Response (200 OK):**
```json
{
  "authorization_url": "https://api.smartcredit.com/oauth/authorize?client_id=...",
  "state": "random-state-token"
}
```

### POST /consumers/{id}/reports/refresh
Pull latest credit reports from SmartCredit.

**Request:**
```json
{
  "bureaus": ["equifax", "experian", "transunion"]
}
```

**Response (202 Accepted):**
```json
{
  "job_id": "job-uuid",
  "status": "queued",
  "message": "Credit report refresh queued for processing"
}
```

### GET /consumers/{id}/reports
Get consumer's credit reports.

**Query Parameters:**
- `bureau` (optional): Filter by bureau (equifax, experian, transunion)
- `status` (optional): Filter by status (current, superseded)
- `limit` (default: 10): Number of reports to return

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "report-uuid",
      "consumer_id": "consumer-uuid",
      "bureau": "equifax",
      "bureau_display_name": "Equifax",
      "pulled_at": "2026-01-12T12:00:00Z",
      "score": 720,
      "score_category": "Good",
      "status": "current",
      "days_since_pulled": 0,
      "needs_refresh": false,
      "created_at": "2026-01-12T12:00:00Z"
    }
  ],
  "meta": {
    "total": 3,
    "page": 1,
    "per_page": 10
  }
}
```

### GET /consumers/{id}/tradelines
Get consumer's tradelines.

**Query Parameters:**
- `bureau` (optional): Filter by bureau
- `status` (optional): Filter by status (open, closed)
- `disputed` (optional): Filter disputed items (true/false)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "tradeline-uuid",
      "report_id": "report-uuid",
      "bureau": "equifax",
      "creditor_name": "Chase Bank",
      "account_number_masked": "****1234",
      "account_type": "credit_card",
      "opened_date": "2018-03-15",
      "balance": 2500.00,
      "credit_limit": 10000.00,
      "utilization_percentage": 25.0,
      "status": "open",
      "payment_status": "current",
      "dispute_status": "not_disputed",
      "is_disputed": false,
      "created_at": "2026-01-12T12:00:00Z"
    }
  ],
  "meta": {
    "total": 15,
    "page": 1,
    "per_page": 20
  }
}
```

---

## Dispute Endpoints

### POST /disputes
Create a new dispute.

**Request:**
```json
{
  "consumer_id": "consumer-uuid",
  "tradeline_id": "tradeline-uuid",
  "bureau": "equifax",
  "type": "611_dispute",
  "reason_codes": ["inaccurate_balance", "wrong_dates"],
  "narrative": "This account shows an incorrect balance of $2,500. The actual balance should be $1,200 as I paid down $1,300 in December 2025.",
  "priority": "medium"
}
```

**Response (201 Created):**
```json
{
  "id": "dispute-uuid",
  "consumer_id": "consumer-uuid",
  "tradeline_id": "tradeline-uuid",
  "bureau": "equifax",
  "bureau_display_name": "Equifax",
  "type": "611_dispute",
  "type_display_name": "FCRA 611 Dispute",
  "reason_codes": ["inaccurate_balance", "wrong_dates"],
  "narrative": "This account shows an incorrect balance...",
  "status": "draft",
  "status_display_name": "Draft",
  "priority": "medium",
  "created_at": "2026-01-12T13:00:00Z",
  "updated_at": "2026-01-12T13:00:00Z"
}
```

### GET /disputes
List all disputes with filtering.

**Query Parameters:**
- `consumer_id` (optional)
- `bureau` (optional)
- `status` (optional)
- `priority` (optional)
- `assigned_to` (optional)
- `overdue` (optional): true/false
- `page` (default: 1)
- `per_page` (default: 20)
- `sort_by` (default: created_at)
- `sort_order` (default: desc)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "dispute-uuid",
      "consumer": {
        "id": "consumer-uuid",
        "full_name": "John Robert Doe Jr."
      },
      "tradeline": {
        "id": "tradeline-uuid",
        "creditor_name": "Chase Bank",
        "account_number_masked": "****1234"
      },
      "bureau": "equifax",
      "type": "611_dispute",
      "type_display_name": "FCRA 611 Dispute",
      "status": "mailed",
      "status_color": "blue",
      "priority": "medium",
      "due_at": "2026-02-11T13:00:00Z",
      "days_remaining": 30,
      "is_overdue": false,
      "is_sla_approaching": false,
      "created_at": "2026-01-12T13:00:00Z"
    }
  ],
  "meta": {
    "total": 124,
    "page": 1,
    "per_page": 20,
    "total_pages": 7
  }
}
```

### GET /disputes/{id}
Get dispute details.

**Response (200 OK):**
```json
{
  "id": "dispute-uuid",
  "consumer": {...},
  "tradeline": {...},
  "bureau": "equifax",
  "type": "611_dispute",
  "reason_codes": ["inaccurate_balance"],
  "narrative": "This account shows an incorrect balance...",
  "status": "delivered",
  "outcome": "pending",
  "letters": [
    {
      "id": "letter-uuid",
      "type": "611_dispute",
      "status": "delivered",
      "sent_at": "2026-01-13T10:00:00Z",
      "delivered_at": "2026-01-16T14:30:00Z"
    }
  ],
  "evidence": [
    {
      "id": "evidence-uuid",
      "filename": "bank_statement.pdf",
      "file_size": 245678,
      "mime_type": "application/pdf"
    }
  ],
  "timeline": [
    {
      "event": "created",
      "timestamp": "2026-01-12T13:00:00Z",
      "actor": "John Operator"
    },
    {
      "event": "letter_generated",
      "timestamp": "2026-01-13T09:00:00Z"
    },
    {
      "event": "letter_sent",
      "timestamp": "2026-01-13T10:00:00Z"
    }
  ],
  "created_at": "2026-01-12T13:00:00Z",
  "due_at": "2026-02-11T13:00:00Z"
}
```

### PATCH /disputes/{id}
Update dispute.

**Request:**
```json
{
  "status": "approved",
  "narrative": "Updated narrative text...",
  "assigned_to_user_id": "user-uuid",
  "priority": "high"
}
```

### POST /disputes/{id}/evidence
Upload evidence to a dispute.

**Request (multipart/form-data):**
```
file: [binary file data]
description: Bank statement showing payment
source: uploaded
```

**Response (201 Created):**
```json
{
  "id": "evidence-uuid",
  "dispute_id": "dispute-uuid",
  "filename": "bank_statement.pdf",
  "file_url": "https://storage.sfdify.com/evidence/uuid/file.pdf",
  "mime_type": "application/pdf",
  "file_size": 245678,
  "formatted_file_size": "239.9 KB",
  "checksum": "sha256-hash",
  "source": "uploaded",
  "scanned": false,
  "uploaded_at": "2026-01-12T14:00:00Z"
}
```

### DELETE /disputes/{id}/evidence/{evidence_id}
Delete evidence from dispute.

**Response (204 No Content)**

### GET /disputes/{id}/timeline
Get dispute timeline/activity log.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "timeline-uuid",
      "event_type": "status_changed",
      "event_data": {
        "from": "draft",
        "to": "approved"
      },
      "actor": {
        "id": "user-uuid",
        "name": "John Operator",
        "role": "operator"
      },
      "timestamp": "2026-01-12T15:00:00Z",
      "description": "Status changed from Draft to Approved"
    }
  ]
}
```

---

## Letter Endpoints

### POST /letters
Create a new letter for a dispute.

**Request:**
```json
{
  "dispute_id": "dispute-uuid",
  "type": "611_dispute",
  "template_id": "template-uuid",
  "mail_type": "usps_certified_return_receipt",
  "recipient_address": {
    "name": "Equifax Information Services LLC",
    "street1": "P.O. Box 740256",
    "city": "Atlanta",
    "state": "GA",
    "zip": "30374",
    "country": "US"
  },
  "return_address": {
    "name": "John Doe",
    "street1": "123 Main Street",
    "street2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "zip": "10001",
    "country": "US"
  }
}
```

**Response (201 Created):**
```json
{
  "id": "letter-uuid",
  "dispute_id": "dispute-uuid",
  "type": "611_dispute",
  "mail_type": "usps_certified_return_receipt",
  "mail_type_display_name": "Certified Mail with Return Receipt",
  "status": "draft",
  "estimated_cost": 10.73,
  "created_at": "2026-01-12T16:00:00Z"
}
```

### GET /letters/{id}
Get letter details.

**Response (200 OK):**
```json
{
  "id": "letter-uuid",
  "dispute_id": "dispute-uuid",
  "type": "611_dispute",
  "type_display_name": "FCRA 611 Dispute",
  "template_id": "template-uuid",
  "mail_type": "usps_certified_return_receipt",
  "status": "delivered",
  "status_color": "green",
  "pdf_url": "https://storage.sfdify.com/letters/uuid/letter.pdf",
  "lob_id": "ltr_123abc",
  "lob_url": "https://dashboard.lob.com/#/letters/ltr_123abc",
  "tracking_code": "9400100000000000000000",
  "tracking_url": "https://tools.usps.com/go/TrackConfirmAction?tLabels=9400100000000000000000",
  "expected_delivery_date": "2026-01-20",
  "recipient_address": {...},
  "return_address": {...},
  "approved_at": "2026-01-13T09:00:00Z",
  "sent_at": "2026-01-13T10:00:00Z",
  "delivered_at": "2026-01-16T14:30:00Z",
  "cost": 10.73,
  "formatted_cost": "$10.73",
  "days_since_sent": 3,
  "created_at": "2026-01-12T16:00:00Z"
}
```

### GET /letters/{id}/pdf
Download letter PDF.

**Response (200 OK):**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="dispute_letter_611.pdf"

[PDF binary data]
```

### POST /letters/{id}/approve
Approve letter for sending.

**Request:**
```json
{
  "approved_by_user_id": "user-uuid",
  "notes": "Reviewed and approved for mailing"
}
```

**Response (200 OK):**
```json
{
  "id": "letter-uuid",
  "status": "approved",
  "approved_at": "2026-01-13T09:00:00Z",
  "approved_by_user_id": "user-uuid"
}
```

### POST /letters/{id}/send
Send approved letter via Lob.

**Response (200 OK):**
```json
{
  "id": "letter-uuid",
  "status": "queued",
  "lob_id": "ltr_123abc",
  "estimated_delivery_date": "2026-01-20",
  "message": "Letter queued for mailing"
}
```

### POST /letters/{id}/reject
Reject letter and request changes.

**Request:**
```json
{
  "reason": "Incorrect recipient address",
  "notes": "Please update the bureau address"
}
```

---

## Letter Template Endpoints

### GET /letter-templates
List available letter templates.

**Query Parameters:**
- `type` (optional): Filter by template type
- `active` (optional): Filter active templates

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "template-uuid",
      "name": "FCRA 611 Dispute - Standard",
      "type": "611_dispute",
      "type_display_name": "FCRA 611 Dispute",
      "description": "Standard dispute letter for inaccurate information",
      "is_system_template": true,
      "active": true,
      "version": 1,
      "required_variables": ["consumer_name", "dob", "ssn_last4", "tradelines"],
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

### GET /letter-templates/{id}
Get template details including content.

**Response (200 OK):**
```json
{
  "id": "template-uuid",
  "name": "FCRA 611 Dispute - Standard",
  "type": "611_dispute",
  "content": "Dear {{bureau_name}},\n\nI am writing to dispute...",
  "variables": {
    "consumer_name": {
      "description": "Full name of the consumer",
      "type": "string",
      "required": true
    },
    "dob": {
      "description": "Date of birth",
      "type": "date",
      "format": "MMMM d, yyyy",
      "required": true
    }
  },
  "disclaimer": "This letter is for informational purposes only...",
  "legal_citations": ["15 U.S.C. § 1681i"],
  "active": true
}
```

---

## Webhook Endpoints

### POST /webhooks/lob
Receive webhooks from Lob.

**Request (from Lob):**
```json
{
  "id": "evt_123abc",
  "event_type": "letter.delivered",
  "date_created": "2026-01-16T14:30:00Z",
  "object": {
    "id": "ltr_123abc",
    "status": "delivered",
    "tracking_events": [...]
  }
}
```

**Response (200 OK):**
```json
{
  "received": true
}
```

### POST /webhooks/smartcredit
Receive webhooks from SmartCredit.

**Request (from SmartCredit):**
```json
{
  "event_type": "credit_report.updated",
  "consumer_id": "sc-consumer-123",
  "bureau": "equifax",
  "timestamp": "2026-01-12T12:00:00Z"
}
```

---

## Admin Endpoints

### GET /admin/metrics
Get system metrics and analytics.

**Response (200 OK):**
```json
{
  "disputes": {
    "total": 1240,
    "active": 245,
    "resolved": 895,
    "sla_breaches": 3,
    "average_resolution_days": 35
  },
  "letters": {
    "sent_this_month": 120,
    "in_transit": 45,
    "delivered": 72,
    "returned": 3,
    "total_cost_this_month": 1287.60
  },
  "consumers": {
    "total": 520,
    "with_smartcredit": 480,
    "kyc_verified": 515
  }
}
```

### GET /admin/billing
Get billing information.

**Response (200 OK):**
```json
{
  "current_period": {
    "start": "2026-01-01",
    "end": "2026-01-31",
    "letter_count": 120,
    "certified_letter_count": 85,
    "first_class_letter_count": 35,
    "smartcredit_pull_count": 45,
    "lob_postage_total": 1024.05,
    "smartcredit_cost": 135.00,
    "platform_fee": 199.00,
    "amount_due": 1358.05,
    "status": "pending"
  }
}
```

---

## Error Responses

### Standard Error Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

### HTTP Status Codes
- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `202 Accepted`: Request accepted for async processing
- `204 No Content`: Successful request with no response body
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource conflict (e.g., duplicate)
- `422 Unprocessable Entity`: Validation error
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Service temporarily unavailable

---

## Rate Limiting

API requests are rate-limited per tenant:

- **Free Tier**: 100 requests/hour
- **Professional**: 1,000 requests/hour
- **Enterprise**: 10,000 requests/hour

Rate limit headers:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1610000000
```

---

**API Version**: v1
**Last Updated**: 2026-01-12
**Documentation**: https://docs.sfdify.com/api
