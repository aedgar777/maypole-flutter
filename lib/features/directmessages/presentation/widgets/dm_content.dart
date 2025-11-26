import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import '../../domain/dm_thread.dart';
import '../dm_providers.dart';

/// The content of a DM screen without the Scaffold wrapper.
/// This allows it to be embedded in either a full-screen route (mobile)
/// or within an adaptive layout (desktop).
class DmContent extends ConsumerStatefulWidget {
  final DMThread thread;
  final bool showAppBar;
  final bool autoFocus;

  const DmContent({
    super.key,
    required this.thread,
    this.showAppBar = true,
    this.autoFocus = false,
  });

  @override
  ConsumerState<DmContent> createState() => _DmContentState();
}

class _DmContentState extends ConsumerState<DmContent> {
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
            .read(dmViewModelProvider(widget.thread.id).notifier)
            .loadMoreMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(dmViewModelProvider(widget.thread.id));
    final currentUser = AppSession().currentUser;

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
                final bool isMe = message.sender == currentUser!.username;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(4),
                    child: Text(message.body),
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
        if (currentUser != null)
          _buildMessageInput(currentUser.username, widget.thread.partnerId),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      return Material(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CachedProfileAvatar(imageUrl: widget.thread.partnerProfpic),
            const SizedBox(width: 8),
            Text(widget.thread.partnerName),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildMessageInput(String senderUsername, String recipientId) {
    void sendMessage() {
      if (_messageController.text.isNotEmpty) {
        final currentUser = AppSession().currentUser;
        if (currentUser != null) {
          ref
              .read(dmViewModelProvider(widget.thread.id).notifier)
              .sendDmMessage(
                _messageController.text,
                currentUser.firebaseID,
                senderUsername,
                recipientId,
              );
          _messageController.clear();
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Enter a message',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              onSubmitted: AppConfig.isWideScreen ? (_) => sendMessage() : null,
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
