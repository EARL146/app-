import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController(text: 'Juan Dela Cruz');
  final _emailController = TextEditingController(
    text: 'juan.delacruz@example.com',
  );
  final _phoneController = TextEditingController(text: '+63 912 345 6789');
  bool _twoStep = true;
  bool _orderUpdates = true;
  bool _digitalReceipt = true;
  bool _promotions = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                  subtitle: 'Last updated: not available',
                  action: 'Change',
                  onTap: () => _notice('Password changes'),
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
                    'Account verification preview',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (value) => setState(() => _twoStep = value),
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
                  title: 'Order updates via SMS',
                  subtitle: 'Delivery status updates',
                  value: _orderUpdates,
                  onChanged: (value) => setState(() => _orderUpdates = value),
                ),
                _PreferenceSwitch(
                  title: 'Digital e-receipt',
                  subtitle: 'Send order receipts to email',
                  value: _digitalReceipt,
                  onChanged: (value) => setState(() => _digitalReceipt = value),
                ),
                _PreferenceSwitch(
                  title: 'Promotional alerts',
                  subtitle: 'Offers, launches and coupons',
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
                    'Settings are saved only in this screen preview. Authentication and notification services are not connected.',
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account preferences saved for this preview only.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Save changes'),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _twoStep = true;
                _orderUpdates = true;
                _digitalReceipt = true;
                _promotions = false;
              }),
              child: const Text(
                'Cancel reset',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _notice(String feature) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature are not connected in this demo.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
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
