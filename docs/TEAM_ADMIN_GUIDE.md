# Team Admin Guide - Managing Private Project Access

This guide helps team admins manage access, secrets, and permissions for the Maypole private team
project.

## 🎯 Your Responsibilities as Team Admin

- ✅ **Manage GitHub repository access** and permissions
- ✅ **Control Firebase project access** for team members
- ✅ **Distribute team secrets** securely to team members
- ✅ **Monitor and rotate secrets** regularly
- ✅ **Onboard new team members** and offboard departing ones

## 🚀 New Team Member Onboarding

### Step 1: GitHub Repository Access

1. **Add to GitHub repository:**
   ```bash
   # Go to your GitHub repository
   # Settings → Manage access → Invite a collaborator
   # Add their GitHub username with appropriate role:
   # - Write: For most developers
   # - Admin: For senior developers/DevOps
   ```

2. **Set up GitHub environment permissions** (if using environment secrets):
   ```bash
   # Settings → Environments → development
   # Add the team member to reviewers (if needed)
   
   # Settings → Environments → production  
   # Only add senior team members here
   ```

### Step 2: Firebase Project Access

1. **Add to development Firebase project:**
   ```bash
   # Go to Firebase Console → maypole-flutter-dev
   # Settings → Users and permissions
   # Add their Google account email with role:
   # - Editor: For most developers (can modify Firestore, test data)
   # - Viewer: For read-only access (if needed)
   ```

2. **Add to production Firebase project** (senior members only):
   ```bash
   # Go to Firebase Console → maypole-flutter-ce6c3  
   # Settings → Users and permissions
   # Add their Google account email with role:
   # - Viewer: For debugging and analytics access
   # - Editor: Only for DevOps/senior developers
   ```

### Step 3: Distribute Team Secrets

Choose one of these methods to securely share configuration:

#### **Method A: Direct File Sharing** (Recommended for small teams)

1. **Create a secure package for the new team member:**
   ```bash
   # Create a temporary secure folder
   mkdir temp-onboarding-TEAMMEMBER-NAME
   
   # Copy the team configuration files
   cp .env.local temp-onboarding-TEAMMEMBER-NAME/
   cp android/app/google-services.json temp-onboarding-TEAMMEMBER-NAME/
   cp ios/Runner/GoogleService-Info.plist temp-onboarding-TEAMMEMBER-NAME/ # if exists
   
   # Create instructions file
   echo "Place these files in your project root:
   - .env.local → project root
   - google-services.json → android/app/
   - GoogleService-Info.plist → ios/Runner/ (if doing iOS dev)
   
   Then run: flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev" > temp-onboarding-TEAMMEMBER-NAME/INSTRUCTIONS.txt
   ```

2. **Share securely:**
    - **Option 1**: Encrypted ZIP via secure file sharing (1Password, Bitwarden)
    - **Option 2**: Hand delivery on encrypted USB drive
    - **Option 3**: Secure messaging platform (Signal, encrypted Slack DM)
    - **❌ Never**: Email, regular Slack, or unencrypted methods

3. **Clean up:**
   ```bash
   # After team member confirms receipt and setup
   rm -rf temp-onboarding-TEAMMEMBER-NAME
   ```

#### **Method B: Google Secret Manager** (Enterprise approach)

1. **Set up centralized secret management:**
   ```bash
   # Create a dedicated secrets project (one-time setup)
   gcloud projects create maypole-secrets-$(date +%s)
   gcloud config set project maypole-secrets-PROJECT_ID
   gcloud services enable secretmanager.googleapis.com
   
   # Store team secrets
   gcloud secrets create firebase-dev-config --data-file=.env.local
   gcloud secrets create firebase-prod-config --data-file=.env.production # if exists
   ```

2. **Grant team member access:**
   ```bash
   # Development secrets (all team members)
   gcloud secrets add-iam-policy-binding firebase-dev-config \
     --member='user:teammember@company.com' \
     --role='roles/secretmanager.secretAccessor'
   
   # Production secrets (senior members only)
   gcloud secrets add-iam-policy-binding firebase-prod-config \
     --member='user:senior-dev@company.com' \
     --role='roles/secretmanager.secretAccessor'
   ```

3. **Provide team member with instructions:**
   ```bash
   # Send them this command to retrieve secrets:
   gcloud auth login
   gcloud config set project maypole-secrets-PROJECT_ID
   gcloud secrets versions access latest --secret="firebase-dev-config" > .env.local
   ```

## 🔄 Regular Admin Tasks

### Monthly Access Audit

1. **Review GitHub repository access:**
   ```bash
   # Settings → Manage access
   # Verify all team members still need access
   # Check for any unused or suspicious accounts
   ```

2. **Review Firebase project permissions:**
   ```bash
   # Firebase Console → Settings → Users and permissions
   # Verify team members still need their current access levels
   # Remove any unused accounts
   ```

