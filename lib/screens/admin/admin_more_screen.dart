import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../navigation/app_routes.dart';
import '../../providers/admin_customers_provider.dart';
import '../../providers/admin_orders_provider.dart';
import '../../providers/admin_products_provider.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  title: const Text(
                    'Admin profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Account details and sign out'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.adminProfile),
                ),
              ),
              const SizedBox(height: 24),
              // Business Revenue Summary
              Text(
                'Revenue Summary',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RevenueSummaryCard(),
              const SizedBox(height: 24),
              // Quick Stats
              Text(
                'Business Health',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _BusinessHealthCard(),
              const SizedBox(height: 24),
              // Admin Settings
              Text(
                'Admin Settings',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _AdminSettingsCard(),
              const SizedBox(height: 24),
              // Payout Information
              Text(
                'Payout Information',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _PayoutCard(),
              const SizedBox(height: 24),
              // App Information
              Text(
                'App Information',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _AppInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminOrdersProvider>(
      builder: (context, orderProvider, _) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Revenue',
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.trending_up, color: AppColors.brandOrange),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₱${orderProvider.totalRevenue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Orders: ${orderProvider.totalOrders}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Delivered: ${orderProvider.deliveredOrders}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BusinessHealthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer3<
      AdminOrdersProvider,
      AdminProductsProvider,
      AdminCustomersProvider
    >(
      builder: (context, orderProvider, productProvider, customerProvider, _) {
        final deliveryRate = orderProvider.totalOrders > 0
            ? '${(orderProvider.deliveredOrders / orderProvider.totalOrders * 100).toStringAsFixed(1)}%'
            : 'N/A';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _HealthMetric(
                  label: 'Delivery Success Rate',
                  value: deliveryRate,
                  icon: Icons.local_shipping,
                  color: Colors.green,
                ),
                const Divider(height: 16),
                _HealthMetric(
                  label: 'Customer Satisfaction',
                  value: '${(4.6).toStringAsFixed(1)}/5.0',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                const Divider(height: 16),
                _HealthMetric(
                  label: 'Product Availability',
                  value:
                      '${(productProvider.availableProducts / productProvider.totalProducts * 100).toStringAsFixed(0)}%',
                  icon: Icons.inventory_2,
                  color: AppColors.brandOrange,
                ),
                const Divider(height: 16),
                _HealthMetric(
                  label: 'Active Customers',
                  value: customerProvider.activeCustomers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _AdminSettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage alert settings',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Update password & permissions',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language & Region',
            subtitle: 'Change app language',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Contact support team',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brandOrange),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class _PayoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Account Details',
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PayoutRow('Bank Name', 'BDO (Demo - Not Connected)'),
                  const SizedBox(height: 8),
                  _PayoutRow('Account Number', '****1234 (Hidden)'),
                  const SizedBox(height: 8),
                  _PayoutRow('Account Holder', 'BurgerBites Restaurant'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Backend integration required for payout settings',
                  ),
                  backgroundColor: Colors.orange,
                ),
              ),
              child: const Text('Update Payout Settings'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payouts are processed weekly on Fridays',
                      style: Theme.of(context).textTheme.bodySmall!
                          .copyWith(color: Colors.blue[900]),
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

class _PayoutRow extends StatelessWidget {
  final String label;
  final String value;

  const _PayoutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('App Name', 'BurgerBites Admin'),
            const SizedBox(height: 12),
            _InfoRow('Version', '1.0.0'),
            const SizedBox(height: 12),
            _InfoRow('Build', '#2024'),
            const SizedBox(height: 12),
            _InfoRow('Environment', 'Demo Mode (No Backend)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Running in demo mode. Changes are not persisted to a backend server.',
                      style: Theme.of(context).textTheme.bodySmall!
                          .copyWith(color: Colors.orange[900]),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
