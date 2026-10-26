import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/admin_orders_provider.dart';
import '../../widgets/admin_page_frame.dart';
import '../../widgets/food_image.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminOrdersProvider>().loadOrders();
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
          'Orders Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: AdminPageFrame(
        child: Consumer<AdminOrdersProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                if (provider.isLoading) const LinearProgressIndicator(),
                if (provider.errorMessage != null)
                  TextButton.icon(
                    onPressed: () => provider.loadOrders(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(provider.errorMessage!),
                  ),
                // Stats Cards Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatCard(
                          label: 'Total Orders',
                          value: provider.totalOrders.toString(),
                          color: AppColors.brandOrange,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Pending',
                          value: provider.pendingOrders.toString(),
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Processing',
                          value: provider.processingOrders.toString(),
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Delivered',
                          value: provider.deliveredOrders.toString(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                // Search & Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by order ID...',
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
                      SizedBox(
                        height: 44,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'All',
                                isSelected: _selectedStatus == null,
                                onTap: () {
                                  setState(() => _selectedStatus = null);
                                  provider.setFilterStatus(null);
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Pending',
                                isSelected:
                                    _selectedStatus == OrderStatus.pending,
                                onTap: () {
                                  setState(
                                    () => _selectedStatus = OrderStatus.pending,
                                  );
                                  provider.setFilterStatus(OrderStatus.pending);
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Processing',
                                isSelected:
                                    _selectedStatus == OrderStatus.processing,
                                onTap: () {
                                  setState(
                                    () => _selectedStatus =
                                        OrderStatus.processing,
                                  );
                                  provider.setFilterStatus(
                                    OrderStatus.processing,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Delivered',
                                isSelected:
                                    _selectedStatus == OrderStatus.delivered,
                                onTap: () {
                                  setState(
                                    () =>
                                        _selectedStatus = OrderStatus.delivered,
                                  );
                                  provider.setFilterStatus(
                                    OrderStatus.delivered,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Cancelled',
                                isSelected:
                                    _selectedStatus == OrderStatus.canceled,
                                onTap: () {
                                  setState(
                                    () =>
                                        _selectedStatus = OrderStatus.canceled,
                                  );
                                  provider.setFilterStatus(
                                    OrderStatus.canceled,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Orders List
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found',
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
                          itemCount: provider.orders.length,
                          itemBuilder: (context, index) {
                            final order = provider.orders[index];
                            return _OrderCard(
                              order: order,
                              onTap: () => _showOrderDetails(context, order),
                              onStatusUpdate: (newStatus) =>
                                  _updateOrderStatus(context, order, newStatus),
                              onCancel: () => _cancelOrder(context, order),
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

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsBottomSheet(order: order),
    );
  }

  void _updateOrderStatus(
    BuildContext context,
    Order order,
    OrderStatus newStatus,
  ) {
    final provider = context.read<AdminOrdersProvider>();
    provider.updateOrderStatus(order.id, newStatus).then((_) {
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
  }

  void _cancelOrder(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Cancel order ${order.id}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminOrdersProvider>().cancelOrder(order.id).then((
                _,
              ) {
                if (!context.mounted) return;
                final provider = context.read<AdminOrdersProvider>();
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
            child: const Text('Yes, Cancel'),
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
      padding: const EdgeInsets.all(16),
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
            style: Theme.of(context).textTheme.headlineSmall!
                .copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final Function(OrderStatus) onStatusUpdate;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusUpdate,
    required this.onCancel,
  });

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.processing:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.shipped:
        return const Color(0xFF8963E8);
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextStatuses = switch (order.status) {
      OrderStatus.pending => [OrderStatus.processing, OrderStatus.canceled],
      OrderStatus.processing => [OrderStatus.ready, OrderStatus.canceled],
      OrderStatus.ready => [OrderStatus.shipped, OrderStatus.canceled],
      OrderStatus.shipped => [OrderStatus.delivered],
      OrderStatus.delivered || OrderStatus.canceled => <OrderStatus>[],
    };
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
                          order.customerName.trim().isEmpty
                              ? 'Customer'
                              : order.customerName.trim(),
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Items: ${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} | Total: ₱${order.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 45,
                      height: 45,
                      child: FoodImage(
                        imageUrl: order.items.first.productImage,
                        borderRadius: 11,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.items.first.productName}  ×${order.items.first.quantity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (order.items.first.saleDiscountPercent > 0)
                            Text(
                              '${order.items.first.saleDiscountPercent.toStringAsFixed(order.items.first.saleDiscountPercent % 1 == 0 ? 0 : 2)}% Discount Sale',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (order.items.length > 1)
                      Text(
                        '+${order.items.length - 1} more',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: PopupMenuButton<OrderStatus>(
                      enabled: nextStatuses.isNotEmpty,
                      onSelected: (OrderStatus status) =>
                          onStatusUpdate(status),
                      itemBuilder: (_) => nextStatuses
                          .map(
                            (status) => PopupMenuItem<OrderStatus>(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          )
                          .toList(),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          nextStatuses.isEmpty
                              ? order.status.displayName
                              : 'Change Status',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    onPressed: nextStatuses.contains(OrderStatus.canceled)
                        ? onCancel
                        : null,
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

class _OrderDetailsBottomSheet extends StatelessWidget {
  final Order order;

  const _OrderDetailsBottomSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final saleSavings = order.items.fold<double>(
      0,
      (sum, item) => sum + item.saleDiscountAmount,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Material(
          color: AppColors.pageBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.brandGlow,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.brandOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order details',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Order #${order.id}  ·  ${_formatDate(order.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _OrderStatusPill(
                        label: _getStatusLabel(order.status),
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Close order details',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _OrderSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeading(
                          icon: Icons.person_outline_rounded,
                          title: 'Customer & delivery',
                        ),
                        const SizedBox(height: 14),
                        Text(
                          order.customerName.trim().isEmpty
                              ? 'Name unavailable'
                              : order.customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (order.customerPhone.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  order.customerPhone,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (order.deliveryAddress?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.brandOrange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    order.deliveryAddress!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _OrderMeta(
                                label: 'PLACED',
                                value: _formatDateTime(order.createdAt),
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OrderMeta(
                                label: 'QUANTITY',
                                value:
                                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                icon: Icons.shopping_bag_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Items ordered',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${order.items.length} ${order.items.length == 1 ? 'product' : 'products'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderItemTile(item: item),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _OrderSectionCard(
                    child: Column(
                      children: [
                        _OrderTotalLine(
                          label: 'Subtotal',
                          value: _formatMoney(order.subtotal),
                        ),
                        if (saleSavings > 0) ...[
                          const SizedBox(height: 9),
                          _OrderTotalLine(
                            label: 'Discount sale savings',
                            value: '−${_formatMoney(saleSavings)}',
                            valueColor: AppColors.success,
                          ),
                        ],
                        if (order.shippingCost > 0) ...[
                          const SizedBox(height: 9),
                          _OrderTotalLine(
                            label: 'Delivery',
                            value: _formatMoney(order.shippingCost),
                          ),
                        ],
                        const SizedBox(height: 9),
                        _OrderTotalLine(
                          label: 'Tax',
                          value: _formatMoney(order.tax),
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),
                        _OrderTotalLine(
                          label: 'Total paid',
                          value: _formatMoney(order.total),
                          isEmphasized: true,
                        ),
                      ],
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.shipped:
        return const Color(0xFF8963E8);
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)} · $hour:$minute $period';
  }
}

String _customizationSummary(Map<String, dynamic> customizations) {
  final parts = <String>[];
  final brand = customizations['drink_brand']?.toString().trim();
  final size = customizations['size']?.toString().trim();
  if (brand != null && brand.isNotEmpty) parts.add(brand);
  if (size != null && size.isNotEmpty) parts.add(size);
  final toppings = customizations['toppings'];
  if (toppings is List && toppings.isNotEmpty) {
    parts.add(toppings.map((value) => value.toString()).join(', '));
  }
  return parts.join(' · ');
}

class _OrderSectionCard extends StatelessWidget {
  final Widget child;

  const _OrderSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.brandOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _OrderStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OrderMeta({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final customization = _customizationSummary(item.customizations);
    final hasSale = item.saleDiscountPercent > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: FoodImage(
              imageUrl: item.productImage,
              category: item.productCategory,
              borderRadius: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty ${item.quantity}${customization.isEmpty ? '' : '  ·  $customization'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (hasSale) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandGlow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.saleDiscountPercent.toStringAsFixed(item.saleDiscountPercent % 1 == 0 ? 0 : 2)}% sale · saved ${_formatMoney(item.saleDiscountAmount)}',
                      style: TextStyle(
                        color: AppColors.brandOrangeDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(item.subtotal),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (hasSale) ...[
                const SizedBox(height: 2),
                Text(
                  _formatMoney(item.originalSubtotal),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTotalLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isEmphasized;

  const _OrderTotalLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isEmphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style?.copyWith(
            color: valueColor ?? (isEmphasized ? AppColors.brandOrange : null),
            fontSize: isEmphasized ? 18 : null,
          ),
        ),
      ],
    );
  }
}

String _formatMoney(double amount) => '₱${amount.toStringAsFixed(2)}';
