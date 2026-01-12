# SFDIFY Credit Dispute System - Database Schema & ERD

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MULTI-TENANT ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   tenants    │
├──────────────┤
│ id (PK)      │─────┐
│ name         │     │
│ plan         │     │
│ branding     │     │
│ created_at   │     │
└──────────────┘     │
                     │ 1:N
                     │
                     ├──────────────────────────────────┐
                     │                                  │
                     ▼                                  ▼
          ┌──────────────┐                   ┌──────────────────┐
          │    users     │                   │    consumers     │
          ├──────────────┤                   ├──────────────────┤
          │ id (PK)      │                   │ id (PK)          │
          │ tenant_id(FK)│                   │ tenant_id (FK)   │
          │ role         │                   │ first_name       │
          │ email        │                   │ last_name        │
          │ phone        │                   │ dob              │
          │ 2fa_secret   │                   │ ssn_last4        │
          │ created_at   │                   │ addresses[]      │
          └──────────────┘                   │ phones[]         │
                                             │ emails[]         │
                                             │ smartcredit_id   │
                                             │ kyc_status       │
                                             │ consent_at       │
                                             │ created_at       │
                                             └──────────────────┘
                                                      │ 1:N
                                                      ▼
                                             ┌──────────────────┐
                                             │  credit_reports  │
                                             ├──────────────────┤
                                             │ id (PK)          │
                                             │ consumer_id (FK) │─────┐
                                             │ pulled_at        │     │
                                             │ bureau           │     │
                                             │ raw_json         │     │
                                             │ hash             │     │
                                             │ score            │     │
                                             │ status           │     │
                                             └──────────────────┘     │
                                                                      │ 1:N
                                                                      ▼
                                             ┌──────────────────────────────────┐
                                             │          tradelines              │
                                             ├──────────────────────────────────┤
                                             │ id (PK)                          │
                                             │ report_id (FK)                   │
                                             │ bureau                           │
                                             │ creditor_name                    │
                                             │ account_number_masked            │
                                             │ account_type                     │
                                             │ opened_date                      │
                                             │ balance                          │
                                             │ status                           │
                                             │ payment_status                   │
                                             │ dispute_status                   │
                                             │ last_payment_date                │
                                             │ credit_limit                     │
                                             │ remarks                          │
                                             └──────────────────────────────────┘
                                                      │
                                                      │ 1:N
                                                      ▼
                              ┌────────────────────────────────────────────────┐
                              │                   disputes                     │
                              ├────────────────────────────────────────────────┤
                              │ id (PK)                                        │
                              │ consumer_id (FK)                               │
                              │ tradeline_id (FK)                              │
                              │ bureau                                         │
                              │ type                                           │
                              │ reason_codes[]                                 │
                              │ narrative                                      │
                              │ status                                         │
                              │ created_at                                     │
                              │ due_at                                         │
                              │ closed_at                                      │
                              │ outcome                                        │
                              │ resolution_notes                               │
                              └────────────────────────────────────────────────┘
                                      │                      │
                                      │ 1:N                  │ 1:N
                                      ▼                      ▼
                    ┌──────────────────────┐     ┌──────────────────────┐
                    │      letters         │     │      evidence        │
                    ├──────────────────────┤     ├──────────────────────┤
                    │ id (PK)              │     │ id (PK)              │
                    │ dispute_id (FK)      │     │ dispute_id (FK)      │
                    │ type                 │     │ filename             │
                    │ template_id          │     │ file_url             │
                    │ render_version       │     │ mime_type            │
                    │ pdf_url              │     │ file_size            │
                    │ lob_id               │     │ checksum             │
                    │ mail_type            │     │ source               │
                    │ tracking_code        │     │ scanned              │
                    │ status               │     │ uploaded_at          │
                    │ sent_at              │     │ uploaded_by_id (FK)  │
                    │ delivered_at         │     └──────────────────────┘
                    │ returned_at          │
                    │ cost                 │
                    │ created_at           │
                    └──────────────────────┘
                            │
                            │ References
                            ▼
                    ┌──────────────────────┐
                    │ letter_templates     │
                    ├──────────────────────┤
                    │ id (PK)              │
                    │ tenant_id (FK)       │
                    │ name                 │
                    │ type                 │
                    │ content              │
                    │ variables[]          │
                    │ compliance_notes     │
                    │ version              │
                    │ active               │
                    │ created_at           │
                    └──────────────────────┘

