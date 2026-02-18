import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
/// This file is used when building for iOS, Android, macOS, etc.
class WebAdWidget extends StatelessWidget {
  final String adSlot;
  final String adFormat;
  final bool isResponsive;
  final int? width;
  final int? height;
  final String? adKey;

  const WebAdWidget({
    super.key,
    required this.adSlot,
    this.adFormat = 'banner',
    this.isResponsive = true,
    this.width,
    this.height,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty container on non-web platforms
    return const SizedBox.shrink();
  }
}

/// Convenience widgets for common ad formats
class WebHorizontalBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebHorizontalBannerAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebDisplayAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebDisplayAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebVerticalBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebVerticalBannerAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebRectangleAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebRectangleAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Adsterra-specific ad formats
class WebSocialBarAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebSocialBarAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebNativeBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebNativeBannerAd({
    super.key,
    required this.adSlot,
    this.adKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
