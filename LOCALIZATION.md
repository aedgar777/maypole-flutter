# Localization Setup

This app uses Flutter's built-in localization system with ARB (Application Resource Bundle) files.

## Structure

- `lib/l10n/` - Contains ARB files for translations
    - `app_en.arb` - English translations (default/template)
    - `app_es.arb` - Spanish translations
- `lib/l10n/generated/` - Auto-generated localization code (don't edit manually)
- `l10n.yaml` - Configuration file for localization generation

## Adding/Modifying Translations

1. Edit the ARB files in `lib/l10n/`:
    - Add new keys to `app_en.arb` (this is the template)
    - Add corresponding translations to other language files (e.g., `app_es.arb`)

2. Generate the localization code:
   ```bash
   flutter gen-l10n
   ```

   Or simply run your app - the files will be generated automatically:
   ```bash
   flutter run
   ```

## Using Translations in Code

Import the localization class:

```dart
import 'package:maypole/l10n/generated/app_localizations.dart';
```

Access translations in your widgets:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Text(l10n.welcomeMessage);
}
```

For strings with placeholders:

```dart
Text(l10n.welcome('John'))  // Welcome John
```

## Adding a New Language

1. Create a new ARB file: `lib/l10n/app_XX.arb` (where XX is the language code)
2. Copy the structure from `app_en.arb`
3. Translate all the values
4. Run `flutter gen-l10n`

The new language will automatically be added to `supportedLocales`.

## ARB File Format

```json
{
  "@@locale": "en",
  "keyName": "Translation text",
  "@keyName": {
    "description": "Description for translators"
  },
  "greeting": "Hello {name}!",
  "@greeting": {
    "description": "A greeting with user's name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

## Current Supported Languages

- English (en)
- Spanish (es)

## Resources

- [Flutter Internationalization Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
