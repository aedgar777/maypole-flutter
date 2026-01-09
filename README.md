# 🗺️ Maypole

**Place-based messaging for your community**

Maypole is a location-based social messaging platform that connects people through the places they care about. Whether it's your neighborhood park, favorite coffee shop, or local landmark, Maypole creates persistent chat rooms tied to real-world locations—turning physical spaces into digital communities.

---

## 🌟 What is Maypole?

Imagine walking into your favorite coffee shop and instantly being able to chat with everyone else who's ever been there. Or discussing the best running routes with fellow joggers at your local park. Maypole makes this possible by creating **location-anchored chat rooms** that anyone can discover and join.

### Key Features

- **📍 Location-Based Chat Rooms**: Every place can have its own persistent community chat (we call them "maypoles")
- **🔍 Place Discovery**: Search for any location using Google Places API and join or create its community
- **💬 Real-Time Messaging**: Text and image sharing with live updates
- **🖼️ Shared Galleries**: Each location has a photo gallery where community members can share images
- **👤 Direct Messaging**: Private conversations between users
- **🔔 Push Notifications**: Stay updated with community activity via Firebase Cloud Messaging
- **🎨 Modern UI/UX**: Beautiful, responsive design with dark theme
- **🔒 Privacy-First**: Control who can message you, block users, and manage your data

### User Experience Highlights

- **Discover Communities**: Find chat rooms for parks, restaurants, neighborhoods, events, and more
- **Share Experiences**: Post photos and messages about places you visit
- **Meet People**: Connect with others who share your local interests
- **Stay Connected**: Get notified when people chat at your favorite spots
- **Explore History**: Browse photo galleries to see how places evolve over time

---

## 🛠️ Technical Stack

### Mobile Application

**Framework & Language**
- **Flutter 3.8+** - Google's cross-platform UI toolkit
- **Dart SDK 3.8.0** - Modern, type-safe programming language
- **Target Platforms**: iOS, Android, macOS, Web

**Architecture & State Management**
- **Riverpod 3.0** - Modern reactive state management
- **Provider Pattern** - Clean dependency injection
- **Feature-Based Architecture** - Modular, scalable codebase organized by feature domains

**Firebase Integration**
- **Firebase Core 4.2** - Foundation for Firebase services
- **Firebase Auth 6.1** - User authentication and account management
- **Cloud Firestore 6.1** - Real-time NoSQL database with offline persistence
- **Firebase Storage 13.0** - Scalable cloud storage for images
- **Cloud Functions 6.0** - Serverless backend logic
- **Firebase Cloud Messaging 16.0** - Push notifications
- **Firebase Remote Config 6.1** - Feature flags and remote configuration

**Navigation & Routing**
- **GoRouter 17.0** - Declarative routing with deep linking support
- **Route-based Authentication Guards** - Automatic auth state management

**UI/UX Libraries**
- **Material Design 3** - Modern Google design system
- **Custom Theming** - Consistent dark theme across the app
- **Cached Network Image 3.4** - Optimized image loading and caching
- **Image Picker 1.0** - Native camera and gallery integration
- **Flutter Cache Manager 3.4** - Persistent image caching with 30-day retention

**External Services**
- **Google Places API** - Location search and place data
- **Google Mobile Ads 5.2** - AdMob integration for monetization

**Development Tools**
- **Flutter Lints 6.0** - Comprehensive code quality rules
- **Internationalization (i18n)** - Multi-language support infrastructure
- **Environment Variables** - Separate dev/prod configurations via dotenv

**Permissions & Native Features**
- **Permission Handler 11.3** - Runtime permissions management
- **Shared Preferences 2.3** - Local key-value storage
- **URL Launcher 6.3** - External link handling

### Backend Services

**Cloud Functions**
- **Python 3.x** - Python-based Firebase Functions for backend logic
- **Node.js** - JavaScript-based functions for additional services
- **Firebase Admin SDK** - Server-side Firebase operations

**Database Schema**
- **Firestore Collections**:
  - `maypoles`: Location-based chat threads
  - `messages`: Real-time messages with text and images
  - `users`: User profiles and authentication data
  - `DMThreads`: Private direct message conversations
  - `notifications`: Push notification management
- **Composite Indexes**: Optimized queries for message pagination
- **Security Rules**: Row-level security for data access control

**Storage**
- **Firebase Storage**: Hierarchical file organization for user-uploaded images
- **CORS Configuration**: Cross-origin resource sharing for web access
- **Cloud Storage Rules**: Secure file access policies

### Infrastructure & DevOps

