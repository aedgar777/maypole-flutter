/**
 * Firebase Cloud Function for handling account deletion cleanup
 * 
 * This function runs asynchronously after account deletion to update
 * all messages from a deleted user to show "[Deleted User]" instead
 * of their username.
 * 
 * SETUP:
 * 1. Make sure you have Firebase Functions initialized:
 *    firebase init functions
 * 
 * 2. Install dependencies:
 *    cd functions && npm install
 * 
 * 3. Deploy:
 *    firebase deploy --only functions
 * 
 * USAGE:
 * Modify AuthService.deleteAccount() to mark the account for deletion
 * instead of immediately deleting it. This function will handle the rest.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Triggered when a user document is updated.
 * If the document has deletionPending=true, process account deletion.
 */
exports.processAccountDeletion = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    
    // Only proceed if deletionPending was just set to true
    if (!after.deletionPending || before.deletionPending) {
      return null;
    }
    
    const userId = context.params.userId;
    const username = after.username;
    
    console.log(`Processing account deletion for user: ${username} (${userId})`);
    
    try {
      // Step 1: Update Maypole chat messages
      await updateMaypoleMessages(username);
      
      // Step 2: Update Direct Messages
      await updateDirectMessages(username);
      
      // Step 3: Delete user document
      await db.collection('users').doc(userId).delete();
      console.log(`Deleted user document for ${userId}`);
      
      // Step 4: Delete username reservation
      await db.collection('usernames').doc(username.toLowerCase()).delete();
      console.log(`Deleted username reservation for ${username}`);
      
      // Step 5: Delete Firebase Auth account
      try {
        await admin.auth().deleteUser(userId);
        console.log(`Deleted auth account for ${userId}`);
      } catch (authError) {
        // Auth account might already be deleted
        console.log(`Auth account already deleted or not found: ${authError.message}`);
      }
      
      console.log(`Successfully completed account deletion for ${username}`);
      return null;
      
    } catch (error) {
      console.error(`Error processing account deletion for ${username}:`, error);
      // Mark as failed for retry or manual intervention
      await db.collection('users').doc(userId).update({
        deletionFailed: true,
        deletionError: error.message,
      });
      throw error;
    }
  });

/**
 * Updates all Maypole chat messages from a user to show "[Deleted User]"
 */
async function updateMaypoleMessages(username) {
  console.log(`Updating Maypole messages for ${username}`);
  
  // Use collectionGroup to query all messages across all maypole threads
  const messagesQuery = await db.collectionGroup('messages')
    .where('sender', '==', username)
    .where('type', '==', 'place')
    .get();
  
  if (messagesQuery.empty) {
    console.log('No Maypole messages found');
    return;
  }
  
  // Process in batches (Firestore batch limit is 500)
  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;
  
  messagesQuery.docs.forEach((doc) => {
    currentBatch.update(doc.ref, { sender: '[Deleted User]' });
    operationCount++;
    
    // If we hit the batch limit, start a new batch
    if (operationCount === 500) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      operationCount = 0;
    }
  });
  
  // Add the last batch if it has operations
  if (operationCount > 0) {
    batches.push(currentBatch);
  }
  
  // Commit all batches
  await Promise.all(batches.map(batch => batch.commit()));
  console.log(`Updated ${messagesQuery.size} Maypole messages in ${batches.length} batch(es)`);
}

/**
 * Updates all Direct Messages from a user to show "[Deleted User]"
 * 
 * Note: This requires knowing the structure of your DM threads.
 * You may need to adjust based on your actual implementation.
 */
async function updateDirectMessages(username) {
  console.log(`Updating Direct Messages for ${username}`);
  
  // Query all DM thread documents where this user might have messages
  // This depends on your DM structure - adjust as needed
  const messagesQuery = await db.collectionGroup('messages')
    .where('sender', '==', username)
    .where('type', '==', 'direct')
    .get();
  
  if (messagesQuery.empty) {
    console.log('No Direct Messages found');
    return;
  }
  
  // Process in batches
  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;
  
  messagesQuery.docs.forEach((doc) => {
    currentBatch.update(doc.ref, { sender: '[Deleted User]' });
    operationCount++;
    
    if (operationCount === 500) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      operationCount = 0;
    }
  });
  
  if (operationCount > 0) {
    batches.push(currentBatch);
  }
  
  await Promise.all(batches.map(batch => batch.commit()));
  console.log(`Updated ${messagesQuery.size} Direct Messages in ${batches.length} batch(es)`);
}

/**
 * Alternative: Trigger on Auth user deletion
 * 
 * This version triggers directly on Firebase Auth deletion events.
 * Uncomment if you want to use this approach instead.
 */
/*
exports.onUserAuthDelete = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  
  console.log(`User deleted from Auth: ${userId}`);
  
  try {
    // Fetch username from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log('User document already deleted');
      return null;
    }
    
    const username = userDoc.data().username;
    
    // Update all messages
    await updateMaypoleMessages(username);
    await updateDirectMessages(username);
    
    // Delete user document
    await db.collection('users').doc(userId).delete();
    
    // Delete username reservation
    await db.collection('usernames').doc(username.toLowerCase()).delete();
    
    console.log(`Cleanup completed for ${username}`);
    return null;
    
  } catch (error) {
    console.error('Error in auth deletion cleanup:', error);
    throw error;
  }
});
*/

/**
 * Manual cleanup function (callable from admin)
 * 
 * Use this to manually clean up a deleted user's messages.
 * Call it from your app or admin panel when needed.
 */
exports.manualCleanupDeletedUser = functions.https.onCall(async (data, context) => {
  // Verify the caller is authenticated (add admin check in production)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to call this function'
    );
  }
  
  const { username } = data;
  
  if (!username) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Username is required'
    );
  }
  
  try {
    await updateMaypoleMessages(username);
    await updateDirectMessages(username);
    
    return {
      success: true,
      message: `Successfully updated messages for ${username}`,
    };
  } catch (error) {
    console.error('Manual cleanup error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update messages',
      error.message
    );
  }
});

/**
 * MONITORING AND METRICS
 * 
 * Add these if you want to track deletion metrics:
 */

// Log deletion events to a separate collection for analytics
async function logDeletionEvent(userId, username) {
  await db.collection('deletionLogs').add({
    userId,
    username,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: 'completed',
  });
}

// Count messages updated
async function recordDeletionStats(username, maypoleCount, dmCount) {
  await db.collection('deletionStats').add({
    username,
    maypoleMessagesUpdated: maypoleCount,
    directMessagesUpdated: dmCount,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
