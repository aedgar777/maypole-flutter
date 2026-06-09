import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/utils/screen_utils.dart';
import 'package:maypole/core/widgets/lazy_profile_avatar.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/widgets/report_content_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:maypole/core/services/hive_moderation_provider.dart';
import 'package:maypole/core/widgets/animated_message_item.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../../domain/direct_message.dart';
import '../../domain/dm_thread.dart';
import '../../domain/pending_message.dart';
import '../../domain/staged_image_info.dart';
import '../dm_providers.dart';
import 'dm_message_bubble.dart';
import 'pending_message_bubble.dart';
import 'staged_images_widget.dart';

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
  final ImagePicker _picker = ImagePicker();
  final List<StagedImageInfo> _stagedImages = [];
  bool _isFirstLoad = true; // Track if this is the first load
  
  // Track pending messages with their upload states
  final List<PendingMessage> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Check if this is an ephemeral thread (hasMessages == false)
    // If so, set it in the view model so it gets persisted on first message
    if (!widget.thread.hasMessages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dmViewModelProvider(widget.thread.id).notifier).setEphemeralThread(widget.thread);
      });
    }

    // Mark thread as read when opening (skip for ephemeral threads)
    if (widget.thread.hasMessages) {
      _markAsRead();
    }

    // Auto-focus if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageFocusNode.requestFocus();
      });
    }
  }

  Future<void> _markAsRead() async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null) return;

    try {
      await ref.read(dmThreadServiceProvider).markThreadAsRead(
        widget.thread.id,
        currentUser.firebaseID,
      );
    } catch (e) {
      // Silently fail - not critical
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

    final body = Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: messagesAsyncValue.when(
                data: (messages) {
              // On first load, mark all existing messages as already seen
              // This prevents the stutter from animating all cached messages
              if (_isFirstLoad && messages.isNotEmpty) {
                _isFirstLoad = false;
                for (final message in messages) {
                  final messageKey = message.id ?? '${message.sender}_${message.timestamp.millisecondsSinceEpoch}';
                  _animatedMessageIds.add(messageKey);
                }
              }
              
              // Filter out pending messages that match Firestore messages
              // Keep pending messages that are still uploading
              final visiblePendingMessages = _pendingMessages.where((pending) {
                // Hide if there's a matching Firestore message
                final hasMatch = messages.any((msg) {
                  final senderMatch = msg.sender == pending.message.sender;
                  final bodyMatch = msg.body == pending.message.body;
                  final timeDiff = msg.timestamp.difference(pending.message.timestamp).abs().inSeconds;
                  
                  // For messages with images, also check if uploaded URLs match
                  bool imagesMatch = true;
                  if (pending.pendingImages.isNotEmpty && msg.imageUrls.isNotEmpty) {
                    final uploadedUrls = pending.pendingImages
                        .where((img) => img.uploadedUrl != null)
                        .map((img) => img.uploadedUrl!)
                        .toSet();
                    final msgUrls = msg.imageUrls.toSet();
                    
                    // Match if any uploaded URL is in the Firestore message
                    imagesMatch = uploadedUrls.isNotEmpty && uploadedUrls.intersection(msgUrls).isNotEmpty;
                  }
                  
                  return senderMatch && bodyMatch && timeDiff < 10 && imagesMatch;
                });
                
                if (hasMatch) {
                  // Schedule removal on next frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _pendingMessages.removeWhere((m) => m.tempId == pending.tempId);
                      });
                    }
                  });
                  return false;
                }
                return true;
              }).toList();
              
              // Combine visible pending messages with fetched messages
              final totalItemCount = messages.length + visiblePendingMessages.length;
              
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  // Pending messages appear first (at index 0, 1, etc.)
                  if (index < visiblePendingMessages.length) {
                    final pendingMsg = visiblePendingMessages[visiblePendingMessages.length - 1 - index];
                    return _buildPendingMessage(pendingMsg, currentUser!, partner);
                  }
                  
                  // Regular messages follow
                  final messageIndex = index - visiblePendingMessages.length;
                  final message = messages[messageIndex];
                  final bool isMe = message.sender == currentUser!.username;
                  final bool isDeleted = message.isDeletedFor(currentUser.firebaseID);
                  
                  // Determine if this message is grouped with adjacent messages
                  // Note: ListView is reversed, so visual "above" is messageIndex - 1, "below" is messageIndex + 1
                  // Use messageIndex instead of index for the messages array
                  final bool isGroupedWithNext = _isGroupedWith(
                    messages, messageIndex, messageIndex - 1, isMe,
                  );
                  final bool isGroupedWithPrevious = _isGroupedWith(
                    messages, messageIndex, messageIndex + 1, isMe,
                  );
                  
                  // Use message ID or a combination of sender + timestamp as unique key
                  final messageKey = message.id ?? '${message.sender}_${message.timestamp.millisecondsSinceEpoch}';
                  final isNew = !_animatedMessageIds.contains(messageKey);
                  
                  // Mark this message as seen
                  if (isNew) {
                    _animatedMessageIds.add(messageKey);
                  }
                  
                  return AnimatedMessageItem(
                    key: ValueKey(messageKey),
                    isNew: isNew,
                    child: DmMessageBubble(
                    message: message,
                    isOwnMessage: isMe,
                    partnerId: partner?.id ?? '',
                    partnerUsername: partner?.username ?? '',
                    partnerProfilePicUrl: partner?.profilePicUrl ?? '',
                    onDelete: !isDeleted ? (triggerContext) => _showMessageContextMenu(context, message, triggerContext) : null,
                    isGroupedWithNext: isGroupedWithNext,
                    isGroupedWithPrevious: isGroupedWithPrevious,
                    isDeleted: isDeleted,
                  ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ErrorDialog.show(context, error);
              });
              return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            if (currentUser != null && partner != null) ...[
              // Staged images area (above message input)
              StagedImagesWidget(
                images: _stagedImages,
                onRemoveImage: _removeStagedImage,
              ),
              _buildMessageInput(currentUser.username, partner.id),
            ],
          ],
        ),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      // Use the scaffold background color to prevent grey screen
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: ScreenUtils.shouldShowAppBarBackButton(),
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
                    LazyProfileAvatar(
                      userId: partner.id,
                      initialProfilePictureUrl: partner.profilePicUrl,
                    ),
                    const SizedBox(width: 8),
                    Text(partner.username),
                  ],
                ),
              )
            : Text(AppLocalizations.of(context)!.directMessage),
      ),
      body: body,
    );
  }

  Widget _buildMessageInput(String senderUsername, String recipientId) {
    Future<void> sendMessage() async {
      if (_messageController.text.isEmpty && _stagedImages.isEmpty) {
        return;
      }

      final currentUser = AppSession().currentUser;
      if (currentUser == null) return;

      final messageText = _messageController.text;
      final imagesToUpload = List<StagedImageInfo>.from(_stagedImages);
      final imagePaths = imagesToUpload.map((img) => img.path).toList();
      final mimeTypes = imagesToUpload.map((img) => img.mimeType).toList();
      
      // Clear input immediately for better UX
      _messageController.clear();
      setState(() {
        _stagedImages.clear();
      });

      // Create pending message with local image paths
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final pendingImages = imagesToUpload.map((img) => PendingImage(
        localPath: img.path,
        mimeType: img.mimeType,
      )).toList();
      
      final pendingMessage = PendingMessage(
        tempId: tempId,
        message: DirectMessage(
          sender: senderUsername,
          timestamp: DateTime.now(),
          body: messageText,
          recipient: recipientId,
          imageUrls: [], // Will be populated as images upload
        ),
        pendingImages: pendingImages,
        status: MessageStatus.sending,
      );

      // Add to pending messages list for immediate display
      setState(() {
        _pendingMessages.add(pendingMessage);
      });

      // Scroll to bottom to show new message
      _scrollToBottom();

      try {
        // Upload images one by one, updating status as we go
        List<String> uploadedUrls = [];
        for (int i = 0; i < imagePaths.length; i++) {
          try {
            final urls = await ref.read(dmImageServiceProvider).uploadMultipleImages(
              threadId: widget.thread.id,
              userId: currentUser.firebaseID,
              filePaths: [imagePaths[i]],
              mimeTypes: [mimeTypes[i]],
            );
            
            if (urls.isNotEmpty) {
              uploadedUrls.add(urls.first);
              
              // Update pending image status
              if (mounted) {
                setState(() {
                  final index = _pendingMessages.indexWhere((m) => m.tempId == tempId);
                  if (index != -1) {
                    final updated = _pendingMessages[index].pendingImages[i].copyWith(
                      uploadedUrl: urls.first,
                      status: ImageUploadStatus.uploaded,
                    );
                    final updatedImages = List<PendingImage>.from(_pendingMessages[index].pendingImages);
                    updatedImages[i] = updated;
                    _pendingMessages[index] = _pendingMessages[index].copyWith(
                      pendingImages: updatedImages,
                    );
                  }
                });
              }
            }
          } catch (e) {
            // Mark this image as failed
            if (mounted) {
              setState(() {
                final index = _pendingMessages.indexWhere((m) => m.tempId == tempId);
                if (index != -1) {
                  final updated = _pendingMessages[index].pendingImages[i].copyWith(
                    status: ImageUploadStatus.failed,
                    errorMessage: e.toString(),
                  );
                  final updatedImages = List<PendingImage>.from(_pendingMessages[index].pendingImages);
                  updatedImages[i] = updated;
                  _pendingMessages[index] = _pendingMessages[index].copyWith(
                    pendingImages: updatedImages,
                  );
                }
              });
            }
          }
        }

        // Send message to Firestore with uploaded URLs
        await ref.read(dmViewModelProvider(widget.thread.id).notifier).sendDmMessage(
          messageText,
          currentUser.firebaseID,
          senderUsername,
          recipientId,
          imageUrls: uploadedUrls,
        );

        // Mark message as sent - it will be automatically removed when Firestore version appears
        if (mounted) {
          setState(() {
            final index = _pendingMessages.indexWhere((m) => m.tempId == tempId);
            if (index != -1) {
              _pendingMessages[index] = _pendingMessages[index].copyWith(
                status: MessageStatus.sent,
              );
            }
          });
        }
      } catch (e) {
        // Mark message as failed
        if (mounted) {
          setState(() {
            final index = _pendingMessages.indexWhere((m) => m.tempId == tempId);
            if (index != -1) {
              _pendingMessages[index] = _pendingMessages[index].copyWith(
                status: MessageStatus.failed,
                errorMessage: e.toString(),
              );
            }
          });
          AppToast.showError(context, 'Failed to send message: $e');
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 38.0),
      child: Row(
        children: [
          // Image picker button
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.white70,
            onPressed: _stagedImages.length >= 5
                ? null
                : () => _pickImages(),
            tooltip: _stagedImages.length >= 5
                ? 'Maximum 5 images per message'
                : 'Add photo',
          ),
          Expanded(
            child: CallbackShortcuts(
              bindings: kIsWeb
                  ? <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.enter): sendMessage,
                    }
                  : {},
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLength: 1000,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
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
                maxLines: kIsWeb ? null : 1,
                textInputAction: kIsWeb ? TextInputAction.newline : TextInputAction.send,
                onSubmitted: kIsWeb ? null : (_) => sendMessage(),
                onTapOutside: (_) => _messageFocusNode.unfocus(),
              ),
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

  Future<void> _pickImages() async {
    if (_stagedImages.length >= 5) {
      AppToast.showError(context, 'Maximum 5 images per message');
      return;
    }

    try {
      // On web/desktop, skip the dialog and go straight to gallery
      // On mobile, show the camera/gallery choice dialog
      final ImageSource source;
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        // Show dialog to choose between camera and gallery
        final selectedSource = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
        if (selectedSource == null) return;
        source = selectedSource;
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Add to staged images
      if (mounted && _stagedImages.length < 5) {
        setState(() {
          _stagedImages.add(StagedImageInfo(
            path: image.path,
            mimeType: image.mimeType,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e);
      }
    }
  }

  void _removeStagedImage(int index) {
    setState(() {
      _stagedImages.removeAt(index);
    });
  }

  Widget _buildPendingMessage(PendingMessage pendingMsg, currentUser, DMParticipant? partner) {
    // Check if all images are uploaded
    final allUploaded = pendingMsg.pendingImages.every((img) => img.status == ImageUploadStatus.uploaded);
    
    // If all uploaded, show regular message bubble with uploaded URLs
    if (allUploaded && pendingMsg.status == MessageStatus.sent) {
      final uploadedUrls = pendingMsg.pendingImages
          .map((img) => img.uploadedUrl)
          .whereType<String>()
          .toList();
      
      return AnimatedMessageItem(
        key: ValueKey(pendingMsg.tempId),
        isNew: true,
        child: DmMessageBubble(
          message: DirectMessage(
            id: pendingMsg.tempId,
            sender: pendingMsg.message.sender,
            timestamp: pendingMsg.message.timestamp,
            body: pendingMsg.message.body,
            recipient: pendingMsg.message.recipient,
            imageUrls: uploadedUrls,
          ),
          isOwnMessage: true,
          partnerId: partner?.id ?? '',
          partnerUsername: partner?.username ?? '',
          partnerProfilePicUrl: partner?.profilePicUrl ?? '',
          onDelete: null, // No delete for pending
          isGroupedWithNext: false,
          isGroupedWithPrevious: false,
          isDeleted: false,
        ),
      );
    }
    
    // Otherwise show pending bubble with overlays
    return AnimatedMessageItem(
      key: ValueKey(pendingMsg.tempId),
      isNew: true,
      child: PendingMessageBubble(
        pendingMessage: pendingMsg,
        isOwnMessage: true,
        onRetry: (imageIndex) => _retryImageUpload(pendingMsg.tempId, imageIndex),
      ),
    );
  }

  Future<void> _retryImageUpload(String tempId, int imageIndex) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null) return;

    final pendingIndex = _pendingMessages.indexWhere((m) => m.tempId == tempId);
    if (pendingIndex == -1) return;

    final pendingMsg = _pendingMessages[pendingIndex];
    if (imageIndex >= pendingMsg.pendingImages.length) return;

    final imagePath = pendingMsg.pendingImages[imageIndex].localPath;

    // Mark as uploading again
    setState(() {
      final updatedImage = pendingMsg.pendingImages[imageIndex].copyWith(
        status: ImageUploadStatus.uploading,
        errorMessage: null,
      );
      final updatedImages = List<PendingImage>.from(pendingMsg.pendingImages);
      updatedImages[imageIndex] = updatedImage;
      _pendingMessages[pendingIndex] = pendingMsg.copyWith(pendingImages: updatedImages);
    });

    try {
      final urls = await ref.read(dmImageServiceProvider).uploadMultipleImages(
        threadId: widget.thread.id,
        userId: currentUser.firebaseID,
        filePaths: [imagePath],
      );

      if (urls.isNotEmpty && mounted) {
        setState(() {
          final updatedImage = pendingMsg.pendingImages[imageIndex].copyWith(
            uploadedUrl: urls.first,
            status: ImageUploadStatus.uploaded,
          );
          final updatedImages = List<PendingImage>.from(pendingMsg.pendingImages);
          updatedImages[imageIndex] = updatedImage;
          _pendingMessages[pendingIndex] = pendingMsg.copyWith(pendingImages: updatedImages);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final updatedImage = pendingMsg.pendingImages[imageIndex].copyWith(
            status: ImageUploadStatus.failed,
            errorMessage: e.toString(),
          );
          final updatedImages = List<PendingImage>.from(pendingMsg.pendingImages);
          updatedImages[imageIndex] = updatedImage;
          _pendingMessages[pendingIndex] = pendingMsg.copyWith(pendingImages: updatedImages);
        });
      }
    }
  }

  void _showMessageContextMenu(BuildContext context, DirectMessage message, [BuildContext? triggerContext]) {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    final formattedDateTime = DateTimeUtils.formatFullDateTime(message.timestamp);
    final bool isMyMessage = message.sender == currentUser.username;

    // Check if we're on a wide screen (desktop/web)
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600 || kIsWeb;

    if (isWideScreen && triggerContext != null) {
      // Desktop: Show menu at the position of the 3-dot button
      final RenderBox? renderBox = triggerContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final isOwnMessage = message.sender == currentUser.username;

        showMenu<dynamic>(
          context: context,
          position: RelativeRect.fromLTRB(
            isOwnMessage ? position.dx - 200 : position.dx + size.width,
            position.dy,
            isOwnMessage ? position.dx : position.dx + size.width + 200,
            position.dy + size.height,
          ),
          items: [
            // Timestamp
            PopupMenuItem(
              enabled: false,
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(formattedDateTime),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Only show delete option if it's the user's own message
            if (isMyMessage) ...[
              PopupMenuItem(
                onTap: () => _deleteMessage(message),
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Message', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            // Show report option for messages from other users
            if (!isMyMessage) ...[
              PopupMenuItem(
                onTap: () => _reportMessage(message),
                child: const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Report Message', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ],
        );
        return;
      }
    }

    // Mobile: Use bottom sheet (existing behavior)
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
              // Show report option for messages from other users
              if (!isMyMessage)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Report Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportMessage(message);
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
        final l10n = AppLocalizations.of(context)!;
        AppToast.showError(context, l10n.errorDeletingMessage(e.toString()));
      }
    }
  }

  Future<void> _reportMessage(DirectMessage message) async {
    final currentUser = AppSession().currentUser;
    if (currentUser == null || message.id == null) return;

    // Show confirmation dialog
    final confirmed = await ReportContentDialog.show(
      context,
      contentType: 'message',
    );

    if (!confirmed || !mounted) return;

    try {
      final hiveModerationService = ref.read(hiveModerationServiceProvider);
      
      // Determine if message has images or text or both
      final hasImages = message.imageUrls.isNotEmpty;
      final hasText = message.body.isNotEmpty;
      
      bool success = false;
      
      if (hasImages && hasText) {
        // Report message with both text and images
        success = await hiveModerationService.reportMessageWithImages(
          contentId: message.id!,
          reporterId: currentUser.firebaseID,
          textContent: message.body,
          imageUrls: message.imageUrls,
          additionalContext: {
            'sender': message.sender,
            'thread_id': widget.thread.id,
            'timestamp': message.timestamp.toIso8601String(),
          },
        );
      } else if (hasImages) {
        // Report images only
        success = await hiveModerationService.reportMessageWithImages(
          contentId: message.id!,
          reporterId: currentUser.firebaseID,
          textContent: '',
          imageUrls: message.imageUrls,
          additionalContext: {
            'sender': message.sender,
            'thread_id': widget.thread.id,
            'timestamp': message.timestamp.toIso8601String(),
          },
        );
      } else if (hasText) {
        // Report text only
        success = await hiveModerationService.reportTextContent(
          contentId: message.id!,
          reporterId: currentUser.firebaseID,
          textContent: message.body,
          additionalContext: {
            'sender': message.sender,
            'thread_id': widget.thread.id,
            'timestamp': message.timestamp.toIso8601String(),
          },
        );
      }

      if (mounted) {
        if (success) {
          AppToast.showSuccess(
            context,
            'Message reported successfully. Thank you for keeping our community safe.',
          );
        } else {
          AppToast.showError(
            context,
            'Failed to report message. Please try again later.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Error reporting message: ${e.toString()}',
        );
      }
    }
  }
}

/// Widget for displaying a pending/uploading message
