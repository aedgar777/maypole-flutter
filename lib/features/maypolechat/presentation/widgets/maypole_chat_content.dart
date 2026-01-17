import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/services/location_service.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/widgets/report_content_dialog.dart';
import 'package:maypole/core/services/hive_moderation_provider.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';
import 'package:maypole/features/maypolechat/presentation/screens/maypole_gallery_screen.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/mention_controller.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/mention_text_field.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/message_with_mentions.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/image_upload_notification.dart';
import 'package:maypole/features/settings/settings_providers.dart';
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
  final double? latitude;
  final double? longitude;
  final bool showAppBar;
  final bool autoFocus;

  const MaypoleChatContent({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.address,
    this.latitude,
    this.longitude,
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
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  Position? _currentPosition;
  bool _isFirstLoad = true; // Track if this is the first load

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateCurrentPosition();

    debugPrint('🏠 MaypoleChatContent initialized:');
    debugPrint('   Place: ${widget.maypoleName}');
    debugPrint('   Coordinates: lat=${widget.latitude}, lon=${widget.longitude}');

    // Auto-focus if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageFocusNode.requestFocus();
      });
    }
  }
  
  Future<void> _updateCurrentPosition() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    debugPrint('📍 Current position: lat=${position?.latitude}, lon=${position?.longitude}');
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }
  
  bool get _isWithinProximity {
    debugPrint('🔍 Checking proximity:');
    debugPrint('   Place coords: lat=${widget.latitude}, lon=${widget.longitude}');
    debugPrint('   Current position: lat=${_currentPosition?.latitude}, lon=${_currentPosition?.longitude}');
    
    // Check if user has enabled "Show When at Location" feature
    final locationState = ref.watch(locationSettingsViewModelProvider);
    final showWhenAtLocationEnabled = locationState.preferences.showWhenAtLocation;
    
    debugPrint('   Show when at location enabled: $showWhenAtLocationEnabled');
    
    // If feature is not enabled, allow uploads anywhere
    if (!showWhenAtLocationEnabled) {
      debugPrint('   ✅ Show when at location disabled - allowing image upload');
      return true;
    }
    
    if (widget.latitude == null || widget.longitude == null) {
      debugPrint('   ⚠️ No place coordinates - allowing image upload by default');
      // If no coordinates for the place, allow image upload
      return true;
    }
    
    if (_currentPosition == null) {
      debugPrint('   ❌ No current position - denying image upload');
      // If can't get position, deny image upload
      return false;
    }
    
    final locationService = ref.read(locationServiceProvider);
    final isNearby = locationService.isPositionWithinProximity(
      targetLat: widget.latitude!,
      targetLon: widget.longitude!,
      position: _currentPosition,
    );
    
    debugPrint('   Result: ${isNearby == true ? "✅ Within proximity" : "❌ Not within proximity"}');
    return isNearby ?? false;
  }
  
  bool _isMessageFromNearby(MaypoleMessage message) {
    // Check if user has enabled "Show When at Location" feature
    final locationState = ref.watch(locationSettingsViewModelProvider);
    final showWhenAtLocation = locationState.preferences.showWhenAtLocation;
    
    // If feature is disabled, don't show badges
    if (!showWhenAtLocation) {
      return false;
    }
    
    // If no coordinates for the place or message, can't determine
    if (widget.latitude == null || widget.longitude == null) {
      return false;
    }
    
    if (message.senderLatitude == null || message.senderLongitude == null) {
      return false;
    }
    
    final locationService = ref.read(locationServiceProvider);
    final distance = locationService.calculateDistance(
      message.senderLatitude!,
      message.senderLongitude!,
      widget.latitude!,
      widget.longitude!,
    );
    
    return distance <= LocationService.proximityThreshold;
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
            data: (messages) {
              // On first load, mark all existing messages as already seen
              // This prevents the stutter from animating all cached messages
              if (_isFirstLoad && messages.isNotEmpty) {
                _isFirstLoad = false;
                for (final message in messages) {
                  final messageKey = message.id ?? '${message.senderId}_${message.timestamp.millisecondsSinceEpoch}';
                  _animatedMessageIds.add(messageKey);
                }
              }
              
              return ListView.builder(
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
                    child: message.isImageUpload
                      ? ImageUploadNotification(
                          senderName: message.senderName,
                          maypoleId: widget.threadId,
                          maypoleName: widget.maypoleName,
                          imageId: message.imageId ?? '',
                          timestamp: message.timestamp,
                        )
                      : Padding(
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
                            isNearby: _isMessageFromNearby(message),
                            isOwnMessage: isOwnMessage,
                            onTagUser: !isOwnMessage 
                                ? () => _tagUser(message.senderName, message.senderId)
                                : null,
                            onDelete: isOwnMessage
                                ? () => _deleteMessage(message)
                                : null,
                            onReport: !isOwnMessage
                                ? () => _reportMessage(message)
                                : null,
                          ),
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
        if (currentUser != null) _buildMessageInput(currentUser, l10n),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      return Material(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.maypoleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaypoleGalleryScreen(
                    threadId: widget.threadId,
                    maypoleName: widget.maypoleName,
                  ),
                ),
              );
            },
            tooltip: 'View gallery',
          ),
        ],
      ),
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
              latitude: widget.latitude,
              longitude: widget.longitude,
              senderLatitude: _currentPosition?.latitude,
              senderLongitude: _currentPosition?.longitude,
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
          _isUploadingImage
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.image),
                  color: _isWithinProximity ? Colors.white70 : Colors.white24,
                  onPressed: _isWithinProximity 
                      ? () => _pickAndUploadImage(sender)
                      : () {
                          AppToast.showError(
                            context,
                            'You have "Show When at Location" enabled. You must be within 100m to post pictures. Disable in Preferences to post from anywhere.',
                          );
                        },
                  tooltip: _isWithinProximity 
                      ? 'Add photo' 
                      : 'Must be at location to add photo',
                ),
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

  Future<void> _pickAndUploadImage(DomainUser sender) async {
    if (_isUploadingImage) return;

    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
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

      if (source == null) return;

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload image
      await ref.read(maypoleImageServiceProvider).uploadImage(
        maypoleId: widget.threadId,
        maypoleName: widget.maypoleName,
        userId: sender.firebaseID,
        username: sender.username,
        filePath: image.path,
      );

      if (mounted) {
        AppToast.showSuccess(context, 'Image uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Rate limit')) {
          AppToast.showError(context, e.toString());
        } else {
          ErrorDialog.show(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
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
        AppToast.showError(context, l10n.errorDeletingMessage(e.toString()));
      }
    }
  }

  Future<void> _reportMessage(MaypoleMessage message) async {
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
      
      // Report text content
      final success = await hiveModerationService.reportTextContent(
        contentId: message.id!,
        reporterId: currentUser.firebaseID,
        textContent: message.body,
        additionalContext: {
          'sender_name': message.senderName,
          'sender_id': message.senderId,
          'maypole_id': widget.threadId,
          'maypole_name': widget.maypoleName,
          'timestamp': message.timestamp.toIso8601String(),
        },
      );

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
