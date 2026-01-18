# Versioning Strategy

This document explains how versions are automatically managed in the deployment pipeline.

## Version Format

Maypole uses semantic versioning with build numbers:

```
MAJOR.MINOR.PATCH+BUILD
  1  .  0  .  0  + 20
```

- **MAJOR**: Breaking changes (manually controlled)
- **MINOR**: New features (manually controlled)
- **PATCH**: Bug fixes (auto-bumped for beta)
- **BUILD**: Build number (auto-bumped for dev)

## Automatic Versioning Rules

### 🔧 Development Deployments (Internal Testing)

**Bumps**: Build number only

```
Before:  1.0.0+20
After:   1.0.0+21
```

**Why**: Dev deployments are frequent and incremental. Users in internal testing don't need to track version names, just that they have the latest build.

**Scripts that auto-bump build**:
- `dev-deploy-all.sh` only

**Scripts that do NOT bump**:
- `dev-deploy-android.sh`, `dev-deploy-ios.sh`, `dev-deploy-web.sh` (individual platform scripts)

### 🧪 Beta Deployments (Public Testing)

**Bumps**: Patch version + build number

```
Before:  1.0.0+21
After:   1.0.1+22
```

**Why**: Beta releases are shown to external testers and represent more significant milestones. The version name change signals a new beta release with potential bug fixes.

**Scripts that auto-bump patch**:
- `beta-deploy-all.sh` only

**Scripts that do NOT bump**:
- `beta-deploy-android.sh`, `beta-deploy-ios.sh`, `beta-deploy-web.sh` (individual platform scripts)

### 🌟 Production Deployments

**Bumps**: None (promotes from beta)

```
Beta version:  1.0.1+22
Prod version:  1.0.1+22  (same)
```

**Why**: Production mobile apps are promoted from beta through app store consoles, ensuring the exact build that was tested goes to production. No rebuild = no versioning needed.

**Exception**: For major/minor version bumps (new features, breaking changes), manually run:
```bash
./scripts/bump-version.sh [major|minor]
```

## Manual Version Control

### Interactive Bump (with git commit/tag)
```bash
./scripts/bump-version.sh [major|minor|patch|build]
```

Features:
- Shows before/after comparison
- Asks for confirmation
- Offers to create git commit
- Offers to create git tag
- Creates backup (pubspec.yaml.backup)

### Non-Interactive Bump (for automation)
```bash
./scripts/auto-bump-version.sh [major|minor|patch|build]
```

Used by deployment scripts. No prompts, no git operations.

### Build Number Only (legacy)
```bash
./scripts/auto-bump-build.sh
```

Equivalent to `auto-bump-version.sh build`.

## When to Manually Bump Major/Minor

### Minor Version (New Features)
When adding significant new functionality:
```bash
./scripts/bump-version.sh minor
# 1.0.5+30 → 1.1.0+31
```

Then deploy to beta:
```bash
./scripts/deployment/beta-deploy-android.sh  # Will bump to 1.1.1+32
```

### Major Version (Breaking Changes)
When making incompatible changes:
```bash
./scripts/bump-version.sh major
# 1.5.3+50 → 2.0.0+51
```

Then deploy to beta:
```bash
./scripts/deployment/beta-deploy-android.sh  # Will bump to 2.0.1+52
```

## Version History Example

Real-world example of version progression:

```
Day 1:  1.0.0+20  (initial state)
        dev-deploy-all.sh → 1.0.0+21 (all platforms, dev internal)

Day 2:  Quick Android-only fix
        (manually bump: auto-bump-build.sh)
        dev-deploy-android.sh → 1.0.0+22 (Android only, dev internal)

Day 3:  Ready for beta testing
        beta-deploy-all.sh → 1.0.1+23 (all platforms, beta public)

Day 5:  More dev changes
        dev-deploy-all.sh → 1.0.1+24 (all platforms, dev internal)
        dev-deploy-all.sh → 1.0.1+25 (all platforms, dev internal)

Day 7:  Another beta with fixes
        beta-deploy-all.sh → 1.0.2+26 (all platforms, beta public)

Day 10: Promote to production via consoles
        iOS: 1.0.2+26 (promoted from beta)
        Android: 1.0.2+26 (promoted from beta)

Day 12: Major new feature ready
        bump-version.sh minor → 1.1.0+27
        beta-deploy-all.sh → 1.1.1+28 (all platforms, beta public)
```

## CI/CD Integration

In CI/CD pipelines, versioning is automatic:

```yaml
# GitHub Actions example
- name: Deploy to Dev
  run: |
    # Version bump happens inside the script
    ./scripts/deployment/dev-deploy-android.sh
    
- name: Commit Version Bump
  run: |
    git config user.name "CI Bot"
    git config user.email "ci@maypole.app"
    git add pubspec.yaml
    git commit -m "chore: bump version [skip ci]"
    git push
```

## Version Visibility

Users see versions in:
- **Android**: Play Store listing, About screen
- **iOS**: App Store listing, Settings → About
- **Web**: About screen, browser console

Build numbers are primarily for internal tracking and app store submissions.

## Troubleshooting

### "Version already exists in Play Store"
Each upload to Play Store needs a unique build number. If you see this error:
1. Check current version: `grep "^version:" pubspec.yaml`
2. Manually bump: `./scripts/auto-bump-build.sh`
3. Re-run deployment

### "CFBundleVersion already uploaded to TestFlight"
Same solution as above - bump build number.

### Accidentally bumped wrong version
1. Edit `pubspec.yaml` manually
2. Or restore backup: `cp pubspec.yaml.backup pubspec.yaml`
3. Re-run deployment (will bump from correct base)

## When to Use Individual vs Deploy-All Scripts

### Use `*-deploy-all.sh` (Recommended)
- **Regular development cycles** - Deploying to all platforms with automatic versioning
- **Beta releases** - Shipping a new version to public testers
- **CI/CD pipelines** - Automated deployments

### Use Individual Platform Scripts
- **Quick fixes for one platform** - Testing Android-only or iOS-only changes
- **Platform-specific issues** - When one platform fails, retry just that platform
- **Custom versioning** - When you've already manually bumped version
- **Partial deployments** - Only need web or mobile, not both

**Important**: When using individual scripts, you must manually bump version first:
```bash
# For dev (build number only)
./scripts/auto-bump-build.sh
./scripts/deployment/dev-deploy-android.sh

# For beta (patch version)
./scripts/auto-bump-version.sh patch
./scripts/deployment/beta-deploy-ios.sh
```

## Best Practices

1. **Prefer `*-deploy-all.sh` scripts** - They handle versioning automatically
2. **Let automation handle dev/beta bumps** - Don't manually edit versions for routine deployments
3. **Plan major/minor bumps** - Coordinate feature releases with version strategy
4. **Tag releases** - Use `bump-version.sh` with git tags for production milestones
5. **Monitor build numbers** - If they grow large (>1000), consider resetting with major version bump
6. **Document breaking changes** - When bumping major version, maintain CHANGELOG.md
