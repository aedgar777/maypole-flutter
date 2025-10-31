import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/features/chat/presentation/widgets/dm_thread_list.dart';
import 'package:maypole/features/chat/presentation/widgets/place_chat_thread_list.dart';
import '../../identity/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            dividerColor: Colors.white.withOpacity(0.1),
            tabs: const [
              Tab(text: 'Places'),
              Tab(text: 'Direct Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PlaceChatThreadList(threads: const []),
            DMThreadList(threads: const []),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go('/search');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
