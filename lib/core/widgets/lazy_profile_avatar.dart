import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/services/profile_picture_cache_service.dart';
import 'package:maypole/core/widgets/cached_profile_avatar.dart';

/// A profile avatar that lazy-loads the profile picture URL if not provided
/// 
/// If [initialProfilePictureUrl] is provided and not empty, uses it directly.
/// Otherwise, fetches the current profile picture for [userId] from Firestore.
/// This ensures all avatars show the most recent profile picture.
class LazyProfileAvatar extends ConsumerWidget {
  final String userId;
  final String? initialProfilePictureUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData fallbackIcon;

  const LazyProfileAvatar({
    super.key,
    required this.userId,
    this.initialProfilePictureUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we have a profile picture URL already, use it
    if (initialProfilePictureUrl != null && initialProfilePictureUrl!.isNotEmpty) {
      return CachedProfileAvatar(
        imageUrl: initialProfilePictureUrl,
        radius: radius,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        fallbackIcon: fallbackIcon,
      );
    }

    // Otherwise, fetch it from Firestore
    if (userId.isEmpty) {
      return CachedProfileAvatar(
        imageUrl: null,
        radius: radius,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        fallbackIcon: fallbackIcon,
      );
    }

    // Watch the profile picture provider
    final profilePictureAsync = ref.watch(profilePictureUrlProvider(userId));

    return profilePictureAsync.when(
      data: (profilePictureUrl) {
        return CachedProfileAvatar(
          imageUrl: profilePictureUrl.isNotEmpty ? profilePictureUrl : null,
          radius: radius,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          fallbackIcon: fallbackIcon,
        );
      },
      loading: () {
        // Show loading state - use a subtle placeholder
        return CachedProfileAvatar(
          imageUrl: null,
          radius: radius,
          backgroundColor: backgroundColor,
          iconColor: iconColor?.withOpacity(0.5),
          fallbackIcon: fallbackIcon,
        );
      },
      error: (error, stack) {
        // On error, show fallback
        return CachedProfileAvatar(
          imageUrl: null,
          radius: radius,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          fallbackIcon: fallbackIcon,
        );
      },
    );
  }
}
