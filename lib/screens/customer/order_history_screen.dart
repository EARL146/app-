import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../../widgets/food_image.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerOrdersProvider>().loadOrders(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<CustomerOrdersProvider>();
    final orders = history.orders.where((order) {
      final active =
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.processing ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.shipped;
      return active == _showActive;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('My orders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 5, 17, 22),
        children: [
          if (history.isLoading) const LinearProgressIndicator(),
          if (history.errorMessage != null)
            TextButton.icon(
              onPressed: () => history.loadOrders(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(history.errorMessage!),
            ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6D9),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: AppColors.brandOrange,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your BurgerBites activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your orders and updates come from your BurgerBites account.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                _OrderTab(
                  label: 'Active orders',
                  selected: _showActive,
                  onTap: () => setState(() => _showActive = true),
                ),
                _OrderTab(
                  label: 'Completed',
                  selected: !_showActive,
                  onTap: () => setState(() => _showActive = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 31,
                    color: AppColors.brandOrange,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No orders in this section',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try the other tab or start a new order.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            )
          else
            ...orders.map((order) => _OrderCard(order: order)),
        ],
      ),
    );
  }
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.processing ||
      OrderStatus.ready ||
      OrderStatus.shipped => AppColors.info,
      OrderStatus.canceled => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                _dateLabel(order.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 37,
                    height: 37,
                    child: FoodImage(
                      imageUrl: item.productImage,
                      borderRadius: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.productName}  ×${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '₱${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.items.length} item${order.items.length == 1 ? '' : 's'} · Total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                '₱${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.brandOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.status == OrderStatus.pending
                      ? () async {
                          final history = context
                              .read<CustomerOrdersProvider>();
                          final success = await history.cancelOrder(order.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Order cancelled.'
                                    : history.errorMessage ??
                                          'Unable to cancel order.',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text(
                    'Cancel order',
                    style: TextStyle(fontSize: 9),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reorder(context),
                  icon: const Icon(Icons.replay_rounded, size: 14),
                  label: const Text('Reorder', style: TextStyle(fontSize: 9)),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

  void _reorder(BuildContext context) {
    final cart = context.read<CartProvider>();
    final products = context.read<CatalogProvider>().products;
    for (final item in order.items) {
      final matches = products.where((product) => product.id == item.productId);
      if (matches.isNotEmpty) {
        cart.addItem(
          matches.first,
          quantity: item.quantity,
          unitPrice: item.price,
          displayName: item.productName,
          customizations: item.customizations,
        );
      }
    }
    Navigator.of(context).pushNamed('/cart');
  }
}
