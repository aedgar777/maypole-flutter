# Ads System Documentation

This directory contains the complete ad implementation for both mobile (AdMob) and web (AdSense) platforms.

## 📁 Directory Structure

```
lib/core/ads/
├── README.md                    # This file
├── FEATURE_FLAGS.md            # Feature flag documentation
├── USAGE_EXAMPLES.md           # Code examples for using ads
├── ad_config.dart              # Ad configuration & feature flags
├── ad_providers.dart           # Riverpod providers for ads
├── ad_service.dart             # AdMob service (mobile)
└── widgets/
    ├── banner_ad_widget.dart        # Mobile banner ads (AdMob)
    ├── interstitial_ad_manager.dart # Mobile interstitial ads (AdMob)
    ├── web_ad_widget.dart           # Web ads (AdSense) ⭐ NEW
    └── platform_adaptive_ad.dart    # Cross-platform ad widget ⭐ NEW
```

## 🚀 Quick Start

### For Mobile Ads (AdMob)

```dart
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';

// Simple banner ad
BannerAdWidget()
```

### For Web Ads (AdSense)

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';

// Simple web banner
if (kIsWeb)
  WebHorizontalBannerAd(adSlot: 'YOUR_AD_SLOT_ID')
```

### For Cross-Platform Ads (Both)

```dart
import 'package:maypole/core/ads/widgets/platform_adaptive_ad.dart';

// Shows AdMob on mobile, AdSense on web
PlatformHorizontalBannerAd(
  webAdSlot: 'YOUR_WEB_AD_SLOT_ID',
)
```

## 📚 Documentation

- **[FEATURE_FLAGS.md](FEATURE_FLAGS.md)** - Complete guide to ad feature flags and scenarios
- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** - Code examples for implementing ads
- **[WEB_ADS_IMPLEMENTATION_GUIDE.md](../../WEB_ADS_IMPLEMENTATION_GUIDE.md)** - Full setup guide for web ads

## 🎯 Feature Flags

Ads are controlled by Firebase Remote Config:

- **`ads_enabled`** - Master flag (all ads)
- **`ads_web_enabled`** - Web ads only (requires master) ⭐ NEW
- **`ads_banner_enabled`** - Mobile banner ads (requires master)
- **`ads_interstitial_enabled`** - Mobile interstitial ads (requires master)

See [FEATURE_FLAGS.md](FEATURE_FLAGS.md) for details.

## 🛠️ Setup Required

### Mobile (Already Configured)
- ✅ AdMob account configured
- ✅ Ad unit IDs in `ad_config.dart`
- ✅ App IDs in AndroidManifest.xml and Info.plist

### Web (New Setup Required)
1. Get Google AdSense account and Publisher ID
2. Create ad units and get ad slot IDs
3. Update `web/index.html` with your Publisher ID
4. Update `web_ad_widget.dart` with your Publisher ID
5. Configure Firebase Remote Config flags

See **[WEB_ADS_IMPLEMENTATION_GUIDE.md](../../WEB_ADS_IMPLEMENTATION_GUIDE.md)** for detailed instructions.

## 🎨 Available Ad Widgets

### Mobile (AdMob)
- `BannerAdWidget` - Standard mobile banner
- `InterstitialAdManager` - Full-screen ads

### Web (AdSense)
- `WebDisplayAd` - Responsive display ad
- `WebHorizontalBannerAd` - Horizontal banner (leaderboard)
- `WebVerticalBannerAd` - Vertical banner (skyscraper)
- `WebRectangleAd` - Fixed 300x250 rectangle
- `WebAdWidget` - Customizable ad widget

### Cross-Platform
- `PlatformAdaptiveAd` - Auto-detects platform
- `PlatformHorizontalBannerAd` - Platform-specific horizontal banner
- `PlatformDisplayAd` - Platform-specific display ad

## ⚙️ Configuration

### Check if ads are enabled:

```dart
import 'package:maypole/core/ads/ad_config.dart';

if (AdConfig.adsEnabled) {
  // Master flag is ON
}

if (AdConfig.webAdsEnabled) {
  // Web ads are ON (master flag also ON)
}

if (AdConfig.bannerAdsEnabled) {
  // Mobile banner ads are ON (master flag also ON)
}
```

### Ad Unit IDs

Mobile ad units are configured in `ad_config.dart`:
- Test ad units used in debug mode
- Production ad units used in release mode

Web ad units are passed as parameters to widgets.

## 🧪 Testing

### Mobile Ads
```bash
# Run app in debug mode (uses test ads)
flutter run

# Run in release mode (uses production ads)
flutter run --release
```

### Web Ads
```bash
# Build and serve web app
flutter build web
# Deploy to a real URL (ads won't work on localhost)
```

**Important:** AdSense ads require:
- Approved AdSense account
- Real domain (not localhost)
- Correct Publisher ID and ad slot IDs

## 🔍 Debugging

### Check ad status:

```dart
import 'package:flutter/foundation.dart';
import 'package:maypole/core/ads/ad_config.dart';

debugPrint('Master flag: ${AdConfig.adsEnabled}');
debugPrint('Web ads: ${AdConfig.webAdsEnabled}');
debugPrint('Mobile banner: ${AdConfig.bannerAdsEnabled}');
debugPrint('Mobile interstitial: ${AdConfig.interstitialAdsEnabled}');
```

### Common issues:

1. **Ads not showing on web:**
   - Check AdSense account is approved
   - Verify Publisher ID in `web/index.html`
   - Check ad slot IDs are correct
   - Ensure deployed to real URL (not localhost)
   - Check browser console for errors

2. **Ads not showing on mobile:**
   - Check feature flags in Remote Config
   - Verify ad unit IDs in `ad_config.dart`
   - Check AdMob initialization in `main.dart`

3. **All ads disabled:**
   - Check `ads_enabled` flag in Remote Config
   - This is the master kill switch

## 📱 Platforms Supported

| Platform | Ad Network | Status |
|----------|-----------|--------|
| iOS | Google AdMob | ✅ Configured |
| Android | Google AdMob | ✅ Configured |
| Web | Google AdSense | ✅ Ready (needs IDs) |
| macOS | N/A | ❌ Not configured |
| Windows | N/A | ❌ Not configured |
| Linux | N/A | ❌ Not configured |

## 🤝 Contributing

When adding new ad functionality:

1. Add configuration to `ad_config.dart`
2. Create widget in `widgets/` directory
3. Add feature flag to Remote Config
4. Update documentation
5. Add usage examples to `USAGE_EXAMPLES.md`

## 📄 License

Part of the Maypole app.

## 🆘 Support

For issues:
1. Check [FEATURE_FLAGS.md](FEATURE_FLAGS.md) for flag configuration
2. Check [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) for implementation examples
3. Check [WEB_ADS_IMPLEMENTATION_GUIDE.md](../../WEB_ADS_IMPLEMENTATION_GUIDE.md) for web setup
4. Review Firebase Remote Config settings
5. Check ad network dashboards (AdMob/AdSense)

---

**Last Updated:** January 2026  
**Version:** 1.1.2  
**New Features:** Web ads support with feature flags 🎉
