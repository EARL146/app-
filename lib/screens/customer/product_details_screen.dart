import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/animated_brand_button.dart';
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
  static const _drinkSizes = ['Regular', 'Large', 'XL'];

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
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                final itemCount = cart.items.fold<int>(
                  0,
                  (count, item) => count + item.quantity,
                );
                return IconButton(
                  tooltip: 'Cart${itemCount == 0 ? '' : ', $itemCount items'}',
                  onPressed: () => Navigator.of(context).pushNamed('/cart'),
                  icon: Badge(
                    isLabelVisible: itemCount > 0,
                    label: Text('$itemCount'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      SizedBox(
                        height: heroHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(
                                  alpha: .12,
                                ),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FoodImage(
                                  imageUrl: product.imageUrl,
                                  category: product.category,
                                  borderRadius: 25,
                                ),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00000000),
                                        Color(0x00000000),
                                        Color(0x770F0B09),
                                      ],
                                      stops: [0, .52, 1],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  top: 14,
                                  child: _HeroPill(
                                    icon: product.available
                                        ? Icons.check_circle_rounded
                                        : Icons.remove_circle_rounded,
                                    label: product.available
                                        ? 'AVAILABLE NOW'
                                        : 'CURRENTLY UNAVAILABLE',
                                    color: product.available
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                                if (product.rating != null)
                                  Positioned(
                                    left: 14,
                                    bottom: 14,
                                    child: _HeroPill(
                                      icon: Icons.star_rounded,
                                      label: product.reviewCount == null
                                          ? product.rating!.toStringAsFixed(1)
                                          : '${product.rating!.toStringAsFixed(1)}  ·  ${product.reviewCount} reviews',
                                      color: AppColors.warning,
                                    ),
                                  ),
                                Positioned(
                                  right: 13,
                                  top: 13,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: FavoriteButton(
                                        product: product,
                                        iconSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                'Listed price',
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
                            label: product.available
                                ? 'Available'
                                : 'Unavailable',
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
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this item',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
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
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isBurgerProduct) ...[
                        const SizedBox(height: 18),
                        const _FieldHeading(
                          title: 'Burger size',
                          trailing: 'Select one',
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _SizeOption(
                              label: 'Regular',
                              detail: '1/4 lb',
                              icon: Icons.lunch_dining_rounded,
                              selected: _size == 'Regular',
                              onTap: () => setState(() => _size = 'Regular'),
                            ),
                            const SizedBox(width: 8),
                            _SizeOption(
                              label: 'Large',
                              detail: '+ ₱80',
                              icon: Icons.lunch_dining_rounded,
                              selected: _size == 'Large',
                              onTap: () => setState(() => _size = 'Large'),
                            ),
                            const SizedBox(width: 8),
                            _SizeOption(
                              label: 'Double',
                              detail: '+ ₱120',
                              icon: Icons.fastfood_rounded,
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
                          trailing: 'Select one',
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _SizeOption(
                              label: 'Small',
                              detail: '₱${product.price.toStringAsFixed(0)}',
                              icon: Icons.fastfood_rounded,
                              selected: _size == 'Small',
                              onTap: () => setState(() => _size = 'Small'),
                            ),
                            const SizedBox(width: 8),
                            _SizeOption(
                              label: 'Medium',
                              detail: '₱${product.price.toStringAsFixed(0)}',
                              icon: Icons.fastfood_rounded,
                              selected: _size == 'Medium',
                              onTap: () => setState(() => _size = 'Medium'),
                            ),
                            const SizedBox(width: 8),
                            _SizeOption(
                              label: 'Large',
                              detail: '₱${product.price.toStringAsFixed(0)}',
                              icon: Icons.fastfood_rounded,
                              selected: _size == 'Large',
                              onTap: () => setState(() => _size = 'Large'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'All sizes are currently ₱${product.price.toStringAsFixed(0)}.',
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
                          trailing: 'Choose one',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _drinkBrands
                              .map(
                                (brand) => _BrandOption(
                                  brand: brand,
                                  selected: _drinkBrand == brand,
                                  onTap: () =>
                                      setState(() => _drinkBrand = brand),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _FieldHeading(
                          title: 'Drink size',
                          trailing:
                              '₱${product.price.toStringAsFixed(0)} listed price',
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            for (
                              var index = 0;
                              index < _drinkSizes.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(width: 8),
                              _SizeOption(
                                label: _drinkSizes[index],
                                detail: '₱${product.price.toStringAsFixed(0)}',
                                icon: Icons.local_cafe_rounded,
                                selected: _size == _drinkSizes[index],
                                onTap: () =>
                                    setState(() => _size = _drinkSizes[index]),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'All drink sizes are currently ₱${product.price.toStringAsFixed(0)}.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Container(
                          height: 47,
                          decoration: BoxDecoration(
                            color: AppColors.pageBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              AnimatedPressScale(
                                pressedScale: 0.88,
                                child: IconButton(
                                  onPressed: () => setState(
                                    () => _quantity = (_quantity - 1).clamp(
                                      1,
                                      99,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 17,
                                  ),
                                ),
                              ),
                              AnimatedValueText(
                                '$_quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              AnimatedPressScale(
                                pressedScale: 0.88,
                                child: IconButton(
                                  onPressed: () => setState(
                                    () => _quantity = (_quantity + 1).clamp(
                                      1,
                                      99,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 17),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: AnimatedPressScale(
                            child: SizedBox(
                              height: 49,
                              child: Consumer<CartProvider>(
                                builder: (context, cart, _) => ElevatedButton(
                                  onPressed: product.available
                                      ? () async {
                                          if (!await requireCustomerAccount(
                                            context,
                                            action:
                                                'add this item to your cart',
                                          )) {
                                            return;
                                          }
                                          if (!context.mounted) return;
                                          final toppings = _extras.toList()
                                            ..sort();
                                          final displayName = isDrinkProduct
                                              ? '$_drinkBrand ${_size == 'Regular' ? '' : '$_size '}${product.name}'
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
                                                ? {
                                                    'size': _size,
                                                    'drink_brand': _drinkBrand,
                                                  }
                                                : const {},
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$displayName added to cart',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
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
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Text(
                                          '₱${(_unitPrice * _quantity).toStringAsFixed(0)}',
                                          key: ValueKey(
                                            (_unitPrice * _quantity)
                                                .toStringAsFixed(0),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .1),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
      ],
    ),
  );
}

class _FieldHeading extends StatelessWidget {
  const _FieldHeading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 17,
        decoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceMuted : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.brandOrange : AppColors.border,
                width: selected ? 1.5 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.brandOrange.withValues(alpha: .12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.brandOrange
                      : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: selected
                        ? AppColors.brandOrangeDark
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandOption extends StatelessWidget {
  const _BrandOption({
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final String brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedPressScale(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandOrange : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.brandOrange,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              brand,
              style: TextStyle(
                color: selected
                    ? AppColors.brandOrangeDark
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.brandOrange : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          value: selected,
          onChanged: (value) => onChanged(value ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.brandOrange,
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: CircleAvatar(
            radius: 20,
            backgroundColor: selected
                ? AppColors.brandGlow
                : AppColors.surfaceMuted,
            child: Icon(
              label == 'Extra cheese'
                  ? Icons.lunch_dining_rounded
                  : Icons.local_fire_department_rounded,
              color: AppColors.brandOrange,
              size: 19,
            ),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          subtitle: Text(
            detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
