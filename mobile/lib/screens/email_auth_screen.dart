import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

class EmailAuthScreen extends StatefulWidget {
  final String email;

  const EmailAuthScreen({super.key, required this.email});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() {
      _isVerifying = true;
      _message = null;
    });

    try {
      await AuthService.verifyEmail(email: widget.email, code: _codeController.text.trim());
      if (!mounted) return;
      context.go('/dashboard');
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await AuthService.resendVerification(email: widget.email);
      setState(() {
        _message = 'Code resent — check your email.';
        _messageIsError = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
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
                // Mascot / brand accent bubble, mirrors the wireframe's
                // circular avatar overlay.
                Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.goldDark,
                    child: const Icon(Icons.mail_outline, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Check Your Email',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "We've sent a verification code to ${widget.email}. Enter it below to continue.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _codeController,
                  hint: 'Enter verification code',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
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
                  onPressed: _isVerifying ? null : _handleVerify,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify Email'),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _isResending ? null : _handleResend,
                    child: Text(
                      _isResending ? 'Resending...' : 'Resend Code',
                      style: AppTextStyles.muted,
                    ),
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
