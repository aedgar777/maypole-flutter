import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../../../identity/auth_providers.dart';
import '../../../directmessages/presentation/dm_providers.dart';

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
      error: (err, stack) {
        final l10n = AppLocalizations.of(context)!;
        return Center(child: Text(l10n.error(err.toString())));
      },
    );
  }

  Widget _buildChatList(BuildContext context, WidgetRef ref, DomainUser user) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: l10n.settings,
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
          bottom: TabBar(
            dividerColor: Colors.white.withAlpha(26),
            tabs: [
              Tab(text: l10n.maypolesTab),
              Tab(text: l10n.directMessagesTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMaypoleChatList(context, user),
            _buildDmList(context, ref, user),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await context.push<PlacePrediction>('/search');

            if (result != null && context.mounted) {
              // Navigate to the chat screen, passing the placeId as the threadId
              // and the place name (business name only) as the maypoleName.
              context.push('/chat/${result.placeId}', extra: result.placeName);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMaypoleChatList(BuildContext context, DomainUser user) {
    final l10n = AppLocalizations.of(context)!;

    if (user.maypoleChatThreads.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(l10n.noPlaceChats),
          ));
    }
    return ListView.builder(
      itemCount: user.maypoleChatThreads.length,
      itemBuilder: (context, index) {
        final thread = user.maypoleChatThreads[index];
        final formattedDateTime = DateTimeUtils.formatRelativeDateTime(
          thread.lastMessageTime,
          context: context,
        );
        return ListTile(
          title: Text(thread.name),
          subtitle: Text(l10n.lastMessage(formattedDateTime)),
          onTap: () {
            context.push('/chat/${thread.id}', extra: thread.name);
          },
        );
      },
    );
  }

  Widget _buildDmList(BuildContext context, WidgetRef ref, DomainUser user) {
    final l10n = AppLocalizations.of(context)!;

    if (user.dmThreads.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(l10n.noDirectMessages),
          ));
    }
    return ListView.builder(
      itemCount: user.dmThreads.length,
      itemBuilder: (context, index) {
        final threadMetadata = user.dmThreads[index];
        final formattedDateTime = DateTimeUtils.formatRelativeDateTime(
          threadMetadata.lastMessageTime,
          context: context,
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(threadMetadata.partnerProfpic),
          ),
          title: Text(threadMetadata.partnerName),
          subtitle: Text(l10n.lastMessage(formattedDateTime)),
          onTap: () async {
            // Navigate to DM screen with the thread metadata converted to DMThread
            final dmThread = await ref
                .read(dmThreadServiceProvider)
                .getDMThreadById(threadMetadata.id);
            if (dmThread != null && context.mounted) {
              context.push('/dm/${threadMetadata.id}', extra: dmThread);
            }
          },
        );
      },
    );
  }
}
