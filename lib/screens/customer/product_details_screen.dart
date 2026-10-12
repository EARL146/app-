import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text('Details'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Icon(
                    _productIcon(product.category ?? 'Burgers'),
                    size: 120,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        Text(
                          '${product.rating ?? 4.8}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      return SizedBox(
                        width: 180,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            cart.addItem(product, quantity: _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Add to cart'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _productIcon(String category) {
    switch (category) {
      case 'Burgers':
        return Icons.lunch_dining_rounded;
      case 'Chicken':
        return Icons.kebab_dining_rounded;
      case 'Sides':
        return Icons.local_pizza_rounded;
      case 'Drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }
}
