import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/features/maypolechat/presentation/screens/maypole_gallery_screen.dart';
import 'package:maypole/features/maypolechat/presentation/maypole_chat_providers.dart';

/// Widget that displays an image upload notification in the chat
/// Shows: "<username> has added an image" with "an image" clickable
class ImageUploadNotification extends ConsumerWidget {
  final String senderName;
  final String maypoleId;
  final String maypoleName;
  final String imageId;
  final DateTime timestamp;

  const ImageUploadNotification({
    super.key,
    required this.senderName,
    required this.maypoleId,
    required this.maypoleName,
    required this.imageId,
    required this.timestamp,
  });

  /// Calculate opacity based on message age (same as regular messages)
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

  void _navigateToImage(BuildContext context, WidgetRef ref) {
    // Simply navigate to gallery with the initial image ID
    // The gallery screen will handle loading and opening the image
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaypoleGalleryScreen(
          threadId: maypoleId,
          maypoleName: maypoleName,
          initialImageId: imageId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = _calculateOpacity();

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            // Camera icon
            Icon(
              Icons.camera_alt,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            // Message text
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  children: [
                    TextSpan(
                      text: senderName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' has added '),
                    TextSpan(
                      text: 'an image',
                      style: const TextStyle(
                        color: brightTeal,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _navigateToImage(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
