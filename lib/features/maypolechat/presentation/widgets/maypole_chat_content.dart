import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../maypole_chat_providers.dart';

/// The content of a maypole chat screen without the Scaffold wrapper.
/// This allows it to be embedded in either a full-screen route (mobile)
/// or within an adaptive layout (desktop).
class MaypoleChatContent extends ConsumerStatefulWidget {
  final String threadId;
  final String maypoleName;
  final bool showAppBar;

  const MaypoleChatContent({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.showAppBar = true,
  });

  @override
  ConsumerState<MaypoleChatContent> createState() => _MaypoleChatContentState();
}

class _MaypoleChatContentState extends ConsumerState<MaypoleChatContent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ref
            .read(maypoleChatViewModelProvider(widget.threadId).notifier)
            .loadMoreMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(
      maypoleChatViewModelProvider(widget.threadId),
    );
    final currentUser = AppSession().currentUser;
    final l10n = AppLocalizations.of(context)!;

    final body = Column(
      children: [
        Expanded(
          child: messagesAsyncValue.when(
            data: (messages) => ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: '${message.sender}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: message.body),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text(l10n.error(error.toString()))),
          ),
        ),
        if (currentUser != null) _buildMessageInput(currentUser, l10n),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      return Material(child: body);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.maypoleName)),
      body: body,
    );
  }

  Widget _buildMessageInput(DomainUser sender, AppLocalizations l10n) {
    void sendMessage() {
      if (_messageController.text.isNotEmpty) {
        ref
            .read(maypoleChatViewModelProvider(widget.threadId).notifier)
            .sendMessage(widget.maypoleName, _messageController.text, sender);
        _messageController.clear();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: l10n.enterMessage,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              onSubmitted: AppConfig.isWideScreen ? (_) => sendMessage() : null,
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: sendMessage),
        ],
      ),
    );
  }
}
