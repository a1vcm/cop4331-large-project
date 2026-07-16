import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

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
/// iOS UITabBar shape. Purely presentational — MainShell owns the actual
/// branch-switching logic (see widgets/main_shell.dart).
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
                label: 'Search',
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
/// supply their middle content (and optionally a title/back action). The
/// bottom tab bar is no longer part of this — it's owned by MainShell and
/// automatically stays visible for every screen inside the tab shell
/// (including pushed detail screens), and automatically absent for
/// full-screen flows like auth that live outside the shell entirely.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final String? title;

  const AppScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.title,
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
      ),
    );
  }
}
