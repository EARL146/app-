import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(backgroundColor: AppColors.pageBackground, title: const Text('Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add some burger favorites to get started.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fastfood_rounded,
                                color: AppColors.brandOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${item.price.toStringAsFixed(0)} each',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      cart.updateQuantity(item.productId, item.quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      cart.updateQuantity(item.productId, item.quantity + 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _summaryRow('Delivery', '₱${cart.deliveryFee.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _summaryRow('Tax', '₱${cart.tax.toStringAsFixed(0)}'),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      _summaryRow('Total', '₱${cart.total.toStringAsFixed(0)}', isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _summaryRow(String label, String value, {bool isTotal = false}) {
  return Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
