import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget that displays a user's profile picture with caching.
/// 
/// If the [imageUrl] is empty or null, it shows a default person icon.
/// The image is cached to improve performance and reduce network usage.
class CachedProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData fallbackIcon;

  const CachedProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        Theme
            .of(context)
            .colorScheme
            .surfaceContainerHighest;
    final icColor = iconColor ??
        Theme
            .of(context)
            .colorScheme
            .onSurfaceVariant;

    // If no image URL, show default avatar
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Icon(
          fallbackIcon,
          size: radius * 0.8,
          color: icColor,
        ),
      );
    }

    // Use Image widget with CachedNetworkImageProvider for better control
    // This approach loads from cache immediately without showing placeholder
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Image(
          image: CachedNetworkImageProvider(
            imageUrl!,
            cacheKey: imageUrl,
            maxWidth: (radius * 2 * MediaQuery
                .of(context)
                .devicePixelRatio).round(),
            maxHeight: (radius * 2 * MediaQuery
                .of(context)
                .devicePixelRatio).round(),
          ),
          fit: BoxFit.cover,
          // Use frameBuilder to handle loading states smoothly
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            // If image loaded synchronously (from cache), show it immediately
            if (wasSynchronouslyLoaded == true) {
              return child;
            }
            // If still loading, show child with fade or loading indicator
            if (frame == null) {
              return Center(
                child: Icon(
                  fallbackIcon,
                  size: radius * 0.8,
                  color: icColor.withOpacity(0.3),
                ),
              );
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                fallbackIcon,
                size: radius * 0.8,
                color: icColor,
              ),
            );
          },
        ),
      ),
    );
  }
}
