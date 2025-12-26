import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/mention_controller.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/mention_text_field.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/message_with_mentions.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
import '../maypole_chat_providers.dart';

/// The content of a maypole chat screen without the Scaffold wrapper.
/// This allows it to be embedded in either a full-screen route (mobile)
/// or within an adaptive layout (desktop).
class MaypoleChatContent extends ConsumerStatefulWidget {
  final String threadId;
  final String maypoleName;
  final String? address;
  final bool showAppBar;
  final bool autoFocus;

  const MaypoleChatContent({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.address,
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
            .read(maypoleChatViewModelProvider(widget.threadId).notifier)
            .loadMoreMessages();
      }
    }
  }

  void _tagUser(String username, String userId) {
    // Insert @username at the current cursor position or at the end
    final currentText = _messageController.text;
    final currentSelection = _messageController.selection;
    
    String tagText = '@$username ';
    int insertPosition;
    
    if (currentSelection.isValid) {
      insertPosition = currentSelection.baseOffset;
    } else {
      insertPosition = currentText.length;
    }
    
    // Insert tag at the cursor position
    final newText = currentText.substring(0, insertPosition) +
        tagText +
        currentText.substring(insertPosition);
    
    _messageController.text = newText;
    
    // Move cursor after the tag
    final newCursorPosition = insertPosition + tagText.length;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPosition),
    );
    
    // Add the mention to the controller
    ref.read(mentionControllerProvider.notifier).addMention(
      UserMention(
        userId: userId,
        username: username,
        startIndex: insertPosition,
        endIndex: insertPosition + '@$username'.length,
      ),
    );
    
    // Focus the text field
    _messageFocusNode.requestFocus();
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
                final isOwnMessage = currentUser != null && 
                    message.senderId == currentUser.firebaseID;
                
                // Use message ID or a combination of sender + timestamp as unique key
                final messageKey = message.id ?? '${message.senderId}_${message.timestamp.millisecondsSinceEpoch}';
                final isNew = !_animatedMessageIds.contains(messageKey);
                
                // Mark this message as seen
                if (isNew) {
                  _animatedMessageIds.add(messageKey);
                }
                
                return _AnimatedMessageItem(
                  key: ValueKey(messageKey),
                  isNew: isNew,
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showMessageContextMenu(context, message);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: MessageWithMentions(
                        senderName: message.senderName,
                        senderId: message.senderId,
                        senderProfilePictureUrl: message.senderProfilePictureUrl,
                        body: message.body,
                        timestamp: message.timestamp,
                        isOwnMessage: isOwnMessage,
                        onTagUser: !isOwnMessage 
                            ? () => _tagUser(message.senderName, message.senderId)
                            : null,
                        onDelete: isOwnMessage
                            ? () => _deleteMessage(message)
                            : null,
                      ),
                    ),
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
      bottomNavigationBar: AdConfig.adsEnabled
          ? const BannerAdWidget(
              padding: EdgeInsets.all(4),
            )
          : null,
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
              address: widget.address ?? '',
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

  void _showMessageContextMenu(BuildContext context, MaypoleMessage message) {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    final formattedDateTime = DateTimeUtils.formatFullDateTime(message.timestamp);
    final bool isMyMessage = message.senderId == currentUser.firebaseID;

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
                title: Text(AppLocalizations.of(context)!.cancel),
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

  Future<void> _deleteMessage(MaypoleMessage message) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    try {
      await ref.read(maypoleChatThreadServiceProvider).deleteMaypoleMessage(
        widget.threadId,
        message.id!,
        currentUser.firebaseID,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingMessage(e.toString())),
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
