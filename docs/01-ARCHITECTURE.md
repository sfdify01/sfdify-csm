# SFDIFY Credit Dispute Letter System - Architecture

## System Overview

A production-ready, multi-tenant web application and API that automates consumer credit disputes and mailing. The system generates compliant dispute letters, integrates with SmartCredit for credit data, and uses Lob for print and mail services.

---

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    CLIENTS                                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Flutter Web  │  │ Flutter iOS  │  │Flutter Android│  │   Admin UI   │             │
│  │   Consumer   │  │   Consumer   │  │   Consumer   │  │  (Operators) │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
└─────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────────┘
          │                 │                 │                 │
          └─────────────────┴────────┬────────┴─────────────────┘
                                     │ HTTPS/REST
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY / LOAD BALANCER                             │
│                    (Rate Limiting, SSL Termination, Auth Check)                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              DJANGO APPLICATION LAYER                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Auth Service  │  │Consumer Service │  │ Dispute Service │  │ Letter Service  │ │
│  │                 │  │                 │  │                 │  │                 │ │
│  │ • JWT/OAuth2    │  │ • CRUD          │  │ • Issue select  │  │ • Template mgmt │ │
│  │ • RBAC          │  │ • KYC status    │  │ • Workflow      │  │ • PDF render    │ │
│  │ • 2FA           │  │ • Consent       │  │ • SLA tracking  │  │ • AI generation │ │
│  │ • Tenant scope  │  │ • Profile       │  │ • Status mgmt   │  │ • Approval flow │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │                    │          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Credit Service  │  │Evidence Service │  │  Mail Service   │  │ Webhook Service │ │
│  │                 │  │                 │  │                 │  │                 │ │
│  │ • SmartCredit   │  │ • Upload/store  │  │ • Lob API       │  │ • Lob events    │ │
│  │ • Report parse  │  │ • Virus scan    │  │ • Address valid │  │ • SmartCredit   │ │
│  │ • Tradeline map │  │ • Checksums     │  │ • Cost tracking │  │ • Idempotency   │ │
│  │ • Reconcile     │  │ • MIME validate │  │ • Mail classes  │  │ • Retry logic   │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │                    │          │
└───────────┼────────────────────┼────────────────────┼────────────────────┼──────────┘
            │                    │                    │                    │
            ▼                    ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              MESSAGE QUEUE (Redis/Celery)                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  credit_pull    │  │  pdf_render     │  │  mail_send      │  │  reconcile      │ │
│  │     queue       │  │     queue       │  │     queue       │  │     queue       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   sla_check     │  │  notification   │  │  webhook_proc   │  │    billing      │ │
│  │     queue       │  │     queue       │  │     queue       │  │     queue       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
            │                    │                    │                    │
            ▼                    ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CELERY WORKERS                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Credit Worker   │  │ Render Worker   │  │  Mail Worker    │  │ Recon Worker    │ │
│  │                 │  │                 │  │                 │  │                 │ │
│  │ • Pull reports  │  │ • WeasyPrint    │  │ • Lob API calls │  │ • Compare data  │ │
│  │ • Parse JSON    │  │ • HTML→PDF      │  │ • Retry logic   │  │ • Auto-close    │ │
│  │ • Store data    │  │ • Hash verify   │  │ • Cost calc     │  │ • Schedule next │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  SLA Worker     │  │ Notify Worker   │  │ Webhook Worker  │  │ Billing Worker  │ │
│  │                 │  │                 │  │                 │  │                 │ │
│  │ • Check due     │  │ • Email/SMS     │  │ • Process events│  │ • Aggregate     │ │
│  │ • Create tasks  │  │ • Templates     │  │ • Update status │  │ • Invoice gen   │ │
│  │ • Escalate      │  │ • Queue mgmt    │  │ • Audit log     │  │ • Usage meter   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
            │                    │                    │                    │
            ▼                    ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                DATA LAYER                                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐   │
