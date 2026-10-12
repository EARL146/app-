import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'All'
        ? DemoData.products
        : DemoData.products.where((product) => product.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text('Menu'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: DemoData.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = DemoData.categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    selectedColor: AppColors.brandOrange,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return MenuProductCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuProductCard extends StatelessWidget {
  const MenuProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/product-details', arguments: product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _productIcon(product.category ?? 'Burgers'),
                      size: 54,
                      color: AppColors.brandOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      return IconButton(
                        onPressed: () {
                          cart.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle, color: AppColors.brandOrange),
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
