import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../services/api_client.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/course_search_field.dart';

/// Mirrors frontend/src/pages/CourseSearchPage.jsx exactly: autocomplete
/// search bar, prefix/difficulty filters + sort, a page-size dropdown
/// (10/5/25/50/All) and a "Next" button that cumulatively reveals more
/// results — not page-jumping, just a growing `visibleCount`.
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
  int _visibleCount = 10;

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

  List<Course> get _displayedCourses {
    final visible = _visibleCourses;
    if (_pageSize == -1) return visible;
    return visible.take(_visibleCount).toList();
  }

  void _resetVisibleCount([int? size]) => _visibleCount = size ?? _pageSize;

  void _goToCourse(Course course) => context.push('/courses/${course.id}');

  @override
  Widget build(BuildContext context) {
    // Register a Theme dependency so every text style in this screen
    // repaints the moment the light/dark toggle fires.
    Theme.of(context);
    final visibleCourses = _visibleCourses;
    final displayedCourses = _displayedCourses;

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          children: [
            CourseSearchField(
              controller: _searchController,
              onSubmitted: (q) {
                setState(_resetVisibleCount);
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
                    _resetVisibleCount();
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
                    _resetVisibleCount();
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
                    _resetVisibleCount();
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
                    _resetVisibleCount(size);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _loading
                  ? 'Loading courses...'
                  : _error ??
                      '${visibleCourses.length} result${visibleCourses.length == 1 ? '' : 's'}'
                          '${displayedCourses.length < visibleCourses.length ? ' — showing ${displayedCourses.length}' : ''}',
              style: AppTextStyles.muted,
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
            else if (_error == null) ...[
              for (final course in displayedCourses) _CourseCard(course: course, onTap: () => _goToCourse(course)),
              if (displayedCourses.length < visibleCourses.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: _NextButton(
                      onPressed: () => setState(() => _visibleCount += _pageSize == -1 ? 0 : _pageSize),
                    ),
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

/// Mirrors .show-more-btn: outlined gold pill (blue in dark mode).
class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: ThemeColors.primary(context), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        minimumSize: const Size(0, 44),
        foregroundColor: ThemeColors.text(context),
      ),
      child: const Text('Next'),
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
