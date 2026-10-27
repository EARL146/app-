import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/admin_page_frame.dart';
import '../../services/api_service.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_customers_provider.dart';
import '../../providers/admin_orders_provider.dart';
import '../../providers/admin_products_provider.dart';

class AdminMoreScreen extends StatefulWidget {
  const AdminMoreScreen({super.key});

  @override
  State<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends State<AdminMoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminDashboardProvider>().load(force: true);
      context.read<AdminOrdersProvider>().loadOrders(force: true);
      context.read<AdminProductsProvider>().loadProducts(force: true);
      context.read<AdminCustomersProvider>().loadCustomers(force: true);
    });
  }

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
      body: AdminPageFrame(
        child: SingleChildScrollView(
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
                    leading: CircleAvatar(
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
                // Payment Setup
                Text(
                  'Payment Setup',
                  style: Theme.of(context).textTheme.titleLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _PayoutCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardProvider>(
      builder: (context, dashboard, _) {
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
                      'Order value',
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: 'Refresh revenue',
                      onPressed: dashboard.isLoading
                          ? null
                          : () => dashboard.load(force: true),
                      icon: dashboard.isLoading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: AppColors.brandOrange,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dashboard.hasData
                      ? '₱${dashboard.orderValue.toStringAsFixed(2)}'
                      : '—',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dashboard.hasData) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Collected after delivery: ₱${dashboard.deliveredRevenue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (dashboard.errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    dashboard.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.danger),
                  ),
                ],
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
                        'Total Orders: ${dashboard.totalOrders}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Delivered: ${dashboard.deliveredOrders}',
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

void _openAdminNotifications(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AdminNotificationSheet(),
  );
}

class _AdminNotificationSheet extends StatefulWidget {
  const _AdminNotificationSheet();

  @override
  State<_AdminNotificationSheet> createState() =>
      _AdminNotificationSheetState();
}

class _AdminNotificationSheetState extends State<_AdminNotificationSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminOrdersProvider>().loadOrders(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminOrdersProvider>(
      builder: (context, orders, _) {
        final notifications = orders.allOrders.take(30).toList();
        final pendingCount = notifications
            .where((order) => order.status == OrderStatus.pending)
            .length;
        final activeCount = notifications
            .where(
              (order) => {
                OrderStatus.processing,
                OrderStatus.ready,
                OrderStatus.shipped,
              }.contains(order.status),
            )
            .length;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          minChildSize: .55,
          maxChildSize: .94,
          builder: (context, controller) => Material(
            color: AppColors.pageBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.brandGlow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.brandOrange,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order notifications',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    '$pendingCount pending · $activeCount in progress',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh order notifications',
                              onPressed: orders.isLoading
                                  ? null
                                  : () => orders.loadOrders(force: true),
                              icon: orders.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                            ),
                            IconButton(
                              tooltip: 'Close notifications',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: orders.isLoading && notifications.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : orders.errorMessage != null && notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_off_outlined,
                                    size: 34,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    orders.errorMessage!,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        orders.loadOrders(force: true),
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 42,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'You’re all caught up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'New and updated orders will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) {
                              final order = notifications[index];
                              final statusColor = _notificationStatusColor(
                                order.status,
                              );
                              final itemQuantity = order.items.fold<int>(
                                0,
                                (sum, item) => sum + item.quantity,
                              );
                              return Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.adminOrders);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: .1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            color: statusColor,
                                            size: 19,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${order.customerName.trim().isEmpty ? 'Customer' : order.customerName} · Order #${order.id}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$itemQuantity ${itemQuantity == 1 ? 'item' : 'items'} · ₱${order.total.toStringAsFixed(2)} · ${_notificationDate(order.createdAt)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: .1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            order.status.displayName,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pushNamed(AppRoutes.adminOrders);
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Open orders management'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _notificationStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.warning,
  OrderStatus.processing ||
  OrderStatus.ready ||
  OrderStatus.shipped => AppColors.info,
  OrderStatus.delivered => AppColors.success,
  OrderStatus.canceled => AppColors.danger,
};

String _notificationDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

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
                  label: 'Product Availability',
                  value: productProvider.totalProducts == 0
                      ? '—'
                      : '${(productProvider.availableProducts / productProvider.totalProducts * 100).toStringAsFixed(0)}%',
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
            icon: Icons.storefront_rounded,
            title: 'Store profile',
            subtitle: 'Manage public contact and delivery information',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminStoreProfile),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'See new orders and order status updates',
            onTap: () => _openAdminNotifications(context),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Manage your password and sign out from Admin Profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminProfile),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language & Region',
            subtitle:
                'Language preference is saved; full translation is pending',
            onTap: () => Navigator.pushNamed(context, AppRoutes.language),
          ),
          const Divider(height: 0),
          _SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Review and resolve customer messages',
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminSupport),
          ),
        ],
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

