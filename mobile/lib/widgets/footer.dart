import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mirrors frontend/src/pages/components/Footer.jsx: a single centered
/// copyright line on a black band. Shown at the end of every screen's
/// scroll content except Home (Home mounts its own copy, matching
/// App.jsx's `showFooter = view !== 'home'`).
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Text(
        '© $year made by the KnightRate team',
        textAlign: TextAlign.center,
        style: AppTextStyles.muted.copyWith(color: AppColors.white.withValues(alpha: 0.75), fontSize: 13),
      ),
    );
  }
}