│  │         PostgreSQL (Primary)        │  │           Redis (Cache)              │   │
│  │                                     │  │                                     │   │
│  │ • All application data              │  │ • Session cache                     │   │
│  │ • Column-level encryption (SSN)     │  │ • Rate limiting counters            │   │
│  │ • Row-level security (tenant_id)    │  │ • Celery broker/backend             │   │
│  │ • Audit log tables                  │  │ • Temporary tokens                  │   │
│  │ • Full-text search indexes          │  │ • API response cache                │   │
│  └─────────────────────────────────────┘  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐   │
│  │        S3/GCS (Object Storage)      │  │      Secrets Manager (Vault)        │   │
│  │                                     │  │                                     │   │
│  │ • Evidence files (encrypted)        │  │ • SmartCredit OAuth tokens          │   │
│  │ • Generated PDFs                    │  │ • Lob API keys                      │   │
│  │ • Credit report JSON archives       │  │ • Database credentials              │   │
│  │ • Template assets                   │  │ • Encryption keys                   │   │
│  └─────────────────────────────────────┘  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
            │                    │
            ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL INTEGRATIONS                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐   │
│  │           SmartCredit API           │  │              Lob API                 │   │
│  │                                     │  │                                     │   │
│  │ • OAuth2 token exchange             │  │ • Letter creation                   │   │
│  │ • GET /reports (3-bureau)           │  │ • Certified mail options            │   │
│  │ • GET /tradelines                   │  │ • Address verification              │   │
│  │ • GET /alerts                       │  │ • Webhooks (delivery events)        │   │
│  │ • GET /scores                       │  │ • PDF rendering                     │   │
│  │ • Webhooks (report updates)         │  │ • Return receipt tracking           │   │
│  └─────────────────────────────────────┘  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐   │
│  │         Notification Services       │  │           AI/LLM Service            │   │
│  │                                     │  │                                     │   │
│  │ • SendGrid/SES (Email)              │  │ • Claude API / OpenAI               │   │
│  │ • Twilio (SMS)                      │  │ • Narrative generation              │   │
│  │ • Push notifications                │  │ • Content review                    │   │
│  └─────────────────────────────────────┘  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              OBSERVABILITY                                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Prometheus    │  │    Grafana      │  │     Sentry      │  │  CloudWatch/    │ │
│  │    Metrics      │  │   Dashboards    │  │  Error Tracking │  │  Stackdriver    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Jaeger/       │  │   ELK Stack     │  │   PagerDuty     │  │   Datadog       │ │
│  │   Zipkin        │  │   (Logs)        │  │   (Alerting)    │  │   APM           │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Components

### 1. API Gateway Layer
- **Technology**: NGINX / AWS ALB / Cloudflare
- **Responsibilities**:
  - SSL/TLS termination
  - Rate limiting (100 req/min per user, 1000/min per tenant)
  - Request routing
  - DDoS protection
  - Authentication token validation

### 2. Django Application Services

#### Auth Service
- JWT token issuance and validation
- OAuth2 flows for SmartCredit
- Multi-factor authentication (TOTP)
- Role-based access control (RBAC)
- Session management
- Tenant isolation

#### Consumer Service
- Consumer profile CRUD
- KYC status management
- Consent capture and audit
- Address/contact management
- SmartCredit connection management

#### Credit Service
- SmartCredit API integration
- Credit report fetching and parsing
- Tradeline normalization
- Bureau data mapping
- Report comparison and reconciliation
- Alert processing

#### Dispute Service
- Issue selection and categorization
- Dispute workflow management
- Status transitions
- SLA tracking and enforcement
- Task creation and assignment
- Outcome reconciliation

#### Letter Service
- Template management
- Variable substitution
- AI narrative generation
- PDF rendering (WeasyPrint)
- Approval workflow
- Version control

#### Evidence Service
- File upload handling
- Virus scanning (ClamAV)
- MIME type validation
- Checksum generation
- S3 storage management
- Evidence indexing

#### Mail Service
- Lob API integration
- Address verification
- Mail class selection
- Cost calculation
- Tracking management
- Delivery status updates

#### Webhook Service
- Idempotent event processing
- Lob webhook handling
- SmartCredit webhook handling
- Status synchronization
- Retry with exponential backoff

### 3. Background Workers (Celery)

| Worker | Queue | Responsibilities |
|--------|-------|------------------|
| Credit Worker | credit_pull | Fetch/parse credit reports, store tradelines |
| Render Worker | pdf_render | Generate PDFs, verify integrity |
| Mail Worker | mail_send | Submit to Lob, track costs |
| Recon Worker | reconcile | Compare reports, update dispute status |
| SLA Worker | sla_check | Monitor deadlines, create follow-up tasks |
| Notify Worker | notification | Send email/SMS notifications |
| Webhook Worker | webhook_proc | Process incoming webhooks |
| Billing Worker | billing | Aggregate usage, generate invoices |

