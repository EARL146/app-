import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/admin_form_styles.dart';
import '../../models/product_model.dart';
import '../../providers/admin_products_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_image_carousel.dart';
import '../../widgets/admin_sale_schedule_summary.dart';

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
  late List<TextEditingController> _imageControllers;
  late TextEditingController _discountController;

  late String _selectedCategory;
  late bool _isAvailable;
  late bool _saleEnabled;
  late String _saleScope;
  DateTime? _saleStartsAt;
  DateTime? _saleEndsAt;

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
    final imageUrls = widget.product.galleryImages;
    _imageControllers = List.generate(
      3,
      (index) => TextEditingController(
        text: index < imageUrls.length ? imageUrls[index] : '',
      ),
    );
    _discountController = TextEditingController(
      text: widget.product.discountPercent.toStringAsFixed(0),
    );
    _selectedCategory = widget.product.category ?? 'Burgers';
    _isAvailable = widget.product.available;
    _saleEnabled = widget.product.discountPercent > 0;
    _saleScope = widget.product.discountScope;
    _saleStartsAt = widget.product.discountStartsAt?.toLocal();
    _saleEndsAt = widget.product.discountEndsAt?.toLocal();
    if (!_saleScopes.any((option) => option.$1 == _saleScope)) {
      _saleScope = 'all';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final controller in _imageControllers) {
      controller.dispose();
    }
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminFormStyles.page,
      appBar: AppBar(
        backgroundColor: AdminFormStyles.surface,
        foregroundColor: AdminFormStyles.text,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminFormStyles.border),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AdminFormStyles.text,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer<AdminProductsProvider>(
        builder: (context, provider, _) {
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
            data: AdminFormStyles.theme(context),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(),
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
                    hint: 'Available units',
                    keyboardType: TextInputType.number,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Set stock to at least 1 for customers to see this product.',
                      style: TextStyle(
                        color: AdminFormStyles.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildSaleSettings(),
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
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
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
            color: AdminFormStyles.text,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: AdminFormStyles.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
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
            color: AdminFormStyles.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AdminFormStyles.surface,
            border: Border.all(color: AdminFormStyles.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A2D1C14),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            dropdownColor: AdminFormStyles.surface,
            style: const TextStyle(
              color: AdminFormStyles.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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

  List<String> get _imageUrls => _imageControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .take(3)
      .toList(growable: false);

  Widget _buildImageGallery() {
    final images = _imageUrls;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminFormStyles.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AdminFormStyles.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2D1C14),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.brandOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Product images',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AdminFormStyles.text,
                  ),
                ),
              ),
              Text(
                '${images.length}/3',
                style: TextStyle(
                  color: AppColors.brandOrangeDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Add up to 3 image paths or URLs. They rotate automatically in the menu.',
            style: TextStyle(color: AdminFormStyles.mutedText, fontSize: 10),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < _imageControllers.length; index++) ...[
            TextField(
              controller: _imageControllers[index],
              style: const TextStyle(color: AdminFormStyles.text, fontSize: 12),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Image ${index + 1}',
                hintText: index == 0
                    ? 'assets/products/burger.jpg'
                    : 'Optional image path or URL',
                prefixIcon: const Icon(
                  Icons.image_outlined,
                  color: AdminFormStyles.mutedText,
                  size: 18,
                ),
              ),
            ),
            if (index < _imageControllers.length - 1) const SizedBox(height: 8),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 150,
                child: ProductImageCarousel(
                  images: images,
                  category: _selectedCategory,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaleSettings() => Material(
    color: AdminFormStyles.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: AdminFormStyles.border),
    ),
    child: Column(
      children: [
        SwitchListTile.adaptive(
          value: _saleEnabled,
          activeThumbColor: AppColors.brandOrange,
          title: const Text(
            'Timed discount sale',
            style: TextStyle(
              color: AdminFormStyles.text,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          subtitle: const Text(
            'Choose a discount and target; expiry defaults to 24 hours after start',
            style: TextStyle(color: AdminFormStyles.mutedText, fontSize: 10),
          ),
          onChanged: (value) => setState(() {
            _saleEnabled = value;
            if (value) {
              _saleStartsAt ??= DateTime.now();
              _saleEndsAt ??= _saleStartsAt!.add(const Duration(days: 1));
            }
          }),
        ),
        if (!_saleEnabled && (_saleStartsAt != null || _saleEndsAt != null))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AdminSaleScheduleSummary(
              startsAt: _saleStartsAt,
              endsAt: _saleEndsAt,
            ),
          ),
        if (_saleEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: AdminFormStyles.text,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount percent',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _saleScope,
                  dropdownColor: AdminFormStyles.surface,
                  style: const TextStyle(
                    color: AdminFormStyles.text,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sale applies to',
                  ),
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
                const SizedBox(height: 10),
                _dateTimePicker(
                  context,
                  'Starts',
                  _saleStartsAt,
                  (value) => setState(() {
                    _saleStartsAt = value;
                    if (value != null &&
                        (_saleEndsAt == null || !_saleEndsAt!.isAfter(value))) {
                      _saleEndsAt = value.add(const Duration(days: 1));
                    }
                  }),
                ),
                const SizedBox(height: 8),
                _dateTimePicker(
                  context,
                  'Expires',
                  _saleEndsAt,
                  (value) => setState(() => _saleEndsAt = value),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _dateTimePicker(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    final display = value == null
        ? 'Choose date and time'
        : value.toLocal().toString().substring(0, 16);
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (selectedDate == null || !context.mounted) return;
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? now),
        );
        if (selectedTime == null) return;
        onChanged(
          DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          ),
        );
      },
      icon: const Icon(Icons.schedule_rounded, size: 16),
      label: Text(
        '$label · $display',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandOrangeDark,
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(42),
      ),
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
            color: AdminFormStyles.text,
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
    final stockQuantity = int.tryParse(_stockController.text);
    if (_isAvailable && (stockQuantity == null || stockQuantity < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set stock to at least 1 so customers can see this available product.',
          ),
        ),
      );
      return;
    }

    final discountPercent = double.tryParse(_discountController.text) ?? -1;
    if (_saleEnabled &&
        (_saleEndsAt == null ||
            discountPercent <= 0 ||
            discountPercent > 90 ||
            !(_saleStartsAt ?? DateTime.now()).isBefore(_saleEndsAt!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set a valid discount and expiry later than its start time.',
          ),
        ),
      );
      return;
    }
    final images = _imageUrls;
    final success = await provider.updateProduct(
      productId: widget.product.id,
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stockQuantity: stockQuantity ?? -1,
      category: _selectedCategory,
      imageUrl: images.isEmpty ? '' : images.first,
      imageUrls: images,
      available: _isAvailable,
      discountPercent: _saleEnabled ? discountPercent : 0,
      discountScope: _saleScope,
      discountStartsAt: _saleStartsAt,
      discountEndsAt: _saleEndsAt,
    );

    if (!context.mounted) return;

    if (success) {
      final message = provider.successMessage ?? 'Product updated.';
      final messenger = ScaffoldMessenger.of(context);
      final savedProduct = provider.selectedProduct;
      final catalog = context.read<CatalogProvider>();
      if (savedProduct != null) {
        catalog.upsertProduct(savedProduct);
      }
      unawaited(catalog.loadProducts(force: true));
      provider.clearMessages();
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
