import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _requestedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    final userId = auth.currentUserId;
    if (!auth.isAuthenticated || userId == null) {
      _requestedUserId = null;
      return;
    }
    if (_requestedUserId == userId) return;
    _requestedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.read<AuthService>().currentUserId != userId) {
        return;
      }
      unawaited(context.read<CustomerOrdersProvider>().loadOrders(force: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final customerOrders = context.watch<CustomerOrdersProvider>();
    final orderCountStatus = _orderCountStatus(auth, customerOrders);
    final orderCount =
        orderCountStatus.value ?? customerOrders.orders.length.toString();
    final deliveryCount =
        orderCountStatus.value ??
        customerOrders.orders
            .where((order) => order.status == OrderStatus.delivered)
            .length
            .toString();
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
                      gradient: AppColors.warmSurfaceGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D1E130C),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryButtonGradient,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26FF6422),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 31,
                            color: Colors.white,
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
                  if (!auth.isAuthenticated && !auth.isInitializing) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Customer and admin accounts can sign in here.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/sign-in'),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                  const _RewardsCard(),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.receipt_long_rounded,
                          value: orderCount,
                          label: 'Orders',
                          detail: orderCountStatus.detail,
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.stars_rounded,
                          value: '—',
                          label: 'Points',
                          detail: 'Not supported yet',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.delivery_dining_rounded,
                          value: deliveryCount,
                          label: 'Deliveries',
                          detail: orderCountStatus.detail,
                        ),
                      ),
                    ],
                  ),
                  if (auth.isAuthenticated &&
                      customerOrders.errorMessage != null) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order history unavailable. ${customerOrders.errorMessage}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context
                              .read<CustomerOrdersProvider>()
                              .loadOrders(force: true),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
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
                  if (auth.isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthService>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/customer-home',
                          (route) => false,
                          arguments: true,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 17),
                      label: const Text('Sign out'),
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

({String? value, String? detail}) _orderCountStatus(
  AuthService auth,
  CustomerOrdersProvider orders,
) {
  if (auth.isInitializing) return (value: '…', detail: 'Checking account');
  if (!auth.isAuthenticated) return (value: '—', detail: 'Sign in to view');
  if (orders.isLoading) return (value: '…', detail: 'Loading');
  if (orders.errorMessage != null) {
    return (value: '—', detail: 'Unavailable');
  }
  return (value: null, detail: null);
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
                'POINTS NOT AVAILABLE',
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
            'Points are unavailable because the BurgerBites API and database do not support rewards yet.',
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
    this.detail,
  });
  final IconData icon;
  final String value;
  final String label;
  final String? detail;

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
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 7),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AnimatedPressScale(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
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
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
