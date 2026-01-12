# SFDIFY Credit Dispute Letter System - Architecture

## System Overview

The SFDIFY Credit Dispute Letter System is a production-ready, multi-tenant platform that automates consumer credit disputes by:
- Integrating with SmartCredit for credit report data
- Generating compliant FCRA dispute letters
- Mailing letters via Lob API
- Tracking dispute lifecycle and SLAs
- Maintaining complete audit trails

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter Client                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Consumer   │  │   Disputes   │  │   Letters    │          │
│  │   Dashboard  │  │  Management  │  │   Tracking   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────┬─────────────────────────────────────┘
                            │ REST API
┌────────────────────────────┼─────────────────────────────────────┐
│                    Backend API Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Auth &     │  │   Dispute    │  │   Letter     │          │
│  │   Tenancy    │  │   Service    │  │   Service    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────────────┬───────────────┬───────────────┬──────────────────┘
               │               │               │
     ┌─────────┼───────────────┼───────────────┼─────────┐
     │         │               │               │         │
┌────▼────┐ ┌──▼─────────┐ ┌──▼──────────┐ ┌──▼────────┐
│Database │ │ SmartCredit│ │ Lob API     │ │   Queue   │
│(Primary)│ │    API     │ │ (Mail)      │ │  (Jobs)   │
└─────────┘ └────────────┘ └─────────────┘ └───────────┘
```

## System Architecture Components

### 1. Service Layer

#### **A. Consumer Service**
- User registration and KYC verification
- SmartCredit OAuth connection flow
- Consumer profile management
- Multi-address and contact information

#### **B. Credit Report Service**
- Pull credit reports from SmartCredit (3-bureau)
- Parse and normalize bureau data
- Track report versions and changes
- Detect tradeline updates

#### **C. Dispute Service**
- Issue identification and categorization
- Dispute creation per bureau
- Status tracking and workflow management
- SLA monitoring (30/45 day timelines)
- Outcome reconciliation

#### **D. Letter Service**
- Template selection based on dispute type
- Variable interpolation and personalization
- PDF generation with evidence attachments
- Letter versioning and approval workflow
- Quality checks before mailing

#### **E. Mailing Service (Lob Integration)**
- Lob letter creation
- Mail class selection (First Class, Certified, Return Receipt)
- Tracking and delivery status updates
- Webhook processing for mail events
- Cost tracking per letter

#### **F. Evidence Service**
- File upload and validation
- Virus scanning and MIME type checking
- Evidence packaging with disputes
- Document checksum verification
- Secure storage with encryption

#### **G. Notification Service**
- Email and SMS notifications
- Event-driven triggers (mail sent, SLA approaching, bureau response)
- Template-based messaging
- Delivery tracking

#### **H. Audit Service**
- Complete chain of custody logging
- User action tracking
- Data access logs
- Compliance reporting
- GDPR/CCPA data export

#### **I. Billing Service**
- Usage metering (letters sent, SmartCredit API calls)
- Invoice generation per tenant
- Cost allocation (Lob postage, SmartCredit fees)
- Payment tracking

#### **J. Compliance Service**
- FCRA compliance checks
- Letter content validation
- PII masking and encryption
- Consent management
- Data retention enforcement

### 2. Integration Layer

#### **SmartCredit Integration**
```dart
// OAuth flow
- Authorization endpoint
- Token exchange
- Token refresh
- Secure token storage in vault

// API Endpoints
- GET /credit-reports (3-bureau pull)
- GET /tradelines (account details)
- GET /alerts (change notifications)
- GET /score-factors (analysis)
```

#### **Lob Integration**
```dart
// Letter API
- POST /letters (create and send)
- GET /letters/{id} (status check)
- POST /webhooks (delivery events)

