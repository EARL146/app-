import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/food_image.dart';
import '../../widgets/customer_account_prompt.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const _drinkBrands = [
    'Coca-Cola',
    'Sprite',
    'Pepsi',
    'Royal',
    'Mountain Dew',
    '7Up',
  ];

  int _quantity = 1;
  String _size = 'Regular';
  String _drinkBrand = _drinkBrands.first;
  final Set<String> _extras = {};

  @override
  void initState() {
    super.initState();
    if (_isFries(widget.product)) _size = 'Small';
  }

  double get _unitPrice {
    final isBurger = _isBurger(widget.product);
    final sizePrice = isBurger
        ? switch (_size) {
            'Large' => 80.0,
            'Double' => 120.0,
            _ => 0.0,
          }
        : 0.0;
    final extrasPrice = _extras.fold<double>(
      0,
      (sum, item) => sum + (item == 'Extra cheese' ? 25 : 45),
    );
    return widget.product.price + sizePrice + extrasPrice;
  }

  bool _isBurger(Product product) =>
      product.category?.trim().toLowerCase() == 'burgers';

  bool _isDrink(Product product) =>
      product.category?.trim().toLowerCase() == 'drinks';

  bool _isFries(Product product) {
    final category = product.category?.trim().toLowerCase();
    return category == 'fries' ||
        (category == 'sides' && product.name.toLowerCase().contains('fries'));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isBurgerProduct = _isBurger(product);
    final isFriesProduct = _isFries(product);
    final isDrinkProduct = _isDrink(product);
    final categoryLabel = product.category?.trim();
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.34)
        .clamp(220.0, 310.0)
        .toDouble();
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
                    height: heroHeight,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.brandOrange,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Base price',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProductInfoChip(
                        icon: Icons.restaurant_menu_rounded,
                        label: categoryLabel?.isNotEmpty == true
                            ? categoryLabel!
                            : 'Menu item',
                      ),
                      _ProductInfoChip(
                        icon: product.available
                            ? Icons.check_circle_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                        label: product.available ? 'Available' : 'Unavailable',
                        color: product.available
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      if (product.rating != null)
                        _ProductInfoChip(
                          icon: Icons.star_rounded,
                          label: product.reviewCount == null
                              ? product.rating!.toStringAsFixed(1)
                              : '${product.rating!.toStringAsFixed(1)} (${product.reviewCount})',
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'About this item',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.description.trim().isEmpty
                        ? 'A description for this item has not been added yet.'
                        : product.description.trim(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (isBurgerProduct) ...[
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
                              'Selected size and toppings are saved with your order. Final prices are checked at checkout.',
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
                  if (isFriesProduct) ...[
                    const SizedBox(height: 18),
                    const _FieldHeading(
                      title: 'Fries size',
                      trailing: 'Listed price',
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _SizeOption(
                          label: 'Small',
                          detail: 'Listed price',
                          selected: _size == 'Small',
                          onTap: () => setState(() => _size = 'Small'),
                        ),
                        const SizedBox(width: 8),
                        _SizeOption(
                          label: 'Medium',
                          detail: 'Listed price',
                          selected: _size == 'Medium',
                          onTap: () => setState(() => _size = 'Medium'),
                        ),
                        const SizedBox(width: 8),
                        _SizeOption(
                          label: 'Large',
                          detail: 'Listed price',
                          selected: _size == 'Large',
                          onTap: () => setState(() => _size = 'Large'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'All fries sizes use this product’s current database price.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (isDrinkProduct) ...[
                    const SizedBox(height: 18),
                    const _FieldHeading(
                      title: 'Drink brand',
                      trailing: 'Listed price',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _drinkBrands
                          .map(
                            (brand) => ChoiceChip(
                              label: Text(brand),
                              selected: _drinkBrand == brand,
                              selectedColor: AppColors.brandOrange.withValues(
                                alpha: 0.18,
                              ),
                              onSelected: (_) =>
                                  setState(() => _drinkBrand = brand),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Drink brands use this product’s current database price.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
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
                            onPressed: product.available
                                ? () async {
                                    if (!await requireCustomerAccount(
                                      context,
                                      action: 'add this item to your cart',
                                    )) {
                                      return;
                                    }
                                    if (!context.mounted) return;
                                    final toppings = _extras.toList()..sort();
                                    final displayName = isDrinkProduct
                                        ? '$_drinkBrand ${product.name}'
                                        : '${(isBurgerProduct && _size != 'Regular') || isFriesProduct ? '$_size ' : ''}${product.name}${toppings.isEmpty ? '' : ' + ${toppings.join(', ')}'}';
                                    cart.addItem(
                                      product,
                                      quantity: _quantity,
                                      unitPrice: _unitPrice,
                                      displayName: displayName,
                                      customizations: isBurgerProduct
                                          ? {
                                              'size': _size,
                                              'toppings': toppings,
                                            }
                                          : isFriesProduct
                                          ? {'size': _size}
                                          : isDrinkProduct
                                          ? {'drink_brand': _drinkBrand}
                                          : const {},
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$displayName added to cart',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                : null,
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

class _ProductInfoChip extends StatelessWidget {
  const _ProductInfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
