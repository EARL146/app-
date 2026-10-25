import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/admin_products_provider.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;

  String _selectedCategory = 'Burgers';
  bool _isAvailable = true;
  bool _saleEnabled = false;
  String _saleScope = 'all';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _imageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        title: const Text(
          'Add New Product',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Consumer<AdminProductsProvider>(
        builder: (context, provider, _) {
          if (provider.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
              provider.clearMessages();
              Navigator.pop(context);
            });
          }

          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
              provider.clearMessages();
            });
          }

          return Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: AppColors.darkSurface,
              textTheme: Theme.of(context).textTheme
                  .apply(bodyColor: Colors.white, displayColor: Colors.white),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.darkSurfaceAlt,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B302B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B302B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.brandOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceAlt,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF3B302B)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white70,
                          size: 30,
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Add product image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Use an asset path or image ID below',
                          style: TextStyle(color: Colors.white54, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  _buildField(
                    label: 'Product Name',
                    controller: _nameController,
                    hint: 'Enter product name',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Description',
                    controller: _descriptionController,
                    hint: 'Enter product description',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Price (₱)',
                    controller: _priceController,
                    hint: 'Enter price',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Stock quantity',
                    controller: _stockController,
                    hint: 'Enter available units',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildSaleSettings(),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Image Icon/ID',
                    controller: _imageController,
                    hint: 'e.g., burger, chicken, fries',
                  ),
                  const SizedBox(height: 16),
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => _submitForm(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceAlt,
            border: Border.all(color: const Color(0xFF3B302B)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            dropdownColor: AppColors.darkSurfaceAlt,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            isExpanded: true,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            items: {'Burgers', 'Chicken', 'Sides', 'Drinks', _selectedCategory}
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  if (!_saleScopes.any((option) => option.$1 == _saleScope)) {
                    _saleScope = 'all';
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }

  List<(String, String)> get _saleScopes {
    final options = <(String, String)>[('all', 'All sizes and brands')];
    if (_selectedCategory == 'Drinks') {
      options.addAll([
        for (final brand in [
          'Coca-Cola',
          'Sprite',
          'Pepsi',
          'Royal',
          'Mountain Dew',
          '7Up',
        ])
          ('brand:$brand', 'Brand: $brand'),
        for (final size in ['Regular', 'Large', 'XL'])
          ('size:$size', 'Size: $size'),
      ]);
    } else if (_selectedCategory == 'Burgers') {
      options.addAll([
        for (final size in ['Regular', 'Large', 'Double'])
          ('size:$size', 'Size: $size'),
      ]);
    } else if (_selectedCategory == 'Fries' || _selectedCategory == 'Sides') {
      options.addAll([
        for (final size in ['Small', 'Medium', 'Large'])
          ('size:$size', 'Size: $size'),
      ]);
    }
    return options;
  }

  Widget _buildSaleSettings() => Material(
    color: AppColors.darkSurfaceAlt,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF3B302B)),
    ),
    child: Column(
      children: [
        SwitchListTile.adaptive(
          value: _saleEnabled,
          activeThumbColor: AppColors.brandOrange,
          title: const Text(
            '40% Discount Sale',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          subtitle: const Text(
            'Show this product in Discount Sale',
            style: TextStyle(color: Colors.white60, fontSize: 9),
          ),
          onChanged: (value) => setState(() => _saleEnabled = value),
        ),
        if (_saleEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DropdownButtonFormField<String>(
              initialValue: _saleScope,
              dropdownColor: AppColors.darkSurfaceAlt,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(labelText: 'Sale applies to'),
              items: _saleScopes
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.$1,
                      child: Text(option.$2),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _saleScope = value);
              },
            ),
          ),
      ],
    ),
  );

  Widget _buildAvailabilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Availability',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        Switch(
          value: _isAvailable,
          onChanged: (value) => setState(() => _isAvailable = value),
          activeThumbColor: AppColors.brandOrange,
        ),
      ],
    );
  }

  void _submitForm(BuildContext context, AdminProductsProvider provider) async {
    final success = await provider.addProduct(
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stockQuantity: int.tryParse(_stockController.text) ?? -1,
      category: _selectedCategory,
      imageUrl: _imageController.text,
      available: _isAvailable,
      discountPercent: _saleEnabled ? 40 : 0,
      discountScope: _saleScope,
    );

    if (!context.mounted) return;

    if (success) {
      provider.clearMessages();
      Navigator.pop(context);
    }
  }
}
