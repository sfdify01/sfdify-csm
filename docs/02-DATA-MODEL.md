# SFDIFY Credit Dispute Letter System - Data Model & ERD

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    ENTITY RELATIONSHIP DIAGRAM                                           │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘

                                            ┌─────────────────┐
                                            │     TENANTS     │
                                            ├─────────────────┤
                                            │ PK id           │
                                            │    name         │
                                            │    plan         │
                                            │    branding     │
                                            │    settings     │
                                            │    created_at   │
                                            └────────┬────────┘
                                                     │
                          ┌──────────────────────────┼──────────────────────────┐
                          │                          │                          │
                          ▼                          ▼                          ▼
              ┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
              │      USERS      │        │    CONSUMERS    │        │ BILLING_INVOICES│
              ├─────────────────┤        ├─────────────────┤        ├─────────────────┤
              │ PK id           │        │ PK id           │        │ PK id           │
              │ FK tenant_id    │        │ FK tenant_id    │        │ FK tenant_id    │
              │    email        │        │    name         │        │    month        │
              │    role         │        │    dob          │        │    item_count   │
              │    phone        │        │    ssn_enc      │        │    postage_total│
              │    2fa_secret   │        │    ssn_last4    │        │    amount_due   │
              │    created_at   │        │    addresses    │        │    status       │
              └────────┬────────┘        │    phones       │        └─────────────────┘
                       │                 │    emails       │
                       │                 │    kyc_status   │
                       │                 │    consent_at   │
                       │                 │    consent_ip   │
                       │                 └────────┬────────┘
                       │                          │
                       │           ┌──────────────┼──────────────┐
                       │           │              │              │
                       │           ▼              │              ▼
                       │  ┌─────────────────┐    │     ┌─────────────────┐
                       │  │SMARTCREDIT_CONN │    │     │ CREDIT_REPORTS  │
                       │  ├─────────────────┤    │     ├─────────────────┤
                       │  │ PK id           │    │     │ PK id           │
                       │  │ FK consumer_id  │    │     │ FK consumer_id  │
                       │  │    access_token │    │     │    pulled_at    │
                       │  │    refresh_token│    │     │    bureau       │
                       │  │    token_expires│    │     │    raw_json     │
                       │  │    scopes       │    │     │    hash         │
                       │  │    status       │    │     │    score        │
                       │  └─────────────────┘    │     └────────┬────────┘
                       │                         │              │
                       │                         │              ▼
                       │                         │     ┌─────────────────┐
                       │                         │     │   TRADELINES    │
                       │                         │     ├─────────────────┤
                       │                         │     │ PK id           │
                       │                         │     │ FK report_id    │
                       │                         │     │    bureau       │
                       │                         │     │    creditor_name│
                       │                         │     │    account_mask │
                       │                         │     │    account_type │
                       │                         │     │    opened_date  │
                       │                         │     │    balance      │
                       │                         │     │    credit_limit │
                       │                         │     │    payment_status│
                       │                         │     │    status       │
                       │                         │     │    bureau_item_id│
                       │                         │     │    dispute_status│
                       │                         │     └────────┬────────┘
                       │                         │              │
                       │                         │              │
                       │                         ▼              │
                       │                ┌─────────────────┐     │
                       │                │    DISPUTES     │◄────┘
                       │                ├─────────────────┤
                       │                │ PK id           │
                       │                │ FK consumer_id  │
                       │                │ FK tradeline_id │
                       │                │    bureau       │
                       │                │    type         │
                       │                │    reason_codes │
                       │                │    narrative    │
                       │                │    status       │
                       │                │    created_at   │
                       │                │    due_at       │
                       │                │    closed_at    │
                       │                │    outcome      │
                       │                └────────┬────────┘
                       │                         │
                       │          ┌──────────────┼──────────────┐
                       │          │              │              │
                       │          ▼              ▼              ▼
                       │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
                       │  │    LETTERS      │ │    EVIDENCE     │ │  DISPUTE_TASKS  │
                       │  ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
                       │  │ PK id           │ │ PK id           │ │ PK id           │
                       │  │ FK dispute_id   │ │ FK dispute_id   │ │ FK dispute_id   │
                       │  │ FK template_id  │ │    filename     │ │ FK assigned_to  │
                       │  │    type         │ │    file_url     │ │    type         │
                       │  │    render_ver   │ │    mime         │ │    title        │
                       │  │    pdf_url      │ │    checksum     │ │    due_at       │
                       │  │    html_content │ │    source       │ │    status       │
                       │  │    lob_id       │ │    uploaded_at  │ │    completed_at │
                       │  │    mail_type    │ └─────────────────┘ └─────────────────┘
                       │  │    tracking_code│
                       │  │    recipient_addr│
                       │  │    return_addr  │
                       │  │    cost         │
                       │  │    status       │
                       │  │    approved_by  │────────────────────────┐
                       │  │    approved_at  │                        │
                       │  │    sent_at      │                        │
                       │  │    delivered_at │                        │
                       │  │    created_at   │                        │
                       │  └────────┬────────┘                        │
                       │           │                                 │
                       │           ▼                                 │
                       │  ┌─────────────────┐                        │
                       │  │  LETTER_EVENTS  │                        │
                       │  ├─────────────────┤                        │
                       │  │ PK id           │                        │
                       │  │ FK letter_id    │                        │
                       │  │    event_type   │                        │
                       │  │    event_data   │                        │
                       │  │    source       │                        │
                       │  │    created_at   │                        │
                       │  └─────────────────┘                        │
                       │                                             │
                       └─────────────────────────────────────────────┘
                                             │
                                             ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│LETTER_TEMPLATES │        │   AUDIT_LOGS    │        │    WEBHOOKS     │
