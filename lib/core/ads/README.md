# Ad System

This directory contains the complete ad implementation for both mobile (AdMob) and web (Adsterra) platforms.

## Architecture

```
lib/core/ads/
├── ad_config.dart               # Configuration and ad unit IDs
├── ad_providers.dart            # Riverpod providers for ad state
├── ad_service.dart              # AdMob initialization and loading
├── README.md                    # This file
└── widgets/
    ├── banner_ad_widget.dart    # Mobile banner ads (AdMob)
    ├── interstitial_ad_manager.dart  # Full-screen mobile ads
    ├── platform_adaptive_ad.dart     # Automatically shows correct ad type
    ├── web_ad_widget.dart       # Entry point with conditional exports
    ├── web_ad_widget_stub.dart  # Stub for non-web platforms
    └── web_ad_widget_web.dart   # Web ads (Adsterra) - Web only
```

## Platform Support

| Platform | Ad Network | Status |
|----------|------------|--------|
| Android | Google AdMob | ✅ Ready |
| iOS | Google AdMob | ✅ Ready |
| Web | Adsterra | ✅ Ready (needs IDs) |

## Usage

### Quick Start - Platform Adaptive Ads

The easiest way to show ads is using `PlatformAdaptiveAd`:

```dart
import 'package:maypole/core/ads/widgets/platform_adaptive_ad.dart';

// Shows AdMob on mobile, Adsterra on web
PlatformAdaptiveAd(
  webAdSlot: 'YOUR_ADSTERRA_SLOT_ID',
  webAdFormat: 'horizontal',
)
```

### For Mobile Ads (AdMob)

```dart
import 'package:maypole/core/ads/widgets/banner_ad_widget.dart';

// Simple banner
BannerAdWidget()
```

### For Web Ads (Adsterra)

```dart
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';

// Simple web banner
if (kIsWeb)
  WebHorizontalBannerAd(adSlot: 'YOUR_ADSTERRA_SLOT_ID')
```

## Configuration

### AdMob (Mobile)

Ad unit IDs are managed in `ad_config.dart`:
- Test ads are used in debug mode automatically
- Production ads are used in release builds

### Web (Adsterra)

1. Create an Adsterra account at [https://adsterra.com](https://adsterra.com)
2. Add your website/app URL in the Adsterra dashboard
3. Create ad placements and get your slot IDs
4. Update `ad_config.dart` with your Adsterra slot IDs:

```dart
// In ad_config.dart
static const String adsterraBannerSlot = '123456789';
static const String adsterraLeaderboardSlot = '987654321';
```

5. Update your widget code with your slot IDs:

```dart
WebRectangleAd(adSlot: AdConfig.adsterraBannerSlot)
```

## Adsterra Ad Formats

Adsterra offers several ad formats:

### Banner Ads
- **300x250** (Medium Rectangle) - Use `WebRectangleAd`
- **728x90** (Leaderboard) - Use `WebHorizontalBannerAd`
- **160x600** (Wide Skyscraper) - Use `WebVerticalBannerAd`
- **Responsive** - Use `WebDisplayAd`

### Special Formats
- **Social Bar** - Use `WebSocialBarAd`
- **Native Banner** - Use `WebNativeBannerAd`

## Remote Config Feature Flags

Ads can be controlled remotely via Firebase:

| Flag | Description |
|------|-------------|
| `ads_enabled` | Master switch for all ads |
| `banner_ads_enabled` | Banner ads specifically |
| `interstitial_ads_enabled` | Full-screen mobile ads |
| `web_ads_enabled` | Web platform ads (Adsterra) |
| `interstitial_frequency` | How often to show interstitials |

## Testing

### Mobile (AdMob)

Test ads are automatically used in debug mode. No configuration needed.

### Web (Adsterra)

1. Ensure `web_ads_enabled` is true in Remote Config
2. Use valid Adsterra slot IDs from your dashboard
3. Test with your site URL registered in Adsterra

## Troubleshooting

### Ads not showing on web

1. **Check the browser console** for JavaScript errors
2. **Verify slot IDs** are correctly entered in AdConfig
3. **Check Adsterra account** - ensure your site is approved
4. **Check Remote Config** - ensure `web_ads_enabled` is true
5. **Test on deployed URL** - Adsterra may require your actual domain

### Build issues

If you get build errors on web:
```bash
flutter clean
flutter pub get
flutter build web
```

### Ad slot IDs format

Adsterra slot IDs are numeric values that appear in your ad script URLs:
```
//pl123456789.effectiveratecpm.com/123456789/invoke.js
    ^^^^^^^^^
    This is your slot ID
```

## Migration from AdSense

If you previously used Google AdSense:

1. ✅ Remove AdSense script from `web/index.html`
2. ✅ Update `web_ad_widget_web.dart` for Adsterra format
3. ✅ Replace AdSense ad slot IDs with Adsterra slot IDs
4. ✅ Update `ad_config.dart` with new configuration constants

## API Reference

See inline documentation in:
- `ad_config.dart` - Configuration options
- `ad_service.dart` - Initialization and loading
- `widgets/web_ad_widget_web.dart` - Web widget options

## Support

For issues with:
- **AdMob**: Check [Google AdMob Help](https://support.google.com/admob)
- **Adsterra**: Contact Adsterra support or check their [Publisher Guide](https://adsterra.com/publisher-guide)
