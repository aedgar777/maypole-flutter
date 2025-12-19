import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool isDeleted;

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
    this.isDeleted = false,
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
    // Grouped messages: 1px apart, Non-grouped messages: 4px apart
    final double topMargin = isGroupedWithPrevious ? 1.0 : 4.0;
    final double bottomMargin = isGroupedWithNext ? 1.0 : 4.0;

    return GestureDetector(
      onLongPress: !isDeleted ? () {
        HapticFeedback.mediumImpact();
        onDelete?.call();
      } : null,
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isDeleted 
                ? Colors.transparent
                : (isOwnMessage ? Colors.blue[200] : Colors.grey[300]),
            border: isDeleted 
                ? Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: EdgeInsets.fromLTRB(8, topMargin, 8, bottomMargin),
          child: Text(
            isDeleted ? 'message deleted' : message.body,
            style: TextStyle(
              color: isDeleted ? Colors.grey.withValues(alpha: 0.6) : Colors.black,
              fontSize: 15,
              fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }


}
