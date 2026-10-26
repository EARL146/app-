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
      builder: (context) => _OrderDetailsBottomSheet(order: order),
      isScrollControlled: true,
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
                'Order Details',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _DetailRow('Order ID', order.id),
              _DetailRow(
                'Customer',
                order.customerName.trim().isEmpty
                    ? 'Name unavailable'
                    : order.customerName,
              ),
              if (order.customerPhone.trim().isNotEmpty)
                _DetailRow('Phone', order.customerPhone),
              if (order.deliveryAddress?.trim().isNotEmpty == true)
                _DetailRow('Delivery address', order.deliveryAddress!),
              _DetailRow(
                'Status',
                _getStatusLabel(order.status),
                statusColor: _getStatusColor(order.status),
              ),
              _DetailRow('Date', _formatDate(order.createdAt)),
              _DetailRow(
                'Items',
                '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} items across ${order.items.length} products',
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FoodImage(
                          imageUrl: item.productImage,
                          category: item.productCategory,
                          borderRadius: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.productName} ×${item.quantity}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (_customizationSummary(item.customizations)
                                .isNotEmpty)
                              Text(
                                _customizationSummary(item.customizations),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            if (item.saleDiscountPercent > 0)
                              Text(
                                '${item.saleDiscountPercent.toStringAsFixed(item.saleDiscountPercent % 1 == 0 ? 0 : 2)}% Discount Sale · saved ₱${item.saleDiscountAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.brandOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₱${item.subtotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (item.saleDiscountPercent > 0)
                            Text(
                              'was ₱${item.originalSubtotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
              _DetailRow('Subtotal', '₱${order.subtotal.toStringAsFixed(2)}'),
              _DetailRow('Tax', '₱${order.tax.toStringAsFixed(2)}'),
              _DetailRow(
                'Total',
                '₱${order.total.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? statusColor;
  final bool isBold;

  const _DetailRow(
    this.label,
    this.value, {
    this.statusColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
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