┌──────────────────────┐        ┌──────────────────────────┐
│      webhooks        │        │      audit_logs          │
├──────────────────────┤        ├──────────────────────────┤
│ id (PK)              │        │ id (PK)                  │
│ provider             │        │ tenant_id (FK)           │
│ event_type           │        │ actor_id (FK)            │
│ payload              │        │ actor_role               │
│ received_at          │        │ entity                   │
│ processed_at         │        │ entity_id                │
│ status               │        │ action                   │
│ error_message        │        │ diff_json                │
│ retry_count          │        │ ip_address               │
└──────────────────────┘        │ user_agent               │
                                │ created_at               │
                                └──────────────────────────┘

┌──────────────────────────┐
│    billing_invoices      │
├──────────────────────────┤
│ id (PK)                  │
│ tenant_id (FK)           │
│ billing_period_start     │
│ billing_period_end       │
│ letter_count             │
│ lob_postage_total        │
│ smartcredit_pulls        │
│ smartcredit_cost         │
│ platform_fee             │
│ amount_due               │
│ status                   │
│ paid_at                  │
│ invoice_pdf_url          │
│ created_at               │
└──────────────────────────┘

┌──────────────────────────┐
│   consumer_consents      │
├──────────────────────────┤
│ id (PK)                  │
│ consumer_id (FK)         │
│ consent_type             │
│ consented_at             │
│ ip_address               │
│ user_agent               │
│ revoked_at               │
└──────────────────────────┘
```

## Table Definitions with Constraints

### 1. tenants
Multi-tenant isolation and branding.

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    plan VARCHAR(50) NOT NULL, -- 'starter', 'professional', 'enterprise'
    branding JSONB, -- logo_url, primary_color, letterhead_url
    settings JSONB, -- feature flags, limits, configs
    lob_api_key VARCHAR(255) ENCRYPTED,
    smartcredit_client_id VARCHAR(255) ENCRYPTED,
    smartcredit_client_secret VARCHAR(255) ENCRYPTED,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_plan CHECK (plan IN ('starter', 'professional', 'enterprise')),
    CONSTRAINT chk_status CHECK (status IN ('active', 'suspended', 'cancelled'))
);

CREATE INDEX idx_tenants_status ON tenants(status);
```

### 2. users
System operators with role-based access.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    totp_secret VARCHAR(255) ENCRYPTED,
    totp_enabled BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_role CHECK (role IN ('owner', 'operator', 'viewer', 'auditor')),
    CONSTRAINT chk_status CHECK (status IN ('active', 'suspended', 'deleted')),
    CONSTRAINT uk_users_email_tenant UNIQUE (tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
```

### 3. consumers
End users whose credit is being disputed.

```sql
CREATE TABLE consumers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    suffix VARCHAR(20),
    dob DATE NOT NULL ENCRYPTED,
    ssn_last4 VARCHAR(4) NOT NULL,
    ssn_full VARCHAR(11) ENCRYPTED, -- stored only if needed

    -- Addresses (JSONB array)
    addresses JSONB NOT NULL, -- [{type, street1, street2, city, state, zip, country, is_current}]

    -- Contact
    phones JSONB, -- [{type: 'mobile'|'home'|'work', number, is_primary}]
    emails JSONB, -- [{email, is_primary, verified}]

    -- SmartCredit Integration
    smartcredit_connection_id VARCHAR(255),
    smartcredit_access_token TEXT ENCRYPTED,
    smartcredit_refresh_token TEXT ENCRYPTED,
    smartcredit_token_expires_at TIMESTAMP,
    smartcredit_connected_at TIMESTAMP,

    -- Verification
    kyc_status VARCHAR(50) DEFAULT 'pending',
    kyc_completed_at TIMESTAMP,

    -- Consent
    consent_at TIMESTAMP,
    consent_ip INET,

    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_kyc_status CHECK (kyc_status IN ('pending', 'verified', 'failed', 'manual_review')),
    CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'deleted'))
);