├─────────────────┤        ├─────────────────┤        ├─────────────────┤
│ PK id           │        │ PK id           │        │ PK id           │
│ FK tenant_id    │        │ FK actor_id     │        │    provider     │
│    name         │        │    actor_role   │        │    event_type   │
│    type         │        │    tenant_id    │        │    payload      │
│    subject      │        │    entity       │        │    idempotency  │
│    body_html    │        │    entity_id    │        │    received_at  │
│    body_text    │        │    action       │        │    processed_at │
│    variables    │        │    diff_json    │        │    status       │
│    is_active    │        │    ip_address   │        └─────────────────┘
│    version      │        │    user_agent   │
│    created_at   │        │    created_at   │
└─────────────────┘        └─────────────────┘
```

---

## Detailed Schema Definitions

### 1. Tenants Table

```sql
CREATE TABLE tenants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(100) UNIQUE NOT NULL,
    plan            VARCHAR(50) NOT NULL DEFAULT 'starter',
    branding        JSONB DEFAULT '{}',
    settings        JSONB DEFAULT '{}',
    smartcredit_config JSONB DEFAULT '{}',
    lob_config      JSONB DEFAULT '{}',
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_active ON tenants(is_active);
```

**JSON Structure - branding:**
```json
{
  "logo_url": "https://s3.../tenant-123/logo.png",
  "primary_color": "#1E40AF",
  "secondary_color": "#3B82F6",
  "company_name": "Credit Repair Pro",
  "letterhead_url": "https://s3.../tenant-123/letterhead.pdf",
  "return_address": {
    "name": "Credit Repair Pro",
    "address_line1": "123 Main St",
    "address_city": "New York",
    "address_state": "NY",
    "address_zip": "10001"
  }
}
```

---

### 2. Users Table

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    phone           VARCHAR(20),
    role            VARCHAR(20) NOT NULL DEFAULT 'viewer',
    totp_secret     BYTEA,  -- Encrypted 2FA secret
    totp_enabled    BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT users_tenant_email_unique UNIQUE (tenant_id, email),
    CONSTRAINT users_role_check CHECK (role IN ('owner', 'operator', 'viewer', 'auditor'))
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(tenant_id, role);
```

---

### 3. Consumers Table

```sql
CREATE TABLE consumers (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Identity (PII - encrypted where noted)
    first_name          VARCHAR(100) NOT NULL,
    middle_name         VARCHAR(100),
    last_name           VARCHAR(100) NOT NULL,
    suffix              VARCHAR(20),
    dob                 DATE NOT NULL,
    ssn_encrypted       BYTEA,  -- AES-256 encrypted full SSN
    ssn_last4           VARCHAR(4) NOT NULL,

    -- Contact arrays
    addresses           JSONB DEFAULT '[]',
    phones              JSONB DEFAULT '[]',
    emails              JSONB DEFAULT '[]',

    -- Status
    kyc_status          VARCHAR(20) DEFAULT 'pending',
    kyc_verified_at     TIMESTAMPTZ,

    -- Consent
    consent_text        TEXT,
    consent_at          TIMESTAMPTZ,
    consent_ip          INET,
    consent_user_agent  TEXT,

    -- Metadata
    notes               TEXT,
    tags                VARCHAR(50)[] DEFAULT '{}',
    created_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT consumers_kyc_check CHECK (kyc_status IN ('pending', 'verified', 'failed', 'expired'))
);

CREATE INDEX idx_consumers_tenant ON consumers(tenant_id);
CREATE INDEX idx_consumers_ssn_last4 ON consumers(tenant_id, ssn_last4);
CREATE INDEX idx_consumers_name ON consumers(tenant_id, last_name, first_name);
CREATE INDEX idx_consumers_kyc ON consumers(tenant_id, kyc_status);
```

