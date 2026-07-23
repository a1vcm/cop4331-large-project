import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../services/api_client.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/course_search_field.dart';

/// Mirrors frontend/src/pages/CourseSearchPage.jsx's autocomplete search
/// bar, prefix/difficulty filters + sort, and page-size dropdown
/// (10/5/25/50/All), but diverges on pagination: mobile uses real
/// prev/next page-jumping instead of web's cumulative-reveal "Next".
class CourseSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const CourseSearchScreen({super.key, this.initialQuery});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

const _difficultyLabels = {
  'easy': 'Easy',
  'medium': 'Moderate',
  'hard': 'Hard',
  'unrated': 'Not yet rated',
};

const _pageSizeOptions = [10, 5, 25, 50, -1]; // -1 == 'all'

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  late final _searchController = TextEditingController(text: widget.initialQuery ?? '');
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  String _filterBy = 'all';
  String _prefixFilter = 'all';
  String _sortBy = 'relevance';
  int _pageSize = 10; // -1 == 'all'
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String? q]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await CourseService.getCourses(q);
      if (!mounted) return;
      setState(() => _courses = courses);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _prefixes {
    final set = <String>{};
    for (final c in _courses) {
      if (c.department != null && c.department!.isNotEmpty) set.add(c.department!);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Course> get _visibleCourses {
    var list = _courses.where((c) {
      if (_prefixFilter != 'all' && c.department != _prefixFilter) return false;
      if (_filterBy != 'all' && c.difficultyKey != _filterBy) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'credits':
        list.sort((a, b) => (a.credits ?? 0).compareTo(b.credits ?? 0));
        break;
      case 'difficulty':
        list.sort((a, b) {
          final aVal = a.numRatings == 0 ? double.infinity : a.avgDifficulty;
          final bVal = b.numRatings == 0 ? double.infinity : b.avgDifficulty;
          return aVal.compareTo(bVal);
        });
        break;
      default:
        break;
    }
    return list;
  }

  int get _totalPages {
    if (_pageSize == -1) return 1;
    return (_visibleCourses.length / _pageSize).ceil().clamp(1, 1 << 30);
  }

  List<Course> get _displayedCourses {
    final visible = _visibleCourses;
    if (_pageSize == -1) return visible;
    final page = _currentPage.clamp(0, _totalPages - 1);
    return visible.skip(page * _pageSize).take(_pageSize).toList();
  }

  void _resetPage() => _currentPage = 0;

  void _goToCourse(Course course) => context.push('/courses/${course.id}');

  @override
  Widget build(BuildContext context) {
    // Register a Theme dependency so every text style in this screen
    // repaints the moment the light/dark toggle fires.
    Theme.of(context);
    final visibleCourses = _visibleCourses;
    final displayedCourses = _displayedCourses;
    final totalPages = _totalPages;
    final page = _currentPage.clamp(0, totalPages - 1);

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          children: [
            CourseSearchField(
              controller: _searchController,
              onSubmitted: (q) {
                setState(_resetPage);
                _load(q);
              },
              onSelectCourse: _goToCourse,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ControlDropdown(
                  width: (MediaQuery.sizeOf(context).width - 24 * 2 - 12) / 2,
                  value: _filterBy,
                  items: const {
                    'all': 'Filter By',
                    'easy': 'Difficulty: Easy',
                    'medium': 'Difficulty: Moderate',
                    'hard': 'Difficulty: Hard',
                  },
                  onChanged: (v) => setState(() {
                    _filterBy = v ?? 'all';
                    _resetPage();
                  }),
                ),
                _ControlDropdown(
                  width: (MediaQuery.sizeOf(context).width - 24 * 2 - 12) / 2,
                  value: _prefixFilter,
                  items: {
                    'all': 'All Prefixes',
                    for (final p in _prefixes) p: p,
                  },
                  onChanged: (v) => setState(() {
                    _prefixFilter = v ?? 'all';
                    _resetPage();
                  }),
                ),
                _ControlDropdown(
                  width: (MediaQuery.sizeOf(context).width - 24 * 2 - 12) / 2,
                  value: _sortBy,
                  items: const {
                    'relevance': 'Sort By',
                    'name': 'Name',
                    'credits': 'Credits',
                    'difficulty': 'Difficulty',
                  },
                  onChanged: (v) => setState(() {
                    _sortBy = v ?? 'relevance';
                    _resetPage();
                  }),
                ),
                _ControlDropdown(
                  width: double.infinity,
                  goldBorder: true,
                  value: _pageSize.toString(),
                  items: {
                    for (final size in _pageSizeOptions) size.toString(): 'Show ${size == -1 ? 'All' : size}',
                  },
                  onChanged: (v) => setState(() {
                    final size = int.tryParse(v ?? '10') ?? 10;
                    _pageSize = size;
                    _resetPage();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _loading
                  ? 'Loading courses...'
                  : _error ?? '${visibleCourses.length} result${visibleCourses.length == 1 ? '' : 's'}',
              style: AppTextStyles.muted,
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
            else if (_error == null) ...[
              for (final course in displayedCourses) _CourseCard(course: course, onTap: () => _goToCourse(course)),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PageNavButton(
                        icon: Icons.chevron_left,
                        onPressed: page > 0 ? () => setState(() => _currentPage = page - 1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Page ${page + 1} of $totalPages', style: AppTextStyles.muted),
                      ),
                      _PageNavButton(
                        icon: Icons.chevron_right,
                        onPressed: page < totalPages - 1 ? () => setState(() => _currentPage = page + 1) : null,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mirrors .control-dropdown / .control-dropdown-pagesize.
class _ControlDropdown extends StatelessWidget {
  final double width;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  final bool goldBorder;

  const _ControlDropdown({
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
    this.goldBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ThemeColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: goldBorder ? Border.all(color: ThemeColors.primary(context), width: 1.5) : null,
          boxShadow: goldBorder
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            style: AppTextStyles.body.copyWith(fontSize: 13),
            dropdownColor: ThemeColors.surface(context),
            items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Icon-only prev/next pager control: outlined gold circle (blue in dark
/// mode), disabled (greyed, no-op) at the first/last page.
class _PageNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _PageNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        side: BorderSide(color: enabled ? ThemeColors.primary(context) : ThemeColors.border(context), width: 1.5),
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        foregroundColor: enabled ? ThemeColors.text(context) : ThemeColors.border(context),
      ),
      child: Icon(icon, size: 20),
    );
  }
}

/// Mirrors .class-card / .difficulty-badge — light mode uses color-mix
/// tints, dark mode uses solid saturated fills (CourseSearchPage.css).
class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diffKey = course.difficultyKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = ThemeColors.surface(context);

    final (Color bg, Color fg, Color border) = switch (diffKey) {
      'easy' => isDark
          ? (AppPalette.success, AppPalette.white, AppPalette.success)
          : (Color.lerp(surface, AppPalette.success, 0.18)!, AppPalette.success, AppPalette.success.withValues(alpha: 0.35)),
      'medium' => isDark
          ? (AppPalette.gold, AppPalette.black, AppPalette.gold)
          : (Color.lerp(surface, AppPalette.gold, 0.25)!, AppPalette.goldDark, AppPalette.gold.withValues(alpha: 0.45)),
      'hard' => isDark
          ? (AppPalette.error, AppPalette.white, AppPalette.error)
          : (Color.lerp(surface, AppPalette.error, 0.18)!, AppPalette.error, AppPalette.error.withValues(alpha: 0.35)),
      _ => (ThemeColors.border(context), ThemeColors.text(context), ThemeColors.border(context)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${course.courseCode} - ${course.title}', style: AppTextStyles.subheading.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text('${course.credits ?? '—'} credits  ·  ${course.department ?? '—'}', style: AppTextStyles.muted),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                child: Text(
                  _difficultyLabels[diffKey]!,
                  style: AppTextStyles.muted.copyWith(color: fg, fontWeight: AppFontWeights.bold, fontSize: 12),
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: ThemeColors.emphasis(context),
                  foregroundColor: ThemeColors.onEmphasis(context),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onTap,
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
