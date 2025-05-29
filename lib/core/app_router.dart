

import 'package:go_router/go_router.dart';

import '../features/identity/presentation/login_screen.dart';

final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
        GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
        ),

    ]

);