CREATE INDEX idx_consumers_tenant ON consumers(tenant_id);
CREATE INDEX idx_consumers_smartcredit ON consumers(smartcredit_connection_id);
CREATE INDEX idx_consumers_status ON consumers(status);
```

### 4. credit_reports
Bureau credit report snapshots.

```sql
CREATE TABLE credit_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    bureau VARCHAR(20) NOT NULL,
    pulled_at TIMESTAMP NOT NULL,
    raw_json JSONB NOT NULL,
    hash VARCHAR(64) NOT NULL, -- SHA-256 of raw_json for change detection
    score INTEGER,
    status VARCHAR(50) NOT NULL,
    smartcredit_report_id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_bureau CHECK (bureau IN ('equifax', 'experian', 'transunion')),
    CONSTRAINT chk_status CHECK (status IN ('current', 'superseded', 'failed'))
);

CREATE INDEX idx_reports_consumer ON credit_reports(consumer_id);
CREATE INDEX idx_reports_bureau ON credit_reports(bureau);
CREATE INDEX idx_reports_pulled_at ON credit_reports(pulled_at DESC);
CREATE INDEX idx_reports_hash ON credit_reports(hash);
```

### 5. tradelines
Individual credit accounts on reports.

```sql
CREATE TABLE tradelines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES credit_reports(id) ON DELETE CASCADE,
    bureau VARCHAR(20) NOT NULL,

    -- Account Information
    creditor_name VARCHAR(255) NOT NULL,
    account_number_masked VARCHAR(50),
    account_type VARCHAR(50), -- 'credit_card', 'mortgage', 'auto_loan', etc.

    -- Dates
    opened_date DATE,
    closed_date DATE,
    last_payment_date DATE,
    last_reported_date DATE,

    -- Amounts
    balance DECIMAL(12, 2),
    original_amount DECIMAL(12, 2),
    credit_limit DECIMAL(12, 2),
    high_balance DECIMAL(12, 2),
    monthly_payment DECIMAL(12, 2),

    -- Status
    status VARCHAR(50), -- 'open', 'closed', 'paid', 'charged_off', etc.
    payment_status VARCHAR(50), -- 'current', 'late_30', 'late_60', 'late_90', 'collection'
    dispute_status VARCHAR(50), -- 'not_disputed', 'disputed', 'resolved'

    -- Remarks
    remarks TEXT,
    payment_history VARCHAR(255), -- "000000111222" format

    -- SmartCredit reference
    smartcredit_tradeline_id VARCHAR(255),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_bureau CHECK (bureau IN ('equifax', 'experian', 'transunion'))
);

CREATE INDEX idx_tradelines_report ON tradelines(report_id);
CREATE INDEX idx_tradelines_creditor ON tradelines(creditor_name);
CREATE INDEX idx_tradelines_smartcredit ON tradelines(smartcredit_tradeline_id);
```

### 6. disputes
Consumer dispute cases.

```sql
CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    tradeline_id UUID REFERENCES tradelines(id) ON DELETE SET NULL,
    bureau VARCHAR(20) NOT NULL,

    -- Dispute Details
    type VARCHAR(50) NOT NULL, -- '609_request', '611_dispute', 'mov_request', 'reinvestigation', etc.
    reason_codes VARCHAR(255)[], -- ['not_mine', 'inaccurate_balance', 'duplicate', etc.]
    narrative TEXT,

    -- Status & Timeline
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMP,
    due_at TIMESTAMP,
    followed_up_at TIMESTAMP,
    closed_at TIMESTAMP,

    -- Outcome
    outcome VARCHAR(50), -- 'pending', 'corrected', 'verified', 'deleted', 'updated', 'no_change'
    resolution_notes TEXT,
    bureau_response_received_at TIMESTAMP,

    -- Assignments
    assigned_to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    priority VARCHAR(20) DEFAULT 'medium',

    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_bureau CHECK (bureau IN ('equifax', 'experian', 'transunion')),
    CONSTRAINT chk_type CHECK (type IN (
        '609_request', '611_dispute', 'mov_request', 'reinvestigation',
        'goodwill', 'pay_for_delete', 'identity_theft_block', 'cfpb_complaint'
    )),
    CONSTRAINT chk_status CHECK (status IN (
        'draft', 'pending_review', 'approved', 'mailed', 'delivered',
        'in_transit', 'bureau_investigating', 'resolved', 'closed', 'cancelled'
    )),
    CONSTRAINT chk_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent'))
);

