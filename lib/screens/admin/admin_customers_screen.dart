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
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCustomersProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                          label: 'Active',
                          value: provider.activeCustomers.toString(),
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
                            value: _showOnlyActive,
                            onChanged: (value) {
                              setState(() => _showOnlyActive = value ?? false);
                            },
                            activeColor: AppColors.brandOrange,
                          ),
                          const Text('Show Active Only'),
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
    final baseList = _showOnlyActive
        ? provider.customers.where((c) => c.isActive).toList()
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
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _CustomerCard({
    required this.customer,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      ],
                    ),
                  ),
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
                        '${customer.orderCount} orders',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${customer.rewardPoints.toStringAsFixed(customer.rewardPoints % 1 == 0 ? 0 : 1)} reward points',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Spent: ₱${customer.totalSpent.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w600),
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
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _DetailRow('Status', customer.isActive ? 'Active' : 'Inactive'),
              _DetailRow('Email', customer.email),
              _DetailRow('Phone', customer.phone),
              _DetailRow('Address', customer.address),
              _DetailRow('Joined', _formatDate(customer.joinedDate)),
              const Divider(height: 16),
              _DetailRow('Total Orders', customer.orderCount.toString()),
              _DetailRow(
                'Reward Points',
                customer.rewardPoints.toStringAsFixed(
                  customer.rewardPoints % 1 == 0 ? 0 : 1,
                ),
              ),
              _DetailRow(
                'Total Spent',
                '₱${customer.totalSpent.toStringAsFixed(2)}',
                isBold: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.toggleCustomerStatus(customer.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customer.isActive
                        ? Colors.red
                        : Colors.green,
                  ),
                  child: Text(
                    customer.isActive
                        ? 'Deactivate Customer'
                        : 'Activate Customer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
