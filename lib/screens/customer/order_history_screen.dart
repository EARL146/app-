import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/food_image.dart';
import '../../widgets/customer_account_prompt.dart';

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
    final auth = context.watch<AuthService>();
    if (auth.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: const Text('My orders')),
        body: const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Checking account'),
        ),
      );
    }
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: const Text('My orders')),
        body: const _OrderAccessPrompt(),
      );
    }
    if (auth.currentUserRole != 'customer') {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: const Text('My orders')),
        body: const _OrderAccessPrompt(isNonCustomer: true),
      );
    }

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
          if (history.errorMessage != null && orders.isNotEmpty)
            TextButton.icon(
              onPressed: () => history.loadOrders(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(history.errorMessage!),
            ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEFE6), Color(0xFFFFE1CF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: .16),
              ),
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
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14FF6422),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
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
            if (history.errorMessage != null)
              _OrderHistoryStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Orders unavailable',
                message: history.errorMessage!,
                actionLabel: 'Try again',
                onAction: () => history.loadOrders(force: true),
              )
            else if (history.isLoading || !history.hasLoaded)
              const _OrderHistoryStateCard(
                icon: Icons.receipt_long_rounded,
                title: 'Loading your orders',
                message: 'Your active and past orders will appear here.',
                isLoading: true,
              )
            else
              const _OrderHistoryStateCard(
                icon: Icons.receipt_long_rounded,
                title: 'No orders in this section',
                message: 'Try the other tab or start a new order.',
              )
          else
            ...orders.map((order) => _OrderCard(order: order)),
        ],
      ),
    );
  }
}

class _OrderAccessPrompt extends StatelessWidget {
  const _OrderAccessPrompt({this.isNonCustomer = false});

  final bool isNonCustomer;

  @override
  Widget build(BuildContext context) {
    final title = isNonCustomer
        ? 'Customer account required'
        : 'Sign in to see your orders';
    final message = isNonCustomer
        ? 'You are signed in with an administrator account. Order history is available only to customer accounts.'
        : 'Sign in or create a customer account to view active and past orders.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE6D9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNonCustomer
                        ? Icons.admin_panel_settings_outlined
                        : Icons.receipt_long_rounded,
                    color: AppColors.brandOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (!isNonCustomer) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed('/sign-in', arguments: true),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed('/register', arguments: true),
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                      ),
                      label: const Text('Create account'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderHistoryStateCard extends StatelessWidget {
  const _OrderHistoryStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Icon(icon, size: 31, color: AppColors.brandOrange),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            height: 1.4,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
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
    child: AnimatedPressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryButtonGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x22FF6422),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
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
    return AnimatedEntranceCard(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
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
                child: AnimatedPressScale(
                  borderRadius: BorderRadius.circular(12),
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
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

  Future<void> _reorder(BuildContext context) async {
    if (!await requireCustomerAccount(context, action: 'reorder these items')) {
      return;
    }
    if (!context.mounted) return;
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
