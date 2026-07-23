import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/validate_password.dart';

/// Live checklist shown under a new-password field, mirrors frontend/src/
/// pages/components/PasswordRequirements.jsx. A list of one requirement for
/// now, structured so more can be added later without changing callers.
class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const PasswordRequirementsChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final met = isPasswordValid(password);
    final color = met ? ThemeColors.success(context) : ThemeColors.textMuted(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(met ? '✓' : '*', style: AppTextStyles.muted.copyWith(color: color)),
          const SizedBox(width: 6),
          Text('At least $kMinPasswordLength characters', style: AppTextStyles.muted.copyWith(color: color)),
        ],
      ),
    );
  }
}
