# SFDIFY Credit Dispute System - Firebase Implementation Roadmap

## Document Info
| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-01-15 | SFDIFY Team |

---

## 1. Overview

This document outlines the implementation roadmap for migrating the SFDIFY Credit Dispute System to a Firebase-only architecture. The migration is structured in phases to ensure a smooth transition while maintaining system stability.

### 1.1 Migration Goals

1. **Simplify Infrastructure** - Single platform (Firebase) vs. multiple services
2. **Reduce Operational Overhead** - Serverless, no server management
3. **Improve Scalability** - Automatic scaling with Firebase
4. **Maintain Compliance** - FCRA/GLBA compliance preserved
5. **Flutter Integration** - Native Firebase SDKs for Flutter

### 1.2 Architecture Comparison

| Component | Previous (Django) | New (Firebase) |
|-----------|-------------------|----------------|
| Backend | Django REST Framework | Cloud Functions |
| Database | PostgreSQL | Cloud Firestore |
| Authentication | Custom JWT | Firebase Auth |
| File Storage | Django/S3 | Firebase Storage |
| Background Jobs | Celery + Redis | Cloud Functions (scheduled/triggered) |
| Hosting | VPS/Cloud Run | Firebase Hosting |
| Notifications | Custom | Firebase Cloud Messaging |

---

## 2. Project Structure

### 2.1 Repository Structure

```
sfdify_scm/
├── firebase/                        # Firebase project
│   ├── functions/                   # Cloud Functions
│   │   ├── src/
│   │   │   ├── index.ts            # Main exports
│   │   │   ├── config/             # Configuration
│   │   │   ├── auth/               # Auth functions
│   │   │   ├── consumers/          # Consumer functions
│   │   │   ├── smartcredit/        # SmartCredit integration
│   │   │   ├── disputes/           # Dispute functions
│   │   │   ├── letters/            # Letter functions
│   │   │   ├── mailings/           # Mailing functions
│   │   │   ├── evidence/           # Evidence functions
│   │   │   ├── templates/          # Template functions
│   │   │   ├── webhooks/           # Webhook handlers
│   │   │   ├── scheduled/          # Scheduled functions
│   │   │   ├── triggers/           # Firestore triggers
│   │   │   ├── analytics/          # Analytics functions
│   │   │   └── utils/              # Utilities
│   │   ├── test/                   # Function tests
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── firestore.rules             # Firestore security rules
│   ├── firestore.indexes.json      # Firestore indexes
│   ├── storage.rules               # Storage security rules
│   ├── firebase.json               # Firebase config
│   └── .firebaserc                 # Project aliases
│
├── flutter_app/                     # Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart   # Generated Firebase config
│   │   ├── core/
│   │   │   ├── di/                 # Dependency injection
│   │   │   ├── errors/             # Error handling
│   │   │   ├── utils/              # Utilities
│   │   │   └── constants/          # Constants
│   │   ├── data/
│   │   │   ├── datasources/        # Firebase data sources
│   │   │   ├── models/             # Data models
│   │   │   └── repositories/       # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/           # Domain entities
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   └── usecases/           # Use cases
│   │   ├── presentation/
│   │   │   ├── blocs/              # BLoC state management
│   │   │   ├── pages/              # Screen pages
│   │   │   └── widgets/            # Reusable widgets
│   │   └── services/
│   │       ├── auth_service.dart
│   │       ├── consumer_service.dart
│   │       ├── dispute_service.dart
│   │       └── ...
│   ├── test/                       # Flutter tests
│   └── pubspec.yaml
│
├── docs/                           # Documentation
│   ├── FIREBASE-01-ARCHITECTURE.md
│   ├── FIREBASE-02-DATA-MODEL.md
│   ├── FIREBASE-03-API-SPECIFICATION.md
│   ├── FIREBASE-04-SECURITY-RULES.md
│   └── FIREBASE-05-IMPLEMENTATION-ROADMAP.md
│
└── scripts/                        # Migration scripts
    ├── migrate_data.ts
    └── seed_templates.ts
```

