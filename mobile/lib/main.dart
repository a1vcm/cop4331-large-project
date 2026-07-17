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
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restores a persisted login session before the first frame, so a
  // relaunch doesn't bounce a logged-in user back to the homepage.
  await AuthState.instance.loadFromDisk();
  runApp(const KnightRateApp());
}

final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'account');

/// A gentle crossfade instead of the platform-default slide-from-right, used
/// for every route so navigating never feels like a jarring swipe. Tab
/// switches (Home/Search/Account) don't go through this at all — they're an
/// instant IndexedStack swap via StatefulShellRoute, with no transition and
/// no rebuild of the persistent top/bottom chrome.
CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// go_router works cleanly across mobile AND web (proper URL paths like
/// /login, /register, browser back/forward support) which the plain
/// Navigator API doesn't give you for free on web.
final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthState.instance,
  routes: [
    GoRoute(path: '/register', pageBuilder: (context, state) => _fadePage(const RegisterScreen())),
    GoRoute(
      path: '/email-auth',
      pageBuilder: (context, state) => _fadePage(EmailAuthScreen(email: state.extra as String? ?? '')),
    ),
    GoRoute(path: '/login', pageBuilder: (context, state) => _fadePage(const LoginScreen())),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _fadePage(const ForgotPasswordScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(path: '/', pageBuilder: (context, state) => _fadePage(const HomepageScreen())),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _searchNavigatorKey,
          routes: [
            GoRoute(
              path: '/courses',
              pageBuilder: (context, state) =>
                  _fadePage(CourseSearchScreen(initialQuery: state.uri.queryParameters['q'])),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) =>
                      _fadePage(CourseDetailScreen(courseId: state.pathParameters['id']!)),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _accountNavigatorKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => _fadePage(const ProfileDashboardScreen()),
            ),
          ],
        ),
      ],
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
