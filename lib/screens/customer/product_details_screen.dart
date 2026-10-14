import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/food_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  String _size = 'Regular';
  final Set<String> _extras = {};

  double get _unitPrice {
    final sizePrice = switch (_size) {
      'Large' => 80.0,
      'Double' => 120.0,
      _ => 0.0,
    };
    final extrasPrice = _extras.fold<double>(
      0,
      (sum, item) => sum + (item == 'Extra cheese' ? 25 : 45),
    );
    return widget.product.price + sizePrice + extrasPrice;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.of(context).pushNamed('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
                children: [
                  SizedBox(
                    height: 254,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FoodImage(
                            imageUrl: product.imageUrl,
                            category: product.category,
                            borderRadius: 23,
                          ),
                        ),
                        Positioned(
                          left: 13,
                          top: 13,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CHEF’S SPECIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: FavoriteButton(
                              product: product,
                              iconSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating ?? 4.8}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' (${product.reviewCount ?? 0})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _FieldHeading(
                    title: 'Burger size',
                    trailing: 'Size guide ›',
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _SizeOption(
                        label: 'Regular',
                        detail: '1/4 lb',
                        selected: _size == 'Regular',
                        onTap: () => setState(() => _size = 'Regular'),
                      ),
                      const SizedBox(width: 8),
                      _SizeOption(
                        label: 'Large',
                        detail: '+ ₱80',
                        selected: _size == 'Large',
                        onTap: () => setState(() => _size = 'Large'),
                      ),
                      const SizedBox(width: 8),
                      _SizeOption(
                        label: 'Double',
                        detail: '+ ₱120',
                        selected: _size == 'Double',
                        onTap: () => setState(() => _size = 'Double'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _FieldHeading(
                    title: 'Extra toppings',
                    trailing: 'Optional',
                  ),
                  const SizedBox(height: 6),
                  _ExtraOption(
                    label: 'Extra cheese',
                    detail: '+ ₱25',
                    selected: _extras.contains('Extra cheese'),
                    onChanged: (value) => setState(
                      () => value
                          ? _extras.add('Extra cheese')
                          : _extras.remove('Extra cheese'),
                    ),
                  ),
                  _ExtraOption(
                    label: 'Crispy bacon',
                    detail: '+ ₱45',
                    selected: _extras.contains('Crispy bacon'),
                    onChanged: (value) => setState(
                      () => value
                          ? _extras.add('Crispy bacon')
                          : _extras.remove('Crispy bacon'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.brandOrange,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customization and pricing are stored locally for this demo.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      height: 47,
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(
                              () => _quantity = (_quantity - 1).clamp(1, 99),
                            ),
                            icon: const Icon(Icons.remove_rounded, size: 17),
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_rounded, size: 17),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: SizedBox(
                        height: 49,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) => ElevatedButton(
                            onPressed: () {
                              final customProduct = Product(
                                id: '${product.id}-${_size.toLowerCase()}-${_extras.length}',
                                name:
                                    '${_size == 'Regular' ? '' : '$_size '}${product.name}${_extras.isEmpty ? '' : ' + ${_extras.join(', ')}'}',
                                description: product.description,
                                price: _unitPrice,
                                imageUrl: product.imageUrl,
                                category: product.category,
                                rating: product.rating,
                                reviewCount: product.reviewCount,
                                available: product.available,
                                createdAt: product.createdAt,
                              );
                              cart.addItem(customProduct, quantity: _quantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${customProduct.name} added to cart',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Add to cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₱${(_unitPrice * _quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldHeading extends StatelessWidget {
  const _FieldHeading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    ],
  );
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.darkSurface : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: TextStyle(
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraOption extends StatelessWidget {
  const _ExtraOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.brandOrange,
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}
