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
  late TextEditingController _imageController;

  String _selectedCategory = 'Burgers';
  bool _isAvailable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _imageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandOrange,
        title: const Text('Add New Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
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

          return SingleChildScrollView(
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            items: ['Burgers', 'Chicken', 'Sides', 'Drinks']
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Switch(
          value: _isAvailable,
          onChanged: (value) => setState(() => _isAvailable = value),
          activeColor: AppColors.brandOrange,
        ),
      ],
    );
  }

  void _submitForm(
      BuildContext context, AdminProductsProvider provider) async {
    final success = await provider.addProduct(
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      category: _selectedCategory,
      imageUrl: _imageController.text,
      available: _isAvailable,
    );

    if (!mounted) return;

    if (success) {
      provider.clearMessages();
      Navigator.pop(context);
    }
  }
}
