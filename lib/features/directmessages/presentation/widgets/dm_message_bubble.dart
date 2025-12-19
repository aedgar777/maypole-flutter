import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';

/// A widget that displays a DM message bubble with context menu support
class DmMessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isOwnMessage;
  final String partnerId;
  final String partnerUsername;
  final String partnerProfilePicUrl;
  final VoidCallback? onDelete;
  final bool isGroupedWithNext;
  final bool isGroupedWithPrevious;

  const DmMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.partnerId,
    required this.partnerUsername,
    required this.partnerProfilePicUrl,
    this.onDelete,
    this.isGroupedWithNext = false,
    this.isGroupedWithPrevious = false,
  });

  @override
  Widget build(BuildContext context) {
    // Define corner radius values
    const double standardRadius = 18.0;
    const double sharpRadius = 4.0;

    // Determine which corners should be sharp based on grouping
    BorderRadius borderRadius;
    if (isOwnMessage) {
      // Own messages aligned to right
      borderRadius = BorderRadius.only(
        topLeft: const Radius.circular(standardRadius),
        topRight: Radius.circular(isGroupedWithPrevious ? sharpRadius : standardRadius),
        bottomLeft: const Radius.circular(standardRadius),
        bottomRight: Radius.circular(isGroupedWithNext ? sharpRadius : standardRadius),
      );
    } else {
      // Other's messages aligned to left
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(isGroupedWithPrevious ? sharpRadius : standardRadius),
        topRight: const Radius.circular(standardRadius),
        bottomLeft: Radius.circular(isGroupedWithNext ? sharpRadius : standardRadius),
        bottomRight: const Radius.circular(standardRadius),
      );
    }

    // Dynamic vertical margin based on grouping
    // Grouped messages: 1px apart, Non-grouped messages: 8px apart
    final double topMargin = isGroupedWithPrevious ? 1.0 : 8.0;
    final double bottomMargin = isGroupedWithNext ? 1.0 : 8.0;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isOwnMessage ? Colors.blue[200] : Colors.grey[300],
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: EdgeInsets.fromLTRB(8, topMargin, 8, bottomMargin),
          child: Text(
            message.body,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final timeString = _formatTimestamp(message.timestamp);
    
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
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ] else ...[
              // Other user's message: View Profile option
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToProfile(context);
                },
              ),
            ],
            
            // Cancel option
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
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

  void _navigateToProfile(BuildContext context) {
    try {
      GoRouter.of(context).push(
        '/user-profile/$partnerId',
        extra: {
          'username': partnerUsername,
          'profilePictureUrl': partnerProfilePicUrl,
        },
      );
    } catch (e) {
      ErrorDialog.show(context, e);
    }
  }
}
