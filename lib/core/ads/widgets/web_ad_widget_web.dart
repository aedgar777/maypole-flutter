import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../ad_config.dart';

/// Widget to display Adsterra ads on web platform
/// This widget only works on web platform and respects the web ads feature flag
/// 
/// Adsterra Integration Guide:
/// 1. Create an Adsterra account at https://adsterra.com
/// 2. Get your ad placement codes from the dashboard
/// 3. Use the ad IDs in the widget (adSlot parameter)
/// 
/// Common Adsterra formats:
/// - 'banner' - Standard banner ads (300x250, 728x90, etc.)
/// - 'social_bar' - Social bar ad format
/// - 'native_banner' - Native banner ads
/// - 'popunder' - Pop-under ads (handled separately)
class WebAdWidget extends StatefulWidget {
  /// Ad placement ID from Adsterra (the numeric ID from dashboard, e.g., '28635540')
  final String adSlot;
  
  /// Ad format (e.g., 'banner', 'social_bar', 'native_banner')
  final String adFormat;
  
  /// Whether the ad is responsive
  final bool isResponsive;
  
  /// Fixed width (only used if not responsive)
  final int? width;
  
  /// Fixed height (only used if not responsive)
  final int? height;

  /// Optional padding around the ad
  final EdgeInsetsGeometry? padding;
  
  /// The ad key from Adsterra script (e.g., '5f9bf870d30ef305b76bd374783acc7d')
  /// If not provided, uses adSlot as fallback
  final String? adKey;

  const WebAdWidget({
    super.key,
    required this.adSlot,
    this.adFormat = 'banner',
    this.isResponsive = true,
    this.width,
    this.height,
    this.padding,
    this.adKey,
  });

  @override
  State<WebAdWidget> createState() => _WebAdWidgetState();
}

class _WebAdWidgetState extends State<WebAdWidget> {
  final String _viewType = 'adsterra-ad-${DateTime.now().millisecondsSinceEpoch}';
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && AdConfig.webAdsEnabled) {
      _registerAdWidget();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _registerAdWidget() {
    if (_isRegistered) return;

    try {
      // Register the view factory for this ad
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          // Create the ad container
          final adContainer = html.DivElement()
            ..id = 'ad-container-$viewId'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block';

          // Use the provided ad key or fall back to ad slot
          final key = widget.adKey ?? widget.adSlot;
          
          // Get dimensions
          final height = widget.height ?? _getDefaultHeight();
          final width = widget.width ?? _getDefaultWidth();

          // Create the Adsterra ad script with atOptions format
          final adScript = html.ScriptElement()
            ..text = '''
              atOptions = {
                'key' : '$key',
                'format' : 'iframe',
                'height' : $height,
                'width' : $width,
                'params' : {}
              };
            ''';

          // Create the invoke script
          final invokeScript = html.ScriptElement()
            ..async = true
            ..src = 'https://www.highperformanceformat.com/$key/invoke.js';
          
          adContainer.children.add(adScript);
          adContainer.children.add(invokeScript);

          return adContainer;
        },
      );
      _isRegistered = true;
    } catch (e) {
    }
  }

  int _getDefaultHeight() {
    switch (widget.adFormat) {
      case 'horizontal':
      case '728x90':
        return 90;
      case 'vertical':
      case '160x600':
        return 600;
      case 'rectangle':
      case '300x250':
        return 250;
      case 'social_bar':
        return 50;
      case 'native_banner':
        return 100;
      default:
        return 250;
    }
  }

  int _getDefaultWidth() {
    switch (widget.adFormat) {
      case 'horizontal':
      case '728x90':
        return 728;
      case 'vertical':
      case '160x600':
        return 160;
      case 'rectangle':
      case '300x250':
        return 300;
      case 'social_bar':
        return 728;
      case 'native_banner':
        return 300;
      default:
        return 300;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on web platform
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // Check if web ads are enabled
    if (!AdConfig.webAdsEnabled) {
      return const SizedBox.shrink();
    }

    // Calculate container height based on ad format
    double containerHeight = 250.0; // Default height
    if (!widget.isResponsive && widget.height != null) {
      containerHeight = widget.height!.toDouble();
    } else {
      // Adjust height based on format
      switch (widget.adFormat) {
        case 'horizontal':
        case '728x90':
          containerHeight = 90.0;
          break;
        case 'vertical':
        case '160x600':
          containerHeight = 600.0;
          break;
        case 'rectangle':
        case '300x250':
          containerHeight = 250.0;
          break;
        case 'social_bar':
          containerHeight = 50.0;
          break;
        case 'native_banner':
          containerHeight = 100.0;
          break;
        default:
          containerHeight = 250.0;
      }
    }

    // Show the ad container - no placeholder, no checking
    // Just render the HtmlElementView and let the ad load naturally
    return Container(
      height: containerHeight,
      width: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: SizedBox(
        width: widget.width?.toDouble() ?? 728,
        height: containerHeight,
        child: HtmlElementView(
                      viewType: _viewType,
        ),
      ),
    );
  }
}

/// Preset web ad widgets for common Adsterra ad formats

/// Display ad (responsive banner)
class WebDisplayAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebDisplayAd({super.key, required this.adSlot, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'banner',
      isResponsive: true,
    );
  }
}

/// Horizontal banner ad (leaderboard style - 728x90)
class WebHorizontalBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebHorizontalBannerAd({super.key, required this.adSlot, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'horizontal',
      isResponsive: true,
    );
  }
}

/// Vertical banner ad (skyscraper style - 160x600)
class WebVerticalBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebVerticalBannerAd({super.key, required this.adSlot, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'vertical',
      isResponsive: true,
    );
  }
}

/// Rectangle ad (300x250)
class WebRectangleAd extends StatelessWidget {
  final String adSlot;
  final EdgeInsetsGeometry? padding;
  final String? adKey;

  const WebRectangleAd({super.key, required this.adSlot, this.padding, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'rectangle',
      isResponsive: false,
      width: 300,
      height: 250,
      padding: padding,
    );
  }
}

/// Social bar ad (Adsterra specific format)
class WebSocialBarAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebSocialBarAd({super.key, required this.adSlot, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'social_bar',
      isResponsive: true,
    );
  }
}

/// Native banner ad (Adsterra specific format)
class WebNativeBannerAd extends StatelessWidget {
  final String adSlot;
  final String? adKey;

  const WebNativeBannerAd({super.key, required this.adSlot, this.adKey});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adKey: adKey,
      adFormat: 'native_banner',
      isResponsive: true,
    );
  }
}
