import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 31,
                            color: AppColors.brandOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUserName ?? 'Customer account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                auth.currentUserEmail ??
                                    'Sign in to load account details',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: AppColors.brandOrange,
                                  ),
                                  SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      auth.currentUserAddress ??
                                          'No saved delivery address',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/settings'),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  const _RewardsCard(),
                  const SizedBox(height: 13),
                  const Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.receipt_long_rounded,
                          value: '—',
                          label: 'Orders',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.stars_rounded,
                          value: '—',
                          label: 'Points',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.delivery_dining_rounded,
                          value: '—',
                          label: 'Deliveries',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _GroupLabel(title: 'PERSONAL & PREFERENCES'),
                  const SizedBox(height: 7),
                  _ProfileTile(
                    title: 'Account settings',
                    subtitle: 'Email, phone and security',
                    icon: Icons.manage_accounts_outlined,
                    route: '/settings',
                  ),
                  _ProfileTile(
                    title: 'Language',
                    subtitle: 'Bisaya (Cebuano)',
                    icon: Icons.language_rounded,
                    route: '/language',
                  ),
                  _ProfileTile(
                    title: 'Theme & appearance',
                    subtitle: 'Choose your app colors',
                    icon: Icons.palette_outlined,
                    route: '/themes',
                  ),
                  _ProfileTile(
                    title: 'Calendar & milestones',
                    subtitle: 'Important dates and reminders',
                    icon: Icons.calendar_month_rounded,
                    route: '/calendar',
                  ),
                  _ProfileTile(
                    title: 'Favorites',
                    subtitle: 'Products you saved',
                    icon: Icons.favorite_border_rounded,
                    route: '/favorites',
                  ),
                  _ProfileTile(
                    title: 'Order history',
                    subtitle: 'View your past orders',
                    icon: Icons.receipt_long_outlined,
                    route: '/order-history',
                  ),
                  const SizedBox(height: 17),
                  const _GroupLabel(title: 'SUPPORT'),
                  const SizedBox(height: 7),
                  _ProfileTile(
                    title: 'Contact BurgerBites',
                    subtitle: 'We are here to help',
                    icon: Icons.support_agent_rounded,
                    route: '/contact',
                  ),
                  _ProfileTile(
                    title: 'About us',
                    subtitle: 'Our story and values',
                    icon: Icons.info_outline_rounded,
                    route: '/about',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (auth.isAuthenticated) {
                        await context.read<AuthService>().logout();
                      }
                      if (!context.mounted) return;
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 17),
                    label: Text(auth.isAuthenticated ? 'Sign out' : 'Sign in'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(47),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'BurgerBites · Fresh food, happy moments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF231B17), Color(0xFF3A2A20)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFFC247), size: 19),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'BURGER BITES · REWARDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: .5,
                  ),
                ),
              ),
              Text(
                'ACCOUNT SERVICE REQUIRED',
                style: TextStyle(
                  color: Color(0xFFFFC247),
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Rewards and points will appear here when the customer account service is connected.',
            style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.brandOrange, size: 18),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
        ),
      ],
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: .7,
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed(route),
        dense: true,
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.brandOrange, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
