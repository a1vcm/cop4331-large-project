import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared star rating widget — a read-only fractional display (course
/// summaries, review cards) or an interactive picker (the write-review
/// form). Mirrors frontend/src/pages/components/Stars.jsx: each star fills
/// by percentage so averaged/half-star values render smoothly, and
/// [allowHalf] enables 0.5-increment picks via a left/right split inside
/// each star's hit target — only the overall class-quality rating uses it,
/// per the web's design decision to keep the other scales whole-number.
class Stars extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChange;
  final bool allowHalf;
  final bool readOnly;
  final double size;

  const Stars({
    super.key,
    this.value = 0,
    this.onChange,
    this.allowHalf = false,
    this.readOnly = false,
    this.size = 22,
  });

  bool get _isInteractive => !readOnly && onChange != null;

  @override
  Widget build(BuildContext context) {
    final color = ThemeColors.primary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        final fillPercent = (value - (n - 1)).clamp(0.0, 1.0);
        final star = _StarShape(fillPercent: fillPercent, size: size, color: color);
        if (!_isInteractive) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: star);
        }
        return _StarHitTarget(
          size: size,
          allowHalf: allowHalf,
          onPickHalf: () => onChange!(n - 0.5),
          onPickFull: () => onChange!(n.toDouble()),
          child: star,
        );
      }),
    );
  }
}

class _StarShape extends StatelessWidget {
  final double fillPercent;
  final double size;
  final Color color;

  const _StarShape({required this.fillPercent, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(Icons.star, size: size, color: color.withValues(alpha: 0.25)),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              // A zero widthFactor collapses the Align to zero width, which
              // is fine, but Flutter warns on exactly-zero factors in some
              // versions — nudge it instead of branching on fillPercent == 0.
              widthFactor: fillPercent < 0.001 ? 0.001 : fillPercent,
              child: Icon(Icons.star, size: size, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps one star glyph in a >=44x44 tap target (never smaller than the
/// glyph itself). When [allowHalf], the left half of the target picks
/// n-0.5 and the right half picks n — one unified hit region rather than
/// two separately-sized buttons, so the touch target stays >=44pt even
/// though the visual glyph may be smaller.
class _StarHitTarget extends StatelessWidget {
  final double size;
  final bool allowHalf;
  final VoidCallback onPickHalf;
  final VoidCallback onPickFull;
  final Widget child;

  const _StarHitTarget({
    required this.size,
    required this.allowHalf,
    required this.onPickHalf,
    required this.onPickFull,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final target = size < 44 ? 44.0 : size;
    return SizedBox(
      width: target,
      height: target,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowHalf ? null : onPickFull,
        onTapUp: allowHalf
            ? (details) {
                final isLeftHalf = details.localPosition.dx < target / 2;
                if (isLeftHalf) {
                  onPickHalf();
                } else {
                  onPickFull();
                }
              }
            : null,
        child: Center(child: child),
      ),
    );
  }
}
