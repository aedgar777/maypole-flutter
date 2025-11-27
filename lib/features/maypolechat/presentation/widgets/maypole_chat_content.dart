import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/mention_controller.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/mention_text_field.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/message_with_mentions.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../maypole_chat_providers.dart';

/// The content of a maypole chat screen without the Scaffold wrapper.
/// This allows it to be embedded in either a full-screen route (mobile)
/// or within an adaptive layout (desktop).
class MaypoleChatContent extends ConsumerStatefulWidget {
  final String threadId;
  final String maypoleName;
  final bool showAppBar;
  final bool autoFocus;

  const MaypoleChatContent({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.showAppBar = true,
    this.autoFocus = false,
  });

  @override
  ConsumerState<MaypoleChatContent> createState() => _MaypoleChatContentState();
}

class _MaypoleChatContentState extends ConsumerState<MaypoleChatContent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-focus if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
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
                  child: MessageWithMentions(
                    sender: message.sender,
                    body: message.body,
                    timestamp: message.timestamp,
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ErrorDialog.show(context, error);
              });
              return const Center(child: CircularProgressIndicator());
            },
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
        // Get the mentioned user IDs from the mention controller
        final mentionedUserIds = ref
            .read(mentionControllerProvider.notifier)
            .getMentionedUserIds();

        ref
            .read(maypoleChatViewModelProvider(widget.threadId).notifier)
            .sendMessage(
              widget.maypoleName,
              _messageController.text,
              sender,
              taggedUserIds: mentionedUserIds,
            );

        _messageController.clear();

        // Clear mentions after sending
        ref.read(mentionControllerProvider.notifier).clearMentions();
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 38.0),
      child: Row(
        children: [
          Expanded(
            child: MentionTextField(
              controller: _messageController,
              threadId: widget.threadId,
              focusNode: _messageFocusNode,
              onSubmitted: AppConfig.isWideScreen ? sendMessage : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.white70,
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}