### 4. Data Stores

#### PostgreSQL
- Primary application database
- Column-level encryption for PII (pgcrypto)
- Row-level security policies for tenant isolation
- Indexes for common query patterns
- Partitioning for audit_logs table

#### Redis
- Celery message broker and result backend
- Session cache
- Rate limiting counters
- API response caching
- Distributed locks

#### S3/GCS
- Evidence file storage (AES-256 encryption)
- Generated PDF storage
- Credit report JSON archives
- Template assets and letterheads

#### Secrets Manager
- SmartCredit OAuth tokens
- Lob API keys
- Database credentials
- Encryption keys
- 2FA secrets

---

## Data Flow Diagrams

### Flow 1: Consumer Onboarding & SmartCredit Connection

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Consumer │     │   API    │     │  Credit  │     │SmartCredit│    │   DB     │
│  (App)   │     │ Gateway  │     │ Service  │     │   API    │     │          │
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │                │                │
     │ 1. Register    │                │                │                │
     │───────────────>│                │                │                │
     │                │ 2. Create      │                │                │
     │                │    consumer    │                │                │
     │                │───────────────>│                │                │
     │                │                │ 3. Store       │                │
     │                │                │───────────────────────────────>│
     │                │                │                │                │
     │ 4. Connect SC  │                │                │                │
     │───────────────>│                │                │                │
     │                │ 5. Init OAuth  │                │                │
     │                │───────────────>│                │                │
     │                │                │ 6. Auth URL    │                │
     │                │                │───────────────>│                │
     │<───────────────────────────────────────────────────────────────────
     │ 7. Redirect    │                │                │                │
     │                │                │                │                │
     │ 8. User consents on SmartCredit │                │                │
     │─────────────────────────────────────────────────>│                │
     │                │                │                │                │
     │ 9. Callback    │                │                │                │
     │───────────────>│                │                │                │
     │                │ 10. Exchange   │                │                │
     │                │     code       │                │                │
     │                │───────────────>│                │                │
     │                │                │ 11. Token req  │                │
     │                │                │───────────────>│                │
     │                │                │ 12. Tokens     │                │
     │                │                │<───────────────│                │
     │                │                │ 13. Store vault│                │
     │                │                │───────────────────────────────>│
     │                │                │                │                │
     │                │                │ 14. Fetch reports               │
     │                │                │───────────────>│                │
     │                │                │ 15. 3-bureau   │                │
     │                │                │<───────────────│                │
     │                │                │ 16. Parse &    │                │
     │                │                │     store      │                │
     │                │                │───────────────────────────────>│
     │<───────────────────────────────────────────────────────────────────
     │ 17. Success + tradelines        │                │                │
     │                │                │                │                │
```

### Flow 2: Dispute Creation & Letter Generation

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Consumer │     │ Dispute  │     │  Letter  │     │    AI    │     │   DB     │
│  (App)   │     │ Service  │     │ Service  │     │ Service  │     │          │
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │                │                │
     │ 1. Select      │                │                │                │
     │    issues      │                │                │                │
     │───────────────>│                │                │                │
     │                │ 2. Validate    │                │                │
     │                │    tradelines  │                │                │
     │                │───────────────────────────────────────────────>│
     │                │ 3. Create      │                │                │
     │                │    disputes    │                │                │
     │                │───────────────────────────────────────────────>│
     │                │                │                │                │
     │                │ 4. Generate    │                │                │
     │                │    letters     │                │                │
     │                │───────────────>│                │                │
     │                │                │ 5. Load        │                │
     │                │                │    template    │                │
     │                │                │───────────────────────────────>│
     │                │                │                │                │
     │                │                │ 6. Generate    │                │
     │                │                │    narrative   │                │
     │                │                │───────────────>│                │
     │                │                │ 7. AI draft    │                │
     │                │                │<───────────────│                │
     │                │                │                │                │
     │                │                │ 8. Merge vars  │                │
     │                │                │    & render    │                │
     │                │                │                │                │
     │                │                │ 9. Generate    │                │
     │                │                │    PDF         │                │
     │                │                │                │                │
     │                │                │ 10. Verify     │                │
     │                │                │     hash       │                │
     │                │                │                │                │
     │                │                │ 11. Store PDF  │                │
     │                │                │───────────────────────────────>│
     │<───────────────────────────────────────────────────────────────────
     │ 12. Preview    │                │                │                │
     │                │                │                │                │
```

