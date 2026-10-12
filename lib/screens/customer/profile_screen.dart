import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(backgroundColor: AppColors.pageBackground, title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.brandOrange,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'customer@burgerbites.app',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProfileTile(
              title: 'Account settings',
              icon: Icons.settings_outlined,
              onTap: '/settings',
            ),
            _ProfileTile(title: 'Preferences', icon: Icons.palette_outlined, onTap: '/themes'),
            _ProfileTile(title: 'Language', icon: Icons.language_rounded, onTap: '/language'),
            _ProfileTile(title: 'Contact', icon: Icons.call_outlined, onTap: '/contact'),
            _ProfileTile(title: 'About', icon: Icons.info_outline_rounded, onTap: '/about'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final String onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed(onTap),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.brandOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
