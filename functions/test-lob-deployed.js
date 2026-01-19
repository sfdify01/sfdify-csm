const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'ustaxx-csm'
  });
}

const db = getFirestore();

async function testLobWorkflow() {
  console.log('=== Testing Lob Workflow via Deployed Functions ===\n');
  
  // Create a test consumer document
  const testConsumerId = 'test-consumer-' + Date.now();
  const testDisputeId = 'test-dispute-' + Date.now();
  const testLetterId = 'test-letter-' + Date.now();
  
  console.log('1. Creating test consumer...');
  await db.collection('consumers').doc(testConsumerId).set({
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    address: {
      street: '185 Berry St Ste 6100',
      city: 'San Francisco',
      state: 'CA',
      zipCode: '94107'
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    tenantId: 'test-tenant'
  });
  console.log('   Consumer created:', testConsumerId);
  
  console.log('\n2. Creating test dispute...');
  await db.collection('disputes').doc(testDisputeId).set({
    consumerId: testConsumerId,
    status: 'pending_letter',
    bureau: 'equifax',
    accountName: 'Test Account',
    accountNumber: '****1234',
    reason: 'not_mine',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    tenantId: 'test-tenant'
  });
  console.log('   Dispute created:', testDisputeId);
  
  console.log('\n3. Creating test letter...');
  await db.collection('letters').doc(testLetterId).set({
    disputeId: testDisputeId,
    consumerId: testConsumerId,
    status: 'approved',
    recipientAddress: {
      name: 'Equifax Information Services LLC',
      addressLine1: 'P.O. Box 740256',
      city: 'Atlanta',
      state: 'GA',
      zipCode: '30374'
    },
    senderAddress: {
      name: 'Test User',
      addressLine1: '185 Berry St Ste 6100',
      city: 'San Francisco',
      state: 'CA',
      zipCode: '94107'
    },
    content: '<html><body><h1>Credit Dispute Letter</h1><p>I am writing to dispute the following information...</p></body></html>',
    mailType: 'usps_first_class',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    tenantId: 'test-tenant'
  });
  console.log('   Letter created:', testLetterId);
  
  console.log('\n4. Test documents created. Now call lettersSend function from your app or via curl.');
  console.log('   Letter ID to send:', testLetterId);
  
  // Clean up test data
  console.log('\n5. Cleaning up test data...');
  await db.collection('letters').doc(testLetterId).delete();
  await db.collection('disputes').doc(testDisputeId).delete();
  await db.collection('consumers').doc(testConsumerId).delete();
  console.log('   Test data cleaned up.');
  
  console.log('\n=== Test Complete ===');
}

testLobWorkflow().catch(console.error);
