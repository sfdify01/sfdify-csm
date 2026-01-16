# Flutter Frontend + Firebase Backend Integration Plan

## Overview

This plan outlines the step-by-step integration of the Flutter frontend with the Firebase Cloud Functions backend. The frontend already has excellent infrastructure in place (Clean Architecture, BLoC, DI, Feature Flags) - we need to connect it to the real Firebase backend.

---

## Phase 1: Firebase Service Layer Setup

### 1.1 Create Firebase Cloud Functions Service
Create a centralized service to call Cloud Functions.

**File:** `lib/core/services/firebase_functions_service.dart`

**Tasks:**
- [ ] Create `FirebaseFunctionsService` class
- [ ] Register in DI (`register_module.dart`)
- [ ] Handle authentication token injection
- [ ] Implement generic `call<T>()` method with error handling
- [ ] Map Firebase exceptions to app Failures

### 1.2 Create Firebase Auth Service
Wrap Firebase Auth for the app.

**File:** `lib/core/services/firebase_auth_service.dart`

**Tasks:**
- [ ] Create `FirebaseAuthService` with login/logout/register methods
- [ ] Implement token management (get ID token for Cloud Functions)
- [ ] Handle auth state changes stream
- [ ] Register in DI

### 1.3 Update Register Module
Update DI registration for new services.

**File:** `lib/injection/register_module.dart`

**Tasks:**
- [ ] Register `FirebaseFunctionsService` as singleton
- [ ] Register `FirebaseAuthService` as singleton
- [ ] Ensure emulator configuration is applied

---

## Phase 2: Authentication Feature

### 2.1 Create Auth Feature Structure
```
lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── login_response_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login.dart
│       ├── logout.dart
│       ├── register.dart
│       └── get_current_user.dart
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart
    │   ├── auth_event.dart
    │   └── auth_state.dart
    └── pages/
        ├── login_page.dart
        └── register_page.dart
```

### 2.2 Implementation Tasks
- [ ] Create `UserEntity` and `UserModel`
- [ ] Create `AuthRepository` interface
- [ ] Create `AuthRemoteDataSource` using `FirebaseAuthService`
- [ ] Create `AuthRepositoryImpl`
- [ ] Create auth use cases (Login, Logout, Register, GetCurrentUser)
- [ ] Create `AuthBloc` with states: Initial, Loading, Authenticated, Unauthenticated, Error
- [ ] Create Login and Register pages
- [ ] Add auth routes to `app_router.dart`
- [ ] Add `AuthBloc` to root `MultiBlocProvider`

### 2.3 Auth Guard
- [ ] Create route guard for protected routes
- [ ] Redirect unauthenticated users to login

---

## Phase 3: Tenant Feature

### 3.1 Create Tenant Feature Structure
```
lib/features/tenant/
├── data/
│   ├── datasources/
│   │   └── tenant_remote_datasource.dart
│   ├── models/
│   │   └── tenant_model.dart
│   └── repositories/
│       └── tenant_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── tenant_entity.dart
│   ├── repositories/
│   │   └── tenant_repository.dart
│   └── usecases/
│       ├── get_tenant.dart
│       └── update_tenant.dart
└── presentation/
    ├── bloc/
    │   └── tenant_bloc.dart
    └── pages/
        └── tenant_settings_page.dart
```

### 3.2 Implementation Tasks
- [ ] Create `TenantEntity` and `TenantModel`
- [ ] Create `TenantRemoteDataSource` calling Cloud Functions:
  - `tenantsGet`
  - `tenantsUpdate`
- [ ] Create `TenantRepository` and implementation
- [ ] Create use cases
- [ ] Create `TenantBloc`
- [ ] Create tenant settings page

---

## Phase 4: Consumer Feature Integration

### 4.1 Update Existing Consumer Feature
The consumer feature structure exists but needs Firebase integration.

**Files to update:**
- `lib/features/consumer/data/datasources/consumer_remote_datasource.dart` (create)
- `lib/features/consumer/data/repositories/consumer_repository_impl.dart` (create)
- `lib/features/consumer/domain/repositories/consumer_repository.dart` (create)

### 4.2 Implementation Tasks
- [ ] Create `ConsumerRemoteDataSource` calling Cloud Functions:
  - `consumersCreate`
  - `consumersGet`
  - `consumersUpdate`
  - `consumersList`
  - `consumersTradelinesList`
  - `consumersSmartCreditConnect`
  - `consumersSmartCreditDisconnect`
  - `consumersReportsRefresh`
- [ ] Create `ConsumerRepository` interface
- [ ] Create `ConsumerRepositoryImpl`
- [ ] Create use cases:
  - `GetConsumers`
  - `GetConsumer`
  - `CreateConsumer`
  - `UpdateConsumer`
  - `GetTradelines`
  - `ConnectSmartCredit`
  - `RefreshCreditReport`