**JSON Structure - addresses:**
```json
[
  {
    "type": "current",
    "line1": "456 Oak Avenue",
    "line2": "Apt 7B",
    "city": "Los Angeles",
    "state": "CA",
    "zip": "90001",
    "verified": true,
    "since": "2020-01-15"
  },
  {
    "type": "previous",
    "line1": "789 Pine Street",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "verified": true,
    "from": "2017-03-01",
    "to": "2019-12-31"
  }
]
```

---

### 4. SmartCredit Connections Table

```sql
CREATE TABLE smartcredit_connections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id     UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,

    -- OAuth tokens (encrypted)
    access_token    BYTEA NOT NULL,  -- Encrypted
    refresh_token   BYTEA,           -- Encrypted
    token_expires_at TIMESTAMPTZ NOT NULL,

    -- Scopes and status
    scopes          VARCHAR(100)[] DEFAULT '{}',
    status          VARCHAR(20) DEFAULT 'active',

    -- SmartCredit identifiers
    sc_user_id      VARCHAR(100),
    sc_subscription_id VARCHAR(100),

    -- Usage tracking
    last_pull_at    TIMESTAMPTZ,
    pull_count      INTEGER DEFAULT 0,

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT sc_conn_status_check CHECK (status IN ('active', 'expired', 'revoked', 'error'))
);

CREATE INDEX idx_sc_conn_consumer ON smartcredit_connections(consumer_id);
CREATE INDEX idx_sc_conn_status ON smartcredit_connections(status);
CREATE UNIQUE INDEX idx_sc_conn_consumer_active ON smartcredit_connections(consumer_id)
    WHERE status = 'active';
```

---

### 5. Credit Reports Table

```sql
CREATE TABLE credit_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id     UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    connection_id   UUID REFERENCES smartcredit_connections(id) ON DELETE SET NULL,

    -- Report metadata
    pulled_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bureau          VARCHAR(20) NOT NULL,
    report_date     DATE,

    -- Raw data (encrypted at rest via pgcrypto)
    raw_json        JSONB NOT NULL,
    raw_json_hash   VARCHAR(64) NOT NULL,  -- SHA-256

    -- Parsed summary
    score           INTEGER,
    score_factors   JSONB DEFAULT '[]',
    tradeline_count INTEGER,
    inquiry_count   INTEGER,
    public_record_count INTEGER,

    -- Processing status
    parsed_at       TIMESTAMPTZ,
    parse_errors    JSONB DEFAULT '[]',

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT credit_reports_bureau_check CHECK (bureau IN ('equifax', 'experian', 'transunion'))
);

CREATE INDEX idx_reports_consumer ON credit_reports(consumer_id);
CREATE INDEX idx_reports_bureau ON credit_reports(consumer_id, bureau);
CREATE INDEX idx_reports_pulled ON credit_reports(consumer_id, pulled_at DESC);

-- Partition by month for large datasets
-- CREATE TABLE credit_reports_y2024m01 PARTITION OF credit_reports
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

---

### 6. Tradelines Table

```sql
CREATE TABLE tradelines (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id           UUID NOT NULL REFERENCES credit_reports(id) ON DELETE CASCADE,
    consumer_id         UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,

    -- Bureau identification
    bureau              VARCHAR(20) NOT NULL,
    bureau_item_id      VARCHAR(100),  -- SmartCredit's ID for this tradeline

    -- Creditor info
    creditor_name       VARCHAR(255) NOT NULL,
    creditor_address    JSONB,
    account_number_masked VARCHAR(50),
    account_type        VARCHAR(50),

    -- Account details
    opened_date         DATE,
    closed_date         DATE,
    last_activity_date  DATE,

    -- Financial
    original_balance    DECIMAL(12, 2),
    current_balance     DECIMAL(12, 2),
    credit_limit        DECIMAL(12, 2),
    high_balance        DECIMAL(12, 2),
    monthly_payment     DECIMAL(12, 2),
    past_due_amount     DECIMAL(12, 2),

    -- Status
    account_status      VARCHAR(50),
    payment_status      VARCHAR(50),
    payment_history     JSONB DEFAULT '{}',  -- 24-month history

    -- Dispute tracking
    dispute_status      VARCHAR(20) DEFAULT 'none',
    has_consumer_statement BOOLEAN DEFAULT FALSE,

    -- Remarks/comments from bureau
    remarks             TEXT[],

    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT tradelines_bureau_check CHECK (bureau IN ('equifax', 'experian', 'transunion')),
    CONSTRAINT tradelines_dispute_check CHECK (dispute_status IN ('none', 'in_dispute', 'resolved', 'verified'))
);

