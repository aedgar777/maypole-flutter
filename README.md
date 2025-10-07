# Maypole

Place-based messaging app

Maypole is a place-based messaging app built with Flutter, Firebase, and the Google Places API. It
allows users to chat within threads attached to physical locations in Google Maps, and DM users they
meet there.

## 🚀 Quick Start for Team Members

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourorg/maypole-flutter.git
   cd maypole-flutter
   ```

2. **Get access from team admin**
   - Contact your team admin for repository access
   - Get Firebase project permissions added to your Google account
   - Receive team secrets via secure method

3. **Set up your local environment**
   ```bash
   ./setup.sh  # Creates template files
   ```

4. **Configure Firebase access**
   - See [Team Setup Guide](docs/contributors/firebase-setup-guide.md)
   - Get `.env.local` and `google-services.json` from team admin
   - Place files in correct locations

5. **Start developing**
   ```bash
   flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev
   ```

## 🏗️ Project Structure

- **Development Environment**: `maypole-flutter-dev` (shared by all team members)
- **Production Environment**: `maypole-flutter-ce6c3` (restricted access)
- **Supported Platforms**: Web, Android, iOS (planned), macOS, Windows

## 🔒 Security & Access Control

This project uses a **private team approach** with shared Firebase projects:

- ✅ **Shared development environment** for consistent testing
- ✅ **Role-based access control** (Developer/Senior/Admin)
- ✅ **Centralized secret management** via GitHub secrets
- ✅ **Production environment protection** with restricted access
- ✅ **Secure secret distribution** to team members

## 👥 Team Roles & Permissions

### **Developer** (Most Team Members)

- ✅ Access to development Firebase project
- ✅ Can modify development Firestore and test data
- ✅ Can test features against shared backend
- ❌ No production environment access

### **Senior Developer**

- ✅ Full development environment access
- ✅ Limited production read access for debugging
- ✅ Can review production analytics and logs
- ✅ Can test production builds locally

### **DevOps/Admin**

- ✅ Full access to both environments
- ✅ Manages team member Firebase permissions
- ✅ Handles secret rotation and distribution
- ✅ Deploys to production via GitHub Actions

## 📚 Documentation

- [Team Setup Guide](docs/contributors/firebase-setup-guide.md) - **Start here!**
- [SETUP.md](SETUP.md) - Detailed setup instructions and troubleshooting
- [Development Workflow](#development-workflow) - Daily development practices

## 🛠️ Development Workflow

### **Daily Development**

```bash
# Always develop against shared dev environment
flutter run --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev

# Coordinate with team before major schema changes
# Use shared test accounts and data
```

### **Testing & Building**

```bash
# Build for web (development)
flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev

# Build for Android (development)
flutter build apk --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=dev

# Production builds (senior team members only)
flutter build web --dart-define-from-file=.env.local --dart-define=ENVIRONMENT=production
```

### **Shared Resources**

- **Firestore**: Shared collections and documents for testing
- **Authentication**: Common test user accounts
- **Storage**: Shared file storage for development
- **Analytics**: Shared development analytics data

## 🤝 Contributing

### **New Team Members**

1. **Get access from team admin**
   - GitHub repository access
   - Firebase project permissions
   - Team secrets and configuration files

2. **Follow the setup guide**
   - Complete [Team Setup Guide](docs/contributors/firebase-setup-guide.md)
   - Verify you can build and run the project
   - Test against shared development environment

3. **Start contributing**
   ```bash
   git checkout -b feature-name
   # Make your changes
   # Test against shared dev Firebase
   git push origin feature-name
   # Create pull request
   ```

### **Team Coordination**

- 📢 **Communicate** major changes that affect shared data
- 🔄 **Coordinate** database schema modifications
- 🧪 **Test thoroughly** against shared development environment
- 📋 **Document** any new Firebase rules or configurations

### **Code Review Process**

- All pull requests require review
- Firebase configuration changes need admin approval
- Database schema changes require team discussion
- Production-related changes need senior developer review

## 🔐 Security Guidelines

### **For All Team Members**

- 🔒 Keep your `.env.local` file secure and never commit it
- 🔒 Don't share team secrets outside the organization
- 🔒 Use development environment for all testing
- 🔒 Report security issues immediately to team admin

### **For Senior Team Members**

- 🚨 Production access is for debugging only
- 🚨 Never test experimental features against production
- 🚨 Document any production data access
- 🚨 Follow incident response procedures

### **For Admins**

- 🔑 Rotate secrets regularly (quarterly)
- 🔑 Audit team member access monthly
- 🔑 Remove access immediately when team members leave
- 🔑 Monitor Firebase usage and costs

## 🆘 Getting Help

### **Setup Issues**

- Contact your team admin for access problems
- Check [Team Setup Guide](docs/contributors/firebase-setup-guide.md)
- Ask in team development channel

### **Development Questions**

- Review existing documentation and code
- Ask team members in development channel
- Schedule pair programming sessions
- Create GitHub issues for bugs

### **Production Issues**

- 🚨 **STOP** and contact team lead immediately
- 🚨 **DON'T** attempt fixes without approval
- 🚨 **DOCUMENT** what you observed
- 🚨 **FOLLOW** incident response procedures

## 📊 Team Benefits

### **Shared Development Environment**

- ✅ **Consistent data** across all team members
- ✅ **Realistic testing** with shared user accounts
- ✅ **Integrated testing** of concurrent features
- ✅ **Cost efficient** with single Firebase project

### **Secure Production**

- ✅ **Restricted access** to production environment
- ✅ **Automated deployments** via GitHub Actions
- ✅ **Audit trails** for all production changes
- ✅ **Role-based permissions** for different access levels

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Welcome to the Maypole development team!** 🎉  
Contact your team admin to get started with access and setup.
