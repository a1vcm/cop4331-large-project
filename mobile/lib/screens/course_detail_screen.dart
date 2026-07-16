import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/auth_state.dart';
import '../services/course_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

/// New screen — no frontend/web equivalent exists yet. This is the core
/// "rate a class" feature: course stats up top, the review list below, and
/// a write/edit form for the logged-in user's own review.
class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CourseService.getCourseById(widget.courseId),
        ReviewService.getCourseReviews(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        _course = results[0] as Course;
        _reviews = results[1] as List<Review>;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Review? get _myReview {
    final userId = AuthState.instance.userId;
    if (userId == null) return null;
    try {
      return _reviews.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openReviewForm({Review? existing}) async {
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewFormSheet(courseId: widget.courseId, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ReviewService.deleteReview(review.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CourseHeader(course: _course!),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews (${_reviews.length})', style: AppTextStyles.subheading),
                          if (!AuthState.instance.isLoggedIn)
                            TextButton(
                              onPressed: () => context.push('/login'),
                              child: const Text('Log in to review'),
                            )
                          else if (_myReview == null)
                            ElevatedButton(
                              onPressed: () => _openReviewForm(),
                              child: const Text('Write a Review'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No reviews yet — be the first!', style: AppTextStyles.muted),
                          ),
                        ),
                      for (final review in _reviews)
                        _ReviewCard(
                          review: review,
                          isMine: review.userId == AuthState.instance.userId,
                          onEdit: () => _openReviewForm(existing: review),
                          onDelete: () => _deleteReview(review),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final Course course;

  const _CourseHeader({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(
            [
              course.courseCode,
              if (course.department != null) course.department!,
              if (course.credits != null) '${course.credits} credits',
            ].join(' • '),
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: 'Rating', value: course.numRatings == 0 ? '—' : course.avgRating.toStringAsFixed(1)),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Difficulty',
                value: course.numRatings == 0 ? '—' : course.avgDifficulty.toStringAsFixed(1),
              ),
              const SizedBox(width: 12),
              _StatChip(label: 'Reviews', value: '${course.numRatings}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.subheading),
        Text(label, style: AppTextStyles.muted),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grayLightest),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.authorUsername ?? (isMine ? 'You' : 'Anonymous'),
                style: AppTextStyles.subheading,
              ),
              if (isMine)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              Text('Quality: ${review.quality}/5', style: AppTextStyles.muted),
              Text('Difficulty: ${review.difficulty}/5', style: AppTextStyles.muted),
              if (review.instructor != null && review.instructor!.isNotEmpty)
                Text(review.instructor!, style: AppTextStyles.muted),
              if (review.term != null && review.term!.isNotEmpty)
                Text(review.term!, style: AppTextStyles.muted),
              if (review.grade != null && review.grade!.isNotEmpty)
                Text('Grade: ${review.grade}', style: AppTextStyles.muted),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

/// Bottom-sheet form used for both creating and editing a review.
class _ReviewFormSheet extends StatefulWidget {
  final String courseId;
  final Review? existing;

  const _ReviewFormSheet({required this.courseId, this.existing});

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late int _quality = widget.existing?.quality ?? 3;
  late int _difficulty = widget.existing?.difficulty ?? 3;
  late final _instructorController = TextEditingController(text: widget.existing?.instructor);
  late final _termController = TextEditingController(text: widget.existing?.term);
  late final _gradeController = TextEditingController(text: widget.existing?.grade);
  late final _commentController = TextEditingController(text: widget.existing?.comment);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _instructorController.dispose();
    _termController.dispose();
    _gradeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.existing != null) {
        await ReviewService.updateReview(
          id: widget.existing!.id,
          instructor: _instructorController.text.trim(),
          term: _termController.text.trim(),
          quality: _quality,
          difficulty: _difficulty,
          grade: _gradeController.text.trim(),
          comment: _commentController.text.trim(),
        );
      } else {
        await ReviewService.createReview(
          courseId: widget.courseId,
          instructor: _instructorController.text.trim(),
          term: _termController.text.trim(),
          quality: _quality,
          difficulty: _difficulty,
          grade: _gradeController.text.trim(),
          comment: _commentController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing != null ? 'Edit Your Review' : 'Write a Review',
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 16),
              _RatingSelector(label: 'Quality', value: _quality, onChanged: (v) => setState(() => _quality = v)),
              const SizedBox(height: 12),
              _RatingSelector(
                label: 'Difficulty',
                value: _difficulty,
                onChanged: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructorController,
                decoration: const InputDecoration(hintText: 'Instructor (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _termController,
                decoration: const InputDecoration(hintText: 'Term, e.g. Fall 2026 (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gradeController,
                decoration: const InputDecoration(hintText: 'Grade received (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(hintText: 'Comments (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: AppTextStyles.muted.copyWith(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.existing != null ? 'Save Changes' : 'Submit Review'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSelector({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: AppTextStyles.body)),
        ...List.generate(5, (i) {
          final star = i + 1;
          return IconButton(
            icon: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: AppColors.gold,
              size: 22,
            ),
            onPressed: () => onChanged(star),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }
}