CREATE INDEX idx_tradelines_report ON tradelines(report_id);
CREATE INDEX idx_tradelines_consumer ON tradelines(consumer_id);
CREATE INDEX idx_tradelines_bureau ON tradelines(consumer_id, bureau);
CREATE INDEX idx_tradelines_creditor ON tradelines(consumer_id, creditor_name);
CREATE INDEX idx_tradelines_dispute ON tradelines(consumer_id, dispute_status);
```

---

### 7. Disputes Table

```sql
CREATE TABLE disputes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id     UUID NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    tradeline_id    UUID REFERENCES tradelines(id) ON DELETE SET NULL,

    -- Dispute identification
    dispute_number  VARCHAR(20) UNIQUE NOT NULL,
    bureau          VARCHAR(20) NOT NULL,

    -- Classification
    type            VARCHAR(50) NOT NULL,
    reason_codes    VARCHAR(50)[] NOT NULL,

    -- Content
    narrative       TEXT,
    ai_generated    BOOLEAN DEFAULT FALSE,
    ai_reviewed     BOOLEAN DEFAULT FALSE,

    -- Status workflow
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',

    -- Timeline
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    submitted_at    TIMESTAMPTZ,
    due_at          TIMESTAMPTZ,  -- 30 days from submission
    extended_due_at TIMESTAMPTZ,  -- 45 days if additional info requested
    responded_at    TIMESTAMPTZ,
    closed_at       TIMESTAMPTZ,

    -- Outcome
    outcome         VARCHAR(50),
    outcome_details JSONB,
    bureau_response TEXT,

    -- Relationships
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    assigned_to     UUID REFERENCES users(id) ON DELETE SET NULL,

    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT disputes_bureau_check CHECK (bureau IN ('equifax', 'experian', 'transunion')),
    CONSTRAINT disputes_type_check CHECK (type IN (
        'fcra_609_request',
        'fcra_611_accuracy',
        'method_verification',
        'reinvestigation',
        'goodwill_adjustment',
        'pay_for_delete',
        'identity_theft_605b',
        'cfpb_complaint',
        'generic_dispute'
    )),
    CONSTRAINT disputes_status_check CHECK (status IN (
        'draft', 'pending_review', 'approved', 'mailed',
        'awaiting_response', 'responded', 'resolved', 'escalated', 'closed'
    )),
    CONSTRAINT disputes_outcome_check CHECK (outcome IS NULL OR outcome IN (
        'deleted', 'corrected', 'verified', 'no_response',
        'partial_correction', 'rejected', 'escalated'
    ))
);

CREATE INDEX idx_disputes_consumer ON disputes(consumer_id);
CREATE INDEX idx_disputes_tradeline ON disputes(tradeline_id);
CREATE INDEX idx_disputes_bureau ON disputes(consumer_id, bureau);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_due ON disputes(due_at) WHERE status = 'awaiting_response';
CREATE INDEX idx_disputes_assigned ON disputes(assigned_to) WHERE status IN ('draft', 'pending_review');

