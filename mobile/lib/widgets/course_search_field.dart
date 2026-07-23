import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';

const _debounceDuration = Duration(milliseconds: 300);
const _maxSuggestions = 6;

/// Debounced autocomplete search field, mirrors frontend/src/pages/
/// components/CourseSearchBar.jsx: 300ms debounce after typing, up to 6
/// suggestions in a dropdown, tap (or Enter, via [onSubmitted]) to search.
/// Each suggestion row is >=44pt tall for the touch target minimum.
class CourseSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<Course> onSelectCourse;
  final String hintText;
  final bool pillStyle;

  const CourseSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onSelectCourse,
    this.hintText = 'Search for a class...',
    this.pillStyle = false,
  });

  @override
  State<CourseSearchField> createState() => _CourseSearchFieldState();
}

class _CourseSearchFieldState extends State<CourseSearchField> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<Course> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _closeOverlay();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    _closeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      _suggestions = [];
      _closeOverlay();
      return;
    }
    _debounce = Timer(_debounceDuration, () async {
      try {
        final courses = await CourseService.getCourses(query);
        if (!mounted) return;
        _suggestions = courses.take(_maxSuggestions).toList();
        _showOverlay();
      } catch (_) {
        _suggestions = [];
      }
    });
  }

  void _select(Course course) {
    _closeOverlay();
    widget.controller.text = course.courseCode;
    widget.onSelectCourse(course);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _closeOverlay();
    if (_suggestions.isEmpty || !_focusNode.hasFocus) return;
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;
    final height = renderBox?.size.height ?? 48;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: ThemeColors.surface(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, i) {
                  final course = _suggestions[i];
                  return InkWell(
                    onTap: () => _select(course),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(course.courseCode, style: AppTextStyles.subheading),
                          Text(
                            course.title,
                            style: AppTextStyles.muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: _fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      style: AppTextStyles.body,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) {
        _closeOverlay();
        widget.onSubmitted(v);
      },
      decoration: widget.pillStyle
          ? InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyles.muted.copyWith(fontSize: 14, fontStyle: FontStyle.italic),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            )
          : InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Icon(Icons.search, color: ThemeColors.textMuted(context)),
            ),
    );

    if (!widget.pillStyle) {
      return CompositedTransformTarget(link: _layerLink, child: field);
    }

    // Pill variant: white rounded container with a trailing search button,
    // mirrors .search-bar in Homepage.css/.course-search-bar.
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.surface(context),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.only(left: 20, right: 4),
        child: Row(
          children: [
            Expanded(child: field),
            IconButton(
              onPressed: () {
                _closeOverlay();
                widget.onSubmitted(widget.controller.text);
              },
              tooltip: 'Search',
              icon: Icon(Icons.search, color: ThemeColors.text(context), size: 22),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
