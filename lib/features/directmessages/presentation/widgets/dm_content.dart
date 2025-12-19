import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import '../../domain/direct_message.dart';
import '../../domain/dm_thread.dart';
import '../dm_providers.dart';
import 'dm_message_bubble.dart';

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

  /// Determines if a message should be grouped with an adjacent message
  /// Messages are grouped if they're from the same sender and sent within 2 minutes
  bool _isGroupedWith(
    List<DirectMessage> messages,
    int currentIndex,
    int adjacentIndex,
    bool isCurrentUserMessage,
  ) {
    if (adjacentIndex < 0 || adjacentIndex >= messages.length) {
      return false;
    }

    final currentMessage = messages[currentIndex];
    final adjacentMessage = messages[adjacentIndex];
    final currentUser = AppSession().currentUser;

    if (currentUser == null) return false;

    // Check if both messages are from the same sender
    final isSameSender = currentMessage.sender == adjacentMessage.sender;
    if (!isSameSender) return false;

    // Check if messages are within 2 minutes of each other
    final timeDiff = currentMessage.timestamp.difference(adjacentMessage.timestamp).abs();
    return timeDiff.inMinutes <= 2;
  }

  Future<void> _deleteMessage(DirectMessage message) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(dmViewModelProvider(widget.thread.id).notifier)
            .deleteDmMessage(message);
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(dmViewModelProvider(widget.thread.id));
    final currentUser = AppSession().currentUser;
    
    // Get the partner (the other participant)
    final partner = currentUser != null 
        ? widget.thread.getPartner(currentUser.firebaseID)
        : null;

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
                
                // Determine if this message is grouped with adjacent messages
                // Note: ListView is reversed, so visual "above" is index - 1, "below" is index + 1
                final bool isGroupedWithNext = _isGroupedWith(
                  messages, index, index - 1, isMe,
                );
                final bool isGroupedWithPrevious = _isGroupedWith(
                  messages, index, index + 1, isMe,
                );
                
                return DmMessageBubble(
                  message: message,
                  isOwnMessage: isMe,
                  partnerId: partner?.id ?? '',
                  partnerUsername: partner?.username ?? '',
                  partnerProfilePicUrl: partner?.profilePicUrl ?? '',
                  onDelete: isMe ? () => _deleteMessage(message) : null,
                  isGroupedWithNext: isGroupedWithNext,
                  isGroupedWithPrevious: isGroupedWithPrevious,
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
        if (currentUser != null && partner != null)
          _buildMessageInput(currentUser.username, partner.id),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      return Material(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: partner != null
            ? GestureDetector(
                onTap: () {
                  context.push(
                    '/user-profile/${partner.id}',
                    extra: <String, dynamic>{
                      'username': partner.username,
                      'profilePictureUrl': partner.profilePicUrl,
                    },
                  );
                },
                child: Row(
                  children: [
                    CachedProfileAvatar(imageUrl: partner.profilePicUrl),
                    const SizedBox(width: 8),
                    Text(partner.username),
                  ],
                ),
              )
            : const Text('Direct Message'),
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
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 38.0),
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
                filled: true,
                fillColor: lightPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
