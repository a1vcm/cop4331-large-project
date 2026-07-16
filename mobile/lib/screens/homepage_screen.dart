import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String q) {
    context.push(q.isEmpty ? '/courses' : '/courses?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.home,
      body: ListenableBuilder(
        listenable: AuthState.instance,
        builder: (context, _) {
          final loggedIn = AuthState.instance.isLoggedIn;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PlaceholderBox(width: 60, height: 60),
                const SizedBox(height: 16),
                Text('Find & Review Your Classes', style: AppTextStyles.heading),
                const SizedBox(height: 6),
                Text(
                  'Search courses, professors, and student reviews.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  style: AppTextStyles.body,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: 'Search classes or professors',
                    prefixIcon: const Icon(Icons.search, color: AppColors.grayLight),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      // Mascot / brand placeholder — swap with your actual logo asset.
                      Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.goldDark),
                      const SizedBox(height: 12),
                      Text(
                        loggedIn ? 'Welcome back, ${AuthState.instance.username}!' : 'Welcome!',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => context.push(loggedIn ? '/dashboard' : '/login'),
                        child: Text(loggedIn ? 'My Dashboard' : 'Log In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text('Browse', style: AppTextStyles.subheading),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/courses'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: const PlaceholderBox(height: 70, icon: Icons.school_outlined),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
