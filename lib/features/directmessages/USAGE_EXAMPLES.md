# DM Thread Service - Usage Examples

This document provides practical examples of how to use the DM thread ID generation and related
functionality.

## Basic Setup

First, ensure you have access to the `DMThreadService`:

```dart
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/presentation/dm_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// In a ConsumerWidget or ConsumerStatefulWidget:
final dmService = ref.read(dmThreadServiceProvider);
```

## Example 1: Starting a New Conversation

When a user clicks on another user's profile to start a conversation:

```dart
class UserProfileScreen extends ConsumerWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherUserProfilePic;

  const UserProfileScreen({
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserProfilePic,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = AppSession().currentUser;
    
    return Scaffold(
      appBar: AppBar(title: Text(otherUsername)),
      body: Column(
        children: [
          // ... user profile info ...
          ElevatedButton(
            onPressed: () async {
              if (currentUser == null) return;
              
              final dmService = ref.read(dmThreadServiceProvider);
              
              // This automatically generates the consistent thread ID
              final thread = await dmService.getOrCreateDMThread(
                currentUserId: currentUser.firebaseID,
                currentUsername: currentUser.username,
                currentUserProfpic: currentUser.profilePictureUrl,
                partnerId: otherUserId,
                partnerName: otherUsername,
                partnerProfpic: otherUserProfilePic,
              );
              
              if (context.mounted) {
                // Navigate to the DM screen
                context.push('/dm/${thread.id}', extra: thread);
              }
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}
```

## Example 2: Checking if Conversation Exists

Before showing a "New conversation" indicator:

```dart
Future<bool> hasExistingConversation(
  DMThreadService dmService,
  String userId1,
  String userId2,
) async {
  final threadId = dmService.generateThreadId(userId1, userId2);
  final thread = await dmService.getDMThreadById(threadId);
  return thread != null;
}

// Usage:
final exists = await hasExistingConversation(
  dmService,
  currentUser.firebaseID,
  otherUser.firebaseID,
);

if (exists) {
  print('You already have a conversation with this user');
} else {
  print('Start a new conversation!');
}
```

## Example 3: Sending a Message

Once you're in a conversation:

```dart
class DmMessageComposer extends ConsumerWidget {
  final String threadId;
  final String recipientId;
  final TextEditingController controller;

  const DmMessageComposer({
    required this.threadId,
    required this.recipientId,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = AppSession().currentUser;
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Type a message...',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            if (currentUser == null || controller.text.isEmpty) return;
            
            final dmService = ref.read(dmThreadServiceProvider);
            
            await dmService.sendDmMessage(
              threadId,
              controller.text,
              currentUser.firebaseID,
              recipientId,
            );
            
            controller.clear();
          },
        ),
      ],
    );
  }
}
```

## Example 4: Creating a Search/Contact Selection Flow

When implementing a "New Message" feature:

```dart
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  _NewMessageScreenState createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  List<DomainUser> contacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  
  Future<void> _loadContacts() async {
    // Load users from your backend/Firestore
    // This is just an example
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .limit(50)
        .get();
    
    setState(() {
      contacts = usersSnapshot.docs
          .map((doc) => DomainUser.fromMap(doc.data()))
          .toList();
    });
  }
  
  Future<void> _startConversationWith(DomainUser selectedUser) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null) return;
    
    final dmService = ref.read(dmThreadServiceProvider);
    
    // Get or create the thread
    final thread = await dmService.getOrCreateDMThread(
      currentUserId: currentUser.firebaseID,
      currentUsername: currentUser.username,
      currentUserProfpic: currentUser.profilePictureUrl,
      partnerId: selectedUser.firebaseID,
      partnerName: selectedUser.username,
      partnerProfpic: selectedUser.profilePictureUrl,
    );
    
    if (mounted) {
      // Pop this screen and push the DM screen
      Navigator.pop(context);
      context.push('/dm/${thread.id}', extra: thread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(contact.profilePictureUrl),
            ),
            title: Text(contact.username),
            subtitle: Text(contact.email),
            onTap: () => _startConversationWith(contact),
          );
        },
      ),
    );
  }
}
```

## Example 5: Real-time Message Listening

Stream messages in real-time for a conversation:

