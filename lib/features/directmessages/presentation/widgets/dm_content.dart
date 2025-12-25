import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
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
  final Set<String> _animatedMessageIds = {};

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
                final bool isDeleted = message.isDeletedFor(currentUser.firebaseID);
                
                // Determine if this message is grouped with adjacent messages
                // Note: ListView is reversed, so visual "above" is index - 1, "below" is index + 1
                final bool isGroupedWithNext = _isGroupedWith(
                  messages, index, index - 1, isMe,
                );
                final bool isGroupedWithPrevious = _isGroupedWith(
                  messages, index, index + 1, isMe,
                );
                
                // Use message ID or a combination of sender + timestamp as unique key
                final messageKey = message.id ?? '${message.sender}_${message.timestamp.millisecondsSinceEpoch}';
                final isNew = !_animatedMessageIds.contains(messageKey);
                
                // Mark this message as seen
                if (isNew) {
                  _animatedMessageIds.add(messageKey);
                }
                
                return _AnimatedMessageItem(
                  key: ValueKey(messageKey),
                  isNew: isNew,
                  child: DmMessageBubble(
                    message: message,
                    isOwnMessage: isMe,
                    partnerId: partner?.id ?? '',
                    partnerUsername: partner?.username ?? '',
                    partnerProfilePicUrl: partner?.profilePicUrl ?? '',
                    onDelete: isMe && !isDeleted ? () => _showMessageContextMenu(context, message) : null,
                    isGroupedWithNext: isGroupedWithNext,
                    isGroupedWithPrevious: isGroupedWithPrevious,
                    isDeleted: isDeleted,
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
      bottomNavigationBar: AdConfig.adsEnabled
          ? const BannerAdWidget(
              padding: EdgeInsets.all(4),
            )
          : null,
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

  void _showMessageContextMenu(BuildContext context, DirectMessage message) {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    final formattedDateTime = DateTimeUtils.formatFullDateTime(message.timestamp);
    final bool isMyMessage = message.sender == currentUser.username;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the timestamp at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  formattedDateTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Only show delete option if it's the user's own message
              if (isMyMessage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(DirectMessage message) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    try {
      await ref.read(dmThreadServiceProvider).deleteDmMessage(
        widget.thread.id,
        message.id!,
        currentUser.firebaseID,
        currentUser.username,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// A stateful widget that animates a message item sliding in from the bottom
/// with a fade-in effect when it's new
class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final bool isNew;

  const _AnimatedMessageItem({
    super.key,
    required this.child,
    required this.isNew,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: widget.isNew ? 30.0 : 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: widget.isNew ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