-- Generate dispute number
CREATE OR REPLACE FUNCTION generate_dispute_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dispute_number := 'DSP-' || LPAD(nextval('dispute_number_seq')::TEXT, 8, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE dispute_number_seq START 1;
CREATE TRIGGER set_dispute_number
    BEFORE INSERT ON disputes
    FOR EACH ROW
    WHEN (NEW.dispute_number IS NULL)
    EXECUTE FUNCTION generate_dispute_number();
```

**Reason Codes:**
```
NOT_MINE              - Account does not belong to me
INACCURATE_BALANCE    - Balance reported is incorrect
INACCURATE_STATUS     - Account status is wrong
PAID_NOT_UPDATED      - Paid but showing as open/delinquent
WRONG_DATES           - Incorrect open/close/delinquency dates
DUPLICATE             - Same account reported multiple times
OBSOLETE              - Account is too old to report (7+ years)
RE_AGED               - Dates manipulated to extend reporting
IDENTITY_THEFT        - Fraudulent account from identity theft
MISSING_DISPUTE_NOTICE - Prior dispute not noted on report
WRONG_CREDIT_LIMIT    - Incorrect credit limit reported
WRONG_PAYMENT_HISTORY - Payment history errors
UNAUTHORIZED_INQUIRY  - Inquiry without permissible purpose
MIXED_FILE            - Another person's data on my report
```

---

### 8. Letters Table

```sql
CREATE TABLE letters (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id      UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
    template_id     UUID REFERENCES letter_templates(id) ON DELETE SET NULL,

    -- Letter content
    type            VARCHAR(50) NOT NULL,
    subject         VARCHAR(255),
    body_html       TEXT NOT NULL,
    body_text       TEXT,

    -- Rendered output
    pdf_url         VARCHAR(500),
    pdf_hash        VARCHAR(64),
    render_version  INTEGER DEFAULT 1,
    rendered_at     TIMESTAMPTZ,

    -- Recipient
    recipient_type  VARCHAR(20) NOT NULL,  -- bureau, creditor, collector
    recipient_name  VARCHAR(255) NOT NULL,
    recipient_address JSONB NOT NULL,

    -- Return address
    return_address  JSONB NOT NULL,

    -- Lob integration
    lob_id          VARCHAR(100),
    lob_url         VARCHAR(500),
    mail_type       VARCHAR(50),
    tracking_number VARCHAR(100),
    carrier         VARCHAR(50),

    -- Costs
    cost_printing   DECIMAL(8, 2),
    cost_postage    DECIMAL(8, 2),
    cost_total      DECIMAL(8, 2),

    -- Workflow
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',
    approved_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at     TIMESTAMPTZ,
    sent_at         TIMESTAMPTZ,
    expected_delivery DATE,
    delivered_at    TIMESTAMPTZ,
    returned_at     TIMESTAMPTZ,
    return_reason   VARCHAR(100),

    -- Metadata
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT letters_type_check CHECK (type IN (
        'fcra_609_request',
        'fcra_611_accuracy',
        'method_verification',
        'reinvestigation',
        'goodwill_adjustment',
        'pay_for_delete',
        'identity_theft_605b',
        'cfpb_complaint',
        'generic_dispute'
    )),
    CONSTRAINT letters_recipient_check CHECK (recipient_type IN ('bureau', 'creditor', 'collector', 'cfpb')),
    CONSTRAINT letters_mail_type_check CHECK (mail_type IS NULL OR mail_type IN (
        'first_class', 'certified', 'certified_return_receipt'
    )),
    CONSTRAINT letters_status_check CHECK (status IN (
        'draft', 'pending_approval', 'approved', 'rendering',
        'queued', 'sent', 'in_transit', 'delivered', 'returned', 'failed'
    ))
);

CREATE INDEX idx_letters_dispute ON letters(dispute_id);
CREATE INDEX idx_letters_status ON letters(status);
CREATE INDEX idx_letters_lob ON letters(lob_id);
CREATE INDEX idx_letters_sent ON letters(sent_at) WHERE status IN ('sent', 'in_transit', 'delivered');
```

---

### 9. Letter Templates Table

```sql
CREATE TABLE letter_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES tenants(id) ON DELETE CASCADE,  -- NULL = system template

    -- Template info
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(100) NOT NULL,
    type            VARCHAR(50) NOT NULL,
    description     TEXT,

    -- Content
    subject_template VARCHAR(255),
    body_html       TEXT NOT NULL,
    body_text       TEXT,

    -- Variables metadata
    variables       JSONB DEFAULT '[]',  -- List of required variables

    -- Versioning
    version         INTEGER DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    is_default      BOOLEAN DEFAULT FALSE,

    -- Compliance
    fcra_sections   VARCHAR(20)[],
    disclaimer      TEXT,

    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT templates_type_check CHECK (type IN (
        'fcra_609_request',
        'fcra_611_accuracy',
        'method_verification',
        'reinvestigation',
        'goodwill_adjustment',
        'pay_for_delete',
        'identity_theft_605b',
        'cfpb_complaint',
        'generic_dispute'
    ))
);

CREATE INDEX idx_templates_tenant ON letter_templates(tenant_id);
CREATE INDEX idx_templates_type ON letter_templates(type);
CREATE UNIQUE INDEX idx_templates_default ON letter_templates(tenant_id, type)
    WHERE is_default = TRUE;
```

---

### 10. Evidence Table

```sql
CREATE TABLE evidence (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id      UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,

    -- File info
    filename        VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_url        VARCHAR(500) NOT NULL,
    file_size       INTEGER NOT NULL,
    mime_type       VARCHAR(100) NOT NULL,

    -- Integrity
    checksum_sha256 VARCHAR(64) NOT NULL,
    virus_scanned   BOOLEAN DEFAULT FALSE,
    virus_scan_result VARCHAR(50),

    -- Classification
    evidence_type   VARCHAR(50) NOT NULL,
    description     TEXT,
    source          VARCHAR(50),  -- consumer_upload, smartcredit, police_report

    -- Processing
    ocr_text        TEXT,
    ocr_processed   BOOLEAN DEFAULT FALSE,

    -- Metadata
    uploaded_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    uploaded_at     TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT evidence_type_check CHECK (evidence_type IN (
        'identity_document', 'utility_bill', 'bank_statement',
        'payment_receipt', 'court_document', 'police_report',
        'ftc_affidavit', 'correspondence', 'credit_report',
        'screenshot', 'other'
    ))
);

