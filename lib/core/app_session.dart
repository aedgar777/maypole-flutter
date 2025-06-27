import 'package:maypole/features/identity/data/domain_user.dart';

class AppSession {
  static final AppSession _instance = AppSession._internal();
  DomainUser? currentUser;

  factory AppSession() {
    return _instance;
  }

  AppSession._internal();
}