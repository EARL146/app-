import 'dart:async';

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
import '../../widgets/food_image.dart';
import '../../widgets/product_image_carousel.dart';
import '../../widgets/discount_sale_badge.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/customer_account_prompt.dart';
import '../../widgets/discount_sale_section.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.initialCategory = 'All'});

  final String initialCategory;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late String _selectedCategory = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final menuCategories = catalog.categories
        .where((category) => category != 'Discount Sale')
        .toList(growable: false);
    final filteredProducts = _selectedCategory == 'Discount Sale'
        ? catalog.products
              .where((product) => product.hasCurrentOrUpcomingDiscount)
              .toList()
        : _selectedCategory == 'All'
        ? catalog.products
        : catalog.products
              .where((product) => product.category == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Menu'.tr,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Order updates'.tr,
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed('/order-history'),
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                          IconButton(
                            tooltip: 'Cart'.tr,
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/cart'),
                            icon: Consumer<CartProvider>(
                              builder: (context, cart, _) => Badge(
                                isLabelVisible: cart.items.isNotEmpty,
                                label: Text(
                                  '${cart.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                                ),
                                child: const Icon(Icons.shopping_cart_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 13),
                      child: AnimatedPressScale(
                        child: InkWell(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/search'),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: AppColors.brandOrange,
                                  size: 19,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Search burgers, crispy fries, drinks'.tr,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _MenuOffer(
                        onTap: () => _selectCategory('Burgers'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 37,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        scrollDirection: Axis.horizontal,
                        itemCount: menuCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = menuCategories[index];
                          final selected = category == _selectedCategory;
                          return AnimatedPressScale(
                            child: ChoiceChip(
                              label: Text(category.tr),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.brandOrange,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.brandOrange
                                    : AppColors.border,
                              ),
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              showCheckmark: false,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: DiscountSaleSection(
                        products: catalog.products,
                        isLoading: catalog.isLoading,
                        onSeeAll: () => _selectCategory('Discount Sale'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Popular picks'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${filteredProducts.length} ${'items'.tr}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filteredProducts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                catalog.errorMessage ??
                                    (catalog.isLoading
                                        ? 'Loading menu…'.tr
                                        : _selectedCategory == 'Discount Sale'
                                        ? 'No sale items are available right now. Please check back later.'
                                              .tr
                                        : 'No products are available in this category yet.'
                                              .tr),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (catalog.errorMessage != null)
                                TextButton.icon(
                                  onPressed: () =>
                                      catalog.loadProducts(force: true),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text('Try again'.tr),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = (constraints.crossAxisExtent / 175)
                            .floor()
                            .clamp(2, 4);
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: .72,
                                  crossAxisSpacing: 11,
                                  mainAxisSpacing: 11,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => MenuProductCard(
                                product: filteredProducts[index],
                              ),
                              childCount: filteredProducts.length,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.isEmpty) return const SizedBox.shrink();
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 3, 18, 8),
                    child: AnimatedPressScale(
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/cart'),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 18),
                              const SizedBox(width: 8),
                              AnimatedValueText(
                                '${cart.items.fold<int>(0, (sum, item) => sum + item.quantity)} ${'items'.tr}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              AnimatedValueText(
                                '${'View cart'.tr} · ₱${cart.total.toStringAsFixed(0)}',
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(String category) =>
      setState(() => _selectedCategory = category);
}

class _MenuOffer extends StatefulWidget {
  const _MenuOffer({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MenuOffer> createState() => _MenuOfferState();
}

class _MenuOfferState extends State<_MenuOffer> {
  static const _images = [
    'assets/products/hero_burger_lifestyle.webp',
    'assets/products/hero_drinks_showcase.jpg',
    'assets/products/hero_loaded_fries.jpg',
  ];
  static const _labels = ['Burger', 'Drinks', 'Fries'];

  Timer? _autoAdvanceTimer;
  int _activeImage = 0;
  bool _reduceMotion = false;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_isWidgetTest) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
    } else {
      _autoAdvanceTimer ??= Timer.periodic(
        const Duration(seconds: 4),
        (_) => _selectImage((_activeImage + 1) % _images.length),
      );
    }
  }

  void _selectImage(int index) {
    if (!mounted || index == _activeImage) return;
    setState(() => _activeImage = index);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = (constraints.maxWidth * .52)
            .clamp(190.0, 270.0)
            .toDouble();
        final textWidth = (constraints.maxWidth - 38)
            .clamp(170.0, 330.0)
            .toDouble();
        return Container(
          height: heroHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: .12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < 0) {
                      _selectImage((_activeImage + 1) % _images.length);
                    } else if (velocity > 0) {
                      _selectImage(
                        (_activeImage - 1 + _images.length) % _images.length,
                      );
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: _reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final position = Tween<Offset>(
                        begin: const Offset(0.14, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: position,
                          child: child,
                        ),
                      );
                    },
                    child: Semantics(
                      key: ValueKey(_images[_activeImage]),
                      image: true,
                      label: _labels[_activeImage],
                      child: FoodImage(
                        imageUrl: _images[_activeImage],
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          const Color(0xD916100D),
                          const Color(0x6616100D),
                          const Color(0x0016100D),
                        ],
                        stops: const [0, .46, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 44, 27),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: textWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrandGradientBadge(
                            label: 'BURGERBITES MENU'.tr,
                            icon: Icons.restaurant_rounded,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Delicious food,\ndelivered fast'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                              shadows: [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Burgers, fries & drinks'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              shadows: [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: widget.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .96),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Browse menu'.tr,
                                    style: TextStyle(
                                      color: AppColors.brandOrange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.brandOrange,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 9,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (index) {
                    final selected = index == _activeImage;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label:
                          '${'Show'.tr} ${_labels[index].tr} ${'menu image'.tr}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => _selectImage(index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: AnimatedContainer(
                              duration: _reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              width: selected ? 9 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: selected ? 1 : .62,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MenuProductCard extends StatelessWidget {
  const MenuProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isDrink = product.category?.trim().toLowerCase() == 'drinks';
    final isFries = FriesOptions.isFries(product.category, product.name);
    final drinkBrand = DrinkOptions.brandForProductName(product.name);
    final displayName = isDrink ? drinkBrand : product.name;
    final quickAddName = isFries ? 'Small ${product.name}' : displayName;
    final displayDescription = isDrink
        ? 'Choose your favorite cold drink.'
        : product.description;
    final displayPrice = isDrink
        ? DrinkOptions.priceForSize('Regular')
        : isFries
        ? FriesOptions.priceForSize('Small')
        : product.price;
    final discountedDisplayPrice = product.applyDiscount(
      displayPrice,
      size: isFries ? 'Small' : 'Regular',
      drinkBrand: isDrink ? drinkBrand : null,
    );

    return AnimatedPressScale(
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .pushNamed('/product-details', arguments: product),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductImageCarousel(
                          images: product.galleryImages,
                          category: product.category,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: DiscountSaleBadge(product: product),
                    ),
                    if (product.rating != null)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .95),
                          shape: BoxShape.circle,
                        ),
                        child: FavoriteButton(product: product, iconSize: 17),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Consumer<CartProvider>(
                        builder: (context, cart, _) => IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 31,
                            height: 31,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            if (!await requireCustomerAccount(
                              context,
                              action: 'add this item to your cart',
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            cart.addItem(
                              product,
                              unitPrice: isDrink || isFries
                                  ? displayPrice
                                  : null,
                              displayName: isDrink || isFries
                                  ? quickAddName
                                  : null,
                              customizations: isDrink
                                  ? {
                                      'size': 'Regular',
                                      'drink_brand': drinkBrand,
                                    }
                                  : isFries
                                  ? {'size': 'Small'}
                                  : const {},
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$quickAddName added to cart'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.brandOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isFries
                          ? 'From ₱${discountedDisplayPrice.toStringAsFixed(0)}'
                          : '₱${discountedDisplayPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    'Customizable',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
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
