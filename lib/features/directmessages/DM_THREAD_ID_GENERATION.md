# DM Thread ID Generation

## Overview

The DM thread ID generation system ensures that a conversation between two users always has the same
ID, regardless of which participant initiates the conversation.

## Implementation

### Core Method

```dart
String generateThreadId(String userId1, String userId2) {
  final sortedIds = [userId1, userId2]..sort();
  return '${sortedIds[0]}_${sortedIds[1]}';
}
```

### How It Works

1. **Takes two user IDs** as input
2. **Sorts them lexicographically** (alphabetically)
3. **Concatenates them** with an underscore delimiter
4. **Returns the same result** regardless of parameter order

### Example

```dart
// Both calls produce the same result: "abc123_xyz789"
generateThreadId('abc123', 'xyz789') // Returns: "abc123_xyz789"
generateThreadId('xyz789', 'abc123') // Returns: "abc123_xyz789"
```

## Benefits

- ✅ **Deterministic**: Same inputs always produce same output
- ✅ **Order-independent**: Works regardless of who starts the conversation
- ✅ **Unique**: Each pair of users gets exactly one conversation ID
- ✅ **Simple**: No database lookups or external state needed
- ✅ **Collision-free**: Different user pairs never share the same ID
- ✅ **Firestore-friendly**: Can be used directly as document ID

## Usage

### 1. Get or Create a DM Thread

```dart
final dmThreadService = DMThreadService();

// When user wants to start a conversation with another user
final thread = await dmThreadService.getOrCreateDMThread(
  currentUserId: 'user123',
  currentUsername: 'Alice',
  currentUserProfpic: 'https://example.com/alice.jpg',
  partnerId: 'user456',
  partnerName: 'Bob',
  partnerProfpic: 'https://example.com/bob.jpg',
);

// The thread ID will be automatically generated (e.g., "user123_user456")
print(thread.id);
```

### 2. Generate Thread ID Only

```dart
final dmThreadService = DMThreadService();

// If you just need the ID without creating/fetching the thread
final threadId = dmThreadService.generateThreadId('user123', 'user456');
print(threadId); // Output: "user123_user456"

// Or in reverse order
final sameThreadId = dmThreadService.generateThreadId('user456', 'user123');
print(sameThreadId); // Output: "user123_user456" (same as above!)
```

### 3. Send a Message

```dart
final dmThreadService = DMThreadService();

// Generate the thread ID
final threadId = dmThreadService.generateThreadId(currentUserId, partnerId);

// Send a message
await dmThreadService.sendDmMessage(
  threadId,
  'Hello!',
  currentUserId,
  partnerId,
);
```

### 4. Listen to Messages

```dart
final dmThreadService = DMThreadService();

// Generate the thread ID
final threadId = dmThreadService.generateThreadId(currentUserId, partnerId);

// Listen to messages in real-time
dmThreadService.getDmMessages(threadId).listen((messages) {
  // Update UI with messages
  print('Received ${messages.length} messages');
});
```

## Integration with Firestore

The generated thread ID is used as the Firestore document ID:

```
DMThreads (collection)
  └── user123_user456 (document) <- Generated thread ID
      ├── id: "user123_user456"
      ├── name: "Bob"
      ├── partnerName: "Bob"
      ├── partnerId: "user456"
      ├── partnerProfpic: "https://..."
      ├── lastMessageTime: Timestamp
      ├── lastMessage: {...}
      └── messages (subcollection)
          ├── message1 (auto-generated doc)
          ├── message2 (auto-generated doc)
          └── ...
```

## Best Practices

1. **Always use the service method**: Don't manually create thread IDs
2. **Use `getOrCreateDMThread`**: This ensures the thread exists before sending messages
3. **Store user IDs consistently**: Use the same user ID format throughout your app
4. **Don't modify the algorithm**: Changing the sorting or delimiter will break existing threads

## Security Considerations

Update your Firestore security rules to ensure users can only access threads they're part of:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /DMThreads/{threadId} {
      // Extract user IDs from the thread ID (format: userId1_userId2)
      allow read, write: if request.auth != null && 
        (threadId.split('_')[0] == request.auth.uid || 
         threadId.split('_')[1] == request.auth.uid);
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          (threadId.split('_')[0] == request.auth.uid || 
           threadId.split('_')[1] == request.auth.uid);
      }
    }
  }
}
```

## Testing

You can verify the thread ID generation works correctly:

```dart
void testThreadIdGeneration() {
  final service = DMThreadService();
  
  // Test 1: Order independence
  final id1 = service.generateThreadId('alice', 'bob');
  final id2 = service.generateThreadId('bob', 'alice');
  assert(id1 == id2, 'Thread IDs should be the same regardless of order');
  print('✓ Order independence test passed');
  
  // Test 2: Different pairs produce different IDs
  final id3 = service.generateThreadId('alice', 'charlie');
  assert(id1 != id3, 'Different user pairs should have different thread IDs');
  print('✓ Uniqueness test passed');
  
  // Test 3: Same user pairs always produce same ID
  final id4 = service.generateThreadId('alice', 'bob');
  assert(id1 == id4, 'Same user pairs should always produce the same thread ID');
  print('✓ Consistency test passed');
  
  print('\nAll tests passed! ✓');
}
```

## Future Enhancements

If you need shorter IDs in the future, you can switch to a hash-based approach:

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateThreadIdHash(String userId1, String userId2) {
  final sortedIds = [userId1, userId2]..sort();
  final combined = '${sortedIds[0]}_${sortedIds[1]}';
  final bytes = utf8.encode(combined);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 16); // Use first 16 chars
}
```

However, the current approach is preferred for its simplicity and readability.
