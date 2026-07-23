import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/bookmark.dart';
import '../services/api_client.dart';
import '../services/bookmark_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/review_card.dart';

/// Mirrors frontend/src/pages/BookmarksPage.jsx: every review the logged-in
/// user has bookmarked, across all courses, each tagged with a link back to
/// its course.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
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
      final bookmarks = await BookmarkService.getMine();
      if (!mounted) return;
      setState(() => _bookmarks = bookmarks);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Bookmark bookmark) async {
    final previous = _bookmarks;
    setState(() => _bookmarks = _bookmarks.where((b) => b.id != bookmark.id).toList());
    try {
      await BookmarkService.delete(bookmark.review.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _bookmarks = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      showBookmarksIcon: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _bookmarks.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                          children: [
                            _BookmarksHeading(),
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                "You haven't bookmarked any reviews yet — tap the bookmark icon on a "
                                'review to save it here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.muted,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                          itemCount: _bookmarks.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _BookmarksHeading(),
                              );
                            }
                            i -= 1;
                            final bookmark = _bookmarks[i];
                            final review = bookmark.review;
                            final courseLabel = review.courseCode != null
                                ? '${review.courseCode} - ${review.courseTitle ?? ''}'
                                : 'View course';
                            return ReviewCard(
                              review: review,
                              isBookmarked: true,
                              onToggleBookmark: () => _remove(bookmark),
                              courseLabel: courseLabel,
                              onCourseClick: () => context.push('/courses/${review.courseId}'),
                            );
                          },
                        ),
                ),
    );
  }
}

/// Mirrors .bookmarks-heading: Montserrat 700, 22px, uppercase.
class _BookmarksHeading extends StatelessWidget {
  const _BookmarksHeading();

  @override
  Widget build(BuildContext context) {
    return Text(
      'BOOKMARKS',
      style: AppTextStyles.heading.copyWith(fontSize: 22, letterSpacing: 0.6),
    );
  }
}
