import 'package:maypole/features/identity/domain/domain_user.dart';

class AppSession {
  static final AppSession _instance = AppSession._internal();
  DomainUser? currentUser;

  factory AppSession() {
    return _instance;
  }

  AppSession._internal();
}