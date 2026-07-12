import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dark top bar with icon cluster (info/help/share/profile) — appears
/// identically at the top of every screen in the wireframe.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final bool showBack;

  const AppTopBar({super.key, this.onBack, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.topBar,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: preferredSize.height,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 18),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Container(width: 60, height: 2, color: Colors.white54),
            Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.white, size: 16),
                SizedBox(width: 10),
                Icon(Icons.help_outline, color: AppColors.white, size: 16),
                SizedBox(width: 10),
                Icon(Icons.share_outlined, color: AppColors.white, size: 16),
                SizedBox(width: 10),
                Icon(Icons.person_outline, color: AppColors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// Dark bottom nav bar (hamburger + minus line) — same across every screen.
class AppBottomBar extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const AppBottomBar({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bottomBar,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white, size: 20),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Container(width: 40, height: 2, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

/// Wraps a screen body with the standard top/bottom bars so screens
/// only need to supply their middle content.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;

  const AppScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(showBack: showBack, onBack: onBack),
      body: body,
      bottomNavigationBar: AppBottomBar(onMenuTap: onMenuTap),
    );
  }
}
