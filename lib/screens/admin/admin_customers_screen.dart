import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/admin_customers_provider.dart';
import '../../widgets/admin_page_frame.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyOnline = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCustomersProvider>().loadCustomers();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        context.read<AdminCustomersProvider>().loadCustomers(force: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text(
          'Customers Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: AdminPageFrame(
        child: Consumer<AdminCustomersProvider>(
          builder: (context, provider, _) {
            final customers = _getFilteredCustomers(provider);

            return Column(
              children: [
                if (provider.isLoading) const LinearProgressIndicator(),
                if (provider.errorMessage != null)
                  TextButton.icon(
                    onPressed: () => provider.loadCustomers(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(provider.errorMessage!),
                  ),
                // Stats Cards Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Customers',
                          value: provider.totalCustomers.toString(),
                          color: AppColors.brandOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Total Spent',
                          value:
                              '₱${provider.totalCustomerSpent.toStringAsFixed(0)}',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                // Additional Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Online now',
                          value: provider.onlineCustomers.toString(),
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Avg Order Value',
                          value:
                              '₱${provider.averageOrderValue.toStringAsFixed(0)}',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Search & Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _showOnlyOnline,
                            onChanged: (value) {
                              setState(() => _showOnlyOnline = value ?? false);
                            },
                            activeColor: AppColors.brandOrange,
                          ),
                          const Text('Show Online Only'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Customers List
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No customers found',
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return _CustomerCard(
                              customer: customer,
                              provider: provider,
                              onTap: () => _showCustomerDetails(
                                context,
                                customer,
                                provider,
                              ),
                              onToggleStatus: () =>
                                  _toggleStatus(context, customer, provider),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Customer> _getFilteredCustomers(AdminCustomersProvider provider) {
    final baseList = _showOnlyOnline
        ? provider.customers.where((c) => c.isOnline).toList()
        : provider.customers;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return baseList;

    return baseList.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
    }).toList();
  }

  void _showCustomerDetails(
    BuildContext context,
    Customer customer,
    AdminCustomersProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _CustomerDetailsBottomSheet(customer: customer, provider: provider),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _toggleStatus(
    BuildContext context,
    Customer customer,
    AdminCustomersProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Customer Status'),
        content: Text(
          'Change ${customer.name}\'s status to ${customer.isActive ? 'Inactive' : 'Active'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.toggleCustomerStatus(customer.id).then((_) {
                if (!context.mounted) return;
                if (provider.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.successMessage!),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall!
                .copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final AdminCustomersProvider provider;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _CustomerCard({
    required this.customer,
    required this.provider,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FutureBuilder(
                    future: provider.loadCustomerPhoto(customer.id),
                    builder: (context, snapshot) {
                      final photo = snapshot.data;
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.brandOrange.withValues(
                          alpha: .12,
                        ),
                        backgroundImage: photo == null
                            ? null
                            : MemoryImage(photo),
                        child: photo == null
                            ? Text(
                                customer.name.trim().isEmpty
                                    ? '?'
                                    : customer.name.trim()[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.brandOrange,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.address.isEmpty
                              ? 'Address not provided'
                              : customer.address,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: customer.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: customer.isActive
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer.activityLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CustomerRewardMini(points: customer.rewardPoints),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Spent: ₱${customer.totalSpent.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${customer.orderCount} orders',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Toggle Status'),
                    onPressed: onToggleStatus,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailsBottomSheet extends StatelessWidget {
  final Customer customer;
  final AdminCustomersProvider provider;

  const _CustomerDetailsBottomSheet({
    required this.customer,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminCustomersProvider>(
      builder: (context, latestProvider, _) {
        final matches = latestProvider.customers.where(
          (item) => item.id == customer.id,
        );
        final currentCustomer = matches.isEmpty ? customer : matches.first;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .86,
          minChildSize: .55,
          maxChildSize: .96,
          builder: (context, scrollController) => Material(
            color: AppColors.pageBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: provider.loadCustomerPhoto(
                            currentCustomer.id,
                          ),
                          builder: (context, snapshot) {
                            final photo = snapshot.data;
                            return CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.brandGlow,
                              backgroundImage: photo == null
                                  ? null
                                  : MemoryImage(photo),
                              child: photo == null
                                  ? Text(
                                      currentCustomer.name.trim().isEmpty
                                          ? '?'
                                          : currentCustomer.name
                                                .trim()[0]
                                                .toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.brandOrange,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentCustomer.name.isEmpty
                                    ? 'Customer'
                                    : currentCustomer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                currentCustomer.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  _CustomerStatusPill(
                                    label: currentCustomer.isActive
                                        ? 'Active'
                                        : 'Inactive',
                                    color: currentCustomer.isActive
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      currentCustomer.activityLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: currentCustomer.isOnline
                                                ? AppColors.success
                                                : AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Close customer details',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _CustomerRewardCard(points: currentCustomer.rewardPoints),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CustomerMetric(
                            icon: Icons.receipt_long_rounded,
                            label: 'ORDERS',
                            value: '${currentCustomer.orderCount}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CustomerMetric(
                            icon: Icons.payments_outlined,
                            label: 'TOTAL SPENT',
                            value:
                                '₱${currentCustomer.totalSpent.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Customer information',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 9),
                    _CustomerInfoCard(
                      rows: [
                        _CustomerInfo(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: currentCustomer.phone.isEmpty
                              ? 'Not provided'
                              : currentCustomer.phone,
                        ),
                        _CustomerInfo(
                          icon: Icons.location_on_outlined,
                          label: 'Delivery address',
                          value: currentCustomer.address.isEmpty
                              ? 'Not provided'
                              : currentCustomer.address,
                        ),
                        _CustomerInfo(
                          icon: Icons.calendar_today_outlined,
                          label: 'Joined',
                          value: _formatDate(currentCustomer.joinedDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: latestProvider.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                provider.toggleCustomerStatus(
                                  currentCustomer.id,
                                );
                              },
                        icon: Icon(
                          currentCustomer.isActive
                              ? Icons.person_off_outlined
                              : Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(
                          currentCustomer.isActive
                              ? 'Deactivate customer'
                              : 'Activate customer',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentCustomer.isActive
                              ? AppColors.danger
                              : AppColors.success,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CustomerRewardMini extends StatelessWidget {
  final double points;

  const _CustomerRewardMini({required this.points});

  @override
  Widget build(BuildContext context) {
    const goal = 2500.0;
    final progress = (points / goal).clamp(0.0, 1.0).toDouble();
    final remaining = (goal - points).clamp(0.0, goal).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandGlow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              size: 18,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Burger Bites rewards',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatPoints(points)} pts',
                      style: TextStyle(
                        color: AppColors.brandOrangeDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(AppColors.brandOrange),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  points >= goal
                      ? '2,500 point reward unlocked'
                      : '${_formatPoints(remaining)} pts to 2,500',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRewardCard extends StatelessWidget {
  final double points;

  const _CustomerRewardCard({required this.points});

  @override
  Widget build(BuildContext context) {
    const goal = 2500.0;
    final progress = (points / goal).clamp(0.0, 1.0).toDouble();
    final remaining = (goal - points).clamp(0.0, goal).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BURGER BITES REWARDS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: .92),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(points),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, bottom: 3),
                child: Text(
                  'points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: .25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  points >= goal
                      ? 'Reward unlocked · 2,500 points'
                      : '${_formatPoints(remaining)} more to unlock reward',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CustomerMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brandOrange),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerInfo {
  final IconData icon;
  final String label;
  final String value;

  const _CustomerInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _CustomerInfoCard extends StatelessWidget {
  final List<_CustomerInfo> rows;

  const _CustomerInfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    rows[index].icon,
                    size: 18,
                    color: AppColors.brandOrange,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 98,
                    child: Text(
                      rows[index].label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[index].value,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (index != rows.length - 1)
              Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _CustomerStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CustomerStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatPoints(double points) =>
    points.toStringAsFixed(points % 1 == 0 ? 0 : 1);
