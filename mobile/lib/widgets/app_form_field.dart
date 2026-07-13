import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.grayLight)
            : null,
      ),
    );
  }
}

/// A gray placeholder box standing in for images/logos not yet finalized —
/// mirrors the gray rectangles in the Figma wireframe.
class PlaceholderBox extends StatelessWidget {
  final double? width;
  final double height;
  final IconData icon;

  const PlaceholderBox({
    super.key,
    this.width,
    this.height = 80,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grayLighter.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: AppColors.grayLight),
    );
  }
}
