# Team Setup Guide - Private Project

This guide helps team members set up access to the shared Maypole Firebase projects.

## 🎯 Private Team Project Approach

As a team member, you'll get access to the **shared Firebase projects** rather than creating your
own:

- ✅ Access to shared development environment (`maypole-flutter-dev`)
- ✅ Production environment access (for senior team members)
- ✅ Shared Firestore data and user accounts for testing
- ✅ Consistent environment across all team members
- ✅ `.env.local` file for **local development only** (not used in CI/CD)
- ✅ GitHub Actions uses repository secrets (no .env files needed)

## 🚀 Quick Setup (2 minutes)

### Step 1: Get Access from Team Admin

Contact your team admin to:

1. **Add you to the GitHub repository** with appropriate permissions
2. **Grant you Firebase project access** (they'll add your Google account)
3. **Share the team secrets** with you via secure method

### Step 2: Choose Your Secrets Access Method

Your team admin will provide secrets via one of these methods **for local development only**:

**Note**: These secrets are only needed for running the app locally. GitHub Actions CI/CD uses
repository secrets and does not require `.env` files.

#### **Option A: Direct Secrets File** (Simple)

Team admin provides you with a pre-configured `.env.local` file:

```bash
# Team admin sends you .env.local with actual values
# Just place it in your project root for local development - that's it!
```

#### **Option B: Google Secret Manager** (Enterprise)

Team uses Google Secret Manager for centralized secret management:

```bash
# Authenticate with your work Google account
gcloud auth login

# Set the team's secrets project
gcloud config set project maypole-secrets-XXXXXX

# Retrieve team secrets automatically
gcloud secrets versions access latest --secret="firebase-dev-config" > .env.local
```

#### **Option C: Manual Entry** (Secure)

Team admin provides you with the actual values to enter manually:

```bash
# Copy template
cp .env.example .env.local

# Team admin gives you the actual values to fill in
```

### Step 3: Get Firebase Configuration Files

#### **Android Configuration**

Team admin provides the actual `google-services.json`:

- Place it in `android/app/google-services.json`

#### **iOS Configuration** (if needed)

Team admin provides the actual `GoogleService-Info.plist`:

- Place it in `ios/Runner/GoogleService-Info.plist`

## 🔧 Testing Your Setup

Once you have the team secrets:

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
   ```

3. **Build for web:**
   ```bash
   flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
   ```

4. **Build for Android:**
   ```bash
   flutter build apk --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
   ```

## 🔐 Firebase Projects You'll Have Access To

### **Development Environment**: `maypole-flutter-dev`

- **Purpose**: Daily development and testing
- **Access**: All team members
- **Data**: Shared test data, can be modified/reset
- **Usage**: Use `ENVIRONMENT=dev` in your builds

### **Production Environment**: `maypole-flutter-ce6c3`

- **Purpose**: Production builds and live data
- **Access**: Senior team members only
- **Data**: Real user data - handle with care!
- **Usage**: Use `ENVIRONMENT=production` in your builds

## 👥 Team Member Roles & Access

### **Developer** (Most Team Members)

- ✅ Access to development Firebase project
- ✅ Can read/write development Firestore
- ✅ Can test Authentication flows
- ✅ Can upload to development Storage
- ❌ No production access

### **Senior Developer**

- ✅ Full development access
- ✅ Limited production read access
- ✅ Can create production builds locally
- ✅ Can review production logs and analytics

### **DevOps/Admin**

- ✅ Full access to both environments
- ✅ Can manage team member permissions
- ✅ Can rotate secrets and API keys
- ✅ Can deploy to production

## 🛠️ Development Workflow

### **Daily Development**

```bash
# Always use development environment for daily work
flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev

# Your changes affect the shared dev Firebase
# Coordinate with team if you need to modify shared data structures
```

### **Testing Production Builds** (Senior team members only)

```bash
# Only for testing production build process, not deployment
flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=production

# Note: This builds against production config but doesn't deploy
# Actual production deployment happens via GitHub Actions
```

### **Shared Development Data**

- **Firestore**: Shared collections for testing
- **Authentication**: Shared test user accounts
- **Storage**: Shared file storage for testing
- **Coordinate with team** before making structural changes

## 🔒 Security Guidelines for Team Members

### **Development Environment**

- ✅ Feel free to create/modify test data
- ✅ Test new features freely
- ✅ Reset collections if needed (coordinate with team)
- ⚠️ Don't share dev secrets outside the team

### **Production Environment** (if you have access)

- 🚨 **NEVER modify production data** unless explicitly authorized
- 🚨 **NEVER test experimental features** against production
- ✅ Read-only access for debugging and analysis
- ✅ Report any issues immediately to team lead

### **Secrets Management**

- 🔒 Keep `.env.local` secure on your machine (local development only)
- 🔒 Never commit secrets to version control
- 🔒 Don't share secrets via chat/email
- 🔒 Use secure file sharing if needed
- ℹ️ GitHub Actions uses repository secrets - you don't need to manage .env files for CI/CD

## 🆘 Troubleshooting

### **"Permission denied" accessing Firebase**

- Verify your Google account has been added to the Firebase project
- Check that you're authenticated with the correct Google account
- Contact team admin to verify your permissions

### **"Project not found" errors**

- Double-check the project IDs in your `.env.local`
- Ensure you have access to the specified Firebase projects
- Try re-authenticating: `gcloud auth login`

### **Secrets out of date**

- Team secrets may be rotated periodically
- Contact team admin for updated `.env.local`
- Check team chat/docs for secret rotation announcements

### **Conflicts with other team members**

- Coordinate Firestore structure changes
- Use separate subcollections for experimental features
- Communicate major changes in team channels

## 📞 Getting Help

### **For Access Issues:**

Contact your team admin to:

- Grant Firebase project access
- Provide updated secrets
- Add you to GitHub repository
- Assign appropriate role/permissions

### **For Development Issues:**

- Check team documentation/wiki
- Ask in team development channel
- Review existing GitHub issues
- Pair program with team members

### **For Production Issues:**

- **STOP** what you're doing
- **DON'T** attempt fixes on production
- **CONTACT** team lead/DevOps immediately
- **DOCUMENT** what you observed

## 🎉 You're Ready!

Once your setup is complete:

1. ✅ You can develop against shared Firebase projects
2. ✅ You can test with realistic data and user accounts
3. ✅ Your changes integrate with the team's work
4. ✅ You can collaborate effectively with other team members

Welcome to the team! 🚀

## 🔄 Ongoing Team Processes

### **Daily Standups**

- Report any Firebase issues or data conflicts
- Coordinate major schema changes
- Share testing plans that might affect shared data

### **Code Reviews**

- Firebase rules changes require senior approval
- Database schema changes need team discussion
- Production environment access changes need admin approval

### **Security Reviews**

- Quarterly secret rotation (admin managed)
- Regular access audits
- Immediate access revocation for departing team members