import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_config.dart';
import '../ad_providers.dart';

/// A widget that displays a banner ad
/// Automatically handles ad loading and disposal
class BannerAdWidget extends ConsumerStatefulWidget {
  /// The size of the banner ad (default: standard banner)
  final AdSize adSize;
  
  /// Optional padding around the ad
  final EdgeInsetsGeometry? padding;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    
    // Set a timeout - if ad doesn't load in 5 seconds, hide it
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isLoaded && !_failedToLoad) {
        debugPrint('⏰ Banner ad timed out after 5 seconds');
        setState(() {
          _failedToLoad = true;
        });
        _bannerAd?.dispose();
      }
    });
  }

  void _loadAd() {
    // Check if ads are enabled and initialized
    if (!AdConfig.adsEnabled) {
      setState(() => _failedToLoad = true);
      return;
    }
    
    if (!ref.read(adInitializedProvider)) {
      debugPrint('⚠️ Banner ad not loaded - AdMob not initialized');
      setState(() => _failedToLoad = true);
      return;
    }

    final adService = ref.read(adServiceProvider);
    
    _bannerAd = adService.createBannerAd(
      adSize: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _failedToLoad = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _failedToLoad = true;
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('📱 Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('📱 Banner ad closed');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are not enabled or failed to load, return nothing
    if (!AdConfig.adsEnabled || _failedToLoad) {
      return const SizedBox.shrink();
    }

    // Reserve space for the ad even before it loads
    // This prevents content from shifting when the ad appears
    final adHeight = widget.adSize.height.toDouble();

    Widget content;
    
    if (_bannerAd == null || !_isLoaded) {
      // Show placeholder while ad is loading to reserve space
      content = SizedBox(
        width: widget.adSize.width.toDouble(),
        height: adHeight,
        child: Container(
          color: Colors.transparent,
        ),
      );
    } else {
      // Ad is loaded, show it
      content = SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: adHeight,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Apply padding if provided
    if (widget.padding != null) {
      return Padding(
        padding: widget.padding!,
        child: content,
      );
    }

    return content;
  }
}

/// A banner ad widget optimized for list views
/// Shows an adaptive banner that fits the available width
class ListBannerAdWidget extends ConsumerStatefulWidget {
  /// Optional padding around the ad
  final EdgeInsetsGeometry? padding;

  const ListBannerAdWidget({
    super.key,
    this.padding,
  });

  @override
  ConsumerState<ListBannerAdWidget> createState() => _ListBannerAdWidgetState();
}

class _ListBannerAdWidgetState extends ConsumerState<ListBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    
    // Set a timeout - if ad doesn't load in 5 seconds, hide it
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isLoaded && !_failedToLoad) {
        debugPrint('⏰ List banner ad timed out after 5 seconds');
        setState(() {
          _failedToLoad = true;
        });
        _bannerAd?.dispose();
      }
    });
  }

  Future<void> _loadAd() async {
    // Check if ads are enabled and initialized
    if (!AdConfig.adsEnabled || !ref.read(adInitializedProvider)) {
      if (mounted) {
        setState(() {
          _failedToLoad = true;
        });
      }
      return;
    }

    // Get the screen width to create an adaptive banner
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      debugPrint('❌ Unable to get adaptive banner size');
      if (mounted) {
        setState(() {
          _failedToLoad = true;
        });
      }
      return;
    }

    final adService = ref.read(adServiceProvider);
    
    _bannerAd = adService.createBannerAd(
      adSize: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ List banner ad loaded');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _failedToLoad = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ List banner ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _failedToLoad = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are not enabled or failed to load, return nothing
    if (!AdConfig.adsEnabled || _failedToLoad) {
      return const SizedBox.shrink();
    }

    // Reserve space for adaptive banner (approximately 50-90dp height)
    // Use a reasonable default height while loading
    final adHeight = _bannerAd?.size.height.toDouble() ?? 50.0;

    Widget content;
    
    if (_bannerAd == null || !_isLoaded) {
      // Show placeholder while ad is loading to reserve space
      content = SizedBox(
        width: MediaQuery.of(context).size.width,
        height: adHeight,
        child: Container(
          color: Colors.transparent,
        ),
      );
    } else {
      // Ad is loaded, show it
      content = SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: adHeight,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Apply padding if provided
    if (widget.padding != null) {
      return Padding(
        padding: widget.padding!,
        child: content,
      );
    }

    return content;
  }
}
