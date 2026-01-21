import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import '../ad_config.dart';

/// Widget to display Google AdSense ads on web platform
/// This widget only works on web platform and respects the web ads feature flag
class WebAdWidget extends StatefulWidget {
  /// Ad slot ID from Google AdSense
  final String adSlot;
  
  /// Ad format (e.g., 'auto', 'rectangle', 'horizontal', 'vertical')
  final String adFormat;
  
  /// Whether the ad is responsive
  final bool isResponsive;
  
  /// Fixed width (only used if not responsive)
  final int? width;
  
  /// Fixed height (only used if not responsive)
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
  State<WebAdWidget> createState() => _WebAdWidgetState();
}

class _WebAdWidgetState extends State<WebAdWidget> {
  final String _viewType = 'google-adsense-${DateTime.now().millisecondsSinceEpoch}';
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && AdConfig.webAdsEnabled) {
      _registerAdWidget();
    }
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

          // Create the ins element for Google AdSense
          final adElement = html.Element.tag('ins')
            ..className = 'adsbygoogle'
            ..style.display = 'block'
            ..setAttribute('data-ad-client', _getAdClient())
            ..setAttribute('data-ad-slot', widget.adSlot);

          // Set ad format attributes
          if (widget.isResponsive) {
            adElement.setAttribute('data-ad-format', widget.adFormat);
            adElement.setAttribute('data-full-width-responsive', 'true');
          } else {
            if (widget.width != null) {
              adElement.style.width = '${widget.width}px';
            }
            if (widget.height != null) {
              adElement.style.height = '${widget.height}px';
            }
          }

          adContainer.children.add(adElement);

          // Push the ad (load it)
          _pushAd();

          return adContainer;
        },
      );
      _isRegistered = true;
    } catch (e) {
      debugPrint('❌ Error registering web ad widget: $e');
    }
  }

  /// Get the AdSense client ID from environment or use test client
  String _getAdClient() {
    // AdSense Publisher ID for Maypole app
    return 'ca-pub-9803674282352310';
  }

  void _pushAd() {
    // Push ad after a short delay to ensure DOM is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // Get the adsbygoogle array from window
        final adsbygoogle = js.context['adsbygoogle'];
        if (adsbygoogle != null) {
          // Push an empty object to trigger ad loading
          adsbygoogle.callMethod('push', [js.JsObject.jsify({})]);
        } else {
          debugPrint('⚠️ adsbygoogle not available yet');
        }
      } catch (e) {
        debugPrint('❌ Error pushing ad: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on web platform
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // Check if web ads are enabled
    if (!AdConfig.webAdsEnabled) {
      debugPrint('📵 Web ads are disabled');
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
          containerHeight = 90.0;
          break;
        case 'vertical':
          containerHeight = 600.0;
          break;
        case 'rectangle':
          containerHeight = 250.0;
          break;
        default:
          containerHeight = 250.0;
      }
    }

    return Container(
      height: containerHeight,
      width: double.infinity,
      color: Colors.grey[200],
      child: HtmlElementView(
        viewType: _viewType,
      ),
    );
  }
}

/// Preset web ad widgets for common ad formats

/// Display ad (responsive)
class WebDisplayAd extends StatelessWidget {
  final String adSlot;

  const WebDisplayAd({super.key, required this.adSlot});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adFormat: 'auto',
      isResponsive: true,
    );
  }
}

/// Horizontal banner ad (leaderboard style)
class WebHorizontalBannerAd extends StatelessWidget {
  final String adSlot;

  const WebHorizontalBannerAd({super.key, required this.adSlot});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adFormat: 'horizontal',
      isResponsive: true,
    );
  }
}

/// Vertical banner ad (skyscraper style)
class WebVerticalBannerAd extends StatelessWidget {
  final String adSlot;

  const WebVerticalBannerAd({super.key, required this.adSlot});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adFormat: 'vertical',
      isResponsive: true,
    );
  }
}

/// Rectangle ad (300x250)
class WebRectangleAd extends StatelessWidget {
  final String adSlot;

  const WebRectangleAd({super.key, required this.adSlot});

  @override
  Widget build(BuildContext context) {
    return WebAdWidget(
      adSlot: adSlot,
      adFormat: 'rectangle',
      isResponsive: false,
      width: 300,
      height: 250,
    );
  }
}
