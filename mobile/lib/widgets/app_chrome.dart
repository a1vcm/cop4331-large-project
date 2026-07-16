import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/auth_state.dart';
import '../theme/app_theme.dart';

/// Dark top bar with icon cluster (info/help/share/profile). Its background
/// extends up through the status bar / Dynamic Island (rather than stopping
/// below it) so there's no mismatched white gap up there, and the screen's
/// SystemUiOverlayStyle is set to light content so the system's time/battery
/// icons render in white and stay visible against the dark bar.
class AppTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final String? title;

  const AppTopBar({super.key, this.onBack, this.showBack = false, this.title});

  static const double contentHeight = 48;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: AppColors.topBar,
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
            const SizedBox(width: 8),
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
}

/// Dark bottom bar with a menu button that opens the app's primary
/// navigation as a bottom sheet — the standard iOS pattern for a
/// menu-triggered action sheet anchored near where it was tapped.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key});

  void _openNavMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Courses'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/courses');
              },
            ),
            ListenableBuilder(
              listenable: AuthState.instance,
              builder: (context, _) {
                if (!AuthState.instance.isLoggedIn) {
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Log In'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/login');
                    },
                  );
                }
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('My Dashboard'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.push('/dashboard');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Log Out'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await AuthService.logout();
                        if (context.mounted) context.go('/');
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bottomBar,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white, size: 20),
              onPressed: () => _openNavMenu(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a screen body with the standard top/bottom bars so screens only
/// need to supply their middle content (and optionally a title/back action).
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
        bottomNavigationBar: const AppBottomBar(),
      ),
    );
  }
}
