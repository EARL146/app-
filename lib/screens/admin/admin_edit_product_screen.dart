import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/admin_products_provider.dart';

class AdminEditProductScreen extends StatefulWidget {
  final Product product;

  const AdminEditProductScreen({super.key, required this.product});

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;

  late String _selectedCategory;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stockQuantity.toString(),
    );
    _imageController = TextEditingController(
      text: widget.product.imageUrl ?? '',
    );
    _selectedCategory = widget.product.category ?? 'Burgers';
    _isAvailable = widget.product.available;
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
          'Edit Product',
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
                  borderSide: const BorderSide(
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
                    hint: 'Available units',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Image Icon/ID',
                    controller: _imageController,
                    hint: 'e.g., burger, chicken, fries',
                  ),
                  const SizedBox(height: 16),
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
            items:
                {
                      'Burgers',
                      'Chicken',
                      'Sides',
                      'Fries',
                      'Drinks',
                      _selectedCategory,
                    }
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ),
      ],
    );
  }

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
    final success = await provider.updateProduct(
      productId: widget.product.id,
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stockQuantity: int.tryParse(_stockController.text) ?? -1,
      category: _selectedCategory,
      imageUrl: _imageController.text,
      available: _isAvailable,
    );

    if (!context.mounted) return;

    if (success) {
      provider.clearMessages();
      Navigator.pop(context);
    }
  }
}
