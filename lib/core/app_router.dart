import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import '../features/chat/presentation/place_search_screen.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
import '../features/chat/presentation/home_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(
          path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => PlaceSearchScreen(
          googleApiKey: AppConfig.googlePlacesApiKey,
        ),
      ),
    ],
  );
}
