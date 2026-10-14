import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/demo_admin_account.dart';
import '../../navigation/app_routes.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _branchController;

  String _name = DemoAdminAccount.name;
  String _phone = DemoAdminAccount.phone;
  String _branch = DemoAdminAccount.branch;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _phoneController = TextEditingController(text: _phone);
    _branchController = TextEditingController(text: _branch);
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
                  _profileHeader(),
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
                  if (_editing) _editCard() else _profileDetailsCard(),
                  const SizedBox(height: 20),
                  const _SectionTitle('Admin access'),
                  const SizedBox(height: 8),
                  _accessCard(),
                  const SizedBox(height: 20),
                  const _SectionTitle('Security'),
                  const SizedBox(height: 8),
                  _securityCard(),
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
                    'Demo account details and profile edits are local to this preview. No admin account service is connected.',
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

  Widget _profileHeader() {
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
              _initials(_name),
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
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DemoAdminAccount.role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  DemoAdminAccount.email,
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
              'ACTIVE',
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

  Widget _profileDetailsCard() {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Full name',
          value: _name,
          icon: Icons.person_outline,
        ),
        _DetailRow(
          label: 'Email address',
          value: DemoAdminAccount.email,
          icon: Icons.email_outlined,
        ),
        _DetailRow(
          label: 'Phone number',
          value: _phone,
          icon: Icons.phone_outlined,
        ),
        _DetailRow(
          label: 'Restaurant branch',
          value: _branch,
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
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save profile'),
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

  Widget _accessCard() {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Admin ID',
          value: DemoAdminAccount.adminId,
          icon: Icons.badge_outlined,
        ),
        _DetailRow(
          label: 'Account role',
          value: DemoAdminAccount.role,
          icon: Icons.admin_panel_settings_outlined,
        ),
        _DetailRow(
          label: 'Permissions',
          value: 'Dashboard · Orders · Products · Customers',
          icon: Icons.key_outlined,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _securityCard() {
    return _InfoCard(
      children: const [
        _DetailRow(
          label: 'Sign-in method',
          value: 'Local demo account',
          icon: Icons.lock_outline_rounded,
        ),
        _DetailRow(
          label: 'Account status',
          value: 'Active for preview',
          icon: Icons.verified_user_outlined,
          showDivider: false,
        ),
      ],
    );
  }

  void _beginEditing() {
    _nameController.text = _name;
    _phoneController.text = _phone;
    _branchController.text = _branch;
    setState(() => _editing = true);
  }

  void _cancelEditing() => setState(() => _editing = false);

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Full name is required.')));
      return;
    }
    setState(() {
      _name = name;
      _phone = _phoneController.text.trim().isEmpty
          ? 'Not provided'
          : _phoneController.text.trim();
      _branch = _branchController.text.trim().isEmpty
          ? 'Not assigned'
          : _branchController.text.trim();
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated for this session.')),
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
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
