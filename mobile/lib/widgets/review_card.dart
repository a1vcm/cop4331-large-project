import 'package:flutter/material.dart';
import '../models/review.dart';
import '../theme/app_theme.dart';
import 'stars.dart';

/// Shared review display card, mirrors frontend/src/pages/components/
/// ReviewCard.jsx. Used on the course detail screen (own reviews get
/// edit/delete) and the bookmarks screen (cross-course, shows a
/// [courseLabel] link back to the course instead). Bookmark/edit/delete
/// controls only render when their callback is non-null.
///
/// `whiteOverride` reproduces a pre-existing web quirk: CourseDetailPage.css
/// and BookmarksPage.css both hardcode `.review-list > *` /
/// `.bookmarks-list > *` to a white background regardless of theme,
/// overriding ReviewCard.css's own theme-aware styling — intentionally kept
/// as-is here rather than "fixed", to match the live site.
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isMine;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? courseLabel;
  final VoidCallback? onCourseClick;
  final bool whiteOverride;

  const ReviewCard({
    super.key,
    required this.review,
    this.isMine = false,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.onEdit,
    this.onDelete,
    this.courseLabel,
    this.onCourseClick,
    this.whiteOverride = false,
  });

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      'Difficulty: ${review.difficulty}/5',
      if (review.workload != null) 'Workload: ${review.workload}/5',
      if (review.gradingFairness != null) 'Grading Fairness: ${review.gradingFairness}/5',
      if (review.professorRating != null) 'Professor: ${review.professorRating}/5',
      if (review.instructor != null && review.instructor!.isNotEmpty) review.instructor!,
      if (review.term != null && review.term!.isNotEmpty) review.term!,
      if (review.grade != null && review.grade!.isNotEmpty) 'Grade: ${review.grade}',
    ];

    final textColor = whiteOverride ? AppPalette.black : ThemeColors.text(context);
    final mutedColor = whiteOverride ? AppPalette.gray500 : ThemeColors.textMuted(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(whiteOverride ? AppCardStyle.whiteOverridePad : AppCardStyle.baseVPad),
      decoration: BoxDecoration(
        color: whiteOverride ? AppCardStyle.whiteOverrideBg : ThemeColors.bg(context),
        borderRadius: BorderRadius.circular(whiteOverride ? AppCardStyle.whiteOverrideRadius : AppCardStyle.baseRadius),
        boxShadow: whiteOverride ? AppCardStyle.whiteOverrideShadow() : AppCardStyle.baseShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (courseLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: onCourseClick,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    courseLabel!,
                    style: AppTextStyles.subheading.copyWith(color: ThemeColors.primary(context), fontSize: 13),
                  ),
                ),
              ),
            ),
          // Main row: author + stars, edit/delete pushed to the far right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      review.authorUsername ?? (isMine ? 'You' : 'Anonymous'),
                      style: AppTextStyles.subheading.copyWith(color: textColor, fontSize: 14),
                    ),
                    Stars(value: review.quality, readOnly: true, allowHalf: true, size: 14),
                  ],
                ),
              ),
              if (isMine && (onEdit != null || onDelete != null)) ...[
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: mutedColor),
                    child: Text('Edit', style: TextStyle(decoration: TextDecoration.underline, color: mutedColor)),
                  ),
                if (onDelete != null)
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                    child: Text('Delete', style: TextStyle(decoration: TextDecoration.underline, color: ThemeColors.error(context))),
                  ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: AppTextStyles.body.copyWith(color: textColor, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Text(metaParts.join(' • '), style: AppTextStyles.muted.copyWith(color: mutedColor)),
          // Side row (tags + bookmark) — stacked below content, wrapping
          // horizontally, matching ReviewCard.css's @560px mobile breakpoint
          // (always active on phones).
          if (review.tags.isNotEmpty || onToggleBookmark != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: review.tags.map((tag) => _TagChip(label: tag)).toList(),
                  ),
                ),
                if (onToggleBookmark != null)
                  IconButton(
                    onPressed: onToggleBookmark,
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark review',
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppPalette.gold : mutedColor,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Mirrors .review-tag: green-tinted pill (light mode), solid saturated
/// green (dark mode).
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = ThemeColors.surface(context);
    final (Color bg, Color fg, Color border) = isDark
        ? (AppPalette.success.withValues(alpha: 0.85), AppPalette.white, AppPalette.success)
        : (
            Color.lerp(surface, AppPalette.success, 0.12)!,
            AppPalette.success,
            AppPalette.success.withValues(alpha: 0.35),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Text(label, style: AppTextStyles.muted.copyWith(color: fg, fontWeight: AppFontWeights.bold, fontSize: 11)),
    );
  }
}
