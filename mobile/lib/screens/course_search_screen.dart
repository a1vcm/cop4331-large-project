import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../services/api_client.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

/// Mirrors frontend/src/pages/CourseSearchPage.jsx: search bar, difficulty
/// filter, sort, and a results list with difficulty badges.
class CourseSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const CourseSearchScreen({super.key, this.initialQuery});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

const _difficultyLabels = {
  'easy': 'Easy',
  'medium': 'Medium',
  'hard': 'Hard',
  'unrated': 'Not yet rated',
};

// Matches DIFFICULTY colors in frontend/src/pages/CourseSearchPage.jsx.
const _difficultyColors = {
  'easy': Color(0xFF7FCB8F),
  'medium': Color(0xFFF2D14A),
  'hard': Color(0xFFE57373),
  'unrated': Color(0xFFD9D9D9),
};

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  late final _searchController = TextEditingController(text: widget.initialQuery ?? '');
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  String _filterBy = 'all';
  String _sortBy = 'relevance';

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

  List<Course> get _visibleCourses {
    var list = _courses.where((c) {
      if (_filterBy == 'all') return true;
      return c.difficultyKey == _filterBy;
    }).toList();

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'credits':
        list.sort((a, b) => (b.credits ?? 0).compareTo(a.credits ?? 0));
        break;
      case 'difficulty':
        list.sort((a, b) => a.avgDifficulty.compareTo(b.avgDifficulty));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _visibleCourses;

    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'Search for a class...',
                        prefixIcon: Icon(Icons.search, color: AppColors.grayLight),
                      ),
                      onSubmitted: _load,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterBy,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Filter By')),
                        DropdownMenuItem(value: 'easy', child: Text('Difficulty: Easy')),
                        DropdownMenuItem(value: 'medium', child: Text('Difficulty: Medium')),
                        DropdownMenuItem(value: 'hard', child: Text('Difficulty: Hard')),
                      ],
                      onChanged: (v) => setState(() => _filterBy = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'relevance', child: Text('Sort By')),
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'credits', child: Text('Credits')),
                        DropdownMenuItem(value: 'difficulty', child: Text('Difficulty')),
                      ],
                      onChanged: (v) => setState(() => _sortBy = v ?? 'relevance'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _loading
                      ? 'Loading courses...'
                      : _error ?? '${results.length} results',
                  style: AppTextStyles.muted,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: results.length,
                          itemBuilder: (context, i) => _CourseCard(course: results[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final diffKey = course.difficultyKey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardFill,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: AppTextStyles.subheading),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${course.credits ?? '—'} credits',
                      course.courseCode,
                      if (course.department != null) course.department!,
                    ].join(' • '),
                    style: AppTextStyles.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColors[diffKey],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _difficultyLabels[diffKey]!,
                    style: AppTextStyles.muted.copyWith(color: AppColors.black, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => context.push('/courses/${course.id}'),
                  child: const Text('Show Reviews'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
