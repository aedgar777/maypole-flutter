# Run Configurations Comparison

## Quick Answer

**Main Difference:** How the flavor is specified.

| Configuration | Method | Works On | Recommended |
|--------------|---------|----------|-------------|
| **Android Dev Debug** | Uses `buildFlavor` option | Android only | ✅ Yes - More explicit |
| **Flutter Development** | Uses `--flavor=dev` argument | All platforms | ⚠️ Legacy - Still works |

Both do essentially the same thing, but the **Android Dev** configurations are better organized.

## Detailed Comparison

### Flutter Development (Existing/Legacy)

```xml
<configuration name="Flutter Development">
  <option name="additionalArgs" value="--dart-define=ENVIRONMENT=dev --flavor=dev" />
</configuration>
```

**What it does:**

- Passes `--flavor=dev` as a command-line argument
- Passes `--dart-define=ENVIRONMENT=dev`
- Runs in **debug mode** by default
- Works on all platforms (Android, iOS, etc.)

### Android Dev Debug (New)

```xml
<configuration name="Android Dev Debug">
  <option name="buildFlavor" value="dev" />
  <option name="additionalArgs" value="--dart-define=ENVIRONMENT=dev" />
</configuration>
```

**What it does:**

- Sets `buildFlavor` explicitly (Android Studio understands this better)
- Passes `--dart-define=ENVIRONMENT=dev`
- Runs in **debug mode** by default
- Android-focused (though works on all platforms)

### Android Dev Release (New)

```xml
<configuration name="Android Dev Release">
  <option name="buildFlavor" value="dev" />
  <option name="additionalArgs" value="--release --dart-define=ENVIRONMENT=dev" />
</configuration>
```

**What it does:**

- Sets `buildFlavor` explicitly
- Passes `--release` flag for optimized build
- Passes `--dart-define=ENVIRONMENT=dev`
- Runs in **release mode** (optimized, no hot reload)

## Practical Differences

### Build Variant Selection

**Flutter Development:**

```bash
# Translates to:
flutter run --dart-define=ENVIRONMENT=dev --flavor=dev
```

- Build variant: Selected automatically by Android Studio
- May default to `devDebug` or `devRelease` depending on current Build Variants selection

**Android Dev Debug:**

```bash
# Translates to:
flutter run --debug --flavor dev --dart-define=ENVIRONMENT=dev
```

- Build variant: Explicitly `devDebug` (debug mode + dev flavor)
- More predictable behavior

**Android Dev Release:**

```bash
# Translates to:
flutter run --release --flavor dev --dart-define=ENVIRONMENT=dev
```

- Build variant: Explicitly `devRelease` (release mode + dev flavor)
- Optimized, no debugging

## Which Should You Use?

### Use the NEW "Android Dev" Configurations When:

✅ You want **explicit control** over debug vs release mode
✅ You want **consistent behavior** every time
✅ You want to match the **iOS workflow** (dev-debug, dev-release, etc.)
✅ You're **primarily working on Android**

### Use "Flutter Development" When:

✅ You're working on **multiple platforms** simultaneously
✅ You want **shorter configuration names**
✅ You're **already familiar** with it
✅ You don't care about debug vs release distinction

## Complete Comparison Table

| Aspect | Flutter Development | Android Dev Debug | Android Dev Release |
|--------|---------------------|-------------------|---------------------|
| **Flavor** | dev (via `--flavor`) | dev (via `buildFlavor`) | dev (via `buildFlavor`) |
| **Build Mode** | debug (default) | debug (explicit) | release (explicit) |
| **Build Variant** | Depends on Build Variants panel | Always `devDebug` | Always `devRelease` |
| **Hot Reload** | ✅ Yes | ✅ Yes | ❌ No |
| **Optimized** | ❌ No | ❌ No | ✅ Yes |
| **Debugger** | ✅ Attached | ✅ Attached | ❌ Not attached |
| **App ID** | app.maypole.maypole.dev.debug* | app.maypole.maypole.dev.debug | app.maypole.maypole.dev |
| **Speed** | Fast | Fast | Slower (optimized) |
| **Use Case** | General development | Daily development | Performance testing |

*Depends on selected build variant

## Real-World Example

### Scenario: You want to test performance

**Using Flutter Development:**

1. Select "Flutter Development"
2. Open Build Variants panel
3. Change to `devRelease`
4. Click play
5. ❌ **Problem:** Flutter Development doesn't specify `--release`, so it might still run in debug
   mode

**Using Android Dev Release:**

1. Select "Android Dev Release"
2. Click play
3. ✅ **Always runs in release mode** - predictable!

## Migration Recommendation

### For Daily Development

- **Before:** "Flutter Development"
- **After:** "Android Dev Debug"
- **Why:** More explicit, same speed, better control

### For Performance Testing

- **Before:** "Flutter Development" + manually change Build Variants
- **After:** "Android Dev Release"
- **Why:** One click, always correct mode

### For Production Testing

- **Before:** "Flutter Production" + manually change Build Variants
- **After:** "Android Prod Debug" or "Android Prod Release"
- **Why:** Clear distinction between debugging and release

## Can You Delete the Old Ones?

**Yes, but not necessary.** They still work fine. You can:

### Option 1: Keep Both (Recommended)

- Old configurations still work
- Team members can use whichever they prefer
- No breaking changes

### Option 2: Delete Old, Use New

```bash
rm .idea/runConfigurations/Flutter_Development.xml
rm .idea/runConfigurations/Flutter_Production.xml
```

- Cleaner dropdown menu
- Encourages consistent usage
- More explicit configurations

### Option 3: Rename Old for Clarity

Edit the files and change names:

- "Flutter Development" → "Flutter Dev (Legacy)"
- "Flutter Production" → "Flutter Prod (Legacy)"

## Summary

| Question | Answer |
|----------|--------|
| **Are they the same?** | Similar, but new ones are more explicit |
| **Which is better?** | Android Dev configurations (more control) |
| **Can I use both?** | Yes, use whichever you prefer |
| **Should I switch?** | Recommended for consistency with iOS |
| **What about iOS?** | iOS doesn't have flavors, but has matching configs (dev-debug, prod-release) |

## Recommendation

**Use the new "Android Dev" configurations** because they:

1. ✅ Match your iOS setup (dev-debug, dev-release, prod-debug, prod-release)
2. ✅ Are more explicit about debug vs release
3. ✅ Give you better control
4. ✅ Make it clear what mode you're running in
5. ✅ Work better with the Build Variants system

**Keep "Flutter Development" as backup** if you want, but start using the new ones for consistency.

---

**Bottom Line:** The new "Android Dev" configurations are better organized and give you explicit
control over debug/release modes, making them more suitable for a production workflow.
