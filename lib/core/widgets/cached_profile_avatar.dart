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

    // Show cached network image
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
          ),
      placeholder: (context, url) =>
          CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: SizedBox(
              width: radius * 0.8,
              height: radius * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: icColor,
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: Icon(
              fallbackIcon,
              size: radius * 0.8,
              color: icColor,
            ),
          ),
    );
  }
}
