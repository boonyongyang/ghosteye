import 'package:go_router/go_router.dart';

import '../screens/launch_gate_screen.dart';
import '../screens/director_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const LaunchGateScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/director',
        builder: (context, state) => const DirectorScreen(),
      ),
    ],
  );
}

final appRouter = createAppRouter();
