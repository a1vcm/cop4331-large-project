import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() => _isVerifying = true);

    // TODO: call your teammates' verify-email endpoint, e.g.
    // await AuthService.verifyEmail(code: _codeController.text.trim());

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isVerifying = false);
    context.go('/login');
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
                  "We've sent a verification code to your email. Enter it below to continue.",
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
                    onPressed: () {
                      // TODO: call resend-code endpoint
                    },
                    child: Text('Resend Code', style: AppTextStyles.muted),
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
