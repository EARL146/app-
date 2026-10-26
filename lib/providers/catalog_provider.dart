import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasAttemptedLoad = false;
  bool _forceReloadRequested = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  List<String> get categories {
    final categories =
        _products
            .map((product) => product.category?.trim())
            .whereType<String>()
            .where((category) => category.isNotEmpty)
            .where((category) => category.toLowerCase() != 'discount sale')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories, 'Discount Sale'];
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void upsertProduct(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (!product.available || product.stockQuantity <= 0) {
      if (index >= 0) {
        _products.removeAt(index);
        notifyListeners();
      }
      return;
    }

    if (index < 0) {
      _products.insert(0, product);
    } else {
      _products[index] = product;
    }
    notifyListeners();
  }

  Future<void> loadProducts({bool force = false}) async {
    if (_isLoading) {
      if (force) _forceReloadRequested = true;
      return;
    }
    if (!force && _hasAttemptedLoad) return;
    _isLoading = true;
    _hasAttemptedLoad = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/products',
        requiresAuth: false,
        queryParams: const {'limit': '50', 'offset': '0'},
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid catalog response.'),
      );
      if (!response.success || response.data == null) {
        _errorMessage = response.error ?? 'Unable to load the menu.';
      } else {
        try {
          final raw = response.data!['products'];
          if (raw is! List) {
            throw const FormatException('Invalid products list.');
          }
          _products = raw
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList(growable: false);
        } catch (_) {
          _errorMessage = 'The server returned an invalid menu.';
        }
      }
    } catch (_) {
      _errorMessage =
          'Unable to load the menu. Check the API connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_forceReloadRequested) {
        _forceReloadRequested = false;
        unawaited(loadProducts(force: true));
      }
    }
  }
}