CREATE INDEX idx_evidence_dispute ON evidence(dispute_id);
CREATE INDEX idx_evidence_type ON evidence(dispute_id, evidence_type);
```

---

### 11. Dispute Tasks Table

```sql
CREATE TABLE dispute_tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id      UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,

    -- Task info
    type            VARCHAR(50) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,

    -- Timeline
    due_at          TIMESTAMPTZ NOT NULL,
    reminder_at     TIMESTAMPTZ,

    -- Status
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    priority        VARCHAR(20) DEFAULT 'normal',

    -- Assignment
    assigned_to     UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Completion
    completed_at    TIMESTAMPTZ,
    completed_by    UUID REFERENCES users(id) ON DELETE SET NULL,
    completion_notes TEXT,

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT tasks_type_check CHECK (type IN (
        'review_letter', 'send_letter', 'follow_up',
        'check_response', 'reinvestigate', 'escalate',
        'gather_evidence', 'contact_consumer', 'other'
    )),
    CONSTRAINT tasks_status_check CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    CONSTRAINT tasks_priority_check CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

CREATE INDEX idx_tasks_dispute ON dispute_tasks(dispute_id);
CREATE INDEX idx_tasks_assigned ON dispute_tasks(assigned_to) WHERE status = 'pending';
CREATE INDEX idx_tasks_due ON dispute_tasks(due_at) WHERE status = 'pending';
```

---

### 12. Letter Events Table

```sql
CREATE TABLE letter_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    letter_id       UUID NOT NULL REFERENCES letters(id) ON DELETE CASCADE,

    -- Event info
    event_type      VARCHAR(50) NOT NULL,
    event_data      JSONB DEFAULT '{}',

    -- Source
    source          VARCHAR(50) NOT NULL,  -- system, lob_webhook, user
    source_id       VARCHAR(100),  -- Lob event ID, etc.

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT events_type_check CHECK (event_type IN (
        'created', 'rendered', 'approved', 'rejected',
        'submitted_to_lob', 'mailed', 'in_transit',
        'in_local_area', 'processed_for_delivery',
        'delivered', 'returned_to_sender', 'failed'
    )),
    CONSTRAINT events_source_check CHECK (source IN ('system', 'lob_webhook', 'user', 'smartcredit_webhook'))
);

CREATE INDEX idx_events_letter ON letter_events(letter_id);
CREATE INDEX idx_events_type ON letter_events(letter_id, event_type);
CREATE INDEX idx_events_created ON letter_events(created_at);
```

---

### 13. Webhooks Table

```sql
CREATE TABLE webhooks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Source
    provider        VARCHAR(50) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,

    -- Payload
    payload         JSONB NOT NULL,
    headers         JSONB DEFAULT '{}',

    -- Idempotency
    idempotency_key VARCHAR(255) NOT NULL,

    -- Processing
    received_at     TIMESTAMPTZ DEFAULT NOW(),
    processed_at    TIMESTAMPTZ,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    error_message   TEXT,
    retry_count     INTEGER DEFAULT 0,

    CONSTRAINT webhooks_provider_check CHECK (provider IN ('lob', 'smartcredit', 'stripe')),
    CONSTRAINT webhooks_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'skipped'))
);

CREATE UNIQUE INDEX idx_webhooks_idempotency ON webhooks(provider, idempotency_key);
CREATE INDEX idx_webhooks_status ON webhooks(status) WHERE status = 'pending';
CREATE INDEX idx_webhooks_received ON webhooks(received_at);
```

---

### 14. Audit Logs Table

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Actor
    actor_id        UUID,  -- NULL for system actions
    actor_role      VARCHAR(50),
    actor_email     VARCHAR(255),

    -- Tenant scope
    tenant_id       UUID NOT NULL,

    -- Target
    entity_type     VARCHAR(50) NOT NULL,
    entity_id       UUID NOT NULL,

    -- Action
    action          VARCHAR(50) NOT NULL,
    action_detail   VARCHAR(255),

    -- Changes
    old_values      JSONB,
    new_values      JSONB,
    diff_json       JSONB,

    -- Request context
    ip_address      INET,
    user_agent      TEXT,
    request_id      VARCHAR(100),

    created_at      TIMESTAMPTZ DEFAULT NOW()

) PARTITION BY RANGE (created_at);

-- Create partitions by month
CREATE TABLE audit_logs_y2024m01 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
-- ... additional partitions

CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_logs(actor_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_logs(action, created_at DESC);
```

