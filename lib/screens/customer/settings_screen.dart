import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _twoStep = false;
  bool _orderUpdates = true;
  bool _digitalReceipt = true;
  bool _promotions = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _nameController.text = auth.currentUserName ?? '';
    _emailController.text = auth.currentUserEmail ?? '';
    _phoneController.text = auth.currentUserPhone ?? '';
    _addressController.text = auth.currentUserAddress ?? '';
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Account settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 4, 17, 22),
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          if (_loadError != null)
            TextButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_loadError!),
            ),
          const Text(
            'Manage your account details, contact options and security preferences.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'PERSONAL DETAILS',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Default delivery address',
                    hintText: 'House/building, street, barangay, city',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          _SettingsSection(
            title: 'SECURITY & LOGIN',
            child: Column(
              children: [
                _SettingsAction(
                  icon: Icons.lock_outline_rounded,
                  title: 'Password',
                  subtitle: 'Change the password used to sign in.',
                  action: 'Change',
                  onTap: _changePassword,
                ),
                const Divider(height: 15),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _twoStep,
                  activeThumbColor: AppColors.brandOrange,
                  title: const Text(
                    'Two-step verification',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Two-step sign-in is not configured.',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: null,
                ),
                const Divider(height: 15),
                _SettingsAction(
                  icon: Icons.g_mobiledata_rounded,
                  title: 'Google account',
                  subtitle: 'Not connected',
                  action: 'Link',
                  onTap: () => _notice('Google account linking'),
                ),
                _SettingsAction(
                  icon: Icons.apple_rounded,
                  title: 'Apple account',
                  subtitle: 'Not connected',
                  action: 'Link',
                  onTap: () => _notice('Apple account linking'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          _SettingsSection(
            title: 'NOTIFICATIONS & RECEIPTS',
            child: Column(
              children: [
                _PreferenceSwitch(
                  title: 'SMS order update preference',
                  subtitle:
                      'Saved to your account; SMS messages are not sent yet.',
                  value: _orderUpdates,
                  onChanged: (value) => setState(() => _orderUpdates = value),
                ),
                _PreferenceSwitch(
                  title: 'Email receipt preference',
                  subtitle: 'Saved to your account; email delivery is not configured.',
                  value: _digitalReceipt,
                  onChanged: (value) => setState(() => _digitalReceipt = value),
                ),
                _PreferenceSwitch(
                  title: 'Promotional alert preference',
                  subtitle: 'Saved to your account; promotional messages are not sent yet.',
                  value: _promotions,
                  onChanged: (value) => setState(() => _promotions = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandOrange,
                  size: 15,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Your profile and notification preferences save to your account. SMS and email delivery, two-step sign-in, and social login need provider configuration.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: Text(_isSaving ? 'Saving…' : 'Save changes'),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _twoStep = false;
                _orderUpdates = true;
                _digitalReceipt = true;
                _promotions = false;
              }),
              child: const Text(
                'Reset preferences',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final response = await ApiService().get<Map<String, dynamic>>(
      '/me/preferences',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    if (!mounted) return;
    final preferences = response.data?['preferences'];
    if (!response.success || preferences is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _loadError = response.error ?? 'Unable to load account preferences.';
      });
      return;
    }
    setState(() {
      _orderUpdates = preferences['order_updates'] as bool? ?? true;
      _digitalReceipt = preferences['digital_receipt'] as bool? ?? true;
      _promotions = preferences['promotional_alerts'] as bool? ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final auth = context.read<AuthService>();
    final profileSaved = await auth.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
    );
    if (!mounted) return;
    if (!profileSaved) {
      setState(() => _isSaving = false);
      _showMessage(auth.errorMessage ?? 'Unable to save your profile.');
      return;
    }
    final response = await ApiService().put<Map<String, dynamic>>(
      '/me/preferences',
      body: {
        'order_updates': _orderUpdates,
        'digital_receipt': _digitalReceipt,
        'promotional_alerts': _promotions,
      },
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(
      response.success
          ? 'Profile and preferences saved.'
          : 'Profile saved, but preferences were not saved: ${response.error ?? 'try again.'}',
    );
    if (response.success) await _loadPreferences();
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmation = TextEditingController();
    final passwords = await showDialog<(String, String)?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (next.text != confirmation.text || next.text.length < 12) {
                return;
              }
              Navigator.pop(dialogContext, (current.text, next.text));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    confirmation.dispose();
    if (passwords == null || !mounted) return;
    final response = await ApiService().put<Map<String, dynamic>>(
      '/me/password',
      body: {'current_password': passwords.$1, 'new_password': passwords.$2},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid password response.'),
    );
    if (!mounted) return;
    _showMessage(
      response.success
          ? 'Password changed. Other signed-in sessions were ended.'
          : response.error ?? 'Unable to change your password.',
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

  void _notice(String feature) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature is not configured yet.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: AppColors.brandOrange, size: 17),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
    ),
    trailing: TextButton(
      onPressed: onTap,
      child: Text(
        action,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    dense: true,
    value: value,
    activeThumbColor: AppColors.brandOrange,
    title: Text(
      title,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
    ),
    onChanged: onChanged,
  );
}
