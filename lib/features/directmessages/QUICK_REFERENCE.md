# DM Thread Service - Quick Reference

## TL;DR

```dart
// Generate consistent conversation ID
final threadId = dmService.generateThreadId(userId1, userId2);
// Always returns the same ID regardless of parameter order!

// Get or create a conversation
final thread = await dmService.getOrCreateDMThread(
  currentUserId: 'abc123',
  currentUsername: 'Alice',
  currentUserProfpic: 'https://...',
  partnerId: 'xyz789',
  partnerName: 'Bob',
  partnerProfpic: 'https://...',
);

// Send a message
await dmService.sendDmMessage(threadId, 'Hello!', senderId, recipientId);

// Listen to messages
ref.watch(dmViewModelProvider(threadId));
```

## Key Methods

| Method | Purpose | Returns |
|--------|---------|---------|
| `generateThreadId(id1, id2)` | Generate consistent conversation ID | `String` |
| `getOrCreateDMThread(...)` | Get existing or create new thread | `Future<DMThread>` |
| `getDMThreadById(threadId)` | Fetch specific thread | `Future<DMThread?>` |
| `sendDmMessage(...)` | Send a message | `Future<void>` |
| `getDmMessages(threadId)` | Stream messages in real-time | `Stream<List<DirectMessage>>` |
| `getMoreDmMessages(...)` | Load older messages | `Future<List<DirectMessage>>` |

## Thread ID Format

```
user_id_1_user_id_2

Examples:
- generateThreadId('alice', 'bob') → "alice_bob"
- generateThreadId('bob', 'alice') → "alice_bob" (same!)
- generateThreadId('user123', 'user456') → "user123_user456"
```

## Firestore Structure

```
DMThreads/
  ├── alice_bob/                    ← Document (thread ID)
  │   ├── id: "alice_bob"
  │   ├── name: "Bob"               ← Partner name (from Alice's perspective)
  │   ├── partnerName: "Bob"
  │   ├── partnerId: "bob"
  │   ├── partnerProfpic: "..."
  │   ├── lastMessageTime: Timestamp
  │   ├── lastMessage: {...}
  │   └── messages/                  ← Subcollection
  │       ├── auto_id_1/
  │       │   ├── sender: "alice"
  │       │   ├── recipient: "bob"
  │       │   ├── body: "Hello!"
  │       │   └── timestamp: Timestamp
  │       └── auto_id_2/
  │           └── ...
  └── alice_charlie/
      └── ...
```

## Common Patterns

### Pattern 1: Start New Conversation

```dart
final thread = await dmService.getOrCreateDMThread(
  currentUserId: currentUser.firebaseID,
  currentUsername: currentUser.username,
  currentUserProfpic: currentUser.profilePictureUrl,
  partnerId: otherUser.firebaseID,
  partnerName: otherUser.username,
  partnerProfpic: otherUser.profilePictureUrl,
);
context.push('/dm/${thread.id}', extra: thread);
```

### Pattern 2: Navigate to Existing Thread

```dart
final threadId = dmService.generateThreadId(myId, theirId);
final thread = await dmService.getDMThreadById(threadId);
if (thread != null) {
  context.push('/dm/${thread.id}', extra: thread);
}
```

### Pattern 3: Real-time Messages

```dart
// In your widget:
final messages = ref.watch(dmViewModelProvider(threadId));

messages.when(
  data: (msgs) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

### Pattern 4: Send Message

```dart
ref.read(dmViewModelProvider(threadId).notifier)
   .sendDmMessage(messageText, senderId, recipientId);
```

## Providers

```dart
// Service instance
final dmService = ref.read(dmThreadServiceProvider);

// Messages stream with state management
final messagesState = ref.watch(dmViewModelProvider(threadId));

// Send message
ref.read(dmViewModelProvider(threadId).notifier)
   .sendDmMessage(...);

// Load more messages
ref.read(dmViewModelProvider(threadId).notifier)
   .loadMoreMessages();
```

## Security Rules Example

```javascript
match /DMThreads/{threadId} {
  allow read, write: if request.auth != null && 
    (threadId.split('_')[0] == request.auth.uid || 
     threadId.split('_')[1] == request.auth.uid);
  
  match /messages/{messageId} {
    allow read, write: if request.auth != null && 
      (threadId.split('_')[0] == request.auth.uid || 
       threadId.split('_')[1] == request.auth.uid);
  }
}
```

## Checklist for Implementation

- [x] ✅ Import `dm_providers.dart`
- [x] ✅ Get `DMThreadService` via provider
- [x] ✅ Use `generateThreadId()` for consistency
- [x] ✅ Use `getOrCreateDMThread()` before navigating
- [x] ✅ Pass `DMThread` object via router `extra` parameter
- [x] ✅ Use `dmViewModelProvider` for messages
- [x] ✅ Handle loading and error states
- [x] ✅ Update Firestore security rules

## Testing Quick Check

```dart
void quickTest() {
  final service = DMThreadService();
  
  // Should be true
  assert(
    service.generateThreadId('a', 'b') == 
    service.generateThreadId('b', 'a')
  );
  
  // Should be true
  assert(
    service.generateThreadId('a', 'b') != 
    service.generateThreadId('a', 'c')
  );
  
  print('✅ Thread ID generation working correctly!');
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Different thread IDs for same users | Always use `generateThreadId()` method |
| Messages not updating | Check that you're watching `dmViewModelProvider` |
| Can't see messages | Verify Firestore security rules |
| Duplicate threads | Use `getOrCreateDMThread()` instead of manual creation |
| Thread not found | Ensure both users have the thread in their `dmThreads` array |

## Related Files

- **Service**: `lib/features/directmessages/data/dm_thread_service.dart`
- **Domain**: `lib/features/directmessages/domain/dm_thread.dart`
- **Providers**: `lib/features/directmessages/presentation/dm_providers.dart`
- **Screen**: `lib/features/directmessages/presentation/screens/dm_screen.dart`
- **ViewModel**: `lib/features/directmessages/presentation/viewmodels/dm_viewmodel.dart`
- **Router**: `lib/core/app_router.dart`

## Need More Help?

See the detailed documentation:

- `DM_THREAD_ID_GENERATION.md` - Deep dive into the algorithm
- `USAGE_EXAMPLES.md` - Comprehensive code examples