### Flow 3: Letter Mailing & Tracking

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Operator │     │   Mail   │     │   Lob    │     │ Webhook  │     │   DB     │
│  (Admin) │     │ Service  │     │   API    │     │ Service  │     │          │
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │                │                │
     │ 1. Approve &   │                │                │                │
     │    send letter │                │                │                │
     │───────────────>│                │                │                │
     │                │ 2. Validate    │                │                │
     │                │    addresses   │                │                │
     │                │───────────────>│                │                │
     │                │ 3. Address OK  │                │                │
     │                │<───────────────│                │                │
     │                │                │                │                │
     │                │ 4. Create      │                │                │
     │                │    letter      │                │                │
     │                │───────────────>│                │                │
     │                │ 5. lob_id +    │                │                │
     │                │    tracking    │                │                │
     │                │<───────────────│                │                │
     │                │ 6. Update      │                │                │
     │                │    letter      │                │                │
     │                │───────────────────────────────────────────────>│
     │<───────────────────────────────────────────────────────────────────
     │ 7. Sent        │                │                │                │
     │                │                │                │                │
     │                │                │ 8. Webhook:    │                │
     │                │                │    mailed      │                │
     │                │                │───────────────>│                │
     │                │                │                │ 9. Process     │
     │                │                │                │    event       │
     │                │                │                │───────────────>│
     │                │                │                │                │
     │                │                │ 10. Webhook:   │                │
     │                │                │     delivered  │                │
     │                │                │───────────────>│                │
     │                │                │                │ 11. Update     │
     │                │                │                │     status     │
     │                │                │                │───────────────>│
     │                │                │                │                │
     │                │                │                │ 12. Notify     │
     │                │                │                │     consumer   │
     │                │                │                │                │
