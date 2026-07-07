import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/homepage_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_dashboard_screen.dart';

void main() {
  runApp(const KnightRateApp());
}

/// go_router works cleanly across mobile AND web (proper URL paths like
/// /login, /register, browser back/forward support) which the plain
/// Navigator API doesn't give you for free on web.
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomepageScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/email-auth', builder: (context, state) => const EmailAuthScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => const ProfileDashboardScreen()),
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
