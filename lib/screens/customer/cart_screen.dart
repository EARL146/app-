import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/food_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Your cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final savedAddress = context
              .watch<AuthService>()
              .currentUserAddress
              ?.trim();
          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cart.isLoadingRemoteCart)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (cart.syncErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Unable to load the cart linked to this account yet. ${cart.syncErrorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 38,
                        color: AppColors.brandOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cart.isLoadingRemoteCart
                          ? 'Loading saved cart…'
                          : 'Your cart is empty',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!cart.isLoadingRemoteCart) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Add some burger favorites to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                              '/customer-home',
                              (route) => false,
                            ),
                        icon: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 17,
                        ),
                        label: const Text('Explore the menu'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  children: [
                    if (cart.isLoadingRemoteCart)
                      const LinearProgressIndicator(minHeight: 2),
                    if (cart.syncErrorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cart account sync is unavailable. Your current items remain in this session until the connection is restored.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    if (cart.isSyncing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Saving cart to your account…',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.brandOrange,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DELIVERY ADDRESS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandOrange,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  savedAddress == null || savedAddress.isEmpty
                                      ? 'Add your address at checkout'
                                      : savedAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your Feast (${cart.items.length} unique items)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                                '/customer-home',
                                (route) => false,
                              ),
                          child: const Text('Add more'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ...cart.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: FoodImage(
                                imageUrl: item.productImage,
                                borderRadius: 12,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${item.price.toStringAsFixed(0)} each',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₱${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.brandOrange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.pageBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        cart.updateCartItemQuantity(
                                          item,
                                          item.quantity - 1,
                                        ),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 16,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        cart.updateCartItemQuantity(
                                          item,
                                          item.quantity + 1,
                                        ),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: AppColors.brandOrange,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SummaryCard(
                      subtotal: cart.subtotal,
                      delivery: cart.deliveryFee,
                      tax: cart.tax,
                      total: cart.total,
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'The server confirms tax, delivery, and the final total at checkout.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 11, 18, 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/checkout'),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 17),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Continue to checkout',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '₱${cart.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.delivery,
    required this.tax,
    required this.total,
  });

  final double subtotal;
  final double delivery;
  final double tax;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SummaryLine(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Delivery fee', amount: delivery),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Tax (12%)', amount: tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1),
          ),
          _SummaryLine(label: 'Total amount', amount: total, emphasize: true),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
            fontSize: emphasize ? 13 : 11,
            color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
      Text(
        '₱${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: emphasize ? 17 : 12,
          color: emphasize ? AppColors.brandOrange : AppColors.textPrimary,
        ),
      ),
    ],
  );
}
