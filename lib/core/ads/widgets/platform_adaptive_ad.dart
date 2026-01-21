import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';

/// Platform-adaptive ad widget that shows the appropriate ad type
/// - Web: Shows Google AdSense ads
/// - Mobile (iOS/Android): Shows Google AdMob ads
class PlatformAdaptiveAd extends StatelessWidget {
  /// Ad slot ID for web platform (required if on web)
  final String? webAdSlot;
  
  /// Ad format for web ads
  final String webAdFormat;
  
  /// Whether web ads should be responsive
  final bool webResponsive;

  const PlatformAdaptiveAd({
    super.key,
    this.webAdSlot,
    this.webAdFormat = 'horizontal',
    this.webResponsive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Show Google AdSense ad on web
      if (webAdSlot == null) {
        debugPrint('⚠️ Web ad slot not provided for PlatformAdaptiveAd');
        return const SizedBox.shrink();
      }
      
      return WebAdWidget(
        adSlot: webAdSlot!,
        adFormat: webAdFormat,
        isResponsive: webResponsive,
      );
    } else {
      // Show AdMob banner on mobile (iOS/Android)
      return const BannerAdWidget();
    }
  }
}

/// Horizontal banner ad that adapts to platform
class PlatformHorizontalBannerAd extends StatelessWidget {
  final String? webAdSlot;

  const PlatformHorizontalBannerAd({
    super.key,
    this.webAdSlot,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformAdaptiveAd(
      webAdSlot: webAdSlot,
      webAdFormat: 'horizontal',
      webResponsive: true,
    );
  }
}

/// Display ad that adapts to platform
class PlatformDisplayAd extends StatelessWidget {
  final String? webAdSlot;

  const PlatformDisplayAd({
    super.key,
    this.webAdSlot,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformAdaptiveAd(
      webAdSlot: webAdSlot,
      webAdFormat: 'auto',
      webResponsive: true,
    );
  }
}
