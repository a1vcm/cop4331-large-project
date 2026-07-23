import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/review_tags.dart';
import '../models/course.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/course_service.dart';
import '../services/resource_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stars.dart';

const _gradeOptions = [
  '', 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'W', 'P',
];
const _terms = ['Spring', 'Summer', 'Fall'];
const _commentCharLimit = 500;

/// Same year/term sweep as buildTermOptions() in frontend/src/pages/
/// WriteReviewPage.jsx: next year down to two years back, each year's terms
/// listed Fall/Summer/Spring (most-recent-first), with the review's existing
/// term (if any, and not already in range) pinned to the top.
List<String> _buildTermOptions(String? existingTerm) {
  final year = DateTime.now().year;
  final options = <String>[];
  for (var y = year + 1; y >= year - 2; y--) {
    for (var i = _terms.length - 1; i >= 0; i--) {
      options.add('${_terms[i]} $y');
    }
  }
  if (existingTerm != null && existingTerm.isNotEmpty && !options.contains(existingTerm)) {
    options.insert(0, existingTerm);
  }
  return options;
}

/// Mirrors frontend/src/pages/WriteReviewPage.jsx: a full pushed screen
/// (not an overlay — the web treats this as a top-level view, always
/// returning to Course Detail on save or cancel), with the full field set:
/// half-star overall rating, 4 secondary rating rows + optional attendance,
/// grade, term, tag multi-select, an attach-resources subform, and a
/// comment box with a running character count.
class WriteReviewScreen extends StatefulWidget {
  final String courseId;
  final Review? existing;

  const WriteReviewScreen({super.key, required this.courseId, this.existing});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  Course? _course;

  late double _quality = widget.existing?.quality ?? 3.0;
  late int _difficulty = widget.existing?.difficulty ?? 3;
  late int _workload = widget.existing?.workload ?? 3;
  late int _gradingFairness = widget.existing?.gradingFairness ?? 3;
  late int _professorRating = widget.existing?.professorRating ?? 3;
  late int _attendance = widget.existing?.attendance ?? 3;
  late String _grade = widget.existing?.grade ?? '';
  late String _term = widget.existing?.term ?? '';
  late final List<String> _tags = List.of(widget.existing?.tags ?? const []);
  late final _instructorController = TextEditingController(text: widget.existing?.instructor);
  late final _commentController = TextEditingController(text: widget.existing?.comment);
  late final _termOptions = _buildTermOptions(widget.existing?.term);

