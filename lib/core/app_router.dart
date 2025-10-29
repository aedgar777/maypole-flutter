import 'package:go_router/go_router.dart';
import '../features/identity/presentation/login_screen.dart';
import '../features/identity/presentation/registration_screen.dart';
import '../features/chat/presentation/chatlist_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ChatListScreen(),
    ),
  ],
);