class _PayoutCard extends StatefulWidget {
  @override
  State<_PayoutCard> createState() => _PayoutCardState();
}

class _PayoutCardState extends State<_PayoutCard> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  double _revenue = 0;
  double _withdrawn = 0;
  double _available = 0;
  List<Map<String, dynamic>> _recentWithdrawals = const [];

  @override
  void initState() {
    super.initState();
    _loadPaymentSummary();
  }

  Future<void> _loadPaymentSummary() async {
    if (mounted) setState(() => _loading = true);
    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/payment-summary',
      fromJson: _asMap,
    );
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.error ?? 'Unable to load payment totals.';
      });
      return;
    }
    final data = response.data!;
    setState(() {
      _loading = false;
      _error = null;
      _revenue = (data['delivered_revenue'] as num?)?.toDouble() ?? 0;
      _withdrawn = (data['total_withdrawn'] as num?)?.toDouble() ?? 0;
      _available = (data['available_balance'] as num?)?.toDouble() ?? 0;
      _recentWithdrawals = (data['recent_withdrawals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    });
  }

  Future<void> _openWithdrawalDialog() async {
    final controller = TextEditingController();
    String? validationMessage;
    final amount = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record a withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available balance: ₱${_available.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount to withdraw',
                  prefixText: '₱ ',
                ),
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  validationMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'This records the withdrawal in the store ledger. It does not transfer funds to GCash or Maya automatically.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, height: 1.4),
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
                final input = controller.text.trim();
                final validAmount = RegExp(r'^\d{1,8}(?:\.\d{1,2})?$')
                    .hasMatch(input);
                if (!validAmount) {
                  setDialogState(
                    () => validationMessage = 'Enter a positive amount with up to two decimal places.',
                  );
                  return;
                }
                final parts = input.split('.');
                final requestedCents =
                    (int.parse(parts.first) * 100) +
                    int.parse(
                      (parts.length > 1 ? parts[1] : '').padRight(2, '0'),
                    );
                final availableCents = (_available * 100).round();
                if (requestedCents <= 0) {
                  setDialogState(
                    () => validationMessage = 'Amount must be above ₱0.',
                  );
                  return;
                }
                if (requestedCents > availableCents) {
                  setDialogState(
                    () => validationMessage =
                        'Insufficient funds. Only ₱${_available.toStringAsFixed(2)} is available.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, input);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    await _recordWithdrawal(amount);
  }

  Future<void> _recordWithdrawal(String amount) async {
    setState(() => _submitting = true);
    final response = await _apiService.post<Map<String, dynamic>>(
      '/admin/withdrawals',
      body: {'amount': amount},
      fromJson: _asMap,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Unable to record the withdrawal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _loadPaymentSummary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Withdrawal recorded in the store ledger.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSummary = !_loading && _error == null;
    final canWithdraw = hasSummary && !_submitting;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.warmSurfaceGradient,
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Available to withdraw',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: 'Refresh payment totals',
                        visualDensity: VisualDensity.compact,
                        onPressed: _loadPaymentSummary,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.brandOrange,
                        ),
                      ),
                  ],
                ),
                Text(
                  canWithdraw ? '₱${_available.toStringAsFixed(2)}' : '—',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentMetric(
                        label: 'Delivered revenue',
                        value: hasSummary
                            ? '₱${_revenue.toStringAsFixed(2)}'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PaymentMetric(
                        label: 'Withdrawals recorded',
                        value: !hasSummary
                            ? '—'
                            : '₱${_withdrawn.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canWithdraw ? _openWithdrawalDialog : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.account_balance_wallet_outlined),
              label: Text(_submitting ? 'Recording…' : 'Withdraw'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Cash-on-delivery earnings count after an order is marked delivered. Withdrawals are recorded here; transfer them manually through your payout provider.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          if (_recentWithdrawals.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent withdrawals',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            for (final withdrawal in _recentWithdrawals.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.south_west_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatWithdrawalDate(
                          withdrawal['created_at']?.toString() ?? '',
                        ),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '−₱${((withdrawal['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) => value is Map<String, dynamic>
      ? value
      : throw const FormatException('Invalid payment response.');

  String _formatWithdrawalDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Withdrawal recorded';
    return '${date.toLocal().day}/${date.toLocal().month}/${date.toLocal().year}';
  }
}

class _PaymentMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary, fontSize: 9),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
