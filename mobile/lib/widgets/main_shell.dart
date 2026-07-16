import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';
import 'app_chrome.dart';

/// The persistent chrome around the app's three tab destinations. The
/// bottom tab bar lives here, outside every page transition, so switching
/// tabs never rebuilds or animates it — StatefulShellRoute swaps the body
/// (`navigationShell`) instantly via an IndexedStack, with no slide.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTabTap(BuildContext context, int index) {
    // The account tab has nothing to show while signed out; push (not
    // goBranch) so the back gesture returns to wherever they tapped from.
    if (index == 2 && !AuthState.instance.isLoggedIn) {
      context.push('/login');
      return;
    }
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomTabBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTabTap(context, index),
        ),
      ),
    );
  }
}
