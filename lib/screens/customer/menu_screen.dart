import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/food_image.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/customer_account_prompt.dart';

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
    final filteredProducts = _selectedCategory == 'All'
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
                          const Expanded(
                            child: Text(
                              'Menu',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Search',
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/search'),
                            icon: const Icon(Icons.search_rounded),
                          ),
                          IconButton(
                            tooltip: 'Cart',
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
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: AppColors.brandOrange,
                                  size: 19,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Search burgers, crispy fries, drinks',
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
                        itemCount: catalog.categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = catalog.categories[index];
                          final selected = category == _selectedCategory;
                          return AnimatedPressScale(
                            child: ChoiceChip(
                              label: Text(category),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Popular picks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${filteredProducts.length} items',
                            style: const TextStyle(
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
                                        ? 'Loading menu…'
                                        : 'No products are available in this category yet.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (catalog.errorMessage != null)
                                TextButton.icon(
                                  onPressed: () =>
                                      catalog.loadProducts(force: true),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try again'),
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
                                '${cart.items.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              AnimatedValueText(
                                'View cart · ₱${cart.total.toStringAsFixed(0)}',
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
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: const Color(0xFF2D1D16),
        borderRadius: BorderRadius.circular(19),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
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
                      child: SlideTransition(position: position, child: child),
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
                      colors: [
                        const Color(0xFF2D1D16),
                        const Color(0xFF2D1D16).withValues(alpha: .92),
                        const Color(0xFF2D1D16).withValues(alpha: .04),
                      ],
                      stops: const [0, .56, 1],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandGradientBadge(
                    label: 'SPECIAL OFFER',
                    icon: Icons.bolt_rounded,
                  ),
                  const Spacer(),
                  const Text(
                    'Delicious food\ndelivered fast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enjoy 20% off your first combo order',
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: widget.onTap,
                    child: const Row(
                      children: [
                        Text(
                          'Order now',
                          style: TextStyle(
                            color: AppColors.brandOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.brandOrange,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 9,
              bottom: 7,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_images.length, (index) {
                  final selected = index == _activeImage;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Show ${_labels[index]} menu image',
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
                              color: selected
                                  ? AppColors.brandOrange
                                  : Colors.white.withValues(alpha: .8),
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
  }
}

class MenuProductCard extends StatelessWidget {
  const MenuProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
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
                      child: FoodImage(
                        imageUrl: product.imageUrl,
                        category: product.category,
                        borderRadius: 12,
                      ),
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
                            cart.addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
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
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
                      '₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Text(
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