CREATE INDEX idx_disputes_consumer ON disputes(consumer_id);
CREATE INDEX idx_disputes_tradeline ON disputes(tradeline_id);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_due_at ON disputes(due_at);
CREATE INDEX idx_disputes_bureau ON disputes(bureau);
```

### 7. letters
Generated and mailed dispute letters.

```sql
CREATE TABLE letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,

    -- Letter Details
    type VARCHAR(50) NOT NULL,
    template_id UUID REFERENCES letter_templates(id),
    render_version INTEGER NOT NULL DEFAULT 1,

    -- Content
    content_html TEXT,
    content_markdown TEXT,
    pdf_url TEXT,
    pdf_checksum VARCHAR(64),

    -- Lob Integration
    lob_id VARCHAR(255),
    lob_url TEXT,
    mail_type VARCHAR(50) NOT NULL, -- 'usps_first_class', 'certified', 'certified_return_receipt'
    tracking_code VARCHAR(255),
    tracking_url TEXT,
    expected_delivery_date DATE,

    -- Addresses
    recipient_address JSONB NOT NULL,
    return_address JSONB NOT NULL,

    -- Status & Timestamps
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP,
    approved_by_user_id UUID REFERENCES users(id),
    sent_at TIMESTAMP,
    in_transit_at TIMESTAMP,
    delivered_at TIMESTAMP,
    returned_at TIMESTAMP,

    -- Cost
    cost DECIMAL(10, 2),

    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_mail_type CHECK (mail_type IN (
        'usps_first_class', 'usps_certified', 'usps_certified_return_receipt'
    )),
    CONSTRAINT chk_status CHECK (status IN (
        'draft', 'pending_approval', 'approved', 'rendering', 'ready',
        'queued', 'sent', 'in_transit', 'in_local_area', 'processed_for_delivery',
        'delivered', 'returned_to_sender', 'failed'
    ))
);

CREATE INDEX idx_letters_dispute ON letters(dispute_id);
CREATE INDEX idx_letters_lob_id ON letters(lob_id);
CREATE INDEX idx_letters_status ON letters(status);
CREATE INDEX idx_letters_sent_at ON letters(sent_at DESC);
```

### 8. letter_templates
Reusable letter templates.

```sql
CREATE TABLE letter_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL for system templates

    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,

    -- Content (Markdown with template variables)
    content TEXT NOT NULL,

    -- Variables
    variables JSONB, -- [{name, description, type, required, default}]

    -- Compliance
    compliance_notes TEXT,
    disclaimer TEXT,
    legal_citations TEXT[],

    -- Version Control
    version INTEGER NOT NULL DEFAULT 1,
    active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by_user_id UUID REFERENCES users(id),

    CONSTRAINT chk_type CHECK (type IN (
        '609_request', '611_dispute', 'mov_request', 'reinvestigation',
        'goodwill', 'pay_for_delete', 'identity_theft_block', 'cfpb_complaint', 'custom'
    ))
);

