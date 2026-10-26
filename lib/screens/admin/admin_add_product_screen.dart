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

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  static const _newProductSaleTarget = '__new_product__';

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late List<TextEditingController> _imageControllers;
  late TextEditingController _discountController;

  String _selectedCategory = 'Burgers';
  bool _isAvailable = true;
  bool _saleEnabled = false;
  bool _isSavingSale = false;
  bool _hasRequestedProducts = false;
  String _saleTargetId = _newProductSaleTarget;
  String _saleScope = 'all';
  DateTime? _saleStartsAt;
  DateTime? _saleEndsAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _imageControllers = List.generate(3, (_) => TextEditingController());
    _discountController = TextEditingController(text: '20');
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedProducts) return;
    _hasRequestedProducts = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProductsProvider>().loadProducts();
    });
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
          'Add New Product',
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
                    hint: 'Enter available units',
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
                  _buildCategoryDropdown(provider),
                  const SizedBox(height: 16),
                  _buildSaleSettings(provider),
                  const SizedBox(height: 16),
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => _submitForm(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
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

  Widget _buildCategoryDropdown(AdminProductsProvider provider) {
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
                  final saleCategory =
                      _saleTargetProduct(provider)?.category ?? value;
                  if (!_saleScopesFor(saleCategory)
                      .any((option) => option.$1 == _saleScope)) {
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

  List<(String, String)> _saleScopesFor(String category) {
    final options = <(String, String)>[('all', 'All sizes and brands')];
    final normalizedCategory = category.toLowerCase();
    if (normalizedCategory.contains('drink')) {
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
    } else if (normalizedCategory.contains('burger')) {
      options.addAll([
        for (final size in ['Regular', 'Large', 'Double'])
          ('size:$size', 'Size: $size'),
      ]);
    } else if (normalizedCategory.contains('fries') ||
        normalizedCategory.contains('side')) {
      options.addAll([
        for (final size in ['Small', 'Medium', 'Large'])
          ('size:$size', 'Size: $size'),
      ]);
    }
    return options;
  }

  Product? _saleTargetProduct(AdminProductsProvider provider) {
    if (_saleTargetId == _newProductSaleTarget) return null;
    for (final product in provider.products) {
      if (product.id == _saleTargetId) return product;
    }
    return null;
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
                  'Add product images',
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

  Widget _buildSaleSettings(AdminProductsProvider provider) {
    final targetProduct = _saleTargetProduct(provider);
    final targetCategory = targetProduct?.category ?? _selectedCategory;
    final scopes = _saleScopesFor(targetCategory);

    return Material(
      color: AdminFormStyles.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
              'Choose a product and discount target; expiry defaults to 24 hours after start',
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
                  DropdownButtonFormField<String>(
                    initialValue: _saleTargetId,
                    dropdownColor: AdminFormStyles.surface,
                    style: const TextStyle(
                      color: AdminFormStyles.text,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      labelText: provider.isLoading
                          ? 'Loading products…'
                          : 'Discount product',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: _newProductSaleTarget,
                        child: Text('New product being added'),
                      ),
                      ...provider.products.map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(
                            '${product.name} · ${product.category ?? 'Product'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      Product? selectedProduct;
                      for (final product in provider.products) {
                        if (product.id == value) {
                          selectedProduct = product;
                          break;
                        }
                      }
                      final category =
                          selectedProduct?.category ?? _selectedCategory;
                      final nextScopes = _saleScopesFor(category);
                      setState(() {
                        _saleTargetId = value;
                        if (!nextScopes.any(
                          (option) => option.$1 == _saleScope,
                        )) {
                          _saleScope = 'all';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose the new item or any existing catalog product.',
                      style: TextStyle(
                        color: AdminFormStyles.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    items: scopes
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
                          (_saleEndsAt == null ||
                              !_saleEndsAt!.isAfter(value))) {
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
                  if (targetProduct == null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'This sale will be saved with the new product.',
                      style: TextStyle(
                        color: AdminFormStyles.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'This action updates the selected product in the catalog.',
                        style: TextStyle(
                          color: AdminFormStyles.mutedText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSavingSale || provider.isLoading
                            ? null
                            : () => _applySaleToExistingProduct(
                                provider,
                                targetProduct,
                              ),
                        icon: _isSavingSale
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.local_fire_department_outlined),
                        label: const Text('Apply timed sale to this product'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandOrangeDark,
                          side: BorderSide(
                            color: AppColors.brandOrange.withValues(alpha: .8),
                          ),
                          minimumSize: const Size.fromHeight(42),
                        ),
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

  Future<void> _applySaleToExistingProduct(
    AdminProductsProvider provider,
    Product product,
  ) async {
    final discountPercent = double.tryParse(_discountController.text) ?? -1;
    if (!_isSaleConfigurationValid(discountPercent)) {
      _showSaleValidationMessage();
      return;
    }

    setState(() => _isSavingSale = true);
    final success = await provider.updateProduct(
      productId: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category ?? _selectedCategory,
      imageUrl: product.imageUrl ?? '',
      imageUrls: product.galleryImages,
      stockQuantity: product.stockQuantity,
      available: product.available,
      discountPercent: discountPercent,
      discountScope: _saleScope,
      discountStartsAt: _saleStartsAt ?? DateTime.now(),
      discountEndsAt: _saleEndsAt,
      showSuccessMessage: false,
    );
    if (!mounted) return;
    setState(() => _isSavingSale = false);
    if (success) {
      provider.clearMessages();
      final savedProduct = provider.selectedProduct;
      final catalog = context.read<CatalogProvider>();
      if (savedProduct != null) {
        catalog.upsertProduct(savedProduct);
      }
      unawaited(catalog.loadProducts(force: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timed sale saved for ${product.name}.')),
      );
    }
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

  bool _isSaleConfigurationValid(double discountPercent) {
    final startsAt = _saleStartsAt;
    final endsAt = _saleEndsAt;
    return _saleEnabled &&
        discountPercent.isFinite &&
        discountPercent > 0 &&
        discountPercent <= 90 &&
        startsAt != null &&
        endsAt != null &&
        startsAt.isBefore(endsAt);
  }

  void _showSaleValidationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Set a valid discount and expiry later than its start time.',
        ),
      ),
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
    final saleTargetsNewProduct = _saleTargetId == _newProductSaleTarget;
    final saleAppliesToNewProduct = _saleEnabled && saleTargetsNewProduct;
    if (saleAppliesToNewProduct &&
        !_isSaleConfigurationValid(discountPercent)) {
      _showSaleValidationMessage();
      return;
    }
    final images = _imageUrls;
    final success = await provider.addProduct(
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stockQuantity: stockQuantity ?? -1,
      category: _selectedCategory,
      imageUrl: images.isEmpty ? '' : images.first,
      imageUrls: images,
      available: _isAvailable,
      discountPercent: saleAppliesToNewProduct ? discountPercent : 0,
      discountScope: saleAppliesToNewProduct ? _saleScope : 'all',
      discountStartsAt: saleTargetsNewProduct ? _saleStartsAt : null,
      discountEndsAt: saleTargetsNewProduct ? _saleEndsAt : null,
    );

    if (!context.mounted) return;

    if (success) {
      final message = provider.successMessage ?? 'Product added.';
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