```dart
class DmMessagesWidget extends ConsumerWidget {
  final String threadId;

  const DmMessagesWidget({required this.threadId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsyncValue = ref.watch(dmViewModelProvider(threadId));
    
    return messagesAsyncValue.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet. Say hi!'),
          );
        }
        
        return ListView.builder(
          reverse: true, // Most recent at bottom
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageBubble(message: message);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading messages: $error'),
      ),
    );
  }
}
```

## Example 6: Pagination (Load More Messages)

Load older messages when scrolling to the top:

```dart
class DmChatScreen extends ConsumerStatefulWidget {
  final DMThread thread;

  const DmChatScreen({required this.thread, super.key});

  @override
  _DmChatScreenState createState() => _DmChatScreenState();
}

class _DmChatScreenState extends ConsumerState<DmChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if scrolled to top
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // Load more messages
        ref
            .read(dmViewModelProvider(widget.thread.id).notifier)
            .loadMoreMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.partnerName)),
      body: Column(
        children: [
          Expanded(
            child: DmMessagesWidget(
              threadId: widget.thread.id,
              scrollController: _scrollController,
            ),
          ),
          DmMessageComposer(
            threadId: widget.thread.id,
            recipientId: widget.thread.partnerId,
          ),
        ],
      ),
    );
  }
}
```

## Example 7: Thread ID Verification (Testing)

Verify the thread ID generation works correctly:

```dart
void testThreadIdConsistency() {
  final dmService = DMThreadService();
  
  const user1 = 'alice_123';
  const user2 = 'bob_456';
  
  // Test that order doesn't matter
  final id1 = dmService.generateThreadId(user1, user2);
  final id2 = dmService.generateThreadId(user2, user1);
  
  print('ID1: $id1'); // Output: alice_123_bob_456
  print('ID2: $id2'); // Output: alice_123_bob_456
  print('IDs match: ${id1 == id2}'); // Output: true
  
  // Test uniqueness
  const user3 = 'charlie_789';
  final id3 = dmService.generateThreadId(user1, user3);
  
  print('ID3: $id3'); // Output: alice_123_charlie_789
  print('ID1 != ID3: ${id1 != id3}'); // Output: true
}
```

## Example 8: Bulk Thread Creation (Admin/Testing)

Create multiple test conversations:

```dart
Future<void> createTestConversations() async {
  final dmService = DMThreadService();
  
  final users = [
    {'id': 'user1', 'name': 'Alice', 'pic': 'https://example.com/alice.jpg'},
    {'id': 'user2', 'name': 'Bob', 'pic': 'https://example.com/bob.jpg'},
    {'id': 'user3', 'name': 'Charlie', 'pic': 'https://example.com/charlie.jpg'},
  ];
  
  // Create conversations between user1 and all others
  for (int i = 1; i < users.length; i++) {
    await dmService.getOrCreateDMThread(
      currentUserId: users[0]['id']!,
      currentUsername: users[0]['name']!,
      currentUserProfpic: users[0]['pic']!,
      partnerId: users[i]['id']!,
      partnerName: users[i]['name']!,
      partnerProfpic: users[i]['pic']!,
    );
    
    print('Created conversation: ${users[0]['name']} <-> ${users[i]['name']}');
  }
}
```

## Best Practices

1. **Always use `getOrCreateDMThread`** instead of manually creating threads
2. **Store the thread ID** in user documents for quick access
3. **Cache thread metadata** in the user's document to avoid extra lookups
4. **Use the provider** instead of instantiating `DMThreadService` directly
5. **Handle offline scenarios** - the service uses Firestore which has offline support
6. **Check for null users** before creating threads
7. **Update the lastMessage field** when sending messages (already handled in `sendDmMessage`)

## Common Pitfalls

❌ **Don't do this:**

```dart
// Manual thread creation without using the service
final threadId = '${userId1}_${userId2}'; // Wrong! Doesn't handle sorting
```

✅ **Do this instead:**

```dart
// Use the service method
final threadId = dmService.generateThreadId(userId1, userId2);
```

❌ **Don't do this:**

```dart
// Creating thread without checking if it exists
await FirebaseFirestore.instance
    .collection('DMThreads')
    .doc(someId)
    .set({...}); // Might overwrite existing thread!
```

✅ **Do this instead:**

```dart
// Use getOrCreateDMThread which handles existence check
final thread = await dmService.getOrCreateDMThread(...);
```
