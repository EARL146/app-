import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/product_model.dart';

class AdminProductsProvider extends ChangeNotifier {
  final List<Product> _products = List.from(DemoData.products);
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
  int get availableProducts => _products.where((p) => p.available).length;

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
    bool available = true,
  }) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Product name is required.';
      notifyListeners();
      return false;
    }

    if (description.trim().isEmpty) {
      _errorMessage = 'Product description is required.';
      notifyListeners();
      return false;
    }

    if (price <= 0) {
      _errorMessage = 'Price must be greater than zero.';
      notifyListeners();
      return false;
    }

    if (category.trim().isEmpty) {
      _errorMessage = 'Category is required.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Check for duplicate
    if (_products.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      _isLoading = false;
      _errorMessage = 'A product with this name already exists.';
      notifyListeners();
      return false;
    }

    final newProduct = Product(
      id: name.toLowerCase().replaceAll(' ', '-'),
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      rating: 4.5,
      reviewCount: 0,
      available: available,
      createdAt: DateTime.now(),
    );

    _products.add(newProduct);
    _isLoading = false;
    _successMessage = 'Product "$name" added successfully!';
    notifyListeners();
    return true;
  }

  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
    bool available = true,
  }) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Product name is required.';
      notifyListeners();
      return false;
    }

    if (description.trim().isEmpty) {
      _errorMessage = 'Product description is required.';
      notifyListeners();
      return false;
    }

    if (price <= 0) {
      _errorMessage = 'Price must be greater than zero.';
      notifyListeners();
      return false;
    }

    if (category.trim().isEmpty) {
      _errorMessage = 'Category is required.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      _isLoading = false;
      _errorMessage = 'Product not found.';
      notifyListeners();
      return false;
    }

    final oldProduct = _products[index];
    _products[index] = Product(
      id: oldProduct.id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      rating: oldProduct.rating,
      reviewCount: oldProduct.reviewCount,
      available: available,
      createdAt: oldProduct.createdAt,
    );

    _isLoading = false;
    _successMessage = 'Product "$name" updated successfully!';
    _selectedProduct = _products[index];
    notifyListeners();
    return true;
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    _products.removeWhere((p) => p.id == productId);
    _isLoading = false;
    _successMessage = 'Product "${product.name}" deleted successfully!';
    _selectedProduct = null;
    notifyListeners();
    return true;
  }

  Future<bool> toggleProductAvailability(String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final product = _products[index];
    _products[index] = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
      category: product.category,
      rating: product.rating,
      reviewCount: product.reviewCount,
      available: !product.available,
      createdAt: product.createdAt,
    );

    _successMessage =
        'Product availability updated to ${!product.available ? 'Available' : 'Unavailable'}.';
    notifyListeners();
    return true;
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              (p.category ?? '').toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }
}
