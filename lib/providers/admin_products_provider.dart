import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';

class AdminProductsProvider extends ChangeNotifier {
  AdminProductsProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final List<Product> _products = [];
  String? _errorMessage;
  bool _isLoading = false;
  String? _successMessage;
  Product? _selectedProduct;

  List<Product> get products => List.unmodifiable(_products);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  Product? get selectedProduct => _selectedProduct;
  int get totalProducts => _products.length;
  int get availableProducts =>
      _products.where((product) => product.available).length;

  Future<void> loadProducts({bool force = false}) async {
    if (_isLoading || (!force && _products.isNotEmpty)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/products',
      fromJson: _asMap,
    );
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to load products.';
    } else {
      try {
        final rows = response.data!['products'];
        if (rows is! List) {
          throw const FormatException('Invalid products list.');
        }
        _products
          ..clear()
          ..addAll(
            rows.whereType<Map<String, dynamic>>().map(Product.fromJson),
          );
      } catch (_) {
        _errorMessage = 'The server returned an invalid product list.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void deselectProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    int stockQuantity = 0,
    bool available = true,
    double discountPercent = 0,
    String discountScope = 'all',
  }) async {
    if (!_validate(name, description, price, category, stockQuantity)) {
      return false;
    }
    return _saveProduct(
      '/admin/products',
      create: true,
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      stockQuantity: stockQuantity,
      available: available,
      discountPercent: discountPercent,
      discountScope: discountScope,
    );
  }

  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    int? stockQuantity,
    bool available = true,
    double discountPercent = 0,
    String discountScope = 'all',
  }) async {
    final matches = _products.where((product) => product.id == productId);
    final old = matches.isEmpty ? null : matches.first;
    final stock = stockQuantity ?? old?.stockQuantity ?? 0;
    if (!_validate(name, description, price, category, stock)) return false;
    return _saveProduct(
      '/admin/products/${Uri.encodeComponent(productId)}',
      create: false,
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      stockQuantity: stock,
      available: available,
      discountPercent: discountPercent,
      discountScope: discountScope,
    );
  }

  bool _validate(
    String name,
    String description,
    double price,
    String category,
    int stock,
  ) {
    _errorMessage = null;
    if (name.trim().length < 2) {
      _errorMessage = 'Product name is required.';
    } else if (description.trim().isEmpty) {
      _errorMessage = 'Product description is required.';
    } else if (price <= 0 || !price.isFinite) {
      _errorMessage = 'Price must be greater than zero.';
    } else if (category.trim().isEmpty) {
      _errorMessage = 'Category is required.';
    } else if (stock < 0) {
      _errorMessage = 'Stock cannot be below zero.';
    }
    if (_errorMessage != null) notifyListeners();
    return _errorMessage == null;
  }

  Future<bool> _saveProduct(
    String endpoint, {
    required bool create,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    required int stockQuantity,
    required bool available,
    required double discountPercent,
    required String discountScope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    final body = {
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'category': category.trim(),
      'image_url': imageUrl.trim(),
      'stock_quantity': stockQuantity,
      'available': available,
      'discount_percent': discountPercent,
      'discount_scope': discountScope,
    };
    final response = create
        ? await _apiService.post<Map<String, dynamic>>(
            endpoint,
            body: body,
            fromJson: _asMap,
          )
        : await _apiService.put<Map<String, dynamic>>(
            endpoint,
            body: body,
            fromJson: _asMap,
          );
    final raw = response.data?['product'];
    if (!response.success || raw is! Map<String, dynamic>) {
      _errorMessage = response.error ?? 'The product was not saved.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final product = Product.fromJson(raw);
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index < 0) {
      _products.insert(0, product);
    } else {
      _products[index] = product;
    }
    _selectedProduct = product;
    _successMessage = create ? 'Product added.' : 'Product updated.';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    final response = await _apiService.delete<Map<String, dynamic>>(
      '/admin/products/${Uri.encodeComponent(productId)}',
      fromJson: _asMap,
    );
    _isLoading = false;
    if (!response.success) {
      _errorMessage = response.error ?? 'Unable to remove the product.';
      notifyListeners();
      return false;
    }
    final index = _products.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      _products[index] = Product(
        id: _products[index].id,
        name: _products[index].name,
        description: _products[index].description,
        price: _products[index].price,
        discountPercent: _products[index].discountPercent,
        discountScope: _products[index].discountScope,
        imageUrl: _products[index].imageUrl,
        category: _products[index].category,
        rating: _products[index].rating,
        reviewCount: _products[index].reviewCount,
        stockQuantity: _products[index].stockQuantity,
        available: false,
        createdAt: _products[index].createdAt,
      );
      _selectedProduct = null;
    }
    _successMessage = 'Product removed from the menu.';
    notifyListeners();
    return true;
  }

  Future<bool> toggleProductAvailability(String productId) async {
    final matches = _products.where((item) => item.id == productId);
    final product = matches.isEmpty ? null : matches.first;
    if (product == null) return false;
    return updateProduct(
      productId: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category ?? 'Burgers',
      imageUrl: product.imageUrl ?? '',
      stockQuantity: product.stockQuantity,
      available: !product.available,
    );
  }

  List<Product> searchProducts(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return products;
    return _products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalized) ||
              (product.category ?? '').toLowerCase().contains(normalized),
        )
        .toList();
  }

  List<Product> getProductsByCategory(String category) => category == 'All'
      ? products
      : _products.where((product) => product.category == category).toList();

  static Map<String, dynamic> _asMap(dynamic json) =>
      json is Map<String, dynamic>
      ? json
      : throw const FormatException('Invalid product response.');
}
