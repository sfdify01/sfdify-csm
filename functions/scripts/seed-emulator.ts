/**
 * Seed Script for Firebase Emulator
 *
 * Run with: npx ts-node scripts/seed-emulator.ts
 *
 * This script populates the Firestore emulator with test data
 * for development and testing purposes.
 */

import * as admin from "firebase-admin";

// Connect to emulator
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";

admin.initializeApp({
  projectId: "ustaxx-csm",
});

const db = admin.firestore();
const auth = admin.auth();

// Test data IDs
const TENANT_ID = "test-tenant-001";
const OWNER_ID = "test-owner-001";
const OPERATOR_ID = "test-operator-001";
const CONSUMER_ID = "test-consumer-001";
const DISPUTE_ID = "test-dispute-001";

async function seedTenant() {
  console.log("Creating test tenant...");
  await db.collection("tenants").doc(TENANT_ID).set({
    id: TENANT_ID,
    name: "Test Credit Repair Company",
    plan: "professional",
    status: "active",
    branding: {
      companyName: "Test Credit Repair Co",
      primaryColor: "#1a73e8",
      tagline: "Helping you repair your credit",
    },
    lobConfig: {
      defaultMailType: "usps_first_class",
      returnAddress: {
        name: "Test Credit Repair Co",
        addressLine1: "123 Main Street",
        city: "Austin",
        state: "TX",
        zipCode: "78701",
      },
    },
    features: {
      aiDraftingEnabled: true,
      certifiedMailEnabled: true,
      identityTheftBlockEnabled: false,
      cfpbExportEnabled: true,
      maxConsumers: 1000,
      maxDisputesPerMonth: 500,
    },
    stats: {
      totalConsumers: 0,
      activeConsumers: 0,
      totalDisputes: 0,
      activeDisputes: 0,
      resolvedDisputes: 0,
      lettersDelivered: 0,
      lettersReturned: 0,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log("✓ Tenant created");
}

// Permissions by role
const ROLE_PERMISSIONS: Record<string, string[]> = {
  owner: [
    "consumers:read", "consumers:write", "consumers:delete",
    "disputes:read", "disputes:write", "disputes:delete", "disputes:approve",
    "letters:read", "letters:write", "letters:send", "letters:approve",
    "evidence:read", "evidence:write", "evidence:delete",
    "users:read", "users:write", "users:delete",
    "tenant:read", "tenant:write",
    "analytics:read", "audit:read",
  ],
  operator: [
    "consumers:read", "consumers:write",
    "disputes:read", "disputes:write",
    "letters:read", "letters:write",
    "evidence:read", "evidence:write",
    "analytics:read",
  ],
  viewer: [
    "consumers:read",
    "disputes:read",
    "letters:read",
    "evidence:read",
  ],
  auditor: [
    "consumers:read",
    "disputes:read",
    "letters:read",
    "evidence:read",
    "audit:read",
  ],
};

async function seedUsers() {
  console.log("Creating test users...");

  // Create owner user in Auth
  try {
    await auth.createUser({
      uid: OWNER_ID,
      email: "owner@testcompany.com",
      password: "TestPassword123!",
      displayName: "Test Owner",
    });
  } catch (e: any) {
    if (e.code !== "auth/uid-already-exists") throw e;
  }

  // Set custom claims for owner (CRITICAL for frontend auth)
  await auth.setCustomUserClaims(OWNER_ID, {
    tenantId: TENANT_ID,
    role: "owner",
    permissions: ROLE_PERMISSIONS.owner,
  });

  // Create owner in Firestore
  await db.collection("users").doc(OWNER_ID).set({
    id: OWNER_ID,
    tenantId: TENANT_ID,
    email: "owner@testcompany.com",
    displayName: "Test Owner",
    role: "owner",
    disabled: false,
    mfaEnabled: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create operator user in Auth
  try {
    await auth.createUser({
      uid: OPERATOR_ID,
      email: "operator@testcompany.com",
      password: "TestPassword123!",
      displayName: "Test Operator",
    });
  } catch (e: any) {
    if (e.code !== "auth/uid-already-exists") throw e;
  }

  // Set custom claims for operator
  await auth.setCustomUserClaims(OPERATOR_ID, {
    tenantId: TENANT_ID,
    role: "operator",
    permissions: ROLE_PERMISSIONS.operator,
  });

  // Create operator in Firestore
  await db.collection("users").doc(OPERATOR_ID).set({
    id: OPERATOR_ID,
    tenantId: TENANT_ID,
    email: "operator@testcompany.com",
    displayName: "Test Operator",
    role: "operator",
    disabled: false,
    mfaEnabled: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✓ Users created with custom claims");
  console.log("  - owner@testcompany.com / TestPassword123!");
  console.log("  - operator@testcompany.com / TestPassword123!");
}

async function seedConsumer() {
  console.log("Creating test consumer...");

  await db.collection("consumers").doc(CONSUMER_ID).set({
    id: CONSUMER_ID,
    tenantId: TENANT_ID,
    // Note: In production these would be encrypted
    firstName: "John",
    lastName: "Doe",
    dob: "1985-03-15",
    ssnLast4: "1234",
    addresses: [
      {
        type: "current",
        street1: "456 Consumer Lane",
        city: "Dallas",
        state: "TX",
        zip: "75201",
        isPrimary: true,
      },
    ],
    phones: [
      {
        type: "mobile",
        number: "+15551234567",
        isPrimary: true,
      },
    ],
    emails: [
      {
        address: "john.doe@example.com",
        isPrimary: true,
        verified: true,
      },
    ],
    kycStatus: "verified",
    kycVerifiedAt: admin.firestore.Timestamp.now(),
    consent: {
      agreedAt: admin.firestore.Timestamp.now(),
      ipAddress: "127.0.0.1",
      termsVersion: "1.0",
      privacyVersion: "1.0",
      fcraDisclosureVersion: "1.0",
    },
    stats: {
      totalDisputes: 0,
      activeDisputes: 0,
      resolvedDisputes: 0,
      totalLetters: 0,
      totalEvidence: 0,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: OPERATOR_ID,
  });

  console.log("✓ Consumer created: John Doe");
}

async function seedTradeline() {
  console.log("Creating test tradeline...");

  const tradelineId = "test-tradeline-001";
  await db.collection("tradelines").doc(tradelineId).set({
    id: tradelineId,
    consumerId: CONSUMER_ID,
    tenantId: TENANT_ID,
    bureau: "equifax",
    creditorName: "Test Bank Credit Card",
    accountNumber: "****5678",
    accountType: "credit_card",
    dateOpened: "2020-01-15",
    currentBalance: 2500,
    creditLimit: 5000,
    paymentStatus: "30_days_late",
    isNegative: true,
    reportedDate: admin.firestore.Timestamp.now(),
    rawData: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✓ Tradeline created: Test Bank Credit Card");
  return tradelineId;
}

async function seedDispute(tradelineId: string) {
  console.log("Creating test dispute...");

  const now = new Date();
  const dueDate = new Date(now);
  dueDate.setDate(dueDate.getDate() + 30);

  await db.collection("disputes").doc(DISPUTE_ID).set({
    id: DISPUTE_ID,
    consumerId: CONSUMER_ID,
    tradelineId: tradelineId,
    tenantId: TENANT_ID,
    bureau: "equifax",
    type: "611_dispute",
    reasonCodes: ["INACCURATE_BALANCE", "INCORRECT_PAYMENT_STATUS"],
    reasonDetails: {
      INACCURATE_BALANCE: {
        reportedValue: 2500,
        actualValue: 0,
        explanation: "Account was paid in full on 12/01/2024",
      },
      INCORRECT_PAYMENT_STATUS: {
        reportedStatus: "30_days_late",
        actualStatus: "current",
        explanation: "Payment was made on time via auto-pay",
      },
    },
    narrative: "I am disputing the accuracy of this account. The balance reported is incorrect as I paid this account in full. Additionally, the payment status shows 30 days late, but I have always paid on time through auto-pay.",
    status: "draft",
    priority: "normal",
    timestamps: {
      createdAt: admin.firestore.Timestamp.now(),
      dueAt: admin.firestore.Timestamp.fromDate(dueDate),
    },
    sla: {
      baseDays: 30,
      extendedDays: 0,
      isExtended: false,
    },
    letterIds: [],
    evidenceIds: [],
    tags: ["first_dispute", "balance_error"],
    createdBy: OPERATOR_ID,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✓ Dispute created: 611 Dispute for Equifax");
}

async function seedLetterTemplate() {
  console.log("Creating letter template...");

  const templateId = "template-611-standard";
  await db.collection("letterTemplates").doc(templateId).set({
    id: templateId,
    tenantId: TENANT_ID,
    name: "Standard 611 Dispute Letter",
    type: "611_dispute",
    version: "1.0",
    isActive: true,
    content: `{{consumerName}}
{{consumerAddress}}

{{date}}

{{bureauName}}
{{bureauAddress}}

Re: Dispute of Inaccurate Information
SSN: XXX-XX-{{ssnLast4}}

Dear Sir or Madam,

I am writing to dispute the following information in my credit report. The items I dispute are:

Account: {{creditorName}}
Account Number: {{accountNumber}}

{{narrative}}

Under the Fair Credit Reporting Act (FCRA) Section 611, I am requesting that you investigate this matter and correct the inaccurate information.

Please investigate this matter and correct the disputed items as soon as possible.

Sincerely,

{{consumerName}}

Enclosures: {{evidenceList}}`,
    variables: [
      "consumerName",
      "consumerAddress",
      "date",
      "bureauName",
      "bureauAddress",
      "ssnLast4",
      "creditorName",
      "accountNumber",
      "narrative",
      "evidenceList",
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: OWNER_ID,
  });

  console.log("✓ Letter template created");
  return templateId;
}

async function main() {
  console.log("\n🌱 Seeding Firebase Emulator with test data...\n");

  try {
    await seedTenant();
    await seedUsers();
    await seedConsumer();
    const tradelineId = await seedTradeline();
    await seedDispute(tradelineId);
    await seedLetterTemplate();

    console.log("\n✅ Seed data created successfully!\n");
    console.log("You can now:");
    console.log("1. Open the Emulator UI at http://localhost:4000");
    console.log("2. Log in with owner@testcompany.com / TestPassword123!");
    console.log("3. Test the Cloud Functions\n");
  } catch (error) {
    console.error("❌ Error seeding data:", error);
    process.exit(1);
  }

  process.exit(0);
}

main();
