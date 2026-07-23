import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_state.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_form_field.dart';

/// Mirrors frontend/src/pages/ProfilePage.jsx: an Overview tab (avatar,
/// username/email, 3 most recent reviews) and an Account tab (change
/// username / email / password, plus delete account).
class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  // 'overview' | 'edit'
  String _tab = 'overview';

  // Recent reviews (top 3, most recent first — per the Figma comment)
  List<Review>? _reviews;
  String? _reviewsError;

  // Account settings state, mirroring ProfilePage.jsx:
  // one open section at a time, one message slot tagged with its section.
  String? _openSection; // 'username' | 'email' | 'password' | null
  ({String section, bool isError, String text})? _message;
  bool _saving = false;

  // Email change is a two-step flow: once the code has been requested, this
  // holds the address awaiting verification and the section shows a code
  // field instead of the email field.
  String? _emailPendingNew;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthState.instance.isLoggedIn) {
        context.go('/login');
        return;
      }
      _loadReviews();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.getMyReviews();
      // Mirrors ProfilePage.jsx: newest first, top 3 only.
      reviews.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _reviews = reviews.take(3).toList();
        _reviewsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reviewsError = e.message);
    }
  }

  void _toggleSection(String name) {
    setState(() {
      _message = null;
      _openSection = _openSection == name ? null : name;
      _emailPendingNew = null;
      _usernameController.clear();
      _emailController.clear();
      _emailCodeController.clear();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _message = (section: 'username', isError: true, text: 'Username is required'));
      return;
    }
    setState(() => _saving = true);
    try {
      await UserService.changeUsername(username);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _openSection = null;
        _message = (section: 'username', isError: false, text: 'Username updated');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (section: 'username', isError: true, text: e.message);
      });
    }
  }

  Future<void> _requestEmailChange() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      setState(() => _message = (section: 'email', isError: true, text: 'Email is required'));
      return;
    }
    setState(() => _saving = true);
    try {
      final message = await UserService.requestEmailChange(newEmail);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _emailPendingNew = newEmail;
        _message = (section: 'email', isError: false, text: message);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (section: 'email', isError: true, text: e.message);
      });
    }
  }

  Future<void> _verifyEmailChange() async {
    final code = _emailCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = (section: 'email', isError: true, text: 'Code is required'));
      return;
    }
    setState(() => _saving = true);
    try {
      await UserService.verifyEmailChange(code);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _openSection = null;
        _emailPendingNew = null;
        _message = (section: 'email', isError: false, text: 'Email updated');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (section: 'email', isError: true, text: e.message);
      });
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (current.isEmpty || next.isEmpty) {
      setState(() => _message = (section: 'password', isError: true, text: 'All fields are required'));
      return;
    }
    if (next != confirm) {
      setState(() => _message = (section: 'password', isError: true, text: 'Passwords do not match'));
      return;
    }
    setState(() => _saving = true);
    try {
      final message = await UserService.changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _openSection = null;
        _message = (section: 'password', isError: false, text: message);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (section: 'password', isError: true, text: e.message);
      });
    }
  }

  Future<void> _confirmDelete() async {
    final password = _deletePasswordController.text;
    if (password.isEmpty) {
      setState(() => _message = (section: 'delete', isError: true, text: 'Password is required'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your account and all of your reviews. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await UserService.deleteAccount(password);
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (section: 'delete', isError: true, text: e.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthState.instance.isLoggedIn) {
      return const AppScaffold(body: SizedBox.shrink());
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: ListenableBuilder(
          // AuthState so session changes reflect instantly; the theme
          // controller so this screen's colors flip the moment the
          // moon/sun toggle is tapped.
          listenable: Listenable.merge([AuthState.instance, ThemeController.instance]),
          builder: (context, _) {
            final username = AuthState.instance.username ?? '';
            final email = AuthState.instance.email ?? '';
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sidebar-tint nav band, mirrors .profile-sidebar's
                        // mobile-breakpoint row layout.
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 76, 12, 12),
                          decoration: BoxDecoration(
                            color: ThemeColors.bg(context),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: _NavRow(
                            tab: _tab,
                            onOverview: () => setState(() => _tab = 'overview'),
                            onAccount: () => setState(() {
                              _tab = 'edit';
                              _openSection = null;
                              _message = null;
                            }),
                            onLogout: _logout,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: AppTextStyles.heading.copyWith(fontSize: 24)),
                              Text(email, style: AppTextStyles.muted),
                              const SizedBox(height: 16),
                              if (_tab == 'overview') ..._buildOverview() else ..._buildAccount(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Avatar overlapping the top-left of the card, mirrors
                    // .profile-avatar's mobile-breakpoint left:16px offset.
                    Positioned(
                      top: -32,
                      left: 16,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeColors.bg(context),
                          border: Border.all(color: ThemeColors.surface(context), width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: AppTextStyles.display.copyWith(color: ThemeColors.primary(context), fontSize: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildOverview() {
    return [
      Text('Recent Reviews', style: AppTextStyles.subheading),
      const SizedBox(height: 12),
      if (_reviewsError != null)
        Text(_reviewsError!, style: AppTextStyles.muted.copyWith(color: ThemeColors.error(context)))
      else if (_reviews == null)
        const Center(
          child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
        )
      else if (_reviews!.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text("You haven't written any reviews yet.", style: AppTextStyles.muted),
        )
      else
        for (final review in _reviews!)
          GestureDetector(
            onTap: () {
              StatefulNavigationShell.of(context).goBranch(1);
              context.push('/courses/${review.courseId}');
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ThemeColors.bg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (review.courseCode != null) review.courseCode!,
                      if (review.courseTitle != null) review.courseTitle!,
                    ].join(' — '),
                    style: AppTextStyles.subheading,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      'Quality: ${review.quality}/5',
                      'Difficulty: ${review.difficulty}/5',
                      if (review.term != null && review.term!.isNotEmpty) review.term!,
                    ].join(' • '),
                    style: AppTextStyles.muted,
                  ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      review.comment!,
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
    ];
  }

  List<Widget> _buildAccount() {
    final username = AuthState.instance.username ?? '—';
    final email = AuthState.instance.email ?? '—';

    return [
      Text('Account Settings', style: AppTextStyles.heading),
      const SizedBox(height: 8),

      // --- Username ---
      _SettingsRow(
        label: 'Username',
        value: username,
        onChange: () => _toggleSection('username'),
      ),
      if (_message?.section == 'username') _MessageText(message: _message!),
      if (_openSection == 'username')
        _SettingsForm(
          saveLabel: 'Save',
          saving: _saving,
          onCancel: () => setState(() => _openSection = null),
          onSave: _saveUsername,
          children: [
            AppTextField(
              controller: _usernameController,
              hint: 'New username',
              icon: Icons.person_outline,
            ),
          ],
        ),

      // --- Email ---
      _SettingsRow(
        label: 'Email',
        value: email,
        onChange: () => _toggleSection('email'),
      ),
      if (_message?.section == 'email') _MessageText(message: _message!),
      if (_openSection == 'email')
        _SettingsForm(
          saveLabel: _emailPendingNew == null ? 'Send Code' : 'Verify',
          saving: _saving,
          onCancel: () => setState(() => _openSection = null),
          onSave: _emailPendingNew == null ? _requestEmailChange : _verifyEmailChange,
          children: _emailPendingNew == null
              ? [
                  AppTextField(
                    controller: _emailController,
                    hint: 'New email address',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ]
              : [
                  Text(
                    'Enter the code sent to $_emailPendingNew',
                    style: AppTextStyles.muted,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _emailCodeController,
                    hint: 'Verification code',
                    icon: Icons.dialpad,
                    keyboardType: TextInputType.number,
                  ),
                ],
        ),

      // --- Password ---
      _SettingsRow(
        label: 'Password',
        value: '••••••••',
        onChange: () => _toggleSection('password'),
      ),
      if (_message?.section == 'password') _MessageText(message: _message!),
      if (_openSection == 'password')
        _SettingsForm(
          saveLabel: 'Save',
          saving: _saving,
          onCancel: () => setState(() => _openSection = null),
          onSave: _savePassword,
          children: [
            AppTextField(
              controller: _currentPasswordController,
              hint: 'Current password',
              icon: Icons.lock_outline,
              obscure: true,
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
        ),

      const SizedBox(height: 16),
      Divider(color: ThemeColors.border(context)),
      const SizedBox(height: 8),

      // --- Delete account ---
      Text(
        'Delete Account',
        style: AppTextStyles.subheading.copyWith(color: ThemeColors.error(context)),
      ),
      const SizedBox(height: 4),
      Text(
        'This permanently removes your account and all of your reviews.',
        style: AppTextStyles.muted,
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _deletePasswordController,
        hint: 'Confirm your password',
        icon: Icons.lock_outline,
        obscure: true,
      ),
      if (_message?.section == 'delete') _MessageText(message: _message!),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.error(context),
            foregroundColor: AppColors.white,
          ),
          onPressed: _saving ? null : _confirmDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete Account'),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}

/// The web sidebar (Overview / Account / Log Out) as a horizontal nav row —
/// mirrors ProfilePage.css's own mobile breakpoint, where the sidebar
/// flattens into a row with a bottom accent border on the active item.
class _NavRow extends StatelessWidget {
  final String tab;
  final VoidCallback onOverview;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  const _NavRow({
    required this.tab,
    required this.onOverview,
    required this.onAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavButton(label: 'Overview', active: tab == 'overview', onTap: onOverview),
        const SizedBox(width: 8),
        _NavButton(label: 'Account', active: tab == 'edit', onTap: onAccount),
        const Spacer(),
        _NavButton(label: 'Log Out', active: false, onTap: onLogout),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? ThemeColors.primary(context) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: active
              ? AppTextStyles.subheading.copyWith(color: ThemeColors.text(context))
              : AppTextStyles.subheading.copyWith(color: ThemeColors.textMuted(context)),
        ),
      ),
    );
  }
}

/// One settings line: label + current value on the left, a Change button on
/// the right — mirrors .settings-row in ProfilePage.css.
class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onChange;

  const _SettingsRow({required this.label, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.muted),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.subheading,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

/// An expanded inline form under a settings row, with Cancel/Save actions —
/// mirrors .settings-form in ProfilePage.css.
class _SettingsForm extends StatelessWidget {
  final List<Widget> children;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  const _SettingsForm({
    required this.children,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: saving ? null : onCancel,
                child: Text('Cancel', style: AppTextStyles.muted),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(saveLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageText extends StatelessWidget {
  final ({String section, bool isError, String text}) message;

  const _MessageText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message.text,
        style: AppTextStyles.muted.copyWith(
          color: message.isError ? ThemeColors.error(context) : ThemeColors.success(context),
        ),
      ),
    );
  }
}
