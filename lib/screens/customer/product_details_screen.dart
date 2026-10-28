import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/drink_options.dart';
import '../../constants/fries_options.dart';
import '../../l10n/app_translations.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/food_image.dart';
import '../../widgets/customer_account_prompt.dart';
import '../../widgets/product_image_carousel.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  String _size = 'Regular';
  String _drinkBrand = DrinkOptions.brands.first;
  final Set<String> _extras = {};

  @override
  void initState() {
    super.initState();
    if (_isFries(widget.product)) _size = 'Small';
    _drinkBrand = _brandForProduct(widget.product);
  }

  @override
  void deactivate() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id) return;
    _quantity = 1;
    _size = _isFries(widget.product) ? 'Small' : 'Regular';
    _drinkBrand = _brandForProduct(widget.product);
    _extras.clear();
  }

  String _brandForProduct(Product product) =>
      DrinkOptions.brandForProductName(product.name);

  String get _drinkDisplayName =>
      [_drinkBrand, if (_size != 'Regular') _size].join(' ');

  double _baseUnitPrice(Product product) {
    if (_isDrink(product)) return DrinkOptions.priceForSize(_size);
    if (_isFries(product)) return FriesOptions.priceForSize(_size);
    final isBurger = _isBurger(product);
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
    return product.price + sizePrice + extrasPrice;
  }

  double _unitPrice(Product product) => product.applyDiscount(
    _baseUnitPrice(product),
    size: _size,
    drinkBrand: _isDrink(product) ? _drinkBrand : null,
  );

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
    final catalog = context.watch<CatalogProvider>();
    final matchingProducts = catalog.products.where(
      (item) => item.id == widget.product.id,
    );
    final product = matchingProducts.isEmpty
        ? widget.product
        : matchingProducts.first;
    final baseUnitPrice = _baseUnitPrice(product);
    final unitPrice = _unitPrice(product);
    final isBurgerProduct = _isBurger(product);
    final isFriesProduct = _isFries(product);
    final isDrinkProduct = _isDrink(product);
    final saleAppliesToSelection = product.discountApplies(
      size: _size,
      drinkBrand: isDrinkProduct ? _drinkBrand : null,
    );
    final categoryLabel = product.category?.trim();
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.33)
        .clamp(220.0, 300.0)
        .toDouble();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('Product details'.tr),
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
                  tooltip:
                      '${'Cart'.tr}${itemCount == 0 ? '' : ', $itemCount ${'items'.tr}'}',
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
                  constraints: const BoxConstraints(maxWidth: 680),
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
                                if (isDrinkProduct)
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    child: _DrinkBrandHeroImage(
                                      key: ValueKey(_drinkBrand),
                                      brand: _drinkBrand,
                                    ),
                                  )
                                else if (product.galleryImages.length > 1)
                                  ProductImageCarousel(
                                    images: product.galleryImages,
                                    category: product.category,
                                  )
                                else
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
                                        ? 'Available'.tr
                                        : 'Unavailable'.tr,
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x080F0B09),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    isDrinkProduct
                                        ? _drinkDisplayName
                                        : product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 23,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${unitPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: AppColors.brandOrange,
                                        fontSize: 21,
                                        height: 1.1,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    if (saleAppliesToSelection)
                                      Text(
                                        '₱${baseUnitPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Selected price',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
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
                                if (product.discountPercent > 0 &&
                                    product.discountApplies(
                                      size: _size,
                                      drinkBrand: isDrinkProduct
                                          ? _drinkBrand
                                          : null,
                                    ))
                                  _ProductInfoChip(
                                    icon: Icons.local_offer_rounded,
                                    label:
                                        '${product.discountPercent.toStringAsFixed(0)}% off',
                                    color: AppColors.success,
                                  ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 13),
                              child: Divider(height: 1),
                            ),
                            Text(
                              'About this item'.tr,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isDrinkProduct
                                  ? 'Choose your favorite refreshing drink and size.'
                                  : product.description.trim().isEmpty
                                  ? 'A description for this item has not been added yet.'
                                  : product.description.trim(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isBurgerProduct) ...[
                        const SizedBox(height: 14),
                        _ProductOptionsPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldHeading(
                                title: 'Burger size',
                                trailing: 'Select one',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _SizeOption(
                                    label: 'Regular',
                                    detail: '1/4 lb',
                                    icon: Icons.lunch_dining_rounded,
                                    selected: _size == 'Regular',
                                    onTap: () =>
                                        setState(() => _size = 'Regular'),
                                  ),
                                  const SizedBox(width: 8),
                                  _SizeOption(
                                    label: 'Large',
                                    detail: '+ ₱80',
                                    icon: Icons.lunch_dining_rounded,
                                    selected: _size == 'Large',
                                    onTap: () =>
                                        setState(() => _size = 'Large'),
                                  ),
                                  const SizedBox(width: 8),
                                  _SizeOption(
                                    label: 'Double',
                                    detail: '+ ₱120',
                                    icon: Icons.fastfood_rounded,
                                    selected: _size == 'Double',
                                    onTap: () =>
                                        setState(() => _size = 'Double'),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                              const _FieldHeading(
                                title: 'Extra toppings',
                                trailing: 'Optional',
                              ),
                              const SizedBox(height: 9),
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
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.brandOrange,
                                      size: 17,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your selected size and toppings are saved with the order. Final prices are checked at checkout.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isFriesProduct) ...[
                        const SizedBox(height: 14),
                        _ProductOptionsPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldHeading(
                                title: 'Fries size',
                                trailing: 'Select one',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < FriesOptions.sizes.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const SizedBox(width: 8),
                                    _SizeOption(
                                      label: FriesOptions.sizes[index],
                                      detail:
                                          '₱${FriesOptions.priceForSize(FriesOptions.sizes[index]).toStringAsFixed(0)}',
                                      icon: Icons.fastfood_rounded,
                                      selected:
                                          _size == FriesOptions.sizes[index],
                                      onTap: () => setState(
                                        () => _size = FriesOptions.sizes[index],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Price updates when you choose a different fries size.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isDrinkProduct) ...[
                        const SizedBox(height: 14),
                        _ProductOptionsPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldHeading(
                                title: 'Drink brand',
                                trailing: 'Choose one',
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: DrinkOptions.brands
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
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                              _FieldHeading(
                                title: 'Drink size',
                                trailing: 'Price by size',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < DrinkOptions.sizes.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const SizedBox(width: 8),
                                    _SizeOption(
                                      label: DrinkOptions.sizes[index],
                                      detail:
                                          '₱${DrinkOptions.priceForSize(DrinkOptions.sizes[index]).toStringAsFixed(0)}',
                                      icon: Icons.local_cafe_rounded,
                                      selected:
                                          _size == DrinkOptions.sizes[index],
                                      onTap: () => setState(
                                        () => _size = DrinkOptions.sizes[index],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The price updates when you choose a different size.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isBurgerProduct &&
                          !isFriesProduct &&
                          !isDrinkProduct) ...[
                        const SizedBox(height: 14),
                        _ProductOptionsPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldHeading(
                                title: 'Ready to order',
                                trailing: 'Sold as listed',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.brandOrange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Choose a quantity below to update your order total, then add this item to your cart.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                border: Border(top: BorderSide(color: AppColors.border)),
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
                                              ? _drinkDisplayName
                                              : '${(isBurgerProduct && _size != 'Regular') || isFriesProduct ? '$_size ' : ''}${product.name}${toppings.isEmpty ? '' : ' + ${toppings.join(', ')}'}';
                                          cart.addItem(
                                            product,
                                            quantity: _quantity,
                                            unitPrice: baseUnitPrice,
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
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          messenger.clearSnackBars();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '$displayName added to cart',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom: 84 +
                                                    MediaQuery.paddingOf(
                                                      context,
                                                    ).bottom,
                                                left: 16,
                                                right: 16,
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              action: SnackBarAction(
                                                label: 'View Cart',
                                                textColor:
                                                    AppColors.brandOrange,
                                                onPressed: () {
                                                  messenger.clearSnackBars();
                                                  Navigator.of(context)
                                                      .pushNamed('/cart');
                                                },
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
                                      Expanded(
                                        child: Text(
                                          product.available
                                              ? 'Add to cart'.tr
                                              : 'Unavailable'.tr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Text(
                                          '₱${(unitPrice * _quantity).toStringAsFixed(0)}',
                                          key: ValueKey(
                                            (unitPrice * _quantity)
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

class _DrinkBrandHeroImage extends StatelessWidget {
  const _DrinkBrandHeroImage({required this.brand, super.key});

  static const _sourceWidth = 1673.0;
  static const _sourceHeight = 940.0;
  static const _cropWidth = 285.0;
  static const _cropHeight = 425.0;
  static const _brandCropLeft = <String, double>{
    'Coca-Cola': 275,
    'Sprite': 0,
    'Pepsi': 815,
    'Royal': 545,
    'Mountain Dew': 1080,
    '7Up': 1360,
  };
  static const _brandColors = <String, List<Color>>{
    'Coca-Cola': [Color(0xFF3B1712), Color(0xFFB9271E)],
    'Sprite': [Color(0xFF133D2E), Color(0xFF2E9B52)],
    'Pepsi': [Color(0xFF12243B), Color(0xFF235E9B)],
    'Royal': [Color(0xFF4C2814), Color(0xFFE88424)],
    'Mountain Dew': [Color(0xFF19331D), Color(0xFF79A82A)],
    '7Up': [Color(0xFF153C2A), Color(0xFF59A94A)],
  };

  final String brand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '$brand drink',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final scale = height / _cropHeight;
          final imageWidth = _sourceWidth * scale;
          final imageHeight = _sourceHeight * scale;
          final viewportWidth = _cropWidth * scale;
          final maxHorizontalOffset = _sourceWidth - _cropWidth;
          final alignmentX =
              2 * (_brandCropLeft[brand]! / maxHorizontalOffset) - 1;
          final colors = _brandColors[brand]!;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -.2),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: .18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: viewportWidth,
                    height: height,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment(alignmentX, 1),
                        minWidth: 0,
                        maxWidth: imageWidth,
                        minHeight: 0,
                        maxHeight: imageHeight,
                        child: Image.asset(
                          'assets/products/hero_drinks_showcase.jpg',
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.local_drink_rounded,
                              color: Colors.white.withValues(alpha: .9),
                              size: 82,
                            ),
                          ),
                        ),
                      ),
                    ),
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
          label.tr,
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

class _ProductOptionsPanel extends StatelessWidget {
  const _ProductOptionsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060F0B09),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
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
          title.tr,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      Text(
        trailing.tr,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ProductInfoChip extends StatelessWidget {
  const _ProductInfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

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
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label.tr,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
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
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $detail',
        child: AnimatedPressScale(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              decoration: BoxDecoration(
                color: selected ? AppColors.surfaceMuted : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.brandOrange : AppColors.border,
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.brandOrange.withValues(alpha: .1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AppColors.brandOrange
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: brand,
    child: AnimatedPressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                Icon(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? AppColors.surfaceMuted : AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.brandOrange : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
