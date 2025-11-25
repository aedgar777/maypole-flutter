# Web Deployment Guide

## Common Issues and Solutions

### Issue: Blank Screen After Firebase Hosting Deployment

**Symptoms:**

- App loads on web after deployment
- Console shows: `Loaded .env file (CI/CD environment)`
- Error: `Uncaught Error at createErrorInternal (assert.ts:176:3)`
- Firebase Auth initialization fails
- Blank screen

**Root Cause:**
The `.env` file is not included in the web build output. Flutter web apps need Firebase
configuration passed via `--dart-define` flags during build, not from `.env` files.

---

## Quick Fix: Rebuild and Redeploy

### For Development Environment:

```bash
# Build web with environment variables
./scripts/build-web-dev.sh

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### For Production Environment:

```bash
# Build web with environment variables
./scripts/build-web-prod.sh

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## Manual Build Commands

If the scripts don't work, you can build manually:

### Development Build:

```bash
flutter build web \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FIREBASE_DEV_WEB_API_KEY=AIzaSyBC7aJ-W1p3mryZM_PQiGcjGdyDaJ-EsPU \
  --dart-define=FIREBASE_DEV_WEB_APP_ID=1:902296622907:web:f58b05427c4f319920891e \
  --dart-define=FIREBASE_DEV_MESSAGING_SENDER_ID=902296622907 \
  --dart-define=FIREBASE_DEV_PROJECT_ID=maypole-flutter-dev \
  --dart-define=FIREBASE_DEV_AUTH_DOMAIN=maypole-flutter-dev.firebaseapp.com \
  --dart-define=FIREBASE_DEV_STORAGE_BUCKET=maypole-flutter-dev.firebasestorage.app \
  --dart-define=FIREBASE_DEV_WEB_MEASUREMENT_ID=G-C4H0YWRQCF
```

### Production Build:

```bash
flutter build web \
  --dart-define=ENVIRONMENT=production \
  --dart-define=FIREBASE_PROD_WEB_API_KEY=AIzaSyCu_lO7uAxI63wDhiuvesjKurUhJBLHLXs \
  --dart-define=FIREBASE_PROD_WEB_APP_ID=1:1069925301177:web:b34f1952febe6bce4e1468 \
  --dart-define=FIREBASE_PROD_MESSAGING_SENDER_ID=1069925301177 \
  --dart-define=FIREBASE_PROD_PROJECT_ID=maypole-flutter-ce6c3 \
  --dart-define=FIREBASE_PROD_AUTH_DOMAIN=maypole-flutter-ce6c3.firebaseapp.com \
  --dart-define=FIREBASE_PROD_STORAGE_BUCKET=maypole-flutter-ce6c3.firebasestorage.app \
  --dart-define=FIREBASE_PROD_WEB_MEASUREMENT_ID=G-YTP58985GW
```

---

## Debugging Tips

### 1. Check Browser Console

After deployment, open the browser console (F12) and look for:

```
🔧 Firebase Config Debug:
  Environment: dev
  Platform: Web
  API Key: ✅ Present (AIzaSyBC7a...)
  App ID: ✅ Present
  Project ID: maypole-flutter-dev
  Auth Domain: maypole-flutter-dev.firebaseapp.com
```

If you see `❌ MISSING` for any value, the build didn't include the Firebase config.

### 2. Test Locally Before Deploying

```bash
# Build and serve locally
flutter build web --dart-define=ENVIRONMENT=dev [other flags...]
firebase serve --only hosting
```

Visit `http://localhost:5000` and check the console for debug output.

### 3. Verify Build Output

Check that `build/web/` contains your compiled app:

```bash
ls -la build/web/
```

You should see:

- `index.html`
- `flutter_bootstrap.js`
- `main.dart.js`
- `assets/` directory

---

## Why This Happens

1. **Flutter Web Compilation**: When Flutter compiles to JavaScript, it embeds `--dart-define`
   values at compile time but **cannot** read `.env` files at runtime.

2. **Asset Loading**: The `pubspec.yaml` lists `.env` as an asset, but for web:
    - Mobile apps: Assets are bundled in the app package
    - Web apps: Assets are served from the server, but the `.env` file contains secrets and
      shouldn't be publicly accessible

3. **Security**: Exposing `.env` files on a web server would leak your API keys to anyone who visits
   your site.

---

## CI/CD Integration

For GitHub Actions, GitLab CI, or other CI/CD pipelines, use environment secrets:

```yaml
# Example GitHub Actions workflow
- name: Build Web App
  env:
    FIREBASE_API_KEY: ${{ secrets.FIREBASE_DEV_WEB_API_KEY }}
    FIREBASE_APP_ID: ${{ secrets.FIREBASE_DEV_WEB_APP_ID }}
    # ... other secrets
  run: |
    flutter build web \
      --dart-define=ENVIRONMENT=dev \
      --dart-define=FIREBASE_DEV_WEB_API_KEY=$FIREBASE_API_KEY \
      --dart-define=FIREBASE_DEV_WEB_APP_ID=$FIREBASE_APP_ID \
      # ... other flags

- name: Deploy to Firebase Hosting
  run: firebase deploy --only hosting --token ${{ secrets.FIREBASE_TOKEN }}
```

---

## Best Practices

1. **Never commit secrets** to version control
2. **Use dart-define for web builds** (required for security)
3. **Use .env files for local mobile development** (convenient for dev)
4. **Store secrets in CI/CD environment variables** (secure)
5. **Test locally** before deploying to production

---

## Platform Differences

| Platform | Configuration Method | Why |
|----------|---------------------|-----|
| Mobile (Android/iOS) | `.env` files work fine | Apps are sandboxed, secrets are compiled into binary |
| Web | `--dart-define` required | Secrets would be exposed in publicly accessible files |
| Desktop | `.env` files work | Apps are sandboxed like mobile |

---

## Troubleshooting Checklist

- [ ] Used `--dart-define` flags for web build
- [ ] Verified all required Firebase config values are present
- [ ] Checked browser console for Firebase initialization errors
- [ ] Tested locally with `firebase serve` before deploying
- [ ] Confirmed `.env` file exists locally (for building)
- [ ] Rebuilt the app after changing configuration

---

## Additional Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web/building)
- [Firebase Hosting Guide](https://firebase.google.com/docs/hosting)
- [FlutterFire Configuration](https://firebase.flutter.dev/docs/overview#initializing-flutterfire)
