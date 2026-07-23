import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mirrors ScrollToTopButton.jsx: a floating gold circle, bottom-right,
/// that appears once the page has scrolled past ~80px and jumps back to
/// the top when tapped. Wraps `child` in a NotificationListener so any
/// scrollable inside it (ListView, SingleChildScrollView, ...) drives the
/// button automatically — no per-screen wiring needed.
class ScrollToTopOverlay extends StatefulWidget {
  final Widget child;

  const ScrollToTopOverlay({super.key, required this.child});

  @override
  State<ScrollToTopOverlay> createState() => _ScrollToTopOverlayState();
}

class _ScrollToTopOverlayState extends State<ScrollToTopOverlay> {
  bool _visible = false;
  BuildContext? _scrollContext;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _scrollContext = notification.context;
        final shouldShow = notification.metrics.pixels > 80;
        if (shouldShow != _visible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _visible = shouldShow);
          });
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_visible)
            Positioned(
              right: 14,
              bottom: 14,
              child: _Button(
                onTap: () {
                  final ctx = _scrollContext;
                  if (ctx == null) return;
                  Scrollable.of(ctx).position.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final VoidCallback onTap;

  const _Button({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Mirrors ScrollToTopButton.css: gold/black in light mode,
    // --color-emphasis (blue)/--color-on-emphasis (white) in dark mode.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ThemeColors.emphasis(context) : AppPalette.gold;
    final fg = isDark ? ThemeColors.onEmphasis(context) : AppPalette.black;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.keyboard_arrow_up, color: fg),
        ),
      ),
    );
  }
}
