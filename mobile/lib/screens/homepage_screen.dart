import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

/// Mirrors frontend/src/pages/Homepage.jsx: a full-bleed campus hero with a
/// dark scrim, centered "Welcome to KnightRate!" title, a pill search bar,
/// and an expandable bottom panel (pull-handle arrow) containing the intro
/// blurb and a Browse Classes card grid.
class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final _searchController = TextEditingController();
  bool _isExpanded = false;
  List<Course> _popularCourses = [];

  static const _collapsedPanelHeight = 56.0;

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
      final courses = await CourseService.getCourses();
      if (!mounted) return;
      setState(() => _popularCourses = courses.take(4).toList());
    } catch (_) {
      // Mirrors Homepage.jsx: silently fall back to an empty cards row.
      if (mounted) setState(() => _popularCourses = []);
    }
  }

  void _search(String q) {
    context.go(q.isEmpty ? '/courses' : '/courses?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    // Register a Theme dependency so every text style in this screen
    // repaints the moment the light/dark toggle fires.
    Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final expandedPanelHeight = (screenHeight * 0.55).clamp(320.0, 480.0);

    return AppScaffold(
      body: Stack(
        children: [
          // --- Hero: campus photo + dark scrim, mirrors .hero/.hero::before ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/homepage_hero_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
          ),

          // --- Centered title + pill search, mirrors .hero-overlay ---
          Positioned.fill(
            bottom: _isExpanded ? expandedPanelHeight : _collapsedPanelHeight,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              padding: EdgeInsets.zero,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The web hides the title when the panel expands.
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Text(
                            'Welcome to KnightRate!',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display.copyWith(
                              color: AppPalette.white,
                              fontSize: 30,
                            ),
                          ),
                        ),
                        secondChild: const SizedBox(width: double.infinity),
                      ),
                      _PillSearchBar(
                        controller: _searchController,
                        onSubmitted: _search,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Expandable bottom panel, mirrors .expandable-panel ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: 0,
            height: _isExpanded ? expandedPanelHeight : _collapsedPanelHeight,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeColors.surface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pull handle — tap to expand/collapse, arrow flips.
                  SizedBox(
                    height: _collapsedPanelHeight,
                    child: InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Center(
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 400),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            size: 28,
                            color: ThemeColors.text(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Intro row, mirrors .intro
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/ucf_logo.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Find the right class, from students who've taken it",
                                      style: AppTextStyles.subheading,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'KnightRate is a course review platform built for UCF '
                                      'Computer Science and IT students — search the catalog, '
                                      'read real ratings for difficulty and quality, and share '
                                      "your own experience once you've taken a class.",
                                      style: AppTextStyles.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Browse Classes', style: AppTextStyles.heading),
                          const SizedBox(height: 12),
                          // Cards, mirrors .cards-row (2×2 on a phone)
                          if (_popularCourses.isEmpty)
                            Text('Loading classes…', style: AppTextStyles.muted)
                          else
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.2,
                              children: [
                                for (final course in _popularCourses)
                                  _CourseCard(course: course),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill-shaped search bar with a trailing magnifier, mirrors
/// .search-bar in Homepage.css.
class _PillSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _PillSearchBar({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 20, right: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search for a class...',
                hintStyle: AppTextStyles.muted.copyWith(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onSubmitted(controller.text),
            tooltip: 'Search',
            icon: Icon(Icons.search, color: ThemeColors.text(context), size: 22),
            // 44x44 minimum touch target, matching the web fix.
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// One Browse Classes card: gold/blue course code over the title, mirrors
/// .card/.card-code/.card-title in Homepage.css.
class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/courses/${course.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ThemeColors.bg(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeColors.border(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              course.courseCode,
              style: AppTextStyles.muted.copyWith(
                color: ThemeColors.primary(context),
                fontWeight: AppFontWeights.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.muted.copyWith(
                color: ThemeColors.text(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