- [ ] Create `ConsumerListBloc` and `ConsumerDetailBloc`
- [ ] Create consumer list and detail pages
- [ ] Add routes

---

## Phase 5: Dispute Feature Integration

### 5.1 Update Existing Dispute Feature
The dispute feature has structure but uses mock data.

**Files to update:**
- `lib/features/dispute/data/datasources/dispute_remote_datasource.dart`
- `lib/features/dispute/data/repositories/dispute_repository_impl.dart`

### 5.2 Implementation Tasks
- [ ] Update `DisputeRemoteDataSource` to call Cloud Functions:
  - `disputesCreate`
  - `disputesGet`
  - `disputesUpdate`
  - `disputesList`
  - `disputesSubmit`
  - `disputesApprove`
  - `disputesClose`
- [ ] Update `DisputeModel` to match backend response
- [ ] Update repository implementation
- [ ] Add new use cases:
  - `CreateDispute`
  - `SubmitDispute`
  - `ApproveDispute`
  - `CloseDispute`
- [ ] Create `DisputeDetailBloc`
- [ ] Create dispute detail and create pages
- [ ] Update routes

---

## Phase 6: Letter Feature Integration

### 6.1 Create Letter Feature Structure
```
lib/features/letter/
├── data/
│   ├── datasources/
│   │   └── letter_remote_datasource.dart
│   ├── models/
│   │   └── letter_model.dart
│   └── repositories/
│       └── letter_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── letter_repository.dart
│   └── usecases/
│       ├── generate_letter.dart
│       ├── get_letter.dart
│       ├── approve_letter.dart
│       ├── send_letter.dart
│       └── list_letters.dart
└── presentation/
    ├── bloc/
    │   ├── letter_list_bloc.dart
    │   └── letter_detail_bloc.dart
    └── pages/
        ├── letter_list_page.dart
        └── letter_detail_page.dart
```

### 6.2 Implementation Tasks
- [ ] Create `LetterModel` (extend existing entity)
- [ ] Create `LetterRemoteDataSource` calling Cloud Functions:
  - `lettersGenerate`
  - `lettersGet`
  - `lettersApprove`
  - `lettersSend`
  - `lettersList`
- [ ] Create repository interface and implementation
- [ ] Create use cases
- [ ] Create `LetterListBloc` and `LetterDetailBloc`
- [ ] Create letter pages with PDF preview
- [ ] Add routes

---

## Phase 7: Evidence Feature

### 7.1 Create Evidence Feature Structure
```
lib/features/evidence/
├── data/
│   ├── datasources/
│   │   └── evidence_remote_datasource.dart
│   ├── models/
│   │   └── evidence_model.dart
│   └── repositories/
│       └── evidence_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── evidence_repository.dart
│   └── usecases/
│       ├── upload_evidence.dart
│       ├── get_evidence.dart
│       ├── delete_evidence.dart
│       └── list_evidence.dart
└── presentation/
    ├── bloc/
    │   └── evidence_bloc.dart
    └── widgets/
        ├── evidence_upload_widget.dart
        └── evidence_list_widget.dart
```

### 7.2 Implementation Tasks
- [ ] Create `EvidenceModel`
- [ ] Create `EvidenceRemoteDataSource` calling Cloud Functions:
  - `evidenceUpload` (with file upload to Storage)
  - `evidenceGet`
  - `evidenceUpdate`
  - `evidenceDelete`
  - `evidenceList`
  - `evidenceLinkToLetter`
  - `evidenceUnlinkFromLetter`
- [ ] Handle file upload via Firebase Storage
- [ ] Create repository interface and implementation
- [ ] Create use cases
- [ ] Create `EvidenceBloc`
- [ ] Create upload widget with drag-and-drop
- [ ] Create evidence list widget for dispute/letter detail pages

---

## Phase 8: User Management Feature

### 8.1 Create User Management Feature
```
lib/features/users/
├── data/
│   ├── datasources/
│   │   └── user_remote_datasource.dart
│   ├── models/
│   │   └── user_model.dart
│   └── repositories/
│       └── user_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   ├── repositories/
│   │   └── user_repository.dart
│   └── usecases/
│       ├── get_users.dart
│       ├── create_user.dart
│       ├── update_user.dart
│       ├── delete_user.dart
│       └── set_user_role.dart
└── presentation/
    ├── bloc/
    │   └── user_management_bloc.dart
    └── pages/
        └── user_management_page.dart
```

### 8.2 Implementation Tasks
- [ ] Create `UserModel` for team members
- [ ] Create `UserRemoteDataSource` calling Cloud Functions:
  - `usersCreate`
  - `usersGet`
  - `usersUpdate`
  - `usersDelete`
  - `usersList`
  - `usersSetRole`
- [ ] Create repository and use cases
- [ ] Create `UserManagementBloc`
- [ ] Create user management page (for owner/admin)
- [ ] Add role-based UI restrictions

---

## Phase 9: Admin Dashboard Feature