  bool _showResourceForm = false;
  final _resourceTitleController = TextEditingController();
  final _resourceUrlController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final course = await CourseService.getCourseById(widget.courseId);
      if (mounted) setState(() => _course = course);
    } catch (_) {
      // Non-fatal — the form still works without the header card.
    }
  }

  @override
  void dispose() {
    _instructorController.dispose();
    _commentController.dispose();
    _resourceTitleController.dispose();
    _resourceUrlController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final instructor = _instructorController.text.trim();
      final comment = _commentController.text.trim();
      if (widget.existing != null) {
        await ReviewService.updateReview(
          id: widget.existing!.id,
          instructor: instructor,
          term: _term,
          quality: _quality,
          difficulty: _difficulty,
          workload: _workload,
          gradingFairness: _gradingFairness,
          professorRating: _professorRating,
          attendance: _attendance,
          grade: _grade,
          comment: comment,
          tags: _tags,
        );
      } else {
        await ReviewService.createReview(
          courseId: widget.courseId,
          instructor: instructor,
          term: _term,
          quality: _quality,
          difficulty: _difficulty,
          workload: _workload,
          gradingFairness: _gradingFairness,
          professorRating: _professorRating,
          attendance: _attendance,
          grade: _grade,
          comment: comment,
          tags: _tags,
        );
      }
      final resourceTitle = _resourceTitleController.text.trim();
      final resourceUrl = _resourceUrlController.text.trim();
      if (resourceTitle.isNotEmpty && resourceUrl.isNotEmpty) {
        // Best-effort, swallowed failure — matches WriteReviewPage.jsx: a
        // failed resource attach must not fail the review save, which has
        // already succeeded by this point.
        try {
          await ResourceService.create(courseId: widget.courseId, title: resourceTitle, url: resourceUrl);
        } catch (_) {
          // ignore
        }
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      showInfoIcon: false,
      showHelpIcon: false,
      showBookmarksIcon: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ThemeColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing != null ? 'Edit Your Review' : 'Rate the Course',
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 16),

              if (_course != null) _CourseInfoCard(course: _course!, instructorController: _instructorController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _termOptions.contains(_term) ? _term : null,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Select term'),
                items: _termOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _term = v ?? ''),
              ),
              const SizedBox(height: 20),

              Text('Overall Rating', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              Row(
                children: [
                  Stars(value: _quality, allowHalf: true, size: 32, onChange: (v) => setState(() => _quality = v)),
                  const SizedBox(width: 12),
                  Text('${_quality.toStringAsFixed(1)} / 5.0', style: AppTextStyles.muted),
                ],
              ),
              const SizedBox(height: 16),

              // Mirrors .rating-grid: a single-column stack of label+stars
              // rows with dividers — this is the CSS's actual layout at
              // every screen width, not just a mobile fallback.
              Container(
                decoration: BoxDecoration(color: ThemeColors.bg(context), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _RatingRow(
                      label: 'Difficulty',
                      value: _difficulty.toDouble(),
                      onChanged: (v) => setState(() => _difficulty = v.round()),
                    ),
                    _RatingRow(
                      label: 'Workload',
                      value: _workload.toDouble(),
                      onChanged: (v) => setState(() => _workload = v.round()),
                    ),
                    _RatingRow(
                      label: 'Grading Fairness',
                      value: _gradingFairness.toDouble(),
                      onChanged: (v) => setState(() => _gradingFairness = v.round()),
                    ),
                    _RatingRow(
                      label: 'Professor Quality',
                      value: _professorRating.toDouble(),
                      onChanged: (v) => setState(() => _professorRating = v.round()),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _RatingRow(
                label: 'Attendance (optional)',
                value: _attendance.toDouble(),
                onChanged: (v) => setState(() => _attendance = v.round()),
                bare: true,
              ),
              const SizedBox(height: 8),

              Text('Grade received', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _grade,
                isExpanded: true,
                items: _gradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(g.isEmpty ? 'Select grade' : g))).toList(),
                onChanged: (v) => setState(() => _grade = v ?? ''),
              ),
              const SizedBox(height: 20),

              Text('Attach Resources', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              if (!_showResourceForm)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showResourceForm = true),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
                    child: const Text('Attach File, Link, or Document'),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _resourceTitleController,
                      maxLength: 120,
                      decoration: const InputDecoration(hintText: 'Title, e.g. Course syllabus'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _resourceUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'https://…'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _showResourceForm = false;
                          _resourceTitleController.clear();
                          _resourceUrlController.clear();
                        }),
                        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              Text('Add Tags', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kReviewTags.map((tag) => _TagToggle(label: tag, selected: _tags.contains(tag), onTap: () => _toggleTag(tag))).toList(),
              ),
              const SizedBox(height: 20),

              Text('Write a Review', style: AppTextStyles.subheading),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 6,
                maxLength: _commentCharLimit,
                decoration: const InputDecoration(
                  hintText: "Share your experience with this course…",
                  alignLabelWithHint: true,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: AppTextStyles.muted.copyWith(color: ThemeColors.error(context))),
              ],
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.existing != null ? 'Save Changes' : 'Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors .course-info-card: avatar placeholder + course title + an
/// inline editable instructor field.
class _CourseInfoCard extends StatelessWidget {
  final Course course;
  final TextEditingController instructorController;

  const _CourseInfoCard({required this.course, required this.instructorController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: ThemeColors.bg(context), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeColors.border(context)),
            alignment: Alignment.center,
            child: Icon(Icons.school_outlined, color: ThemeColors.textMuted(context), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${course.courseCode} - ${course.title}', style: AppTextStyles.subheading.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                TextField(
                  controller: instructorController,
                  style: AppTextStyles.muted,
                  decoration: const InputDecoration(
                    hintText: 'Professor name (optional)',
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One "Label ⭐⭐⭐⭐⭐" row, matching .rating-grid-row: a divider between
/// rows, none after the last.
class _RatingRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isLast;
  final bool bare;

  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontWeight: AppFontWeights.medium, fontSize: 13)),
          Stars(value: value, size: 20, onChange: onChanged),
        ],
      ),
    );
    if (bare) return row;
    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: ThemeColors.border(context)))),
      child: row,
    );
  }
}

/// One tag chip in the multi-select — 14px radius pill, matching
/// .tag-chip. A 44pt-tall tap area regardless of the chip's compact
/// visual size, per the HIG minimum touch target.
class _TagToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? ThemeColors.onPrimary(context) : ThemeColors.textMuted(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ThemeColors.primary(context) : ThemeColors.bg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? ThemeColors.primary(context) : ThemeColors.border(context)),
          ),
          child: Text(label, style: AppTextStyles.muted.copyWith(color: color, fontWeight: AppFontWeights.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
