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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _category = 'Burgers';
  _ProductSort _sort = _ProductSort.recommended;
  final List<String> _recentSearches = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.products;
    final results = products.where((product) {
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          (product.category ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
    switch (_sort) {
      case _ProductSort.priceLowToHigh:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _ProductSort.priceHighToLow:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _ProductSort.topRated:
        results.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case _ProductSort.recommended:
        break;
    }
    final suggestions = query.isEmpty
        ? <Product>[]
        : products
              .where((product) => !results.contains(product))
              .take(3)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Search menu'),
        actions: [
          PopupMenuButton<_ProductSort>(
            tooltip: 'Sort menu items',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => _ProductSort.values
                .map(
                  (sort) => PopupMenuItem<_ProductSort>(
                    value: sort,
                    child: Text(sort.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 3, 17, 9),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search burgers, crispy fries, drinks',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.brandOrange,
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
                  setState(() => _recentSearches.insert(0, trimmed));
                }
              },
            ),
          ),
          SizedBox(
            height: 41,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              scrollDirection: Axis.horizontal,
              children: catalog.categories
                  .map(
                    (category) => _CategoryFilter(
                      label: category,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${query.isEmpty ? 'Menu picks' : 'Search results'} · ${_sort.label}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      Text(
                        '${results.length} found',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                if (catalog.isLoading && products.isEmpty)
                  const _SearchNotice(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Loading the menu',
                    message: 'Fresh picks will appear here in a moment.',
                    isLoading: true,
                  )
                else if (products.isEmpty && catalog.errorMessage != null)
                  _SearchNotice(
                    icon: Icons.cloud_off_rounded,
                    title: 'Menu unavailable',
                    message: catalog.errorMessage!,
                    actionLabel: 'Try again',
                    onAction: () => context
                        .read<CatalogProvider>()
                        .loadProducts(force: true),
                  )
                else if (products.isEmpty)
                  const _SearchNotice(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'No menu items yet',
                    message: 'New menu items will show here when they are available.',
                  )
                else if (results.isEmpty)
                  const _SearchNotice(
                    icon: Icons.search_off_rounded,
                    title: 'No matching items',
                    message:
                        'Try another search or choose a different category.',
                  )
                else
                  ...results.map(
                    (product) => _SearchResultTile(product: product),
                  ),
                if (_recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent searches',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(_recentSearches.clear),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _recentSearches
                        .map(
                          (term) => ActionChip(
                            avatar: const Icon(Icons.history_rounded, size: 16),
                            label: Text(
                              term,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              _controller.text = term;
                              setState(() {});
                            },
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 17),
                  const Text(
                    'More from the menu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map(
                    (product) => _TrendingTile(
                      product: product,
                      onTap: () {
                        _controller.text = product.name;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(icon, color: AppColors.brandOrange, size: 28),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

enum _ProductSort {
  recommended('Recommended'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  topRated('Top rated');

  const _ProductSort(this.label);
  final String label;
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brandOrange,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.brandOrange : AppColors.border,
      ),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 10,
      ),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: () =>
          Navigator.of(context)
              .pushNamed('/product-details', arguments: product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: AppColors.warmSurfaceGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1E130C),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: FoodImage(
                imageUrl: product.imageUrl,
                category: product.category,
                borderRadius: 12,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteButton(product: product, iconSize: 18),
                Consumer<CartProvider>(
                  builder: (context, cart, _) => IconButton.filled(
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
                    icon: const Icon(Icons.add_rounded, size: 17),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTile extends StatelessWidget {
  const _TrendingTile({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
    leading: Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: AppColors.brandOrange,
        size: 17,
      ),
    ),
    title: Text(
      product.name,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${product.reviewCount ?? 0} ordered recently',
      style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
    ),
    trailing: Text(
      '₱${product.price.toStringAsFixed(0)}',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
    ),
    onTap: onTap,
  );
}
