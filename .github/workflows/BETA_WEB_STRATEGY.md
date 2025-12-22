# Beta Web Deployment Strategy

This document outlines strategies for deploying a beta version of the web app for enrolled users.

## Current State

- **Development**: Web app deploys to `maypole-flutter-dev.web.app` (Firebase Hosting)
- **Production**: Web app deploys to `maypole-flutter.web.app` or custom domain
- **Beta**: Currently no web deployment (mobile apps only)

## Recommended Strategies

### Option 1: Firebase Hosting Preview Channels (Recommended)

**Pros**:
- Simple to set up
- No additional Firebase project needed
- Easy URL sharing
- Can be made persistent or temporary

**Cons**:
- URL is not as clean (includes random suffix)
- Limited access control (anyone with URL can access)

**Implementation**:

1. **Create a persistent beta channel**:
   ```bash
   firebase hosting:channel:create beta --project maypole-flutter --ttl 0
   ```

2. **Add to beta.yml workflow**:
   ```yaml
   build_web_beta:
     name: Build and Deploy Web (Beta Channel)
     runs-on: ubuntu-latest
     steps:
       # ... existing setup steps ...
       
       - name: Build Web
         run: |
           flutter build web --release \
             --dart-define=ENVIRONMENT=beta \
             --dart-define=FIREBASE_PROD_WEB_API_KEY=${{ secrets.FIREBASE_PROD_WEB_API_KEY }} \
             # ... other dart-defines
       
       - name: Deploy to Firebase Hosting Beta Channel
         run: |
           echo '${{ secrets.MAYPOLE_FIREBASE_SERVICE_ACCOUNT }}' > $HOME/gcloud-service-key.json
           export GOOGLE_APPLICATION_CREDENTIALS=$HOME/gcloud-service-key.json
           npm install -g firebase-tools
           firebase hosting:channel:deploy beta --project maypole-flutter --non-interactive
   ```

3. **Access Control**: Add authentication check in your Flutter app:
   ```dart
   // In your main.dart or app initialization
   Future<void> checkBetaAccess() async {
     if (kIsWeb && const String.fromEnvironment('ENVIRONMENT') == 'beta') {
       final user = FirebaseAuth.instance.currentUser;
       if (user == null) {
         // Redirect to login
         return;
       }
       
       // Check if user is in beta testers group
       final isBetaTester = await FirebaseFunctions.instance
           .httpsCallable('isBetaTester')
           .call({'userId': user.uid});
       
       if (!isBetaTester.data['isBetaTester']) {
         // Show "Beta access required" message
         // Redirect to main site
       }
     }
   }
   ```

4. **Firebase Function for Beta Access**:
   ```javascript
   // functions/index.js
   exports.isBetaTester = functions.https.onCall(async (data, context) => {
     const userId = data.userId;
     
     // Check Firestore for beta tester status
     const userDoc = await admin.firestore()
       .collection('users')
       .doc(userId)
       .get();
     
     return { isBetaTester: userDoc.data()?.betaTester === true };
   });
   ```

**Beta URL**: `https://maypole-flutter--beta-XXXXXX.web.app`

---

### Option 2: Subdomain Deployment

**Pros**:
- Clean URL (e.g., `beta.maypole.app`)
- Professional appearance
- Easier to communicate to testers

**Cons**:
- Requires custom domain configuration
- More complex DNS setup

**Implementation**:

1. **Configure Firebase Hosting with custom domain**:
   ```bash
   firebase hosting:sites:create maypole-beta --project maypole-flutter
   ```

2. **Update firebase.json**:
   ```json
   {
     "hosting": [
       {
         "site": "maypole-flutter",
         "public": "build/web",
         "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
       },
       {
         "site": "maypole-beta",
         "public": "build/web",
         "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
       }
     ]
   }
   ```

3. **Add DNS record**:
   - Type: A
   - Name: beta
   - Value: Firebase Hosting IP addresses

4. **Deploy in workflow**:
   ```yaml
   - name: Deploy to Beta Site
     run: |
       firebase deploy --only hosting:maypole-beta --project maypole-flutter
   ```

**Beta URL**: `https://beta.maypole.app`

---

### Option 3: Separate Firebase Project

**Pros**:
- Complete isolation
- Separate analytics
- Independent configuration

**Cons**:
- Additional Firebase project to manage
- More complex setup
- Potential cost duplication

**Implementation**:

1. Create new Firebase project: `maypole-flutter-beta`
2. Configure separate Firebase config secrets for beta
3. Deploy to beta project in workflow

**Not recommended** unless you need complete isolation for regulatory/testing reasons.

---

### Option 4: Feature Flags (In-App Beta Features)

**Pros**:
- Single deployment
- Granular control over features
- Easy to A/B test

**Cons**:
- Not a separate environment
- Beta features mixed with production code

**Implementation**:

Use Firebase Remote Config or a custom feature flag system:

```dart
// Check if user has beta access
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

final betaFeaturesEnabled = remoteConfig.getBool('beta_features_enabled');
final userIsBetaTester = await checkBetaTesterStatus();

if (betaFeaturesEnabled && userIsBetaTester) {
  // Show beta features
}
```

This allows beta testing of features without a separate deployment.

---

## Recommended Approach: Option 1 (Firebase Hosting Channels)

For your use case, **Firebase Hosting Preview Channels** is the best balance of simplicity and functionality.

### Implementation Steps

1. **Create the beta channel** (one-time setup):
   ```bash
   firebase hosting:channel:create beta --project maypole-flutter --ttl 0
   ```

2. **Add beta web deployment** to `beta.yml` (optional, if you want web beta):
   - Copy the web build job from `develop.yml`
   - Change deployment to use channel:
     ```bash
     firebase hosting:channel:deploy beta --project maypole-flutter --non-interactive
     ```

3. **Add ENVIRONMENT=beta** dart-define if you want to differentiate beta from prod

4. **Implement optional beta access check** in your Flutter app

5. **Share the beta URL** with your beta testers

### Access Control Options

**Simple**: Share URL only with beta testers (security through obscurity)

**Medium**: Add Firebase Auth login requirement + manual beta list in Firestore

**Advanced**: Implement Firebase Functions to check beta access + email domain restrictions

---

## Environment Variables

Add beta environment support if using Option 1:

```dart
// lib/config/environment.dart
enum Environment {
  dev,
  beta,
  production,
}

Environment get currentEnvironment {
  const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  switch (env) {
    case 'dev':
      return Environment.dev;
    case 'beta':
      return Environment.beta;
    default:
      return Environment.production;
  }
}
```

---

## Monitoring Beta Deployment

- **Firebase Console**: Check Hosting → Channels
- **Analytics**: Firebase Analytics can segment by hostname
- **Crashlytics**: Reports will show the beta URL if crashes occur

---

## Cost Considerations

- **Preview Channels**: No additional cost (uses existing Hosting quota)
- **Custom Domain**: No additional Firebase cost (may have domain registration cost)
- **Separate Project**: Duplicates Firebase costs

---

## Migration Path

Start with **Preview Channels** (Option 1), then migrate to **Subdomain** (Option 2) if needed:

1. Set up preview channel first (quick, no risk)
2. Test with small beta group
3. If successful and you want custom domain, add subdomain later
4. No changes needed to Firebase configuration

---

## Summary

**Immediate Action**: Set up Firebase Hosting Preview Channels for beta web deployment

**Future Enhancement**: Add custom subdomain when beta program matures

**Access Control**: Implement Firebase Auth + Firestore beta list if needed

This gives you flexibility to test quickly while leaving room for future improvements.
