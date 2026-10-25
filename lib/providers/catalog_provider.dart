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
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  List<String> get categories => [
    'All',
    ...(_products
        .map((product) => product.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort()),
    if (_products.any((product) => product.discountPercent > 0))
      'Discount Sale',
  ];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts({bool force = false}) async {
    if (_isLoading || (!force && _hasAttemptedLoad)) return;
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
    }
  }
}