---

## 3. Phase 1: Foundation (Days 1-15)

### 3.1 Firebase Project Setup

#### 3.1.1 Create Firebase Projects

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create projects
firebase projects:create sfdify-dev
firebase projects:create sfdify-staging
firebase projects:create sfdify-production
```

#### 3.1.2 Initialize Firebase

```bash
cd sfdify_scm/firebase

# Initialize Firebase services
firebase init firestore   # Firestore database
firebase init functions    # Cloud Functions
firebase init storage      # Cloud Storage
firebase init hosting      # Web hosting
firebase init emulators    # Local emulators
```

#### 3.1.3 Configure Project Aliases

```json
// .firebaserc
{
  "projects": {
    "dev": "sfdify-dev",
    "staging": "sfdify-staging",
    "production": "sfdify-production"
  }
}
```

### 3.2 Authentication Setup

#### 3.2.1 Enable Auth Providers

In Firebase Console:
1. Enable Email/Password authentication
2. Configure password policy (12+ chars, complexity)
3. Enable email verification

#### 3.2.2 Implement Auth Functions

```typescript
// functions/src/auth/index.ts
export { initializeUser } from "./initializeUser";
export { updateUserRole } from "./updateUserRole";
export { inviteUser } from "./inviteUser";
export { revokeUserAccess } from "./revokeUserAccess";
export { onUserCreated } from "./onCreate";
export { onUserDeleted } from "./onDelete";
```

**Task Checklist - Phase 1.2:**

- [ ] Create `initializeUser` function
- [ ] Create `updateUserRole` function
- [ ] Create `inviteUser` function
- [ ] Create `revokeUserAccess` function
- [ ] Create `onUserCreated` trigger
- [ ] Create `onUserDeleted` trigger
- [ ] Test custom claims flow
- [ ] Test token refresh

### 3.3 Core Data Structure

#### 3.3.1 Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

#### 3.3.2 Create Indexes

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "consumers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "disputes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "disputes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "consumerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "letters",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "disputeId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "mailings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "auditLogs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "auditLogs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "action", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

```bash
firebase deploy --only firestore:indexes
```

### 3.4 Flutter Firebase Integration

#### 3.4.1 Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  cloud_functions: ^4.6.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.10
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.9
```

#### 3.4.2 Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure --project=sfdify-dev
```

#### 3.4.3 Initialize Firebase

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(const SfdifyApp());
}
```

**Task Checklist - Phase 1:**

- [ ] Create Firebase projects (dev, staging, production)
- [ ] Initialize Firebase services
- [ ] Configure project aliases
- [ ] Enable authentication providers
- [ ] Implement auth Cloud Functions
- [ ] Deploy Firestore security rules
- [ ] Create and deploy Firestore indexes
- [ ] Add Flutter Firebase dependencies
- [ ] Configure FlutterFire CLI
- [ ] Test Firebase initialization
- [ ] Set up local emulators

---

## 4. Phase 2: Core Features (Days 16-40)

### 4.1 Consumer Management

#### 4.1.1 Consumer Functions

```typescript
// functions/src/consumers/index.ts
export { createConsumer } from "./create";
export { updateConsumer } from "./update";
export { getConsumer } from "./get";
export { listConsumers } from "./list";
export { deleteConsumer } from "./delete";
export { searchConsumers } from "./search";
```

**Implementation Tasks:**

- [ ] `createConsumer` - Create with PII encryption
- [ ] `updateConsumer` - Update consumer fields
- [ ] `getConsumer` - Retrieve with related data option
- [ ] `listConsumers` - Paginated list with filters
- [ ] `deleteConsumer` - Soft delete
- [ ] `searchConsumers` - Full-text search

#### 4.1.2 Flutter Consumer Service

