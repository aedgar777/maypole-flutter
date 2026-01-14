import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/maypolechat/data/user_search_service.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// A widget that displays a message with @ mentions highlighted
class MessageWithMentions extends StatelessWidget {
  final String senderName;
  final String senderId;
  final String senderProfilePictureUrl;
  final String body;
  final DateTime timestamp;
  final bool isOwnMessage;
  final bool isNearby; // Whether sender was near the location
  final VoidCallback? onTagUser;
  final VoidCallback? onDelete;

  const MessageWithMentions({
    super.key,
    required this.senderName,
    required this.senderId,
    this.senderProfilePictureUrl = '',
    required this.body,
    required this.timestamp,
    this.isOwnMessage = false,
    this.onTagUser,
    this.onDelete,
    this.isNearby = false,
  });

  /// Calculate opacity based on message age
  /// - 0-1 hour: 100% opacity (alpha = 1.0)
  /// - 1-3 hours: 75% opacity (alpha = 0.75)
  /// - 3-6 hours: 50% opacity (alpha = 0.5)
  /// - 6+ hours: 25% opacity (alpha = 0.25)
  double _calculateOpacity() {
    final age = DateTime.now().difference(timestamp);
    final hoursOld = age.inMinutes / 60.0;

    if (hoursOld < 1) {
      return 1.0;
    } else if (hoursOld < 3) {
      return 0.75;
    } else if (hoursOld < 6) {
      return 0.5;
    } else {
      return 0.25;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentions = _parseMentions(body);
    final theme = Theme.of(context);
    final opacity = _calculateOpacity();

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: senderName,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  color: violet,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _navigateToProfile(context),
              ),
              if (isNearby)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                    child: Icon(
                      Icons.location_on,
                      size: 14,
                      color: brightTeal,
                    ),
                  ),
                ),
              const TextSpan(text: ' '),
              ...mentions,
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeString = _formatTimestamp(timestamp);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timestamp - always show
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(timeString),
              enabled: false,
            ),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            
            // Options based on message ownership
            if (isOwnMessage) ...[
              // Own message: Delete option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.deleteMessage, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ] else ...[
              // Other user's message: Tag and View Profile options
              if (onTagUser != null)
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(l10n.tagUser(senderName)),
                  onTap: () {
                    Navigator.pop(context);
                    onTagUser?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(l10n.viewProfile),
                onTap: () async {
                  Navigator.pop(context);
                  await _navigateToProfile(context);
                },
              ),
            ],
            
            // Cancel option
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(l10n.cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    // If senderId is present, navigate directly
    if (senderId.isNotEmpty) {
      final path = '/user-profile/$senderId';
      debugPrint('Navigating to: $path with senderId');
      try {
        GoRouter.of(context).push(
          path,
          extra: {
            'username': senderName,
            'profilePictureUrl': senderProfilePictureUrl,
          },
        );
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
      return;
    }

    // Fallback: Look up user by username for old messages
    debugPrint('senderId is empty, looking up user by username: $senderName');
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch user information
      final userSearchService = UserSearchService();
      final user = await userSearchService.getUserByUsername(senderName);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (user != null) {
        // Navigate to user profile
        GoRouter.of(context).push(
          '/user-profile/${user.firebaseID}',
          extra: {
            'username': user.username,
            'profilePictureUrl': user.profilePictureUrl,
          },
        );
      } else {
        // Show error if user not found
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userNotFound)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ErrorDialog.show(context, e);
      }
    }
  }

  /// Parse the message body and create TextSpans with highlighted mentions
  List<TextSpan> _parseMentions(String text) {
    final List<TextSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    int lastMatchEnd = 0;

    for (final match in mentionRegex.allMatches(text)) {
      // Add text before the mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }

      // Add the mention with highlighting
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: brightTeal,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last mention
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return spans;
  }
}
