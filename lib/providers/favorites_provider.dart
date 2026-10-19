import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Keeps favorites synchronized with the authenticated customer's API account.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._authService, this._apiService) {
    _authService.addListener(_handleAuthChange);
    if (_authService.isAuthenticated) unawaited(loadFavorites());
  }

  final AuthService _authService;
  final ApiService _apiService;
  final Map<String, Product> _favorites = {};
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _loadOperation;

  List<Product> get favorites => List.unmodifiable(_favorites.values);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isFavorite(String productId) => _favorites.containsKey(productId);

  void _handleAuthChange() {
    if (_authService.isAuthenticated) {
      unawaited(loadFavorites());
    } else if (!_authService.isInitializing) {
      _favorites.clear();
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    if (!_authService.isAuthenticated) {
      _favorites.clear();
      _errorMessage = null;
      notifyListeners();
      return;
    }
    final activeLoad = _loadOperation;
    if (activeLoad != null) {
      await activeLoad;
      return;
    }
    final operation = _loadFavoritesFromApi();
    _loadOperation = operation;
    try {
      await operation;
    } finally {
      if (identical(_loadOperation, operation)) _loadOperation = null;
    }
  }

  Future<void> _loadFavoritesFromApi() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.get<Map<String, dynamic>>(
      '/me/favorites',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid favorites response.'),
    );
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to load your favorites.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final raw = response.data!['favorites'];
      if (raw is! List) throw const FormatException('Invalid favorites list.');
      final loaded = <String, Product>{};
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        final productJson = entry['product'] is Map<String, dynamic>
            ? entry['product'] as Map<String, dynamic>
            : entry;
        final product = Product.fromJson(productJson);
        loaded[product.id] = product;
      }
      _favorites
        ..clear()
        ..addAll(loaded);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'The server returned an invalid favorites list.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleFavorite(Product product) async {
    final activeLoad = _loadOperation;
    if (activeLoad != null) await activeLoad;
    if (!_authService.isAuthenticated) {
      _errorMessage = 'Sign in to save favorites to your account.';
      notifyListeners();
      return false;
    }
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final isSaved = _favorites.containsKey(product.id);
    final ApiResponse<dynamic> response;
    if (isSaved) {
      response = await _apiService.delete<dynamic>(
        '/me/favorites/${Uri.encodeComponent(product.id)}',
        fromJson: (json) => json,
      );
    } else {
      response = await _apiService.post<dynamic>(
        '/me/favorites',
        fromJson: (json) => json,
        body: {'product_id': product.id},
      );
    }

    _isLoading = false;
    if (!response.success) {
      _errorMessage = response.error ?? 'Unable to update your favorites.';
      notifyListeners();
      return false;
    }
    if (isSaved) {
      _favorites.remove(product.id);
    } else {
      _favorites[product.id] = product;
    }
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthChange);
    super.dispose();
  }
}
