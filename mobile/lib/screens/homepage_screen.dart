import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

class HomepageScreen extends StatelessWidget {
  const HomepageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
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
              style: AppTextStyles.body,
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
                  Text('Welcome back!', style: AppTextStyles.subheading),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
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
          ],
        ),
      ),
    );
  }
}