// Mail Options
- us_letter size
- color: true/false
- mail_type: usps_first_class | certified | certified_return_receipt
- return_envelope tracking
```

### 3. Data Layer Architecture

See ERD section below for complete data model.

### 4. Queue System

#### **Background Jobs**
- **Letter Rendering Job**: PDF generation (async)
- **Mailing Job**: Lob API calls with retry logic
- **Report Refresh Job**: Scheduled SmartCredit pulls
- **SLA Check Job**: Daily deadline monitoring
- **Reconciliation Job**: Compare old vs new reports
- **Webhook Processing Job**: Handle Lob events

#### **Job Configuration**
- Retry: 3 attempts with exponential backoff
- Timeout: 2 minutes per job
- Priority queue for urgent tasks
- Dead letter queue for failures

### 5. Security Architecture

#### **Authentication & Authorization**
- JWT-based authentication
- Role-based access control (Owner, Operator, Viewer, Auditor)
- Multi-factor authentication (TOTP)
- Session management with refresh tokens

#### **Data Protection**
- Column-level encryption for SSN, DOB
- AES-256 encryption at rest
- TLS 1.3 for data in transit
- Key rotation policies

#### **Secrets Management**
- AWS Secrets Manager / GCP Secret Manager
- API keys and tokens in vault
- Environment-specific configuration
- Automated secret rotation

#### **Compliance**
- FCRA compliance (Fair Credit Reporting Act)
- GLBA Safeguards Rule
- CCPA / GDPR compliance
- SOC 2 audit trail

### 6. Multi-Tenancy

#### **Tenant Isolation**
- Row-level security with tenant_id
- Separate branding per tenant
- Custom letterheads and return addresses
- Per-tenant API rate limits

#### **Tenant Configuration**
- Lob account credentials
- SmartCredit connection per tenant
- Custom letter templates
- Billing plans and limits

### 7. Observability

#### **Logging**
- Structured JSON logs
- Log levels: DEBUG, INFO, WARN, ERROR
- PII masking in logs
- Centralized log aggregation

#### **Metrics**
- API latency percentiles (p50, p95, p99)
- Error rates per endpoint
- Queue depth and processing time
- External API call success rates

#### **Tracing**
- Distributed tracing with correlation IDs
- Request lifecycle tracking
- Performance bottleneck identification

#### **Alerting**
- SLA breach notifications
- External API failures
- Queue backlog alerts
- Security event alerts

## Data Flow

### Dispute Creation Flow
```
1. User connects SmartCredit → OAuth flow → Store tokens
2. System pulls 3-bureau reports → Parse tradelines → Store data
3. User selects inaccurate items → Create dispute records per bureau
4. User adds evidence → Upload and scan files → Link to disputes
5. System generates letters → Select templates → Merge variables → Render PDF
6. Operator reviews → Approve/Edit → Schedule mailing
7. System calls Lob API → Create letter → Track delivery
8. Webhook updates → Mail events → Update dispute status
9. SLA job monitors → 30-day deadline → Schedule follow-up
10. System refreshes report → Compare changes → Reconcile outcomes
```

### Letter Generation Flow
```
1. Select dispute type → Map to letter template (609, 611, MOV, etc.)
2. Load consumer data → Name, DOB, SSN_last4, addresses
3. Load tradeline data → Creditor, account, dates, balances
4. Load bureau addresses → Equifax, Experian, TransUnion
5. Merge template variables → Personalize content
6. Add evidence index → List attached documents
7. Render to PDF → HTML → PDF engine
8. Quality checks → Validate addresses, content length, completeness
9. Store PDF → Cloud storage → Generate signed URL
10. Ready for approval → Operator review → Send or edit
```

## API Design

### Consumer Endpoints
```
POST   /api/v1/consumers
GET    /api/v1/consumers/{id}
PATCH  /api/v1/consumers/{id}
POST   /api/v1/consumers/{id}/smartcredit/connect
POST   /api/v1/consumers/{id}/reports/refresh
GET    /api/v1/consumers/{id}/reports
GET    /api/v1/consumers/{id}/tradelines
```

### Dispute Endpoints
```
POST   /api/v1/disputes
GET    /api/v1/disputes
GET    /api/v1/disputes/{id}
PATCH  /api/v1/disputes/{id}
POST   /api/v1/disputes/{id}/evidence
DELETE /api/v1/disputes/{id}/evidence/{evidence_id}
GET    /api/v1/disputes/{id}/timeline
```

### Letter Endpoints
```
POST   /api/v1/letters
GET    /api/v1/letters/{id}
GET    /api/v1/letters/{id}/pdf
POST   /api/v1/letters/{id}/send
POST   /api/v1/letters/{id}/approve
POST   /api/v1/letters/{id}/reject
```

### Webhook Endpoints
```
POST   /api/v1/webhooks/lob
POST   /api/v1/webhooks/smartcredit
```

### Admin Endpoints
```
GET    /api/v1/admin/metrics
GET    /api/v1/admin/billing
GET    /api/v1/admin/audit-logs
GET    /api/v1/admin/tenants
```

## Technology Stack

### Frontend (Flutter)
- **State Management**: BLoC pattern
- **Networking**: Dio with interceptors
- **DI**: GetIt + Injectable
- **Routing**: GoRouter
- **Persistence**: Hive + SharedPreferences

### Backend (Node.js/NestJS or Django/FastAPI)
- **Framework**: NestJS (TypeScript) or FastAPI (Python)
- **ORM**: Prisma or TypeORM (Node) / SQLAlchemy (Python)
- **Queue**: BullMQ (Redis) or Celery (Python)
- **Cache**: Redis
- **Search**: PostgreSQL full-text or Elasticsearch

### Database
- **Primary**: PostgreSQL 15+ with row-level security
- **Cache**: Redis for sessions and temporary data
- **Documents**: S3-compatible storage for PDFs and evidence

### Infrastructure
- **Hosting**: AWS, GCP, or Azure
- **CDN**: CloudFront or CloudFlare
- **Monitoring**: Datadog, New Relic, or self-hosted Prometheus
- **Secrets**: AWS Secrets Manager or HashiCorp Vault

## SLOs and Performance Targets

- **Uptime**: 99.9% (8.76 hours downtime/year)
- **API Latency**: p95 < 500ms
- **Letter Generation**: < 5 seconds per letter
- **Report Pull**: < 10 seconds (SmartCredit dependent)
- **Webhook Processing**: < 1 second
- **RTO**: 1 hour (Recovery Time Objective)
- **RPO**: 24 hours (Recovery Point Objective)

## Deployment Strategy

### Environments
1. **Development**: Local development with mock APIs
2. **Staging**: Full integration with SmartCredit/Lob sandboxes
3. **Production**: Live system with real APIs

### CI/CD Pipeline
```
Code Commit → Linting & Tests → Build → Deploy to Staging →
Integration Tests → Manual Approval → Deploy to Production →
Smoke Tests → Monitor
```

### Rollback Strategy
- Blue-green deployment for zero downtime
- Database migrations with rollback scripts
- Feature flags for gradual rollout

## 90-Day Implementation Roadmap

### Phase 1: Foundation (Days 1-30)
**Sprint 1 (Week 1-2): Core Infrastructure**
- [ ] Set up backend API framework
- [ ] Database schema implementation
- [ ] Multi-tenancy and RBAC
- [ ] Authentication system
- [ ] Basic Flutter UI scaffolding

**Sprint 2 (Week 3-4): SmartCredit Integration**
- [ ] OAuth flow implementation
- [ ] Credit report pull endpoint
- [ ] Tradeline parsing and normalization
- [ ] Report comparison engine
- [ ] UI for credit report viewing

### Phase 2: Core Features (Days 31-60)
**Sprint 3 (Week 5-6): Dispute Management**
- [ ] Dispute creation workflow
- [ ] Issue categorization system
- [ ] Evidence upload and management
- [ ] Dispute tracking UI
- [ ] Status management

**Sprint 4 (Week 7-8): Letter Generation**
- [ ] Template engine implementation
- [ ] 8 base letter templates (609, 611, MOV, etc.)
- [ ] Variable interpolation
- [ ] PDF generation pipeline
- [ ] Letter preview UI
- [ ] Approval workflow

### Phase 3: Mailing & Tracking (Days 61-90)
**Sprint 5 (Week 9-10): Lob Integration**
- [ ] Lob API integration
- [ ] Mail type selection (Certified, First Class)
- [ ] Webhook handler for mail events
- [ ] Tracking dashboard UI
- [ ] Cost calculation

**Sprint 6 (Week 11-12): SLA & Compliance**
- [ ] SLA monitoring jobs
- [ ] Automated follow-up triggers
- [ ] Notification system (email/SMS)
- [ ] Audit logging
- [ ] Compliance checks
- [ ] Billing system

**Sprint 7 (Week 13): Testing & Launch**
- [ ] End-to-end testing with sandbox APIs
- [ ] Security audit
- [ ] Performance testing
- [ ] Documentation
- [ ] Production deployment
- [ ] Monitoring setup

## Success Metrics

### Operational Metrics
- Letters generated per day
- Average time from intake to first letter
- Delivery success rate
- SLA compliance rate (>95%)

### Business Metrics
- Cost per letter (target: <$5 for certified mail)
- User satisfaction score
- Dispute resolution rate
- Revenue per tenant

### Technical Metrics
- API error rate (<0.1%)
- Average API latency (p95 <500ms)
- System uptime (>99.9%)
- Queue processing time (<30 seconds)

## Risk Management

### Technical Risks
1. **SmartCredit API downtime**: Cache reports locally, retry logic
2. **Lob API rate limits**: Queue management, throttling
3. **PDF generation failures**: Multiple rendering engines, fallback templates
4. **Data breach**: Encryption, access controls, audit logging

### Compliance Risks
1. **FCRA violations**: Legal review of templates, disclaimer text
2. **Unauthorized access**: RBAC, 2FA, session management
3. **Data retention**: Automated deletion policies, user consent

### Operational Risks
1. **Queue backlog**: Horizontal scaling, priority queues
2. **Cost overrun**: Usage monitoring, spending alerts, tenant limits
3. **Letter quality issues**: Multi-layer validation, human approval

## Appendix

### Letter Types Supported
1. **FCRA 609**: Information request
2. **FCRA 611**: Dispute of accuracy
3. **Method of Verification**: Request for proof
4. **Reinvestigation Follow-up**: 30-day follow-up
5. **Goodwill Adjustment**: Request to creditor
6. **Pay for Delete**: Offer to collector
7. **Identity Theft Block**: 605B with police report
8. **CFPB Complaint**: Package export

### Bureau Addresses
- **Equifax**: P.O. Box 740256, Atlanta, GA 30374
- **Experian**: P.O. Box 4500, Allen, TX 75013
- **TransUnion**: P.O. Box 2000, Chester, PA 19016

### Compliance Citations
- Fair Credit Reporting Act (FCRA) 15 U.S.C. § 1681
- FCRA Section 607: Compliance procedures
- FCRA Section 609: Disclosures to consumers
- FCRA Section 611: Procedure in case of disputed accuracy
- FCRA Section 605B: Identity theft block
- GLBA Safeguards Rule: 16 CFR Part 314

---

**Document Version**: 1.0
**Last Updated**: 2026-01-12
**Author**: SFDIFY Engineering Team
