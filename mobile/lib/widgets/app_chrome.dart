import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';
import '../theme/app_theme.dart';

/// The app's three primary destinations, shown as a persistent bottom tab
/// bar (standard iOS UITabBar pattern) rather than a hamburger menu.
enum AppTab { home, search, account }

/// A frosted, translucent surface approximating iOS's "Liquid Glass"
/// material. Flutter has no access to Apple's native glass renderer (that's
/// a SwiftUI/UIKit-only API), so this is a BackdropFilter blur over a
/// semi-transparent tint — a reasonable visual approximation, not the real
/// thing. Used only for the top/bottom chrome, not buttons or cards
/// throughout, since blurring everything hurts legibility more than it helps.
class _GlassSurface extends StatelessWidget {
  final Widget child;
  final Color tint;

  const _GlassSurface({required this.child, required this.tint});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            border: const Border(
              // A hairline edge highlight is a big part of what reads as
              // "glass" rather than plain frosted plastic.
              top: BorderSide(color: Colors.white24, width: 0.5),
              bottom: BorderSide(color: Colors.white24, width: 0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Top bar: back button (or app/page title), extended up through the status
/// bar / Dynamic Island so there's no color mismatch up there. AppScaffold
/// pairs this with a light SystemUiOverlayStyle so the system's time/battery
/// icons render in white and stay visible against the dark glass.
class AppTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final String? title;

  const AppTopBar({super.key, this.onBack, this.showBack = false, this.title});

  static const double contentHeight = 48;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return _GlassSurface(
      tint: AppColors.topBar.withValues(alpha: 0.78),
      child: Padding(
        padding: EdgeInsets.only(top: topInset, left: 12, right: 12),
        child: SizedBox(
          height: contentHeight,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              SizedBox(width: showBack ? 8 : 0),
              Expanded(
                child: Text(
                  title ?? 'KnightRate',
                  style: AppTextStyles.button,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom tab bar: Home / Search / Account, the standard 3-destination
/// iOS UITabBar shape. Account routes straight to login when signed out;
/// logout itself lives only on the account/dashboard screen, not in a menu.
class AppBottomTabBar extends StatelessWidget {
  final AppTab current;

  const AppBottomTabBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      tint: AppColors.bottomBar.withValues(alpha: 0.78),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ListenableBuilder(
            listenable: AuthState.instance,
            builder: (context, _) {
              return Row(
                children: [
                  _TabButton(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    selected: current == AppTab.home,
                    onTap: () => context.go('/'),
                  ),
                  _TabButton(
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                    label: 'Search',
                    selected: current == AppTab.search,
                    onTap: () => context.go('/courses'),
                  ),
                  _TabButton(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Account',
                    selected: current == AppTab.account,
                    onTap: () => context.go(AuthState.instance.isLoggedIn ? '/dashboard' : '/login'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : Colors.white70;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.muted.copyWith(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Wraps a screen body with the standard top bar so screens only need to
/// supply their middle content (and optionally a title/back action). Pass
/// [currentTab] on the three tab-root screens (Home/Search/Account) to show
/// the bottom tab bar; leave it null for pushed detail screens or full-screen
/// flows (auth) that shouldn't show it — except CourseDetailScreen, which
/// passes AppTab.search anyway to keep the tab bar visible on drill-down,
/// matching standard iOS behavior of pushed screens staying inside their tab.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final String? title;
  final AppTab? currentTab;

  const AppScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.title,
    this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            AppTopBar(showBack: showBack, onBack: onBack, title: title),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: currentTab != null ? AppBottomTabBar(current: currentTab!) : null,
      ),
    );
  }
}
