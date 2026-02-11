import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
/// This file is used when building for iOS, Android, macOS, etc.
class WebAdWidget extends StatelessWidget {
  final String adSlot;
  final String adFormat;
  final bool isResponsive;
  final int? width;
  final int? height;

  const WebAdWidget({
    super.key,
    required this.adSlot,
    this.adFormat = 'auto',
    this.isResponsive = true,
    this.width,
    this.height,
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

  const WebHorizontalBannerAd({
    super.key,
    required this.adSlot,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebDisplayAd extends StatelessWidget {
  final String adSlot;

  const WebDisplayAd({
    super.key,
    required this.adSlot,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebVerticalBannerAd extends StatelessWidget {
  final String adSlot;

  const WebVerticalBannerAd({
    super.key,
    required this.adSlot,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebRectangleAd extends StatelessWidget {
  final String adSlot;
  final EdgeInsetsGeometry? padding;

  const WebRectangleAd({
    super.key,
    required this.adSlot,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