3. **Check secret access logs** (if using Google Secret Manager):
   ```bash
   gcloud logging read "resource.type=gce_instance AND logName=projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Fdata_access" --limit=50 --format="table(timestamp,resource.labels.instance_id,protoPayload.authenticationInfo.principalEmail)"
   ```

### Quarterly Secret Rotation

1. **Rotate Firebase API keys:**
   ```bash
   # Firebase Console → Project Settings → Service accounts
   # Generate new private keys
   # Update GitHub repository secrets
   # Update .env.local template
   # Notify team of new secrets
   ```

2. **Update team configurations:**
   ```bash
   # Update your local .env.local with new values
   # Redistribute to team members via secure method
   # Update Google Secret Manager (if using)
   ```

3. **Test rotation:**
   ```bash
   # Verify GitHub Actions still work with new secrets
   # Test local development with new configuration
   # Confirm team members can still access Firebase
   ```

## 👋 Team Member Offboarding

### Immediate Actions (within 1 hour of departure)

1. **Remove GitHub access:**
   ```bash
   # Settings → Manage access → Remove team member
   # Check for any personal access tokens that need revocation
   ```

2. **Remove Firebase access:**
   ```bash
   # Firebase Console → maypole-flutter-dev → Settings → Users and permissions
   # Remove the departing team member
   
   # Firebase Console → maypole-flutter-ce6c3 → Settings → Users and permissions  
   # Remove the departing team member
   ```

3. **Revoke Google Secret Manager access** (if using):
   ```bash
   gcloud secrets remove-iam-policy-binding firebase-dev-config \
     --member='user:former-member@company.com' \
     --role='roles/secretmanager.secretAccessor'
     
   gcloud secrets remove-iam-policy-binding firebase-prod-config \
     --member='user:former-member@company.com' \
     --role='roles/secretmanager.secretAccessor'
   ```

### Within 24 Hours

1. **Review access logs:**
   ```bash
   # Check what the departing team member accessed recently
   # Look for any unusual activity or data access
   # Document any concerns for security review
   ```

2. **Consider secret rotation:**
   ```bash
   # If the team member had production access or was senior developer
   # Consider rotating production secrets as precaution
   # Update team with new configuration if needed
   ```

## 🔐 Security Best Practices

### Secret Distribution

- ✅ **Use encrypted channels** for sharing secrets
- ✅ **Verify recipient identity** before sharing
- ✅ **Use time-limited access** when possible
- ✅ **Document who has what access** and when
- ❌ **Never share via email, Slack, or unencrypted methods**

### Access Management

- ✅ **Principle of least privilege** - only give necessary access
- ✅ **Regular access reviews** - monthly audits
- ✅ **Separate dev/prod access** - different permission levels
- ✅ **Monitor access logs** - watch for unusual activity

### Incident Response

1. **Suspected secret compromise:**
   ```bash
   # Immediately rotate all affected secrets
   # Revoke access for suspected compromised accounts
   # Update GitHub secrets and redistribute team config
   # Document incident and lessons learned
   ```

2. **Unauthorized access detected:**
   ```bash
   # Lock down Firebase projects (restrict to admins only)
   # Investigate scope of unauthorized access
   # Rotate all secrets as precaution
   # Review and strengthen access controls
   ```

## 📊 Team Management Tools

### GitHub Repository Settings

- **Branch protection rules**: Require reviews for main branches
- **Environment protection**: Restrict production deployments
- **Secret scanning**: Enable to detect accidentally committed secrets
- **Dependency scanning**: Monitor for security vulnerabilities

### Firebase Project Management

- **Budget alerts**: Monitor usage and costs
- **Performance monitoring**: Track app performance
- **Crashlytics**: Monitor app crashes and issues
- **Security rules**: Regular review and updates

### Documentation Management

- **Keep team setup guide updated** with current processes
- **Document any custom configurations** or workarounds
- **Maintain emergency contact information** for team members
- **Regular backup** of important configurations

## 🆘 Emergency Procedures

### Production Incident

1. **Assess impact** and gather team leads
2. **Communicate to stakeholders** about status
3. **Follow incident response plan** with proper roles
4. **Document everything** for post-incident review

### Security Incident

1. **Immediately secure** all access points
2. **Revoke compromised credentials** across all systems
3. **Notify security team** and stakeholders
4. **Conduct thorough investigation** and remediation

### Team Lead Unavailable

1. **Ensure backup admin** has all necessary access
2. **Document emergency procedures** and contacts
3. **Cross-train team members** on critical processes
4. **Maintain updated contact information** for all team members

## 📞 Support Resources

### For Team Members

- **Setup issues**: Direct them to team setup guide
- **Access problems**: Check Firebase/GitHub permissions
- **Development questions**: Connect with senior team members
- **Security concerns**: Direct to you immediately

### For You (Admin)

- **GitHub support**: GitHub Enterprise support (if applicable)
- **Firebase support**: Google Cloud support
- **Security incidents**: Company security team
- **Legal/compliance**: Company legal team

Remember: Your role is critical for team security and productivity. When in doubt, err on the side
of caution and restrict access rather than over-permitting.