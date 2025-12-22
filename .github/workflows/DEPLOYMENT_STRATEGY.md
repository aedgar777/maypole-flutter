# Deployment Strategy

This document explains the complete deployment strategy for the Maypole Flutter app.

## Overview

The app uses a **three-tier deployment pipeline** that automatically builds and deploys to different environments based on which branch you push to.

---

## The Three Tiers

### 1️⃣ Development (Internal Testing)

**Trigger:** Push to `develop` branch

**What happens:**
- ✅ Runs unit tests
- ✅ Builds **dev-release** variant (points to dev Firebase)
- ✅ Deploys web to Firebase Hosting (dev project)
- ✅ Uploads Android APK/AAB to **Internal Testing** track
- ✅ Uploads iOS to **TestFlight Internal**
- ✅ **Auto-releases** to testers (`status: completed`)

**Android Details:**
- Package: `app.maypole.dev`
- Track: `internal`
- Testers: Up to 100 internal testers
- Environment: Dev Firebase (`maypole-flutter-dev`)

**Purpose:** Quick iteration and testing with development team

---

### 2️⃣ Beta (Open Testing)

**Trigger:** Push to `beta` branch (typically merge `develop` → `beta`)

**What happens:**
- ✅ Builds **prod-release** variant (points to prod Firebase)
- ✅ Uploads Android AAB to **Beta Track (Open Testing)**
- ✅ Uploads iOS to **TestFlight External Beta**
- ✅ **Auto-releases** to beta testers (`status: completed`)

**Android Details:**
- Package: `app.maypole.maypole`
- Track: `beta`
- Testers: Anyone can join via opt-in link
- Environment: Production Firebase (`maypole-flutter-ce6c3`)

**Purpose:** Public beta testing before production release

**Note:** Configure the beta track as "Open Testing" in Play Console to allow anyone to join. Alternatively, you can keep it as "Closed Testing" and invite specific testers.

---

### 3️⃣ Production

**Trigger:** Push to `master`/`main` branch (typically merge `beta` → `master`)

**What happens:**
- ✅ Builds **prod-release** variant (points to prod Firebase)
- ✅ Deploys web to Firebase Hosting (production)
- ✅ Deploys Firebase services (Firestore rules, indexes, Storage rules)
- ✅ Uploads Android AAB to **Production Track** as **DRAFT**
- ✅ Uploads iOS to **App Store**
- ⚠️ **Does NOT auto-release** (`status: draft`)

**Android Details:**
- Package: `app.maypole.maypole`
- Track: `production`
- Status: **Draft** (requires manual publish)
- Environment: Production Firebase (`maypole-flutter-ce6c3`)

**Purpose:** Production release with manual approval and staged rollout

---

## Why Draft for Production?

The production workflow uses `status: draft` instead of `status: completed` for the Android release. This is intentional and provides several benefits:

### ✅ Benefits of Draft Status

1. **Manual Review**
   - Review the build in Play Console before it goes live
   - Verify all metadata is correct
   - Double-check version numbers

2. **Store Listing Control**
   - Edit descriptions, screenshots, and feature graphics
   - Update "What's New" release notes
   - Polish the presentation before users see it

3. **Staged Rollout**
   - Start with 5-10% of users
   - Monitor crash reports and reviews
   - Gradually increase to 20%, 50%, 100%
   - Halt rollout if issues are discovered

4. **Timing Control**
   - Choose the exact moment to publish
   - Coordinate with marketing announcements
   - Release during business hours for monitoring

5. **Safety**
   - Prevents accidental releases
   - Human oversight for production
   - Reduce risk of pushing bugs to millions

### 📝 How to Publish from Draft

After the workflow uploads the AAB as a draft:

1. **Go to Play Console**
   - Navigate to your app
   - Click "Production" in the left sidebar

2. **Review the Draft**
   - Check the version code and version name
   - Review the AAB details
   - Verify upload was successful

3. **Edit Release Details** (if needed)
   - Update "What's New" section
   - Modify store listing
   - Add screenshots or feature graphics

4. **Choose Rollout Strategy**
   - **Option A - Full Release:** Publish to 100% of users immediately
   - **Option B - Staged Rollout:** Start with 5-10% and gradually increase
   
   **Recommended:** Start with a staged rollout

5. **Publish**
   - Click "Review release"
   - Click "Start rollout to Production" (or "Start rollout to 5% of users")

6. **Monitor**
   - Watch crash reports in Firebase Crashlytics
   - Monitor user reviews
   - Check for any critical issues
   - Increase rollout percentage when confident

### 🎯 Staged Rollout Example

A typical staged rollout timeline:

| Day | Rollout % | Users Affected | Action |
|-----|-----------|----------------|--------|
| 1 | 5% | ~5K users | Initial release, monitor closely |
| 2-3 | 5% | ~5K users | Watch for crashes/bad reviews |
| 3 | 10% | ~10K users | Increase if no issues |
| 4-5 | 10% | ~10K users | Continue monitoring |
| 5 | 20% | ~20K users | Increase if stable |
| 6-7 | 20% | ~20K users | Monitor |
| 7 | 50% | ~50K users | Half of users |
| 8-9 | 50% | ~50K users | Monitor |
| 9 | 100% | All users | Complete rollout |

**Note:** If you discover a critical bug at any stage, you can halt the rollout and push a fix through the pipeline again.

---

## Branch Strategy

```
develop (dev-release)
   ↓
   ↓ (merge develop → beta)
   ↓
beta (prod-release)
   ↓
   ↓ (merge beta → master)
   ↓
master/main (prod-release)
```

### Workflow

1. **Feature development**
   - Create feature branch from `develop`
   - Make changes and test locally
   - Open PR to `develop`
   - Merge → triggers dev deployment