```

---

## Multi-Tenancy Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         REQUEST FLOW                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Request → Extract tenant from JWT → Validate tenant → Set context     │
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                    TENANT ISOLATION                               │  │
│   ├──────────────────────────────────────────────────────────────────┤  │
│   │                                                                   │  │
│   │   ┌─────────────────┐    ┌─────────────────┐                     │  │
│   │   │   Tenant A      │    │   Tenant B      │                     │  │
│   │   │                 │    │                 │                     │  │
│   │   │ • consumers     │    │ • consumers     │                     │  │
│   │   │ • disputes      │    │ • disputes      │                     │  │
│   │   │ • letters       │    │ • letters       │                     │  │
│   │   │ • evidence      │    │ • evidence      │                     │  │
│   │   │ • SmartCredit   │    │ • SmartCredit   │                     │  │
│   │   │   connection    │    │   connection    │                     │  │
│   │   │ • Lob sender    │    │ • Lob sender    │                     │  │
│   │   │ • Branding      │    │ • Branding      │                     │  │
│   │   └─────────────────┘    └─────────────────┘                     │  │
│   │                                                                   │  │
│   │   Database: tenant_id column on all rows                         │  │
│   │   Queries: Automatic tenant_id filtering via middleware          │  │
│   │   Storage: S3 prefix per tenant                                  │  │
│   │                                                                   │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tenant Isolation Strategy

| Layer | Isolation Method |
|-------|-----------------|
| Database | `tenant_id` foreign key on all tables, query filtering middleware |
| API | JWT contains `tenant_id`, validated on every request |
| Storage | S3 bucket prefix: `s3://bucket/{tenant_id}/...` |
| Secrets | Separate SmartCredit/Lob credentials per tenant |
| Caching | Redis key prefix: `{tenant_id}:...` |
| Queues | Task metadata includes tenant context |

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYERS                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ NETWORK SECURITY                                                 │   │
│   │ • WAF (Web Application Firewall)                                │   │
│   │ • DDoS protection                                               │   │
│   │ • TLS 1.3 only                                                  │   │
│   │ • VPC with private subnets                                      │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ APPLICATION SECURITY                                             │   │
│   │ • JWT with short expiry (15 min access, 7 day refresh)          │   │
│   │ • RBAC (owner, operator, viewer, auditor)                       │   │
│   │ • Input validation (Pydantic)                                   │   │
│   │ • Output encoding                                               │   │
│   │ • CSRF protection                                               │   │
│   │ • Rate limiting                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ DATA SECURITY                                                    │   │
│   │ • AES-256 encryption at rest                                    │   │
│   │ • Column-level encryption for SSN (pgcrypto)                    │   │
│   │ • TLS in transit                                                │   │
│   │ • PII masking in logs                                           │   │
│   │ • Secrets in AWS Secrets Manager                                │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ AUDIT & COMPLIANCE                                               │   │
│   │ • Full audit logging (read + write)                             │   │
│   │ • Immutable audit trail                                         │   │
│   │ • Consent capture with timestamp/IP                             │   │
│   │ • Data retention policies                                       │   │
│   │ • FCRA/GLBA compliance controls                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AWS / GCP DEPLOYMENT                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     PRODUCTION ENVIRONMENT                       │   │
│   ├─────────────────────────────────────────────────────────────────┤   │
│   │                                                                  │   │
│   │   Region: us-east-1 (Primary) + us-west-2 (DR)                  │   │
│   │                                                                  │   │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│   │   │ CloudFront  │  │    ALB      │  │   Route53   │             │   │
│   │   │    CDN      │  │ (HTTPS)     │  │    DNS      │             │   │
│   │   └─────────────┘  └─────────────┘  └─────────────┘             │   │
│   │                                                                  │   │
│   │   ┌─────────────────────────────────────────────────┐           │   │
│   │   │              ECS Fargate / EKS                   │           │   │
│   │   │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │           │   │
│   │   │  │ Django  │  │ Django  │  │ Django  │          │           │   │
│   │   │  │ API (3) │  │ API (3) │  │ API (3) │          │           │   │
│   │   │  └─────────┘  └─────────┘  └─────────┘          │           │   │
│   │   │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │           │   │
│   │   │  │ Celery  │  │ Celery  │  │ Celery  │          │           │   │
│   │   │  │Worker(5)│  │Worker(5)│  │Beat (1) │          │           │   │
│   │   │  └─────────┘  └─────────┘  └─────────┘          │           │   │
│   │   └─────────────────────────────────────────────────┘           │   │
│   │                                                                  │   │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│   │   │    RDS      │  │ ElastiCache │  │     S3      │             │   │
│   │   │ PostgreSQL  │  │   Redis     │  │  (Storage)  │             │   │
│   │   │  (Multi-AZ) │  │  (Cluster)  │  │             │             │   │
│   │   └─────────────┘  └─────────────┘  └─────────────┘             │   │
│   │                                                                  │   │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│   │   │  Secrets    │  │     KMS     │  │ CloudWatch  │             │   │
│   │   │  Manager    │  │(Encryption) │  │  (Logging)  │             │   │
│   │   └─────────────┘  └─────────────┘  └─────────────┘             │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack Summary

| Layer | Technology |
|-------|------------|
| Frontend | Flutter Web/Mobile |
| API Framework | Django 5.0 + Django REST Framework |
| Authentication | JWT (djangorestframework-simplejwt) + OAuth2 |
| Database | PostgreSQL 16 with pgcrypto |
| Cache/Queue | Redis 7 + Celery 5 |
| PDF Generation | WeasyPrint |
| Object Storage | AWS S3 / GCP Cloud Storage |
| Secrets | AWS Secrets Manager / GCP Secret Manager |
| Container | Docker + ECS Fargate / GKE |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana + Sentry |
| Logging | ELK Stack / CloudWatch |

---

## SLOs and Operational Targets

| Metric | Target |
|--------|--------|
| Availability | 99.9% uptime |
| API Latency (p95) | < 500ms |
| PDF Render Time | < 10 seconds |
| Webhook Processing | < 30 seconds |
| RTO (Recovery Time Objective) | 1 hour |
| RPO (Recovery Point Objective) | 24 hours |
| Backup Frequency | Daily (incremental), Weekly (full) |
