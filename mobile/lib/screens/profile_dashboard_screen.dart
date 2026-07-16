import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_state.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  List<Review>? _reviews;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthState.instance.isLoggedIn) {
        context.go('/login');
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    try {
      final reviews = await ReviewService.getMyReviews();
      if (!mounted) return;
      setState(() => _reviews = reviews);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthState.instance.isLoggedIn) {
      return const AppScaffold(body: SizedBox.shrink());
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.grayLighter,
                    child: Icon(Icons.person, color: AppColors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AuthState.instance.username ?? '', style: AppTextStyles.heading),
                        Text(AuthState.instance.email ?? '', style: AppTextStyles.muted),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.grayMedium),
                    onPressed: _logout,
                    tooltip: 'Log out',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('My Reviews', style: AppTextStyles.subheading),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: AppTextStyles.muted.copyWith(color: Colors.red))
              else if (_reviews == null)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_reviews!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "You haven't written any reviews yet.",
                    style: AppTextStyles.muted,
                  ),
                )
              else
                for (final review in _reviews!)
                  GestureDetector(
                    onTap: () => context.push('/courses/${review.courseId}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.courseCode ?? review.courseTitle ?? 'Course',
                                  style: AppTextStyles.subheading,
                                ),
                                if (review.courseTitle != null)
                                  Text(review.courseTitle!, style: AppTextStyles.muted),
                              ],
                            ),
                          ),
                          Text('${review.quality}/5 ★', style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
