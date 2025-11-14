import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import '../../../identity/auth_providers.dart';

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

        // User is authenticated, show home list
        return _buildChatList(context, ref, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildChatList(BuildContext context, WidgetRef ref, DomainUser user) {
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
            dividerColor: Colors.white.withAlpha(26),
            tabs: const [
              Tab(text: 'Places'),
              Tab(text: 'Direct Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlaceChatList(context, user),
            _buildDmList(context, user),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await context.push<PlacePrediction>('/search');

            if (result != null) {
              // Navigate to the chat screen, passing the placeId as the threadId
              // and the place name as the maypoleName.
              context.go('/chat/${result.placeId}', extra: {'maypoleName': result.place});
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPlaceChatList(BuildContext context, DomainUser user) {
    if (user.placeChatThreads.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No place chats yet.'),
      ));
    }
    return ListView.builder(
      itemCount: user.placeChatThreads.length,
      itemBuilder: (context, index) {
        final thread = user.placeChatThreads[index];
        return ListTile(
          title: Text(thread.name),
          subtitle: Text('Last message: ${thread.lastMessageTime}'),
          onTap: () {
            context.go('/chat/${thread.id}', extra: {'maypoleName': thread.name});
          },
        );
      },
    );
  }

  Widget _buildDmList(BuildContext context, DomainUser user) {
    if (user.dmThreads.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No direct messages yet.'),
      )); // TODO: Make this look nice
    }
    return ListView.builder(
      itemCount: user.dmThreads.length,
      itemBuilder: (context, index) {
        final thread = user.dmThreads[index];
        return ListTile(
          title: Text(thread.partnerName),
          subtitle: Text('Last message: ${thread.lastMessageTime}'),
          onTap: () {
            // TODO: Navigate to DM screen
          },
        );
      },
    );
  }
}
