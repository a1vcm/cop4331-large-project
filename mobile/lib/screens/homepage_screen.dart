import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/course_search_field.dart';
import '../widgets/footer.dart';

/// Mirrors frontend/src/pages/Homepage.jsx exactly: a normal-flow (not
/// fixed-height) hero banner under a transparent fixed TopBar, an intro
/// section, a "Trending Classes This Week" 2-column card grid, and a
/// Footer — the page just scrolls, there's no expandable panel.
class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final _searchController = TextEditingController();
  List<Course> _popularCourses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await CourseService.getCourses(null, 'recent');
      if (!mounted) return;
      setState(() => _popularCourses = courses.take(4).toList());
    } catch (_) {
      // Mirrors Homepage.jsx: silently fall back to an empty cards row.
      if (mounted) setState(() => _popularCourses = []);
    }
  }

  void _search(String q) {
    context.push(q.isEmpty ? '/courses' : '/courses?q=${Uri.encodeQueryComponent(q)}');
  }

  void _goToCourse(Course course) => context.push('/courses/${course.id}');

  @override
  Widget build(BuildContext context) {
    // Register a Theme dependency so every text style in this screen
    // repaints the moment the light/dark toggle fires.
    Theme.of(context);

    return AppScaffold(
      transparent: true,
      floating: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Hero: campus photo + dark scrim, mirrors .hero ---
            Stack(
              children: [
                SizedBox(
                  height: 560,
                  child: Image.asset('assets/images/homepage_hero_bg.png', fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/ucf_wordmark.png', height: 36),
                            const SizedBox(height: 12),
                            Text(
                              'KNIGHTRATE',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display.copyWith(
                                color: AppColors.white,
                                fontSize: 32,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Real ratings from real students, all in one place. Browse honest reviews '
                              'on classes and gauge valuable resources before you commit.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.85), fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            CourseSearchField(
                              controller: _searchController,
                              onSubmitted: _search,
                              onSelectCourse: _goToCourse,
                              hintText: 'Search classes...',
                              pillStyle: true,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HeroLink(label: 'Browse Categories', onTap: () => context.push('/courses')),
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
                                ),
                                _HeroLink(
                                  label: 'How It Works',
                                  onTap: () {
                                    // Mirrors scrollToHowItWorks(); there's
                                    // no in-page anchor on mobile, so this
                                    // is a no-op scroll cue instead.
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- Intro row, mirrors .intro ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/ucf_logo.png', width: 90, height: 90, fit: BoxFit.contain),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Made for Knights, by Knights', style: AppTextStyles.subheading.copyWith(fontSize: 17)),
                        const SizedBox(height: 6),
                        Text(
                          "KnightRate started as a student project to help our own campus community make "
                          "better decisions. Every review, rating, and recommendation comes from someone "
                          "who's actually been there.",
                          style: AppTextStyles.muted.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('Trending Classes This Week', style: AppTextStyles.heading.copyWith(fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: _popularCourses.isEmpty
                  ? Text('Loading classes…', style: AppTextStyles.muted)
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      children: [for (final course in _popularCourses) _CourseCard(course: course, onTap: () => _goToCourse(course))],
                    ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

class _HeroLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeroLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: AppTextStyles.muted.copyWith(color: AppColors.white, fontWeight: AppFontWeights.medium, fontSize: 13),
        ),
      ),
    );
  }
}

/// One trending-class card: gold/blue course code over the title, mirrors
/// .card/.card-code/.card-title in Homepage.css.
class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ThemeColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeColors.border(context), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              course.courseCode,
              style: AppTextStyles.muted.copyWith(
                color: isDark ? AppPalette.goldLight : AppPalette.goldDark,
                fontWeight: AppFontWeights.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.muted.copyWith(color: ThemeColors.text(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
