import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validate_password.dart';
import '../widgets/app_chrome.dart';
import '../widgets/password_requirements.dart';

/// Mirrors frontend/src/pages/AuthPage.jsx exactly: ONE screen with a
/// Register/Login tab switcher (not two separate pages), a gradient
/// background, and email-verification / forgot-password shown as dimmed
/// overlays on top of the same card rather than separate navigations.
class AuthScreen extends StatefulWidget {
  final bool initialRegister;

  const AuthScreen({super.key, this.initialRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Overlay { none, verify, forgotRequest, forgotReset }

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegister = widget.initialRegister;
  _Overlay _overlay = _Overlay.none;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  ({bool isError, String text})? _authMessage;
  bool _loading = false;

  final _regEmailController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmController = TextEditingController();
  bool _agreedToTerms = false;

  final _verificationCodeController = TextEditingController();
  ({bool isError, String text})? _verificationMessage;

  final _forgotEmailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();
  ({bool isError, String text})? _forgotMessage;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regEmailController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmController.dispose();
    _verificationCodeController.dispose();
    _forgotEmailController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _authMessage = null;
      _loading = true;
    });
    final email = _loginEmailController.text.trim();
    try {
      await AuthService.login(email: email, password: _loginPasswordController.text);
      if (!mounted) return;
      context.go('/dashboard');
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        setState(() {
          _regEmailController.text = email;
          _verificationMessage = (isError: true, text: 'Please verify your email to continue.');
          _overlay = _Overlay.verify;
        });
      } else {
        setState(() => _authMessage = (isError: true, text: e.message));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _authMessage = null);
    if (!isPasswordValid(_regPasswordController.text)) {
      setState(() => _authMessage = (isError: true, text: 'Password must be at least $kMinPasswordLength characters'));
      return;
    }
    if (_regPasswordController.text != _regConfirmController.text) {
      setState(() => _authMessage = (isError: true, text: 'Passwords do not match'));
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _authMessage = (isError: true, text: 'You must agree to the Terms of Service'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.register(
        email: _regEmailController.text.trim(),
        username: _regUsernameController.text.trim(),
        password: _regPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _verificationMessage = null;
        _overlay = _Overlay.verify;
      });
    } on ApiException catch (e) {
      setState(() => _authMessage = (isError: true, text: e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleVerify() async {
    try {
      await AuthService.verifyEmail(email: _regEmailController.text.trim(), code: _verificationCodeController.text.trim());
      if (!mounted) return;
      setState(() => _overlay = _Overlay.none);
      context.go('/dashboard');
    } on ApiException catch (e) {
      setState(() => _verificationMessage = (isError: true, text: e.message));
    }
  }

  Future<void> _handleResend() async {
    try {
      await AuthService.resendVerification(email: _regEmailController.text.trim());
      setState(() => _verificationMessage = (isError: false, text: 'Code resent — check your email.'));
    } on ApiException catch (e) {
      setState(() => _verificationMessage = (isError: true, text: e.message));
    }
  }

  void _openForgotPassword() {
    _forgotEmailController.text = _loginEmailController.text;
    _resetCodeController.clear();
    _newPasswordController.clear();
    _newPasswordConfirmController.clear();
    setState(() {
      _forgotMessage = null;
      _overlay = _Overlay.forgotRequest;
    });
  }

  Future<void> _handleForgotRequest() async {
    try {
      final message = await AuthService.forgotPassword(email: _forgotEmailController.text.trim());
      setState(() {
        _overlay = _Overlay.forgotReset;
        _forgotMessage = (isError: false, text: message);
      });
    } on ApiException catch (e) {
      setState(() => _forgotMessage = (isError: true, text: e.message));
    }
  }

  Future<void> _handleResetPassword() async {
    if (!isPasswordValid(_newPasswordController.text)) {
      setState(() => _forgotMessage = (isError: true, text: 'Password must be at least $kMinPasswordLength characters'));
      return;
    }
    if (_newPasswordController.text != _newPasswordConfirmController.text) {
      setState(() => _forgotMessage = (isError: true, text: 'Passwords do not match'));
      return;
    }
    try {
      await AuthService.resetPassword(
        email: _forgotEmailController.text.trim(),
        code: _resetCodeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _overlay = _Overlay.none;
        _isRegister = false;
        _loginEmailController.text = _forgotEmailController.text;
        _loginPasswordController.clear();
        _authMessage = (isError: false, text: 'Password reset — log in with your new password.');
      });
    } on ApiException catch (e) {
      setState(() => _forgotMessage = (isError: true, text: e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.spaceSurface, AppPalette.spaceBlack, Colors.black],
                  stops: [0.0, 0.65, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.goldLight, AppPalette.gold, AppPalette.goldDark],
                  stops: [0.0, 0.55, 1.0],
                ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 10))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AuthTabs(
                          isRegister: _isRegister,
                          onChanged: (v) => setState(() {
                            _isRegister = v;
                            _authMessage = null;
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: _isRegister ? _buildRegisterForm(context) : _buildLoginForm(context),
                        ),
                      ],
                    ),
                  ),
                  if (_overlay != _Overlay.none) _buildOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Login', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 22)),
        const SizedBox(height: 18),
        _FieldGroup(label: 'Email:', icon: Icons.email_outlined, hint: 'Enter your email', controller: _loginEmailController),
        const SizedBox(height: 18),
        _FieldGroup(
          label: 'Password:',
          icon: Icons.lock_outline,
          hint: 'Enter your password',
          controller: _loginPasswordController,
          obscure: true,
        ),
        if (_authMessage != null) ...[
          const SizedBox(height: 8),
          _AuthMessage(message: _authMessage!),
        ],
        const SizedBox(height: 18),
        _SubmitButton(label: 'Login', loading: _loading, onPressed: _handleLogin),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _openForgotPassword,
            child: Text('Forgot password?', style: AppTextStyles.muted.copyWith(decoration: TextDecoration.underline)),
          ),
        ),
        Center(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.muted,
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Register.',
                  style: TextStyle(color: ThemeColors.text(context), decoration: TextDecoration.underline),
                  recognizer: (TapGestureRecognizer()..onTap = () => setState(() => _isRegister = true)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Register Your Account', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 22)),
        const SizedBox(height: 18),
        _FieldGroup(label: 'Email:', icon: Icons.email_outlined, hint: 'Enter your email', controller: _regEmailController),
        const SizedBox(height: 18),
        _FieldGroup(label: 'Full name:', icon: Icons.person_outline, hint: 'Enter your full name', controller: _regUsernameController),
        const SizedBox(height: 18),
        _FieldGroup(
          label: 'Password:',
          icon: Icons.lock_outline,
          hint: 'Enter your password',
          controller: _regPasswordController,
          obscure: true,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _regPasswordController,
          builder: (context, value, _) => PasswordRequirementsChecklist(password: value.text),
        ),
        const SizedBox(height: 18),
        _FieldGroup(
          label: 'Verify Password:',
          icon: Icons.lock_outline,
          hint: 'Verify your password',
          controller: _regConfirmController,
          obscure: true,
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: AppPalette.gold,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'By checking this box, you are agreeing to our terms of service.',
                    style: AppTextStyles.muted.copyWith(fontWeight: AppFontWeights.bold, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_authMessage != null) ...[
          const SizedBox(height: 4),
          _AuthMessage(message: _authMessage!),
        ],
        const SizedBox(height: 14),
        _SubmitButton(label: 'Register', loading: _loading, onPressed: _handleRegister),
        const SizedBox(height: 6),
        Center(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.muted,
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Login.',
                  style: TextStyle(color: ThemeColors.text(context), decoration: TextDecoration.underline),
                  recognizer: (TapGestureRecognizer()..onTap = () => setState(() => _isRegister = false)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    late Widget card;
    switch (_overlay) {
      case _Overlay.verify:
        card = _VerificationCard(
          heading: 'Verify Your Email',
          subtext: 'We sent a code to ${_regEmailController.text.isEmpty ? 'your email' : _regEmailController.text}',
          codeController: _verificationCodeController,
          message: _verificationMessage,
          submitLabel: 'Verify',
          onSubmit: _handleVerify,
          onResend: _handleResend,
        );
        break;
      case _Overlay.forgotRequest:
        card = _VerificationCard(
          heading: 'Reset Password',
          subtext: "Enter your account email and we'll send a reset code.",
          codeController: _forgotEmailController,
          codeHint: 'Email',
          keyboardType: TextInputType.emailAddress,
          message: _forgotMessage,
          submitLabel: 'Send Code',
          onSubmit: _handleForgotRequest,
          onResend: () => setState(() => _overlay = _Overlay.none),
          resendLabel: 'Back to Log In',
        );
        break;
      case _Overlay.forgotReset:
        card = _VerificationCard(
          heading: 'Enter Reset Code',
          subtext: 'We sent a code to ${_forgotEmailController.text.isEmpty ? 'your email' : _forgotEmailController.text}',
          codeController: _resetCodeController,
          codeHint: 'Reset code',
          extraFields: [
            const SizedBox(height: 12),
            _DarkInput(controller: _newPasswordController, hint: 'New password', obscure: true),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _newPasswordController,
              builder: (context, value, _) => PasswordRequirementsChecklist(password: value.text),
            ),
            const SizedBox(height: 12),
            _DarkInput(controller: _newPasswordConfirmController, hint: 'Confirm new password', obscure: true),
          ],
          message: _forgotMessage,
          submitLabel: 'Reset Password',
          onSubmit: _handleResetPassword,
          onResend: _handleForgotRequest,
        );
        break;
      case _Overlay.none:
        card = const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: card),
          ),
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onChanged;

  const _AuthTabs({required this.isRegister, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _AuthTab(label: 'Register', icon: Icons.edit_outlined, active: isRegister, onTap: () => onChanged(true))),
        Expanded(child: _AuthTab(label: 'Login', icon: Icons.login, active: !isRegister, onTap: () => onChanged(false))),
      ],
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AuthTab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: active ? AppColors.black : ThemeColors.surface(context),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.white : ThemeColors.text(context)),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.subheading.copyWith(
                fontSize: 16,
                color: active ? AppColors.white : ThemeColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors .field-group: a small label caption above a bordered icon+input
/// row (not a filled decoration like AppTextField elsewhere in the app).
class _FieldGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  const _FieldGroup({
    required this.label,
    required this.icon,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.muted.copyWith(fontWeight: AppFontWeights.medium, fontSize: 13, color: ThemeColors.text(context))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ThemeColors.border(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: ThemeColors.textMuted(context)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.muted,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppPalette.blue : AppColors.black,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: AppTextStyles.subheading.copyWith(fontSize: 15, letterSpacing: 0.6),
      ),
      child: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label.toUpperCase()),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final ({bool isError, String text}) message;

  const _AuthMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message.text,
      textAlign: TextAlign.center,
      style: AppTextStyles.muted.copyWith(color: message.isError ? ThemeColors.error(context) : ThemeColors.success(context)),
    );
  }
}

/// Mirrors .verification-card: a dark card dimming-overlaid on the auth
/// card, used for both email verification and the forgot-password flow.
class _VerificationCard extends StatelessWidget {
  final String heading;
  final String subtext;
  final TextEditingController codeController;
  final String codeHint;
  final TextInputType keyboardType;
  final List<Widget> extraFields;
  final ({bool isError, String text})? message;
  final String submitLabel;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final String resendLabel;

  const _VerificationCard({
    required this.heading,
    required this.subtext,
    required this.codeController,
    this.codeHint = 'Enter code',
    this.keyboardType = TextInputType.number,
    this.extraFields = const [],
    required this.message,
    required this.submitLabel,
    required this.onSubmit,
    required this.onResend,
    this.resendLabel = 'Resend code',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheading.copyWith(color: AppColors.white, fontSize: 18, decoration: TextDecoration.underline),
          ),
          const SizedBox(height: 10),
          Text(
            subtext,
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          _DarkInput(controller: codeController, hint: codeHint, keyboardType: keyboardType, centered: true),
          ...extraFields,
          if (message != null) ...[
            const SizedBox(height: 8),
            _AuthMessage(message: message!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.gold,
                foregroundColor: AppPalette.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: AppTextStyles.subheading.copyWith(fontSize: 14),
              ),
              child: Text(submitLabel.toUpperCase()),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onResend,
            child: Text(
              resendLabel,
              style: AppTextStyles.muted.copyWith(color: Colors.white70, decoration: TextDecoration.underline, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool centered;
  final TextInputType keyboardType;

  const _DarkInput({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.centered = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: AppTextStyles.subheading.copyWith(color: AppColors.white, letterSpacing: centered ? 4 : 0, fontSize: centered ? 18 : 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.muted.copyWith(color: Colors.white54),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }
}