CREATE INDEX idx_templates_tenant ON letter_templates(tenant_id);
CREATE INDEX idx_templates_type ON letter_templates(type);
CREATE INDEX idx_templates_active ON letter_templates(active);
```

### 9. evidence
Supporting documents for disputes.

```sql
CREATE TABLE evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,

    -- File Details
    filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL, -- bytes
    checksum VARCHAR(64) NOT NULL, -- SHA-256

    -- Source
    source VARCHAR(50) NOT NULL, -- 'uploaded', 'smartcredit', 'generated'
    description TEXT,

    -- Security
    scanned BOOLEAN DEFAULT FALSE,
    scan_result VARCHAR(50),
    encrypted BOOLEAN DEFAULT TRUE,

    -- Metadata
    uploaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    uploaded_by_user_id UUID REFERENCES users(id),

    CONSTRAINT chk_source CHECK (source IN ('uploaded', 'smartcredit', 'generated')),
    CONSTRAINT chk_mime_type CHECK (mime_type IN (
        'application/pdf', 'image/jpeg', 'image/png', 'image/gif',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ))
);

CREATE INDEX idx_evidence_dispute ON evidence(dispute_id);
CREATE INDEX idx_evidence_checksum ON evidence(checksum);
```

### 10. webhooks
Incoming webhook events from external services.

```sql
CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL, -- 'lob', 'smartcredit'
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    signature VARCHAR(255),

    -- Processing
    received_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,

    -- Idempotency
    idempotency_key VARCHAR(255),

    CONSTRAINT chk_provider CHECK (provider IN ('lob', 'smartcredit')),
    CONSTRAINT chk_status CHECK (status IN ('pending', 'processing', 'processed', 'failed'))
);

CREATE INDEX idx_webhooks_provider ON webhooks(provider);
CREATE INDEX idx_webhooks_status ON webhooks(status);
CREATE INDEX idx_webhooks_idempotency ON webhooks(idempotency_key);
CREATE INDEX idx_webhooks_received_at ON webhooks(received_at DESC);
```

### 11. audit_logs
Comprehensive audit trail.

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Actor
    actor_id UUID REFERENCES users(id),
    actor_role VARCHAR(50),
    actor_email VARCHAR(255),

    -- Entity
    entity VARCHAR(100) NOT NULL, -- 'consumer', 'dispute', 'letter', etc.
    entity_id UUID NOT NULL,

    -- Action
    action VARCHAR(50) NOT NULL, -- 'create', 'read', 'update', 'delete', 'approve', 'send', etc.

    -- Changes
    diff_json JSONB, -- {before: {...}, after: {...}}

    -- Context
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(255),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_action CHECK (action IN (
        'create', 'read', 'update', 'delete', 'approve', 'reject',
        'send', 'upload', 'download', 'export', 'login', 'logout'
    ))
);

CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_audit_actor ON audit_logs(actor_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity, entity_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created_at ON audit_logs(created_at DESC);
```

### 12. billing_invoices
Tenant billing and usage tracking.

```sql
CREATE TABLE billing_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Period
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,

    -- Usage Metrics
    letter_count INTEGER NOT NULL DEFAULT 0,
    certified_letter_count INTEGER NOT NULL DEFAULT 0,
    first_class_letter_count INTEGER NOT NULL DEFAULT 0,
    smartcredit_pull_count INTEGER NOT NULL DEFAULT 0,

    -- Costs
    lob_postage_total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    smartcredit_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    platform_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    tax DECIMAL(10, 2) DEFAULT 0,
    amount_due DECIMAL(10, 2) NOT NULL,

    -- Payment
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP,
    payment_method VARCHAR(50),
    payment_reference VARCHAR(255),

    -- Document
    invoice_pdf_url TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    due_date DATE NOT NULL,

    CONSTRAINT chk_status CHECK (status IN ('draft', 'pending', 'paid', 'overdue', 'cancelled')),
    CONSTRAINT uk_billing_tenant_period UNIQUE (tenant_id, billing_period_start)
);

CREATE INDEX idx_billing_tenant ON billing_invoices(tenant_id);
CREATE INDEX idx_billing_status ON billing_invoices(status);
CREATE INDEX idx_billing_due_date ON billing_invoices(due_date);
```

### 13. consumer_consents
FCRA and privacy law consent tracking.