```dart
// lib/services/consumer_service.dart
class ConsumerService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  ConsumerService()
      : _functions = FirebaseFunctions.instanceFor(region: 'us-central1'),
        _firestore = FirebaseFirestore.instance;

  Future<Consumer> createConsumer(CreateConsumerRequest request);
  Future<Consumer> updateConsumer(String id, UpdateConsumerRequest request);
  Future<Consumer?> getConsumer(String id);
  Future<PaginatedResult<Consumer>> listConsumers(ListConsumersRequest request);
  Future<void> deleteConsumer(String id);
  Future<List<Consumer>> searchConsumers(String query);

  // Real-time listener
  Stream<List<Consumer>> watchConsumers(String tenantId) {
    return _firestore
        .collection('consumers')
        .where('tenantId', isEqualTo: tenantId)
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Consumer.fromFirestore(doc)).toList());
  }
}
```

### 4.2 SmartCredit Integration

#### 4.2.1 SmartCredit Functions

```typescript
// functions/src/smartcredit/index.ts
export { initiateOAuth } from "./initiateOAuth";
export { handleOAuthCallback } from "./handleOAuthCallback";
export { pullCreditReport } from "./pullCreditReport";
export { refreshCreditReport } from "./refreshCreditReport";
export { getCreditReport } from "./getCreditReport";
export { disconnectSmartCredit } from "./disconnect";
export { smartcreditWebhook } from "./webhook";
```

**Implementation Tasks:**

- [ ] OAuth flow initiation
- [ ] OAuth callback handling
- [ ] Token encryption and storage
- [ ] Credit report pulling
- [ ] Report parsing to Firestore
- [ ] Tradeline extraction
- [ ] Webhook handler
- [ ] Token refresh mechanism

### 4.3 Dispute Management

#### 4.3.1 Dispute Functions

```typescript
// functions/src/disputes/index.ts
export { createDispute } from "./create";
export { updateDispute } from "./update";
export { getDispute } from "./get";
export { listDisputes } from "./list";
export { updateDisputeStatus } from "./updateStatus";
export { recordDisputeOutcome } from "./recordOutcome";
export { cancelDispute } from "./cancel";

// Triggers
export { onDisputeCreated } from "./triggers/onCreate";
export { onDisputeUpdated } from "./triggers/onUpdate";
```

**Implementation Tasks:**

- [ ] Create dispute with auto-letter option
- [ ] Update dispute fields
- [ ] Get dispute with related data
- [ ] List disputes with pagination/filters
- [ ] Status transition validation
- [ ] Outcome recording
- [ ] Cancel dispute flow
- [ ] Auto-create tasks on dispute creation

### 4.4 Letter Generation

#### 4.4.1 Letter Functions

```typescript
// functions/src/letters/index.ts
export { generateLetter } from "./generate";
export { previewLetter } from "./preview";
export { approveLetter } from "./approve";
export { rejectLetter } from "./reject";
export { regenerateLetter } from "./regenerate";
export { getLetter } from "./get";
export { downloadLetterPdf } from "./downloadPdf";
```

**Implementation Tasks:**

- [ ] Template rendering engine
- [ ] Variable substitution
- [ ] PDF generation (Puppeteer in Cloud Functions)
- [ ] PDF storage in Firebase Storage
- [ ] Letter preview functionality
- [ ] Approval workflow
- [ ] Version control for letters

#### 4.4.2 PDF Generation Setup

```typescript
// functions/src/utils/pdf.ts
import * as puppeteer from "puppeteer";

export async function generatePdf(html: string): Promise<Buffer> {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"]
  });

  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: "networkidle0" });

    const pdfBuffer = await page.pdf({
      format: "Letter",
      printBackground: true,
      margin: {
        top: "0.75in",
        right: "0.75in",
        bottom: "0.75in",
        left: "0.75in"
      }
    });

    return pdfBuffer;
  } finally {
    await browser.close();
  }
}
```

**Task Checklist - Phase 2:**