### 9.1 Create Admin Feature
```
lib/features/admin/
├── data/
│   ├── datasources/
│   │   └── admin_remote_datasource.dart
│   └── models/
│       ├── analytics_model.dart
│       ├── billing_model.dart
│       └── audit_log_model.dart
├── domain/
│   └── usecases/
│       ├── get_dispute_analytics.dart
│       ├── get_letter_analytics.dart
│       ├── get_billing_usage.dart
│       ├── get_audit_logs.dart
│       └── export_data.dart
└── presentation/
    ├── bloc/
    │   ├── analytics_bloc.dart
    │   └── audit_bloc.dart
    └── pages/
        ├── analytics_dashboard_page.dart
        ├── billing_page.dart
        └── audit_logs_page.dart
```

### 9.2 Implementation Tasks
- [ ] Create models for analytics, billing, audit
- [ ] Create `AdminRemoteDataSource` calling Cloud Functions:
  - `adminAnalyticsDisputes`
  - `adminAnalyticsLetters`
  - `adminBillingUsage`
  - `adminAuditLogs`
  - `adminExportData`
  - `adminGetExportStatus`
  - `adminSystemHealth`
- [ ] Create use cases
- [ ] Create `AnalyticsBloc` and `AuditBloc`
- [ ] Create dashboard pages with charts
- [ ] Add routes (restricted to owner role)

---

## Phase 10: Real-time Updates & Notifications

### 10.1 Firestore Listeners
- [ ] Create `FirestoreListenerService` for real-time updates
- [ ] Add dispute status change listeners
- [ ] Add letter status change listeners
- [ ] Update BLoCs to handle real-time events

### 10.2 Push Notifications (Optional)
- [ ] Setup Firebase Cloud Messaging
- [ ] Handle notification permissions
- [ ] Create notification handler
- [ ] Deep link from notifications to relevant pages

---

## Phase 11: Testing & Quality

### 11.1 Unit Tests
- [ ] Test all use cases
- [ ] Test BLoCs with mock repositories
- [ ] Test repositories with mock datasources

### 11.2 Integration Tests
- [ ] Test auth flow end-to-end
- [ ] Test CRUD operations against emulator
- [ ] Test file upload flow

### 11.3 Widget Tests
- [ ] Test key pages
- [ ] Test form validation

---

## Phase 12: Production Readiness

### 12.1 Error Handling
- [ ] Implement global error boundary
- [ ] Setup Crashlytics error reporting
- [ ] Add user-friendly error messages

### 12.2 Performance
- [ ] Implement pagination for lists
- [ ] Add caching with Hive
- [ ] Optimize image loading

### 12.3 Security
- [ ] Validate all user inputs
- [ ] Implement session timeout
- [ ] Add biometric authentication option

### 12.4 Feature Flags
- [ ] Configure Remote Config flags
- [ ] Implement gradual rollout
- [ ] Add kill switch for emergencies

---

## Implementation Order (Recommended)

1. **Phase 1** - Firebase Service Layer (Foundation)
2. **Phase 2** - Authentication (Required for all other features)
3. **Phase 5** - Dispute Integration (Already has UI structure)
4. **Phase 4** - Consumer Integration (Needed for disputes)
5. **Phase 6** - Letter Integration (Core workflow)
6. **Phase 7** - Evidence Integration (Supports letters)
7. **Phase 3** - Tenant Settings
8. **Phase 8** - User Management
9. **Phase 9** - Admin Dashboard
10. **Phase 10** - Real-time Updates
11. **Phase 11** - Testing
12. **Phase 12** - Production Readiness

---

## Files to Create Summary

### Core Services (Phase 1)
- `lib/core/services/firebase_functions_service.dart`
- `lib/core/services/firebase_auth_service.dart`

### Auth Feature (Phase 2)
- 15+ files (datasource, models, repository, usecases, bloc, pages)

### Tenant Feature (Phase 3)
- 10+ files

### Consumer Feature Updates (Phase 4)
- 8+ files (datasource, repository, usecases, bloc, pages)

### Dispute Feature Updates (Phase 5)
- 5+ files (update existing + add new)

### Letter Feature (Phase 6)
- 12+ files

### Evidence Feature (Phase 7)
- 10+ files

### User Management (Phase 8)
- 12+ files

### Admin Dashboard (Phase 9)
- 15+ files

**Total: ~100+ files to create/modify**

---

## Environment Configuration

Ensure these are configured for each environment:

### Development (Emulator)
```dart
FirebaseConfig.environment = 'dev';
// Uses localhost emulators
```

### Staging
```dart
FirebaseConfig.environment = 'staging';
// Uses staging Firebase project
```

### Production
```dart
FirebaseConfig.environment = 'prod';
// Uses production Firebase project
```

---

## Next Step

Start with **Phase 1: Firebase Service Layer Setup** to create the foundation for all subsequent integrations.
