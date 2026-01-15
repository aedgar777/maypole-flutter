# Deployment Scripts Quick Reference

## 🚀 Common Commands

### Deploy Everything (Dev)
```bash
./scripts/deployment/dev-deploy-all.sh
```
Runs tests → Bumps build number → Deploys Firebase → Builds & uploads Android, iOS, Web to dev/internal testing

### Deploy Everything (Beta)
```bash
./scripts/deployment/beta-deploy-all.sh
```
Bumps patch version → Builds & uploads Android, iOS, Web to beta/public testing

---

## 📱 Development (Internal Testing)

**Note:** Individual scripts do NOT bump version. Use `dev-deploy-all.sh` for automatic version bumping.

### Android → Play Store Internal Testing
```bash
./scripts/deployment/dev-deploy-android.sh
```

### iOS → TestFlight Internal Testing
```bash
./scripts/deployment/dev-deploy-ios.sh
```

### Web → Firebase Hosting (Dev)
```bash
./scripts/deployment/dev-deploy-web.sh
```

---

## 🧪 Beta (Public Testing)

**Note:** Individual scripts do NOT bump version. Use `beta-deploy-all.sh` for automatic version bumping.

### Android → Play Store Open Testing
```bash
./scripts/deployment/beta-deploy-android.sh
```

### iOS → TestFlight Beta
```bash
./scripts/deployment/beta-deploy-ios.sh
```

### Web → Firebase Hosting Beta Channel
```bash
./scripts/deployment/beta-deploy-web.sh
```

---

## 🌟 Production

### Deploy Firebase Tools Only
```bash
./scripts/deployment/prod-deploy-firebase.sh
```

### Deploy Web to Production
```bash
./scripts/deployment/prod-deploy-web.sh
```

### Mobile Apps
Promote from beta via console UIs:
- **Android**: [Play Console](https://play.google.com/console)
- **iOS**: [App Store Connect](https://appstoreconnect.apple.com)

---

## 🔧 Firebase Utilities

### Deploy Firestore Rules
```bash
./scripts/deployment/deploy-firestore-rules.sh
```

### Deploy Firestore Indexes
```bash
./scripts/deployment/deploy-firestore-indexes.sh
```

### Deploy Storage Rules
```bash
./scripts/deployment/deploy-storage-rules.sh
```

### Check Index Status
```bash
./scripts/deployment/check-firestore-indexes.sh
```

---

## 📊 Deployment Tracks

| Environment | Android | iOS | Web |
|------------|---------|-----|-----|
| **Dev** | Internal Testing | Internal Testing | maypole-flutter-dev |
| **Beta** | Open Testing | Beta Testing | maypole-flutter-ce6c3 (beta channel) |
| **Prod** | Production* | Production* | maypole-flutter-ce6c3 |

\* Promoted from beta via console UIs

---

## 📊 Automatic Versioning

**Only `*-deploy-all.sh` scripts bump versions:**

- **`dev-deploy-all.sh`**: Auto-bumps **build number** only (e.g., `1.0.0+20` → `1.0.0+21`)
- **`beta-deploy-all.sh`**: Auto-bumps **patch version** (e.g., `1.0.0+20` → `1.0.1+21`)
- **Individual platform scripts**: NO version bumping
- **Prod**: No auto-versioning (promoted from beta with same version)

Manual version control:
```bash
./scripts/bump-version.sh [major|minor|patch|build]  # Interactive
./scripts/auto-bump-version.sh [major|minor|patch]   # Non-interactive
```

## ⚡ Pro Tips

1. **Always test first**: `dev-deploy-all.sh` runs tests before deploying
2. **Individual deploys**: Use platform-specific scripts for faster iteration
3. **Beta uses prod config**: Beta builds use production Firebase but test tracks
4. **Promote to prod**: Don't build prod mobile apps directly, promote from beta
5. **Check logs**: Each script shows deployment URLs at the end
6. **Version tracking**: Version bumps happen automatically before each build

---

## 🆘 Quick Troubleshooting

- **Permission denied**: `chmod +x scripts/deployment/*.sh`
- **Environment variables**: Check `.env` file exists
- **Firebase**: Run `firebase login` first
- **Fastlane**: `cd android && bundle install` or `cd ios && bundle install`

See [SETUP.md](SETUP.md) for detailed setup instructions.