---

### 15. Billing Invoices Table

```sql
CREATE TABLE billing_invoices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Period
    billing_month   DATE NOT NULL,  -- First day of month

    -- Usage counts
    consumers_count INTEGER DEFAULT 0,
    reports_pulled  INTEGER DEFAULT 0,
    letters_sent    INTEGER DEFAULT 0,

    -- Costs breakdown
    smartcredit_usage DECIMAL(10, 2) DEFAULT 0,
    lob_postage_total DECIMAL(10, 2) DEFAULT 0,
    lob_printing_total DECIMAL(10, 2) DEFAULT 0,
    platform_fee    DECIMAL(10, 2) DEFAULT 0,

    -- Totals
    subtotal        DECIMAL(10, 2) DEFAULT 0,
    tax             DECIMAL(10, 2) DEFAULT 0,
    amount_due      DECIMAL(10, 2) DEFAULT 0,

    -- Status
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',
    due_date        DATE,
    paid_at         TIMESTAMPTZ,

    -- Line items detail
    line_items      JSONB DEFAULT '[]',

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT invoices_status_check CHECK (status IN ('draft', 'pending', 'paid', 'overdue', 'cancelled'))
);

CREATE INDEX idx_invoices_tenant ON billing_invoices(tenant_id);
CREATE INDEX idx_invoices_month ON billing_invoices(billing_month);
CREATE INDEX idx_invoices_status ON billing_invoices(status);
CREATE UNIQUE INDEX idx_invoices_tenant_month ON billing_invoices(tenant_id, billing_month);
```

---

## JSON Examples

### Consumer Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "first_name": "John",
  "middle_name": "Michael",
  "last_name": "Smith",
  "suffix": null,
  "dob": "1985-03-15",
  "ssn_last4": "1234",
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
  "phones": [
    {
      "type": "mobile",
      "number": "+13105551234",
      "verified": true
    }
  ],
  "emails": [
    {
      "type": "primary",
      "address": "john.smith@email.com",
      "verified": true
    }
  ],
  "kyc_status": "verified",
  "kyc_verified_at": "2024-01-15T10:30:00Z",
  "consent_at": "2024-01-15T10:25:00Z",
  "consent_ip": "192.168.1.100",
  "created_at": "2024-01-15T10:20:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### Credit Report Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "consumer_id": "550e8400-e29b-41d4-a716-446655440001",
  "pulled_at": "2024-01-20T14:00:00Z",
  "bureau": "equifax",
  "report_date": "2024-01-20",
  "score": 685,
  "score_factors": [
    {
      "code": "01",
      "description": "Amount owed on accounts is too high"
    },
    {
      "code": "14",
      "description": "Length of time accounts have been established"
    }
  ],
  "tradeline_count": 12,
  "inquiry_count": 3,
  "public_record_count": 0,
  "raw_json_hash": "a1b2c3d4e5f6..."
}
```

### Tradeline Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "report_id": "550e8400-e29b-41d4-a716-446655440002",
  "consumer_id": "550e8400-e29b-41d4-a716-446655440001",
  "bureau": "equifax",
  "bureau_item_id": "EQ-TL-12345678",
  "creditor_name": "Capital One Bank",
  "creditor_address": {
    "line1": "PO Box 30285",
    "city": "Salt Lake City",
    "state": "UT",
    "zip": "84130"
  },
  "account_number_masked": "XXXX-XXXX-XXXX-5678",
  "account_type": "credit_card",
  "opened_date": "2019-06-15",
  "closed_date": null,
  "last_activity_date": "2024-01-15",
  "original_balance": null,
  "current_balance": 2450.00,
  "credit_limit": 5000.00,
  "high_balance": 4800.00,
  "monthly_payment": 75.00,
  "past_due_amount": 0.00,
  "account_status": "Open",
  "payment_status": "Current",
  "payment_history": {
    "2024-01": "OK",
    "2023-12": "OK",
    "2023-11": "OK",
    "2023-10": "30",
    "2023-09": "OK"
  },
  "dispute_status": "none",
  "has_consumer_statement": false,
  "remarks": []
}
```

