import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/food_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _category = 'Burgers';
  final List<String> _recentSearches = [
    'Double Bacon Smash',
    'Crispy Chicken',
    'Loaded Fries',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final filteredByCategory = DemoData.products
        .where((product) => _category == 'All' || product.category == _category)
        .toList();
    final results = query.isEmpty
        ? filteredByCategory
        : DemoData.products.where((product) {
            return product.name.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query) ||
                (product.category ?? '').toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Search menu')),
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
                    ? const Icon(Icons.mic_none_rounded)
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
              children: [
                _CategoryFilter(
                  label: 'All',
                  selected: _category == 'All',
                  onTap: () => setState(() => _category = 'All'),
                ),
                _CategoryFilter(
                  label: 'Burgers',
                  selected: _category == 'Burgers',
                  onTap: () => setState(() => _category = 'Burgers'),
                ),
                _CategoryFilter(
                  label: 'Chicken',
                  selected: _category == 'Chicken',
                  onTap: () => setState(() => _category = 'Chicken'),
                ),
                _CategoryFilter(
                  label: 'Sides',
                  selected: _category == 'Sides',
                  onTap: () => setState(() => _category = 'Sides'),
                ),
                _CategoryFilter(
                  label: 'Drinks',
                  selected: _category == 'Drinks',
                  onTap: () => setState(() => _category = 'Drinks'),
                ),
              ],
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
                        query.isEmpty ? 'Top picks' : 'Top match',
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
                if (results.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: AppColors.textSecondary,
                          size: 29,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No menu items match your search.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...results.map(
                    (product) => _SearchResultTile(product: product),
                  ),
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
                        style: TextStyle(fontSize: 9),
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
                          avatar: const Icon(Icons.history_rounded, size: 13),
                          label: Text(
                            term,
                            style: const TextStyle(fontSize: 9),
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
                const SizedBox(height: 17),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trending cravings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'HOT NOW',
                      style: TextStyle(
                        color: AppColors.brandOrange,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...DemoData.products
                    .take(3)
                    .map(
                      (product) => _TrendingTile(
                        product: product,
                        onTap: () {
                          _controller.text = product.name;
                          setState(() {});
                        },
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
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .pushNamed('/product-details', arguments: product),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
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
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating ?? 4.8}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
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
            Consumer<CartProvider>(
              builder: (context, cart, _) => IconButton.filled(
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
