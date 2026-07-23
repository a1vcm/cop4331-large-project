import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/bookmark.dart';
import '../models/course.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/auth_state.dart';
import '../services/bookmark_service.dart';
import '../services/course_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/review_card.dart';

const _pageSize = 5;
const _maxPageButtons = 5;

const _sortOptions = {
  'recent': 'Most Recent',
  'highest': 'Highest Rated',
  'lowest': 'Lowest Rated',
  'helpful': 'Most Helpful',
};

/// Mirrors frontend/src/pages/CourseDetailPage.jsx exactly: course stats +
/// rating distribution, a sort-by dropdown, the review list with real
/// numbered pagination (fixed page size of 5, a sliding 5-button window),
/// and a write/edit entry point that now pushes a full write-review screen.
class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<Review> _reviews = [];
  Set<String> _bookmarkedIds = {};
  bool _loading = true;
  String? _error;
  String _sortBy = 'recent';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
    });
    try {
      final results = await Future.wait([
        CourseService.getCourseById(widget.courseId),
        ReviewService.getCourseReviews(widget.courseId),
        // Bookmarks are secondary — an expired/invalid token or a logged-out
        // user shouldn't take down the whole page, just leave bookmark
        // state empty (matches CourseDetailPage.jsx's .catch(() => [])).
        AuthState.instance.isLoggedIn
            ? BookmarkService.getMine().catchError((_) => <Bookmark>[])
            : Future.value(<Bookmark>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _course = results[0] as Course;
        _reviews = results[1] as List<Review>;
        _bookmarkedIds = (results[2] as List<Bookmark>).map((b) => b.review.id).toSet();
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

  List<Review> get _sortedReviews {
    final list = List<Review>.of(_reviews);
    switch (_sortBy) {
      case 'highest':
        list.sort((a, b) => b.quality.compareTo(a.quality));
        break;
      case 'lowest':
        list.sort((a, b) => a.quality.compareTo(b.quality));
        break;
      case 'helpful':
        list.sort((a, b) {
          final bScore = b.voteHelpful - b.voteNotHelpful;
          final aScore = a.voteHelpful - a.voteNotHelpful;
          return bScore.compareTo(aScore);
        });
        break;
      case 'recent':
      default:
        list.sort((a, b) {
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    }
    return list;
  }

  ({Map<int, int> counts, int max}) get _distribution {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final bucket = r.quality.round().clamp(1, 5);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    final max = counts.values.fold(1, (m, v) => v > m ? v : m);
    return (counts: counts, max: max);
  }

  Future<void> _openReviewForm({Review? existing}) async {
    if (!mounted) return;
    final saved = await context.push<bool>('/courses/${widget.courseId}/write-review', extra: existing);
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

  Future<void> _toggleBookmark(Review review) async {
    final isBookmarked = _bookmarkedIds.contains(review.id);
    setState(() {
      if (isBookmarked) {
        _bookmarkedIds = {..._bookmarkedIds}..remove(review.id);
      } else {
        _bookmarkedIds = {..._bookmarkedIds, review.id};
      }
    });
    try {
      if (isBookmarked) {
        await BookmarkService.delete(review.id);
      } else {
        await BookmarkService.create(review.id);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (isBookmarked) {
          _bookmarkedIds = {..._bookmarkedIds, review.id};
        } else {
          _bookmarkedIds = {..._bookmarkedIds}..remove(review.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register a Theme dependency so every text style in this screen
    // repaints the moment the light/dark toggle fires.
    Theme.of(context);
    final sortedReviews = _sortedReviews;
    final totalPages = math.max(1, (sortedReviews.length / _pageSize).ceil());
    final page = _page.clamp(0, totalPages - 1);
    final pagedReviews = sortedReviews.skip(page * _pageSize).take(_pageSize).toList();
    final isLoggedIn = AuthState.instance.isLoggedIn;

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
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    children: [
                      _CourseHeader(course: _course!, courseId: widget.courseId, distribution: _distribution),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Reviews (${_reviews.length})', style: AppTextStyles.subheading),
                          ),
                          const SizedBox(width: 8),
                          if (!isLoggedIn)
                            TextButton(
                              onPressed: () => context.push('/login'),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                              child: const Text('Log in to review'),
                            )
                          else if (_myReview == null)
                            ElevatedButton(
                              onPressed: () => _openReviewForm(),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                              child: const Text('Write a Review'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isNotEmpty)
                        Align(alignment: Alignment.centerLeft, child: _SortBar(value: _sortBy, onChanged: (v) => setState(() {
                          _sortBy = v ?? 'recent';
                          _page = 0;
                        }))),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No reviews yet — be the first!', style: AppTextStyles.muted),
                          ),
                        ),
                      for (final review in pagedReviews)
                        ReviewCard(
                          review: review,
                          isMine: review.userId == AuthState.instance.userId,
                          isBookmarked: _bookmarkedIds.contains(review.id),
                          onToggleBookmark: isLoggedIn ? () => _toggleBookmark(review) : null,
                          onEdit: review.userId == AuthState.instance.userId
                              ? () => _openReviewForm(existing: review)
                              : null,
                          onDelete: review.userId == AuthState.instance.userId
                              ? () => _deleteReview(review)
                              : null,
                        ),
                      if (totalPages > 1)
                        _ReviewPagination(
                          page: page,
                          totalPages: totalPages,
                          onPageChange: (p) => setState(() => _page = p),
                        ),
                    ],
                  ),
                ),
    );
  }
}

/// Mirrors .sort-bar: a small shadowed pill.
class _SortBar extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SortBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sort by: ', style: AppTextStyles.body.copyWith(fontWeight: AppFontWeights.bold, fontSize: 13)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              dropdownColor: ThemeColors.surface(context),
              items: [for (final e in _sortOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors .review-pagination / .review-page-btn: a sliding window of up
/// to 5 numbered pill buttons centered on the current page, plus a `›`
/// next-arrow disabled at the last page.
class _ReviewPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const _ReviewPagination({required this.page, required this.totalPages, required this.onPageChange});

  List<int> get _pageButtons {
    const half = _maxPageButtons ~/ 2;
    var start = math.max(0, page - half);
    final end = math.min(totalPages, start + _maxPageButtons);
    start = math.max(0, end - _maxPageButtons);
    return [for (var i = start; i < end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final p in _pageButtons) _PageButton(label: '${p + 1}', active: p == page, onTap: () => onPageChange(p)),
          const SizedBox(width: 4),
          _PageButton(
            label: '›',
            active: false,
            fontSize: 18,
            onTap: page >= totalPages - 1 ? null : () => onPageChange(math.min(totalPages - 1, page + 1)),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final double fontSize;

  const _PageButton({required this.label, required this.active, required this.onTap, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: active ? ThemeColors.emphasis(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: AppFontWeights.bold,
                  color: active ? ThemeColors.onEmphasis(context) : ThemeColors.textMuted(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors .distribution-bar-track/.fill: always gold, never theme-swapped
/// to blue in dark mode (CourseDetailPage.css sets it unconditionally).
class _DistributionChart extends StatelessWidget {
  final ({Map<int, int> counts, int max}) distribution;

  const _DistributionChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final star in [5, 4, 3, 2, 1])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text('$star★', style: AppTextStyles.muted.copyWith(fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (distribution.counts[star] ?? 0) / distribution.max,
                      minHeight: 8,
                      backgroundColor: ThemeColors.border(context),
                      valueColor: const AlwaysStoppedAnimation(AppPalette.gold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${distribution.counts[star] ?? 0}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.muted.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mirrors .course-header-card + .course-rating-summary: two-column on
/// desktop (score/stars left, distribution bars right), stacked on the
/// @600px mobile breakpoint — always active on a phone, so this renders
/// stacked unconditionally.
class _CourseHeader extends StatelessWidget {
  final Course course;
  final String courseId;
  final ({Map<int, int> counts, int max}) distribution;

  const _CourseHeader({required this.course, required this.courseId, required this.distribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                course.numRatings == 0 ? '—' : course.avgRating.toStringAsFixed(1),
                style: AppTextStyles.display.copyWith(fontSize: 40),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: AppPalette.gold, size: 26),
            ],
          ),
          Text('${course.numRatings} review${course.numRatings == 1 ? '' : 's'}', style: AppTextStyles.muted),
          const SizedBox(height: 16),
          _DistributionChart(distribution: distribution),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () => context.push('/courses/$courseId/resources'),
              child: const Text('View Resources'),
            ),
          ),
        ],
      ),
    );
  }
}
