import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/food_image.dart';
import '../../widgets/favorite_button.dart';

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
            Padding(
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
                    onPressed: () => Navigator.of(context).pushNamed('/search'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () => Navigator.of(context).pushNamed('/cart'),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 13),
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed('/search'),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _MenuOffer(onTap: () => _selectCategory('Burgers')),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 37,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: catalog.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = catalog.categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
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
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Padding(
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
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
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
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = (constraints.maxWidth / 175)
                            .floor()
                            .clamp(2, 4);
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                childAspectRatio: .72,
                                crossAxisSpacing: 11,
                                mainAxisSpacing: 11,
                              ),
                          itemBuilder: (context, index) =>
                              MenuProductCard(product: filteredProducts[index]),
                        );
                      },
                    ),
            ),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.isEmpty) return const SizedBox.shrink();
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 3, 18, 8),
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
                            Text(
                              '${cart.items.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
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

class _MenuOffer extends StatelessWidget {
  const _MenuOffer({required this.onTap});

  final VoidCallback onTap;

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
            child: FoodImage(
              imageUrl: 'assets/products/smash_burger.jpg',
              borderRadius: 0,
            ),
          ),
          Positioned.fill(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SPECIAL OFFER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: .5,
                    ),
                  ),
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
                  onTap: onTap,
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
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .pushNamed('/product-details', arguments: product),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
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
                            '${product.rating ?? 4.8}',
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
                        onPressed: () {
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
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
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
