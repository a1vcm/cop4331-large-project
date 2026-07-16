import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

/// Mirrors AuthPage.jsx's two-step forgot-password overlay (request code,
/// then submit code + new password), as its own screen instead of an
/// overlay — a full route reads more naturally on mobile.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _step2 = false;
  bool _isLoading = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestCode() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await AuthService.forgotPassword(email: _emailController.text.trim());
      setState(() {
        _step2 = true;
        _message = 'If that email is registered, a reset code has been sent.';
        _messageIsError = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = 'Passwords do not match';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await AuthService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      context.go('/login');
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      title: 'Reset Password',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _step2 ? 'Enter Reset Code' : 'Reset Password',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _step2
                      ? "We've sent a code to ${_emailController.text}."
                      : "Enter your account email and we'll send a reset code.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!_step2) ...[
                  AppTextField(
                    controller: _emailController,
                    hint: 'example@email.com',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  AppTextField(
                    controller: _codeController,
                    hint: 'Reset code',
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _newPasswordController,
                    hint: 'New password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm new password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: AppTextStyles.muted.copyWith(
                      color: _messageIsError ? Colors.red : Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_step2 ? _handleResetPassword : _handleRequestCode),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_step2 ? 'Reset Password' : 'Send Code'),
                ),
                if (_step2) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleRequestCode,
                      child: Text('Resend code', style: AppTextStyles.muted),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Back to Log In', style: AppTextStyles.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