- [ ] Consumer CRUD functions
- [ ] Consumer Flutter service
- [ ] Consumer list/detail screens
- [ ] SmartCredit OAuth implementation
- [ ] Credit report pulling
- [ ] Report parsing and storage
- [ ] Tradeline display
- [ ] Dispute CRUD functions
- [ ] Dispute status workflow
- [ ] Dispute Flutter screens
- [ ] Letter template system
- [ ] PDF generation setup
- [ ] Letter approval workflow
- [ ] Letter preview functionality

---

## 5. Phase 3: Mailing & Tracking (Days 41-55)

### 5.1 Lob Integration

#### 5.1.1 Mailing Functions

```typescript
// functions/src/mailings/index.ts
export { sendLetter } from "./send";
export { cancelMailing } from "./cancel";
export { trackMailing } from "./track";
export { getMailing } from "./get";

// Webhook
export { lobWebhook } from "./webhook";
```

**Implementation Tasks:**

- [ ] Lob API integration
- [ ] Letter sending function
- [ ] Certified mail support
- [ ] Tracking number handling
- [ ] Delivery status updates
- [ ] Return mail handling
- [ ] Webhook signature verification
- [ ] Status update triggers

### 5.2 Evidence Management

#### 5.2.1 Evidence Functions

```typescript
// functions/src/evidence/index.ts
export { uploadEvidence } from "./upload";
export { confirmUpload } from "./confirmUpload";
export { deleteEvidence } from "./delete";
export { listEvidence } from "./list";
```

**Implementation Tasks:**

- [ ] Signed upload URL generation
- [ ] Upload confirmation
- [ ] File type validation
- [ ] Thumbnail generation (images/PDFs)
- [ ] Evidence listing
- [ ] Secure deletion

### 5.3 SLA Monitoring

#### 5.3.1 Scheduled Functions

```typescript
// functions/src/scheduled/index.ts
export { dailySlaCheck } from "./slaCheck";
export { weeklyCreditRefresh } from "./creditRefresh";
export { dailyCleanup } from "./cleanup";
export { monthlyReportGeneration } from "./reports";
```

**Implementation Tasks:**

- [ ] Daily SLA deadline check
- [ ] Warning notifications (5 days before)
- [ ] Deadline passed notifications
- [ ] SLA violation flagging
- [ ] Weekly credit report refresh
- [ ] Expired data cleanup

**Task Checklist - Phase 3:**

- [ ] Lob API integration
- [ ] Send letter function
- [ ] Lob webhook handler
- [ ] Delivery tracking updates
- [ ] Evidence upload flow
- [ ] Evidence Flutter UI
- [ ] SLA check scheduled function
- [ ] Warning notification system
- [ ] Credit refresh automation
- [ ] Cleanup scheduled function

---

## 6. Phase 4: Analytics & Polish (Days 56-70)

### 6.1 Analytics Dashboard

#### 6.1.1 Analytics Functions

```typescript
// functions/src/analytics/index.ts
export { getDashboardStats } from "./dashboardStats";
export { getDisputeAnalytics } from "./disputeAnalytics";
export { getConsumerAnalytics } from "./consumerAnalytics";
export { exportReport } from "./exportReport";
```

**Implementation Tasks:**

- [ ] Dashboard statistics aggregation
- [ ] Dispute success rate calculation
- [ ] Time series data
- [ ] Bureau comparison metrics
- [ ] Report export functionality

### 6.2 Notifications

#### 6.2.1 FCM Setup

```dart
// lib/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    // Store token in user document

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }
}
```

**Implementation Tasks:**

- [ ] FCM token management
- [ ] Push notification sending
- [ ] In-app notifications
- [ ] Notification preferences
- [ ] Read/dismiss tracking

### 6.3 Template Management

#### 6.3.1 System Templates Seeding