**Version Control & CI/CD**
- **Git** - Version control with feature branch workflow
- **GitHub Actions** - Automated CI/CD pipelines
- **Fastlane** - iOS code signing and deployment automation
- **Fastlane Match** - Shared certificate management across team

**Build & Deployment**
- **Custom Build Scripts** - Automated builds for all platforms (iOS, Android, macOS, Web)
- **Multi-Environment Support** - Separate dev/staging/production environments
- **Automated Version Bumping** - Semantic versioning with auto-increment
- **TestFlight Integration** - iOS beta distribution
- **Play Store Integration** - Android deployment pipeline

**Testing**
- **Flutter Test** - Unit and widget testing framework
- **Mock Services** - Isolated testing with dependency injection
- **Test Coverage** - Comprehensive test suite for core features

**Configuration Management**
- **Firestore Rules** - Declarative security policies
- **Firestore Indexes** - Performance optimization
- **Environment-Specific Configs** - `.env` files for different environments
- **Deployment Scripts** - Automated rule and index deployment

**Native Platform Setup**
- **Android**: Gradle build system, Material 3 theming
- **iOS**: Xcode project with CocoaPods, Swift integration
- **macOS**: Native macOS app target
- **Web**: Progressive Web App (PWA) support

### Code Quality & Standards

- **Linting**: Comprehensive Dart analysis with custom rules
- **Type Safety**: Strong static typing throughout codebase
- **Documentation**: Inline documentation and architecture decision records
- **Clean Architecture**: Separation of data, domain, and presentation layers
- **SOLID Principles**: Maintainable, testable code structure

### Design Patterns

- **Repository Pattern**: Abstract data sources
- **Provider Pattern**: Dependency injection
- **MVVM Architecture**: Clear separation of concerns
- **Reactive Programming**: Stream-based data flow
- **Singleton Services**: Shared service instances
- **Factory Pattern**: Object creation abstraction

---

## 📁 Project Structure

```
maypole-flutter/
├── lib/
│   ├── core/                    # Shared infrastructure
│   │   ├── app_router.dart      # Navigation configuration
│   │   ├── app_theme.dart       # UI theming
│   │   ├── firebase_options.dart # Firebase configuration
│   │   └── services/            # Shared services
│   ├── features/                # Feature modules
│   │   ├── identity/            # Authentication & user profiles
│   │   ├── maypolechat/         # Location-based chat rooms
│   │   ├── maypolesearch/       # Place search & discovery
│   │   ├── directmessages/      # Private messaging
│   │   ├── settings/            # App settings & preferences
│   │   └── home/                # Main navigation hub
│   ├── l10n/                    # Internationalization
│   └── main.dart                # Application entry point
├── functions/                   # Python Firebase Functions
├── functions-js/                # Node.js Firebase Functions
├── android/                     # Android native code
├── ios/                         # iOS native code & Fastlane
├── macos/                       # macOS native code
├── web/                         # Web platform code
├── scripts/                     # Build automation scripts
├── test/                        # Unit and widget tests
├── assets/                      # Images, fonts, and resources
├── firestore.rules              # Database security rules
├── firestore.indexes.json       # Database indexes
└── firebase.json                # Firebase project config
```

---

## 🌐 Use Cases

### For Communities
- Neighborhood associations discussing local events
- Park enthusiasts sharing trail conditions
- Restaurant patrons reviewing dishes and sharing photos
- Event attendees connecting before, during, and after gatherings

### For Businesses
- Coffee shops building regular customer communities
- Gyms connecting members with similar workout schedules
- Retail stores engaging with local shoppers
- Tourist attractions facilitating visitor connections

### For Individuals
- Travelers finding local insights at destinations
- Remote workers discovering coworking spaces
- Pet owners meeting at dog parks
- Hobbyists finding local groups (photography spots, fishing holes, etc.)


---

## 🤝 Contributing

This is a private project, but contributions are welcome from team members. Please follow these guidelines:

1. Create a feature branch from `develop`
2. Follow the existing code style and architecture patterns
3. Write tests for new features
4. Update documentation as needed
5. Submit a pull request for review

---

## 📄 License

Copyright © 2026 Maypole. All rights reserved.

---

## 📞 Contact

For questions, support, or business inquiries:
- Email: info@maypole.app
- Website: [maypole.app](https://maypole.app)

---

## 🙏 Acknowledgments

Built with ❤️ using:
- [Flutter](https://flutter.dev) by Google
- [Firebase](https://firebase.google.com) by Google
- [Riverpod](https://riverpod.dev) by Remi Rousselet
- [GoRouter](https://pub.dev/packages/go_router) by the Flutter team

---

**Maypole** - *Where places become communities* 🗺️💬
