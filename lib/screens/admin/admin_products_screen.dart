import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../navigation/app_routes.dart';
import '../../providers/admin_products_provider.dart';
import '../../widgets/food_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: const Text(
          'Products Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.adminAddProduct);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AdminProductsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Stats Cards Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Products',
                        value: provider.totalProducts.toString(),
                        color: AppColors.brandOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Available',
                        value: provider.availableProducts.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: 'All',
                              isSelected: _selectedCategory == 'All',
                              onTap: () =>
                                  setState(() => _selectedCategory = 'All'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: 'Burgers',
                              isSelected: _selectedCategory == 'Burgers',
                              onTap: () =>
                                  setState(() => _selectedCategory = 'Burgers'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: 'Chicken',
                              isSelected: _selectedCategory == 'Chicken',
                              onTap: () =>
                                  setState(() => _selectedCategory = 'Chicken'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: 'Sides',
                              isSelected: _selectedCategory == 'Sides',
                              onTap: () =>
                                  setState(() => _selectedCategory = 'Sides'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: 'Drinks',
                              isSelected: _selectedCategory == 'Drinks',
                              onTap: () =>
                                  setState(() => _selectedCategory = 'Drinks'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Products List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _getFilteredProducts(provider).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _getFilteredProducts(provider).length,
                        itemBuilder: (context, index) {
                          final product = _getFilteredProducts(provider)[index];
                          return _ProductCard(
                            product: product,
                            onEdit: () => _editProduct(context, product),
                            onDelete: () => _deleteProduct(context, product),
                            onToggleAvailability: () =>
                                _toggleAvailability(context, product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Product> _getFilteredProducts(AdminProductsProvider provider) {
    final baseList = _selectedCategory == 'All'
        ? provider.products
        : provider.getProductsByCategory(_selectedCategory);

    if (_searchController.text.isEmpty) return baseList;
    return baseList
        .where(
          (p) => p.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  void _editProduct(BuildContext context, Product product) {
    context.read<AdminProductsProvider>().selectProduct(product);
    Navigator.pushNamed(
      context,
      AppRoutes.adminEditProduct,
      arguments: product,
    );
  }

  void _deleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AdminProductsProvider>()
                  .deleteProduct(product.id)
                  .then((_) {
                    if (!context.mounted) return;
                    final provider = context.read<AdminProductsProvider>();
                    if (provider.successMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.successMessage!),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(BuildContext context, Product product) {
    context
        .read<AdminProductsProvider>()
        .toggleProductAvailability(product.id)
        .then((_) {
          if (!context.mounted) return;
          final provider = context.read<AdminProductsProvider>();
          if (provider.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.successMessage!),
                backgroundColor: Colors.blue,
              ),
            );
          }
        });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall!
                .copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: FoodImage(
                    imageUrl: product.imageUrl,
                    category: product.category,
                    borderRadius: 13,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _ProductTag(
                            label: product.category ?? 'Burgers',
                            color: AppColors.brandOrange,
                          ),
                          _ProductTag(
                            label: product.available
                                ? 'Available'
                                : 'Unavailable',
                            color: product.available
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.rating ?? 0} · ${product.reviewCount ?? 0} reviews',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '₱${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleAvailability,
                    icon: Icon(
                      product.available
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 14,
                    ),
                    label: Text(
                      product.available ? 'Disable' : 'Enable',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete product',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 19,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTag extends StatelessWidget {
  const _ProductTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
    ),
  );
}