```typescript
// scripts/seed_templates.ts
const systemTemplates = [
  {
    name: "FCRA 609 - Information Request",
    letterType: "fcra_609",
    // ... template content
  },
  {
    name: "FCRA 611 - Dispute Letter",
    letterType: "fcra_611",
    // ... template content
  },
  // ... more templates
];

async function seedTemplates() {
  const db = admin.firestore();
  const batch = db.batch();

  for (const template of systemTemplates) {
    const ref = db.collection("letterTemplates").doc();
    batch.set(ref, {
      ...template,
      tenantId: null,  // System template
      isActive: true,
      isDefault: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  await batch.commit();
}
```

### 6.4 Audit & Compliance

#### 6.4.1 Audit Log Viewer

- [ ] Audit log list view
- [ ] Filter by action/user/resource
- [ ] Export functionality
- [ ] Date range filtering

### 6.5 Error Handling & Monitoring

#### 6.5.1 Crashlytics Integration

```dart
// lib/core/errors/error_handler.dart
class ErrorHandler {
  static void initialize() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> recordError(
    dynamic error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }
}
```

**Task Checklist - Phase 4:**

- [ ] Dashboard statistics function
- [ ] Analytics charts UI
- [ ] FCM notification setup
- [ ] Push notification sending
- [ ] In-app notification center
- [ ] System template seeding
- [ ] Custom template CRUD
- [ ] Audit log viewer
- [ ] Crashlytics integration
- [ ] Performance monitoring
- [ ] Error boundary implementation

---

## 7. Phase 5: Testing & Launch (Days 71-90)

### 7.1 Testing Strategy

#### 7.1.1 Unit Tests

```typescript
// functions/test/consumers.test.ts
import { describe, it, expect } from "vitest";
import { createConsumer } from "../src/consumers/create";

describe("createConsumer", () => {
  it("should create a consumer with encrypted PII", async () => {
    // Test implementation
  });

  it("should fail with invalid email", async () => {
    // Test implementation
  });
});
```

#### 7.1.2 Security Rules Tests

```typescript
// functions/test/security-rules.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";

describe("Firestore Security Rules", () => {
  // Test implementations
});
```

#### 7.1.3 Integration Tests

```dart
// test/integration/dispute_flow_test.dart
void main() {
  group('Dispute Flow Integration Tests', () {
    test('Complete dispute workflow', () async {
      // 1. Create consumer
      // 2. Pull credit report
      // 3. Create dispute
      // 4. Generate letter
      // 5. Approve letter
      // 6. Send letter
      // 7. Track delivery
    });
  });
}
```

### 7.2 Security Testing

- [ ] Authentication bypass attempts
- [ ] Cross-tenant data access tests
- [ ] Role escalation tests
- [ ] Input validation tests
- [ ] Rate limiting tests
- [ ] Webhook signature verification tests

### 7.3 Performance Testing

- [ ] Function cold start times
- [ ] Query performance (with indexes)
- [ ] File upload/download speeds
- [ ] Concurrent user load testing

### 7.4 Pre-Launch Checklist

#### Infrastructure
- [ ] Production Firebase project configured
- [ ] All secrets stored in Secret Manager
- [ ] Security rules deployed and tested
- [ ] Indexes deployed
- [ ] Storage rules deployed
- [ ] Backup schedule configured

#### Integrations
- [ ] SmartCredit production credentials
- [ ] Lob production credentials
- [ ] Webhook URLs configured
- [ ] OAuth redirect URLs configured

#### Compliance
- [ ] FCRA compliance verified
- [ ] GLBA safeguards implemented
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Audit logging enabled

#### Monitoring
- [ ] Crashlytics enabled
- [ ] Performance monitoring enabled
- [ ] Alert policies configured
- [ ] Error tracking setup

#### Flutter App
- [ ] Production build tested
- [ ] App store assets prepared (if applicable)
- [ ] Deep linking configured
- [ ] Analytics tracking verified

### 7.5 Launch Steps

1. **Final Testing** - Complete test suite on staging
2. **Data Migration** - If migrating from existing system
3. **DNS Configuration** - Point domain to Firebase Hosting
4. **Production Deploy** - Deploy all Firebase services
5. **Smoke Testing** - Verify critical paths
6. **Monitoring** - Watch for errors/issues
7. **Gradual Rollout** - Enable for subset of users first