```sql
CREATE TABLE consumer_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,

    consent_type VARCHAR(100) NOT NULL, -- 'fcra_authorization', 'smartcredit_connection', 'data_processing', etc.
    consented_at TIMESTAMP NOT NULL,
    ip_address INET NOT NULL,
    user_agent TEXT,

    -- Consent details
    consent_version VARCHAR(20),
    consent_text TEXT,

    -- Revocation
    revoked_at TIMESTAMP,
    revocation_reason TEXT,

    CONSTRAINT chk_consent_type CHECK (consent_type IN (
        'fcra_authorization', 'smartcredit_connection', 'data_processing',
        'email_notifications', 'sms_notifications', 'third_party_sharing'
    ))
);

CREATE INDEX idx_consents_consumer ON consumer_consents(consumer_id);
CREATE INDEX idx_consents_type ON consumer_consents(consent_type);
```

## JSON Schema Examples

### Consumer Address (consumers.addresses)
```json
[
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
  },
  {
    "type": "previous",
    "street1": "456 Oak Avenue",
    "city": "Brooklyn",
    "state": "NY",
    "zip": "11201",
    "country": "US",
    "is_current": false,
    "moved_out_date": "2020-01-10"
  }
]
```

### Consumer Phones (consumers.phones)
```json
[
  {
    "type": "mobile",
    "number": "+1-555-123-4567",
    "is_primary": true,
    "verified": true
  },
  {
    "type": "home",
    "number": "+1-555-987-6543",
    "is_primary": false,
    "verified": false
  }
]
```

### Letter Template Variables (letter_templates.variables)
```json
[
  {
    "name": "consumer_name",
    "description": "Full name of the consumer",
    "type": "string",
    "required": true
  },
  {
    "name": "dob",
    "description": "Date of birth",
    "type": "date",
    "required": true,
    "format": "MMMM d, yyyy"
  },
  {
    "name": "tradelines",
    "description": "Array of disputed tradelines",
    "type": "array",
    "required": true
  }
]
```

### Audit Log Diff (audit_logs.diff_json)
```json
{
  "before": {
    "status": "draft",
    "narrative": "This account does not belong to me."
  },
  "after": {
    "status": "pending_review",
    "narrative": "This account does not belong to me. I have never opened an account with this creditor."
  }
}
```

## Indexing Strategy

### Performance Indexes
```sql
-- Frequently queried consumer data
CREATE INDEX idx_consumers_name ON consumers(last_name, first_name);

-- Dispute dashboard queries
CREATE INDEX idx_disputes_dashboard ON disputes(tenant_id, status, created_at DESC);

-- Letter tracking queries
CREATE INDEX idx_letters_tracking ON letters(consumer_id, status, sent_at DESC);

-- Audit log searches
CREATE INDEX idx_audit_search ON audit_logs(tenant_id, entity, entity_id, created_at DESC);

-- Billing reports
CREATE INDEX idx_billing_reports ON billing_invoices(tenant_id, billing_period_start DESC);
```

### Full-Text Search Indexes (PostgreSQL)
```sql
-- Search consumers by name
CREATE INDEX idx_consumers_search ON consumers
USING GIN (to_tsvector('english', first_name || ' ' || last_name));

-- Search disputes by narrative
CREATE INDEX idx_disputes_search ON disputes
USING GIN (to_tsvector('english', narrative));

-- Search tradelines by creditor
CREATE INDEX idx_tradelines_search ON tradelines
USING GIN (to_tsvector('english', creditor_name));
```

## Row-Level Security (RLS)

Enable RLS for multi-tenant isolation:

```sql
-- Enable RLS on all tenant-scoped tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumers ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Example policy for users table
CREATE POLICY tenant_isolation_users ON users
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- Similar policies for other tables...
```

## Data Retention Policies

```sql
-- Archive old audit logs (older than 7 years)
CREATE TABLE audit_logs_archive (LIKE audit_logs INCLUDING ALL);

-- Anonymize deleted consumers after 90 days
-- (Scheduled job to encrypt/remove PII while keeping analytics data)

-- Soft delete disputes after resolution
-- Hard delete after retention period per tenant policy
```

---

**Document Version**: 1.0
**Last Updated**: 2026-01-12
**Total Tables**: 13 core tables + archive tables
**Estimated Storage**: ~10GB for 10,000 consumers with 5 years of data