### Dispute Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "consumer_id": "550e8400-e29b-41d4-a716-446655440001",
  "tradeline_id": "550e8400-e29b-41d4-a716-446655440003",
  "dispute_number": "DSP-00000042",
  "bureau": "equifax",
  "type": "fcra_611_accuracy",
  "reason_codes": ["INACCURATE_BALANCE", "WRONG_PAYMENT_HISTORY"],
  "narrative": "The balance reported of $2,450.00 is incorrect. I have attached my most recent statement showing the correct balance of $1,850.00. Additionally, the payment history for October 2023 shows a 30-day late payment, but I have proof of on-time payment attached.",
  "ai_generated": true,
  "ai_reviewed": true,
  "status": "approved",
  "created_at": "2024-01-21T09:00:00Z",
  "submitted_at": null,
  "due_at": null,
  "outcome": null,
  "created_by": "550e8400-e29b-41d4-a716-446655440010",
  "assigned_to": "550e8400-e29b-41d4-a716-446655440011"
}
```

### Letter Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "dispute_id": "550e8400-e29b-41d4-a716-446655440004",
  "template_id": "550e8400-e29b-41d4-a716-446655440020",
  "type": "fcra_611_accuracy",
  "subject": "Dispute of Inaccurate Information - Capital One Account XXXX5678",
  "recipient_type": "bureau",
  "recipient_name": "Equifax Information Services LLC",
  "recipient_address": {
    "line1": "P.O. Box 740256",
    "city": "Atlanta",
    "state": "GA",
    "zip": "30374"
  },
  "return_address": {
    "name": "John M. Smith",
    "line1": "456 Oak Avenue, Apt 7B",
    "city": "Los Angeles",
    "state": "CA",
    "zip": "90001"
  },
  "lob_id": "ltr_abc123def456",
  "lob_url": "https://lob.com/letters/ltr_abc123def456",
  "mail_type": "certified_return_receipt",
  "tracking_number": "9400111899223456789012",
  "carrier": "USPS",
  "cost_printing": 1.50,
  "cost_postage": 7.75,
  "cost_total": 9.25,
  "status": "delivered",
  "approved_by": "550e8400-e29b-41d4-a716-446655440011",
  "approved_at": "2024-01-21T11:00:00Z",
  "sent_at": "2024-01-21T14:00:00Z",
  "expected_delivery": "2024-01-28",
  "delivered_at": "2024-01-26T15:30:00Z",
  "pdf_url": "https://s3.../letters/ltr-550e8400.pdf",
  "pdf_hash": "sha256:abc123...",
  "render_version": 1,
  "created_at": "2024-01-21T09:30:00Z"
}
```

### Evidence Object
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440006",
  "dispute_id": "550e8400-e29b-41d4-a716-446655440004",
  "filename": "evidence-550e8400-capital-one-statement.pdf",
  "original_filename": "CapitalOne_Statement_Jan2024.pdf",
  "file_url": "https://s3.../evidence/550e8400.../capital-one-statement.pdf",
  "file_size": 245678,
  "mime_type": "application/pdf",
  "checksum_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "virus_scanned": true,
  "virus_scan_result": "clean",
  "evidence_type": "bank_statement",
  "description": "Capital One credit card statement showing correct balance of $1,850.00",
  "source": "consumer_upload",
  "ocr_processed": true,
  "ocr_text": "Capital One Statement...",
  "uploaded_by": "550e8400-e29b-41d4-a716-446655440001",
  "uploaded_at": "2024-01-21T09:15:00Z"
}
```

---

## Bureau Addresses Reference

```json
{
  "equifax": {
    "disputes": {
      "name": "Equifax Information Services LLC",
      "line1": "P.O. Box 740256",
      "city": "Atlanta",
      "state": "GA",
      "zip": "30374"
    },
    "identity_theft": {
      "name": "Equifax Information Services LLC",
      "attention": "Fraud Victim Assistance",
      "line1": "P.O. Box 740256",
      "city": "Atlanta",
      "state": "GA",
      "zip": "30374"
    }
  },
  "experian": {
    "disputes": {
      "name": "Experian",
      "line1": "P.O. Box 4500",
      "city": "Allen",
      "state": "TX",
      "zip": "75013"
    },
    "identity_theft": {
      "name": "Experian",
      "attention": "Fraud Victim Assistance",
      "line1": "P.O. Box 9701",
      "city": "Allen",
      "state": "TX",
      "zip": "75013"
    }
  },
  "transunion": {
    "disputes": {
      "name": "TransUnion Consumer Solutions",
      "line1": "P.O. Box 2000",
      "city": "Chester",
      "state": "PA",
      "zip": "19016"
    },
    "identity_theft": {
      "name": "TransUnion Fraud Victim Assistance",
      "line1": "P.O. Box 2000",
      "city": "Chester",
      "state": "PA",
      "zip": "19016"
    }
  }
}
```
