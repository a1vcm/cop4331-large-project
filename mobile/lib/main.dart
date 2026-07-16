import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/homepage_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_dashboard_screen.dart';
import 'screens/course_search_screen.dart';
import 'screens/course_detail_screen.dart';
import 'services/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restores a persisted login session before the first frame, so a
  // relaunch doesn't bounce a logged-in user back to the homepage.
  await AuthState.instance.loadFromDisk();
  runApp(const KnightRateApp());
}

/// go_router works cleanly across mobile AND web (proper URL paths like
/// /login, /register, browser back/forward support) which the plain
/// Navigator API doesn't give you for free on web.
final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthState.instance,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomepageScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/email-auth',
      builder: (context, state) => EmailAuthScreen(email: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => const ProfileDashboardScreen()),
    GoRoute(path: '/courses', builder: (context, state) => CourseSearchScreen(initialQuery: state.uri.queryParameters['q'])),
    GoRoute(
      path: '/courses/:id',
      builder: (context, state) => CourseDetailScreen(courseId: state.pathParameters['id']!),
    ),
  ],
);

class KnightRateApp extends StatelessWidget {
  const KnightRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KnightRate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}
