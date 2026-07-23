import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';
import '../theme/app_theme.dart';
import 'scroll_to_top_button.dart';

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

/// Top navigation bar: mirrors frontend/src/pages/components/TopBar.jsx —
/// back button (optional) + "KnightRate" brand on the leading side, and a
/// trailing icon row (theme toggle, Info→About, Help→FAQ, Bookmarks,
/// Account) on the right. The web's Courses icon is intentionally dropped
/// from this row: on mobile, Courses is already one tap away via the
/// bottom tab bar (see AppBottomTabBar), so repeating it here would be
/// redundant chrome the web doesn't need (it has no tab bar at all).
class AppTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final bool transparent;
  final bool showInfoIcon;
  final bool showHelpIcon;
  final bool showBookmarksIcon;
  final bool showAccountIcon;

  const AppTopBar({
    super.key,
    this.onBack,
    this.showBack = false,
    this.transparent = false,
    this.showInfoIcon = true,
    this.showHelpIcon = true,
    this.showBookmarksIcon = true,
    this.showAccountIcon = false,
  });

  static const double contentHeight = 64;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bar = Padding(
      padding: EdgeInsets.only(top: topInset, left: 20, right: 12),
      child: SizedBox(
        height: contentHeight,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
                onPressed: onBack,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            SizedBox(width: showBack ? 4 : 0),
            Text(
              'KnightRate',
              style: AppTextStyles.button.copyWith(
                color: ThemeColors.primary(context),
                fontWeight: AppFontWeights.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            const _ThemeToggleButton(),
            if (showInfoIcon) _TopBarIcon(icon: Icons.info_outline, tooltip: 'Info', onTap: () => context.push('/about')),
            if (showHelpIcon) _TopBarIcon(icon: Icons.help_outline, tooltip: 'Help', onTap: () => context.push('/faq')),
            if (showBookmarksIcon)
              _TopBarIcon(
                icon: Icons.bookmark_border,
                tooltip: 'Bookmarks',
                onTap: () => context.push(AuthState.instance.isLoggedIn ? '/bookmarks' : '/login'),
              ),
            if (showAccountIcon)
              _TopBarIcon(
                icon: Icons.person_outline,
                tooltip: 'Account',
                onTap: () => context.push(AuthState.instance.isLoggedIn ? '/dashboard' : '/login'),
              ),
          ],
        ),
      ),
    );

    if (!transparent) {
      return ColoredBox(color: AppColors.topBar, child: bar);
    }
    return _GlassSurface(tint: AppColors.topBar.withValues(alpha: 0.6), child: bar);
  }
}

class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: AppColors.white, size: 24),
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }
}

/// Moon in light mode (tap to go dark), sun in dark mode (tap to go light) —
/// exactly ThemeToggle.jsx's behavior.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        return IconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          icon: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            color: AppColors.white,
            size: 24,
          ),
          onPressed: () => ThemeController.instance.toggle(),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        );
      },
    );
  }
}

/// Bottom tab bar: Home / Courses / Account. Per Apple HIG, tab bars are
/// for flat top-level navigation between a small number of peer sections
/// that must stay reachable — that's exactly these three; everything else
/// (About/FAQ/Bookmarks/course detail/etc.) is hierarchical drill-down and
/// belongs in the navigation bar (see AppTopBar) or a pushed route instead.
/// Purely presentational — MainShell owns the actual branch-switching logic.
class AppBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomTabBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      tint: AppColors.bottomBar.withValues(alpha: 0.78),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              _TabButton(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _TabButton(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Courses',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _TabButton(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Account',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
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
    // Accent follows the active skin: gold in light, blue in dark —
    // matching the web's --color-primary swap.
    final color = selected ? ThemeColors.primary(context) : Colors.white70;
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

/// Wraps a screen body with the standard navigation bar so screens only
/// need to supply their middle content. Any page-specific heading (e.g.
/// "Your Bookmarks", a course code) lives inside `body` now, matching the
/// web — TopBar.jsx never shows a page title, only the constant "KnightRate"
/// brand next to the back button.
///
/// `floating: true` overlays the bar on top of `body` (for hero screens
/// like Home/About where the bar is meant to sit transparently over a
/// full-bleed image) instead of pushing `body` down in normal flow.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final bool transparent;
  final bool floating;
  final bool showInfoIcon;
  final bool showHelpIcon;
  final bool showBookmarksIcon;
  final bool showAccountIcon;

  const AppScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.transparent = false,
    this.floating = false,
    this.showInfoIcon = true,
    this.showHelpIcon = true,
    this.showBookmarksIcon = true,
    this.showAccountIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final topBar = AppTopBar(
      showBack: showBack,
      onBack: onBack,
      transparent: transparent,
      showInfoIcon: showInfoIcon,
      showHelpIcon: showHelpIcon,
      showBookmarksIcon: showBookmarksIcon,
      showAccountIcon: showAccountIcon,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: floating
            ? Stack(
                children: [
                  Positioned.fill(child: ScrollToTopOverlay(child: body)),
                  Positioned(top: 0, left: 0, right: 0, child: topBar),
                ],
              )
            : Column(
                children: [topBar, Expanded(child: ScrollToTopOverlay(child: body))],
              ),
      ),
    );
  }
}