---

## 8. Post-Launch (Days 91+)

### 8.1 Monitoring & Optimization

- Monitor function execution times
- Optimize slow queries
- Adjust function memory allocations
- Review and optimize costs

### 8.2 Feature Enhancements

- AI-powered narrative generation
- Batch dispute processing
- Advanced analytics
- Mobile app (iOS/Android)
- White-label support

### 8.3 Scaling Considerations

- Function instance limits
- Firestore read/write limits
- Storage quotas
- Cost optimization strategies

---

## 9. Development Environment Setup

### 9.1 Prerequisites

```bash
# Required tools
node -v  # v20.x
npm -v   # v10.x
flutter --version  # 3.x
firebase --version # 13.x

# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 9.2 Local Development

```bash
# Start Firebase emulators
cd firebase
firebase emulators:start

# Emulator URLs
# Firestore: http://localhost:8080
# Functions: http://localhost:5001
# Auth: http://localhost:9099
# Storage: http://localhost:9199
# Hosting: http://localhost:5000
# UI: http://localhost:4000
```

### 9.3 Flutter Configuration for Emulators

```dart
// lib/main.dart (development only)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to emulators in development
  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator('localhost', 5001);
  }

  runApp(const SfdifyApp());
}
```

---

## 10. Cost Estimation

### 10.1 Firebase Pricing (Blaze Plan)

| Service | Free Tier | Estimated Monthly (1000 users) |
|---------|-----------|-------------------------------|
| Authentication | 50k MAU free | Free |
| Firestore | 50k reads, 20k writes/day | $50-100 |
| Cloud Functions | 2M invocations/month | $20-50 |
| Cloud Storage | 5GB storage, 1GB transfer | $10-20 |
| Hosting | 10GB storage, 360MB/day | Free |
| **Total Estimated** | | **$80-170/month** |

### 10.2 External Services

| Service | Pricing | Estimated Monthly |
|---------|---------|-------------------|
| SmartCredit API | Per report | $500-1000 |
| Lob (Letters) | ~$1-3 per letter | $500-1500 |
| **Total Estimated** | | **$1000-2500/month** |

---

## 11. Risk Mitigation

### 11.1 Technical Risks

| Risk | Mitigation |
|------|------------|
| Cold start latency | Keep critical functions warm, optimize bundle size |
| Firestore query limits | Proper denormalization, pagination |
| Function timeout (9min max) | Break long operations into steps |
| Vendor lock-in | Document APIs, maintain abstraction layers |

### 11.2 Business Risks

| Risk | Mitigation |
|------|------------|
| Firebase outage | Multi-region deployment, status page monitoring |
| Cost overrun | Budget alerts, usage monitoring |
| Data loss | Automated backups, export procedures |

---

## Appendix A: Firebase CLI Commands Reference

```bash
# Project Management
firebase projects:list
firebase use <project-id>

# Deployment
firebase deploy                        # Deploy all
firebase deploy --only functions       # Deploy functions
firebase deploy --only firestore       # Deploy rules + indexes
firebase deploy --only hosting         # Deploy hosting

# Functions
firebase functions:log                 # View logs
firebase functions:shell              # Interactive shell
firebase functions:delete <name>      # Delete function
firebase functions:secrets:set <name> # Set secret

# Emulators
firebase emulators:start              # Start all
firebase emulators:start --only functions,firestore
firebase emulators:export ./backup    # Export emulator data
firebase emulators:start --import ./backup

# Firestore
firebase firestore:delete --all-collections  # DANGER: Delete all
firebase firestore:indexes            # List indexes

# Hosting
firebase hosting:channel:deploy <channel>  # Preview channel
firebase hosting:clone <source> <dest>     # Clone site
```

---

## Appendix B: Useful Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Cloud Functions Samples](https://github.com/firebase/functions-samples)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Extensions](https://firebase.google.com/products/extensions)
