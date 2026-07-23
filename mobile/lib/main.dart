import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/homepage_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_dashboard_screen.dart';
import 'screens/course_search_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/about_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/write_review_screen.dart';
import 'models/review.dart';
import 'services/auth_state.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restores a persisted login session before the first frame, so a
  // relaunch doesn't bounce a logged-in user back to the homepage.
  await AuthState.instance.loadFromDisk();
  // Restores the saved light/dark choice (mirrors ThemeToggle.jsx +
  // localStorage on the web).
  await ThemeController.instance.loadFromDisk();
  runApp(const KnightRateApp());
}

final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'account');

/// Platform-native page transition. Unlike a hand-built CustomTransitionPage,
/// MaterialPage delegates to ThemeData.pageTransitionsTheme, which Flutter
/// maps to CupertinoPageTransitionsBuilder on iOS/macOS by default — that's
/// what supplies both the native slide-from-right animation AND the
/// interactive edge-swipe-to-pop gesture users expect on iOS. A custom
/// FadeTransition page bypasses that entirely, silently losing swipe-back
/// everywhere. Tab switches (Home/Search/Account) don't go through this at
/// all — they're an instant IndexedStack swap via StatefulShellRoute, with
/// no transition and no rebuild of the persistent top/bottom chrome.
MaterialPage<void> _iosPage(GoRouterState state, Widget child) {
  return MaterialPage<void>(key: state.pageKey, child: child);
}

/// go_router works cleanly across mobile AND web (proper URL paths like
/// /login, /register, browser back/forward support) which the plain
/// Navigator API doesn't give you for free on web.
final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthState.instance,
  routes: [
    // Mirrors AuthPage.jsx: one screen, Login/Register are a tab switch
    // inside it (not separate pages) — both routes point at the same
    // screen with a different initial tab.
    GoRoute(path: '/register', pageBuilder: (context, state) => _iosPage(state, const AuthScreen(initialRegister: true))),
    GoRoute(path: '/login', pageBuilder: (context, state) => _iosPage(state, const AuthScreen())),
    GoRoute(
      path: '/bookmarks',
      pageBuilder: (context, state) => _iosPage(state, const BookmarksScreen()),
    ),
    GoRoute(path: '/about', pageBuilder: (context, state) => _iosPage(state, const AboutScreen())),
    GoRoute(path: '/faq', pageBuilder: (context, state) => _iosPage(state, const FaqScreen())),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(path: '/', pageBuilder: (context, state) => _iosPage(state, const HomepageScreen())),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _searchNavigatorKey,
          routes: [
            GoRoute(
              path: '/courses',
              pageBuilder: (context, state) =>
                  _iosPage(state, CourseSearchScreen(initialQuery: state.uri.queryParameters['q'])),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) =>
                      _iosPage(state, CourseDetailScreen(courseId: state.pathParameters['id']!)),
                  routes: [
                    GoRoute(
                      path: 'resources',
                      pageBuilder: (context, state) =>
                          _iosPage(state, ResourcesScreen(courseId: state.pathParameters['id']!)),
                    ),
                    GoRoute(
                      path: 'write-review',
                      pageBuilder: (context, state) => _iosPage(
                        state,
                        WriteReviewScreen(courseId: state.pathParameters['id']!, existing: state.extra as Review?),
                      ),
                    ),
                  ],
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
              pageBuilder: (context, state) => _iosPage(state, const ProfileDashboardScreen()),
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
    // Rebuilds on theme toggle so the whole app flips skin instantly.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'KnightRate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.mode,
          routerConfig: _router,
        );
      },
    );
  }
}