2. **Beta release**
   - When `develop` is stable, merge to `beta`
   - `git checkout beta && git merge develop && git push`
   - Triggers beta deployment
   - Beta testers can test with production Firebase

3. **Production release**
   - When `beta` is stable, merge to `master`
   - `git checkout master && git merge beta && git push`
   - Triggers production deployment
   - **Build is uploaded as draft** - you must manually publish

---

## Environment Configuration

### Development (`develop` branch)
- Build flavor: `dev`
- Firebase project: `maypole-flutter-dev`
- Android package: `app.maypole.dev`
- iOS bundle: `app.maypole.dev`
- Play Store track: `internal`

### Beta & Production (`beta` and `master` branches)
- Build flavor: `prod`
- Firebase project: `maypole-flutter-ce6c3`
- Android package: `app.maypole.maypole`
- iOS bundle: `app.maypole.maypole`
- Play Store tracks: `beta` (beta branch), `production` (master branch)

---

## Quick Reference Commands

### Deploy to Development
```bash
git checkout develop
git add .
git commit -m "feat: add new feature"
git push origin develop
# → Auto-releases to internal testing
```

### Deploy to Beta
```bash
git checkout beta
git merge develop
git push origin beta
# → Auto-releases to beta track
```

### Deploy to Production (as draft)
```bash
# First, update version in pubspec.yaml
vim pubspec.yaml  # Bump version: 1.0.0+1 → 1.0.1+2

git checkout master
git merge beta
git commit -m "chore: bump version to 1.0.1+2"
git push origin master
# → Uploads to production track as DRAFT
# → You must manually publish in Play Console
```

### Manual Publish Steps
1. Go to [Play Console](https://play.google.com/console/)
2. Select your app
3. Click "Production" in sidebar
4. Review the draft release
5. Click "Review release" → "Start rollout to Production"
6. Choose staged rollout percentage (recommended: 5-10%)
7. Monitor and gradually increase

---

## Monitoring & Rollback

### Monitoring Tools
- **Firebase Crashlytics:** Real-time crash reports
- **Play Console:** User reviews, ratings, install metrics
- **Firebase Analytics:** User behavior and engagement
- **GitHub Actions:** Build and deployment logs

### Rollback Strategy

If you discover a critical bug in production:

1. **Halt the rollout**
   - Go to Play Console → Production
   - Click "Pause rollout" or "Halt rollout"

2. **Fix the bug**
   - Create hotfix branch from `master`
   - Fix the bug and test thoroughly
   - Merge to `develop`, then `beta`, then `master`

3. **Deploy fix**
   - Push to `master` → new draft is created
   - Publish the fix with staged rollout

4. **Resume rollout**
   - Monitor the fix in production
   - Gradually increase rollout percentage

---

## Version Management

### Version Format
- Format: `MAJOR.MINOR.PATCH+BUILD`
- Example: `1.2.3+45`
- `MAJOR`: Breaking changes
- `MINOR`: New features, backward compatible
- `PATCH`: Bug fixes
- `BUILD`: Build number (must increase with each release)

### Update Version
Edit `pubspec.yaml`:

```yaml
version: 1.2.3+45
```

**Important:** 
- Increment `BUILD` number for every Play Store/App Store release
- Play Store requires each AAB to have a unique, increasing build number
- App Store requires unique build numbers per version

---

## FAQ

### Q: Can I skip the draft step and auto-release to production?

**A:** Technically yes, by changing `status: draft` to `status: completed` in `production.yml`. However, this is **not recommended** because:
- No human oversight before millions see it
- Cannot review store listing before publish
- No opportunity for staged rollout
- Higher risk of pushing bugs to users

### Q: What if I want to test production builds before releasing?

**A:** Use the beta track! The beta workflow builds with `prod` flavor (production Firebase) but deploys to the beta track. This lets you test the exact production build with real users before promoting to production.

### Q: How do I know when the build is ready to publish?

**A:** After pushing to `master`, you'll receive a notification (if configured) when the workflow completes. Check:
1. GitHub Actions for green checkmark
2. Play Console → Production → Draft releases
3. You should see your new build ready to review

### Q: Can I edit the draft after it's uploaded?

**A:** Yes! You can:
- Edit release notes
- Update store listing (descriptions, screenshots)
- Add/remove testing tracks
- Change rollout strategy

### Q: What happens to the draft if I push again?

**A:** A new draft is created. The old draft remains until you delete it or publish it. You can have multiple drafts, but only one can be published at a time.

### Q: Do I need to manually deploy web and Firebase services?

**A:** No, the production workflow automatically:
- Deploys web to Firebase Hosting (live)
- Deploys Firestore rules and indexes
- Deploys Storage rules

Only the Android/iOS app releases require manual action from draft status.

---

## Troubleshooting

### Build fails on production workflow
- Check GitHub Actions logs for errors
- Verify all secrets are set correctly
- Ensure version number was incremented
- Test build locally: `flutter build appbundle --release --flavor prod`

### Draft doesn't appear in Play Console
- Wait a few minutes (can take 5-10 minutes to process)
- Check workflow logs for upload errors
- Verify service account has correct permissions
- Ensure package name matches (`app.maypole.maypole`)

### Cannot publish draft
- Ensure app is approved by Google (first release requires review)
- Check for policy violations
- Verify all required store listing assets are present
- Ensure app is compliant with target SDK requirements

---

## Additional Resources

- [DEPLOYMENT_SETUP.md](./DEPLOYMENT_SETUP.md) - Detailed setup instructions
- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - Setup progress checklist
- [Google Play Console](https://play.google.com/console/)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/cd)
