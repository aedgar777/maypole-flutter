import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/utils/place_geofence_utils.dart';
import 'package:maypole/core/utils/screen_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/core/widgets/app_toast.dart';
import 'package:maypole/core/widgets/report_content_dialog.dart';
import 'package:maypole/core/services/hive_moderation_provider.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/mention_controller.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/mention_text_field.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/message_with_mentions.dart';
import 'package:maypole/features/maypolechat/presentation/widgets/image_upload_notification.dart';
import 'package:maypole/features/settings/settings_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
import 'package:maypole/core/widgets/animated_message_item.dart';
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
  final String? placeType;
  final bool showAppBar;
  final bool autoFocus;
  final bool readOnly; // If true, shows join prompt instead of input
  final bool showWebAd; // If false, hides web ad banner (used when embedded in home screen)

  const MaypoleChatContent({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.address,
    this.latitude,
    this.longitude,
    this.placeType,
    this.showAppBar = true,
    this.autoFocus = false,
    this.readOnly = false,
    this.showWebAd = true,
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

    if (widget.placeType != null) {
      final radius = PlaceGeofenceUtils.getRadiusForPlaceType(widget.placeType);
    } else {
    }

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
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }
  
  /// Check if user is within proximity (100m) of the place
  /// This uses a fixed threshold for the "Show When at Location" feature
  bool get _isWithinProximity {
    
    // Check if user has enabled "Show When at Location" feature
    final locationState = ref.watch(locationSettingsViewModelProvider);
    final showWhenAtLocationEnabled = locationState.preferences.showWhenAtLocation;
    
    
    // If feature is not enabled, don't check proximity
    if (!showWhenAtLocationEnabled) {
      return false;
    }
    
    if (widget.latitude == null || widget.longitude == null) {
      return false;
    }
    
    if (_currentPosition == null) {
      return false;
    }
    
    final locationService = ref.read(locationServiceProvider);
    final isNearby = locationService.isPositionWithinProximity(
      targetLat: widget.latitude!,
      targetLon: widget.longitude!,
      position: _currentPosition,
    );
    
    return isNearby ?? false;
  }

  /// Check if user is within range of the place based on its type
  /// Uses dynamic geofencing: countries (500km), states (200km), cities (15km), 
  /// neighborhoods (5km), establishments (500m), buildings (200m)
  bool get _isWithinPlaceRange {
    
    if (widget.latitude == null || widget.longitude == null) {
      return false;
    }
    
    if (_currentPosition == null) {
      return false;
    }
    
    final locationService = ref.read(locationServiceProvider);
    final isInRange = locationService.isPositionInRangeOfPlace(
      placeLatitude: widget.latitude!,
      placeLongitude: widget.longitude!,
      position: _currentPosition,
      placeType: widget.placeType,
    );
    
    if (isInRange != null) {
      final radius = PlaceGeofenceUtils.getRadiusForPlaceType(widget.placeType);
      final distance = PlaceGeofenceUtils.getDistanceToPlace(
        position: _currentPosition,
        placeLatitude: widget.latitude!,
        placeLongitude: widget.longitude!,
      );
    }
    
    return isInRange ?? false;
  }
  
  /// Check if image upload button should be enabled
  /// Requires: "Show When at Location" enabled + within 100m proximity
  bool get _canUploadImage => _isWithinProximity;
  
  /// Show explanatory dialog when image upload is disabled
  Future<void> _showImageUploadDisabledDialog() async {
    final locationState = ref.read(locationSettingsViewModelProvider);
    final isLocationEnabled = locationState.preferences.showWhenAtLocation;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: Text(
          isLocationEnabled
              ? 'You need to be within 100 meters of this location to upload images. '
                  'Enable location permissions and get closer to post photos!'
              : 'Enable "Show When at Location" in settings to upload images. '
                  'This helps keep photos authentic to the place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          if (!isLocationEnabled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Open preferences screen
                Navigator.pushNamed(context, '/preferences');
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
  
  /// Check if a message was sent from within the place's geofence range
  /// Uses dynamic range based on place type (e.g., 5km for cities, 500m for restaurants)
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
    
    // Use dynamic geofence range based on place type
    final isInRange = PlaceGeofenceUtils.isUserInRange(
      userLatitude: message.senderLatitude!,
      userLongitude: message.senderLongitude!,
      placeLatitude: widget.latitude!,
      placeLongitude: widget.longitude!,
      placeType: widget.placeType,
    );
    
    return isInRange;
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

    final body = Stack(
      children: [
        Column(
          children: [
            // Web ad banner at the top with gradient background
            // Gradient: light/transparent at bottom, dark at top
            if (kIsWeb && AdConfig.webAdsEnabled && widget.showWebAd)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Center(
                  child: WebHorizontalBannerAd(
                    adSlot: AdConfig.adsterraLeaderboardSlot,
                    adKey: AdConfig.adsterraLeaderboardKey,
                  ),
                ),
              ),
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
                  
                  return AnimatedMessageItem(
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
                            onTagUser: !widget.readOnly && !isOwnMessage 
                                ? () => _tagUser(message.senderName, message.senderId)
                                : null,
                            onDelete: !widget.readOnly && isOwnMessage
                                ? () => _deleteMessage(message)
                                : null,
                            onReport: !widget.readOnly && !isOwnMessage
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
            if (widget.readOnly)
              _buildJoinPrompt(context, l10n)
            else if (currentUser != null)
              _buildMessageInput(currentUser, l10n),
          ],
        ),
      ],
    );

    if (!widget.showAppBar) {
      // When embedded (no app bar), wrap in Material for TextField
      return Material(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: ScreenUtils.shouldShowAppBarBackButton(),
        title: Text(widget.maypoleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareConversation(context),
            tooltip: 'Share conversation',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              context.push(
                '/chat/${widget.threadId}/gallery?name=${Uri.encodeComponent(widget.maypoleName)}',
              );
            },
            tooltip: 'View gallery',
          ),
        ],
      ),
      body: body,
    );
  }

  /// Build a join conversation prompt for anonymous/read-only users
  Widget _buildJoinPrompt(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 38),
      decoration: BoxDecoration(
        color: lightPurple, // Match the message input background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: brightTeal, // Bright teal border for visual pop
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: brightTeal.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Navigate to login screen with return path
            context.go('/login?returnTo=${Uri.encodeComponent('/preview/${widget.threadId}')}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login,
                  color: brightTeal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Join the conversation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sign up or log in to post messages',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              placeType: widget.placeType,
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
                  color: _canUploadImage ? Colors.white70 : Colors.white24,
                  onPressed: _canUploadImage 
                      ? () => _pickAndUploadImage(sender)
                      : _showImageUploadDisabledDialog,
                  tooltip: _canUploadImage 
                      ? 'Add photo' 
                      : 'Location required to add photo',
                ),
          Expanded(
            child: CallbackShortcuts(
              bindings: kIsWeb
                  ? <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.enter): sendMessage,
                    }
                  : {},
              child: MentionTextField(
                controller: _messageController,
                threadId: widget.threadId,
                currentUserId: sender.firebaseID,
                focusNode: _messageFocusNode,
                maxLength: 1000,
                onSubmitted: ScreenUtils.isWideScreenFromContext(context) ? sendMessage : null,
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

  Future<void> _pickAndUploadImage(DomainUser sender) async {
    if (_isUploadingImage) return;

    try {
      // On web/desktop, skip the dialog and go straight to gallery
      // On mobile, show the camera/gallery choice dialog
      final ImageSource source;
      if (ScreenUtils.isWideScreenFromContext(context)) {
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

      setState(() {
        _isUploadingImage = true;
      });

      // Upload image with mimeType for web support
      await ref.read(maypoleImageServiceProvider).uploadImage(
        maypoleId: widget.threadId,
        maypoleName: widget.maypoleName,
        userId: sender.firebaseID,
        username: sender.username,
        filePath: image.path,
        mimeType: image.mimeType,
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        placeType: widget.placeType,
        userMaypoleThreads: sender.maypoleChatThreads,
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

  /// Share the conversation link using the platform's native share dialog
  Future<void> _shareConversation(BuildContext context) async {
    try {
      // Generate the shareable link
      final shareUrl = '${AppConfig.appUrl}/chat/${widget.threadId}';
      
      // Create share text with maypole name and address if available
      final locationInfo = widget.address != null 
          ? ' at ${widget.address}'
          : '';
      
      final shareText = 'Check out the conversation at ${widget.maypoleName}$locationInfo!\n\n$shareUrl';
      
      // Use the native share dialog
      await Share.share(
        shareText,
        subject: 'Join the conversation on Maypole',
      );
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Failed to share conversation',
        );
      }
    }
  }
}