import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _branchController;

  bool _editing = false;
  bool _saving = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Admin profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _profileHeader(auth),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Profile details')),
                      TextButton.icon(
                        onPressed: _editing ? _cancelEditing : _beginEditing,
                        icon: Icon(
                          _editing ? Icons.close_rounded : Icons.edit_rounded,
                          size: 17,
                        ),
                        label: Text(_editing ? 'Cancel' : 'Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_editing) _editCard() else _profileDetailsCard(auth),
                  const SizedBox(height: 20),
                  const _SectionTitle('Admin access'),
                  const SizedBox(height: 8),
                  _accessCard(auth),
                  const SizedBox(height: 20),
                  const _SectionTitle('Security'),
                  const SizedBox(height: 8),
                  _securityCard(auth),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Log out',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrator identity and profile changes are supplied by the authenticated BurgerBites server account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(AuthService auth) {
    final name = auth.currentUserName?.trim().isNotEmpty == true
        ? auth.currentUserName!.trim()
        : 'Administrator';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B32), Color(0xFFF3481E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: AppColors.brandOrangeDark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  auth.currentUserEmail ?? 'Email unavailable',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SIGNED IN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDetailsCard(AuthService auth) {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Full name',
          value: auth.currentUserName ?? 'Not provided by the server',
          icon: Icons.person_outline,
        ),
        _DetailRow(
          label: 'Email address',
          value: auth.currentUserEmail ?? 'Not provided',
          icon: Icons.email_outlined,
        ),
        _DetailRow(
          label: 'Phone number',
          value: auth.currentUserPhone ?? 'Not provided',
          icon: Icons.phone_outlined,
        ),
        _DetailRow(
          label: 'Restaurant branch',
          value: auth.currentUserBranch ?? 'Not assigned',
          icon: Icons.storefront_outlined,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _editCard() {
    return _InfoCard(
      children: [
        _EditField(label: 'Full name', controller: _nameController),
        _EditField(
          label: 'Phone number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        _EditField(label: 'Restaurant branch', controller: _branchController),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving…' : 'Save profile'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accessCard(AuthService auth) {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Admin ID',
          value: auth.currentUserId ?? 'Unavailable',
          icon: Icons.badge_outlined,
        ),
        _DetailRow(
          label: 'Account role',
          value: 'Administrator (server role)',
          icon: Icons.admin_panel_settings_outlined,
        ),
        _DetailRow(
          label: 'Permissions',
          value: 'Dashboard · Orders · Products · Customers · Support',
          icon: Icons.key_outlined,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _securityCard(AuthService auth) {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Sign-in method',
          value: 'BurgerBites server session',
          icon: Icons.lock_outline_rounded,
        ),
        _DetailRow(
          label: 'Account status',
          value: auth.isAuthenticated ? 'Authenticated' : 'Signed out',
          icon: Icons.verified_user_outlined,
          showDivider: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _changingPassword ? null : _changePassword,
              icon: _changingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.password_rounded, size: 17),
              label: Text(
                _changingPassword ? 'Updating password…' : 'Change password',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmation = TextEditingController();
    String? validationMessage;
    final passwords = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                TextField(
                  controller: next,
                  obscureText: true,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'New password (12+ characters)',
                  ),
                ),
                TextField(
                  controller: confirmation,
                  obscureText: true,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                ),
                if (validationMessage != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      validationMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (current.text.isEmpty) {
                  setDialogState(
                    () => validationMessage = 'Enter your current password.',
                  );
                  return;
                }
                if (next.text.length < 12) {
                  setDialogState(
                    () => validationMessage =
                        'Use at least 12 characters for the new password.',
                  );
                  return;
                }
                if (next.text != confirmation.text) {
                  setDialogState(
                    () => validationMessage = 'The new passwords do not match.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, (current.text, next.text));
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    final currentPassword = current.text;
    final nextPassword = next.text;
    current.dispose();
    next.dispose();
    confirmation.dispose();
    if (passwords == null || !mounted) return;

    setState(() => _changingPassword = true);
    final response = await ApiService().put<Map<String, dynamic>>(
      '/me/password',
      body: {'current_password': currentPassword, 'new_password': nextPassword},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid password response.'),
    );
    if (!mounted) return;
    setState(() => _changingPassword = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Password changed. Other signed-in sessions were ended.'
              : response.error ?? 'Unable to change your password.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _beginEditing() {
    final auth = context.read<AuthService>();
    _nameController.text = auth.currentUserName ?? '';
    _phoneController.text = auth.currentUserPhone ?? '';
    _branchController.text = auth.currentUserBranch ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() => setState(() => _editing = false);

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter your full name.')));
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final saved = await auth.updateProfile(
      name: name,
      phone: _phoneController.text,
      branch: _branchController.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Profile saved to your account.'
              : auth.errorMessage ?? 'Unable to save profile changes.',
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the BurgerBites sign-in page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return 'AD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandOrange, size: 19),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (showDivider)
        const Divider(
          height: 1,
          indent: 44,
          endIndent: 14,
          color: AppColors.border,
        ),
    ],
  );
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        isDense: true,
      ),
    ),
  );
}
