import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../identity/presentation/providers/auth_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authStateProvider).when(
      data: (user) {
        if (user == null) {
          // User is not authenticated, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Center(child: CircularProgressIndicator());
        }

        // User is authenticated, show chat list
        return _buildChatList(context, ref, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildChatList(BuildContext context, WidgetRef ref, user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(loginViewModelProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create new chat screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New chat feature coming soon!'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
