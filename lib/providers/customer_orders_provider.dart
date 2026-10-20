import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CustomerOrdersProvider extends ChangeNotifier {
  CustomerOrdersProvider(this._auth, {ApiService? apiService})
    : _api = apiService ?? ApiService() {
    _sessionUserId = _auth.isAuthenticated ? _auth.currentUserId : null;
    _auth.addListener(_onAuthChanged);
    if (_auth.isAuthenticated) unawaited(loadOrders());
  }

  final AuthService _auth;
  final ApiService _api;
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String? _sessionUserId;
  int _requestGeneration = 0;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      if (_sessionUserId != _auth.currentUserId) {
        _requestGeneration++;
        _sessionUserId = _auth.currentUserId;
        _orders = [];
        _isLoading = false;
        _hasLoaded = false;
        _errorMessage = null;
        notifyListeners();
      }
      unawaited(loadOrders(force: true));
    } else if (!_auth.isInitializing) {
      _requestGeneration++;
      _sessionUserId = null;
      _orders = [];
      _isLoading = false;
      _hasLoaded = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> loadOrders({bool force = false}) async {
    if (!_auth.isAuthenticated || _isLoading) return;
    if (!force && _hasLoaded) return;
    final requestGeneration = _requestGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/me/orders',
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid order history response.'),
      );
      if (requestGeneration != _requestGeneration || !_auth.isAuthenticated) {
        return;
      }
      _hasLoaded = true;
      if (!response.success || response.data == null) {
        _errorMessage = response.error ?? 'Unable to load your orders.';
      } else {
        try {
          final rows = response.data!['orders'];
          if (rows is! List) {
            throw const FormatException('Invalid order list.');
          }
          _orders = rows
              .whereType<Map<String, dynamic>>()
              .map(Order.fromJson)
              .toList();
        } catch (_) {
          _errorMessage = 'The server returned an invalid order history.';
        }
      }
    } catch (_) {
      if (requestGeneration == _requestGeneration && _auth.isAuthenticated) {
        _hasLoaded = true;
        _errorMessage = 'Unable to load your orders. Please try again.';
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    final requestGeneration = _requestGeneration;
    final userId = _auth.currentUserId;
    if (!_auth.isAuthenticated || userId == null) return false;
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return false;
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/me/orders/${Uri.encodeComponent(orderId)}/cancel',
        body: const <String, dynamic>{},
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid cancellation response.'),
      );
      if (!response.success) {
        if (requestGeneration != _requestGeneration ||
            !_auth.isAuthenticated ||
            _auth.currentUserId != userId) {
          return false;
        }
        _errorMessage = response.error ?? 'Unable to cancel this order.';
        notifyListeners();
        return false;
      }
      if (requestGeneration != _requestGeneration ||
          !_auth.isAuthenticated ||
          _auth.currentUserId != userId) {
        return false;
      }
      final currentIndex = _orders.indexWhere((order) => order.id == orderId);
      if (currentIndex < 0) return false;
      final order = _orders[currentIndex];
      _orders[currentIndex] = Order(
        id: order.id,
        userId: order.userId,
        items: order.items,
        subtotal: order.subtotal,
        tax: order.tax,
        shippingCost: order.shippingCost,
        total: order.total,
        status: OrderStatus.canceled,
        notes: order.notes,
        deliveryAddress: order.deliveryAddress,
        createdAt: order.createdAt,
        updatedAt: DateTime.now(),
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (requestGeneration == _requestGeneration &&
          _auth.isAuthenticated &&
          _auth.currentUserId == userId) {
        _errorMessage = 'Unable to cancel your order. Please try again.';
        notifyListeners();
      }
      return false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
