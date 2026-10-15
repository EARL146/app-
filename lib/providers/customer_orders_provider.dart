import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CustomerOrdersProvider extends ChangeNotifier {
  CustomerOrdersProvider(this._auth, {ApiService? apiService})
    : _api = apiService ?? ApiService() {
    _auth.addListener(_onAuthChanged);
    if (_auth.isAuthenticated) unawaited(loadOrders());
  }

  final AuthService _auth;
  final ApiService _api;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      unawaited(loadOrders(force: true));
    } else if (!_auth.isInitializing) {
      _orders = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> loadOrders({bool force = false}) async {
    if (!_auth.isAuthenticated || _isLoading) return;
    if (!force && _orders.isNotEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await _api.get<Map<String, dynamic>>(
      '/me/orders',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid order history response.'),
    );
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to load your orders.';
    } else {
      try {
        final rows = response.data!['orders'];
        if (rows is! List) throw const FormatException('Invalid order list.');
        _orders = rows
            .whereType<Map<String, dynamic>>()
            .map(Order.fromJson)
            .toList();
      } catch (_) {
        _errorMessage = 'The server returned an invalid order history.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return false;
    final response = await _api.put<Map<String, dynamic>>(
      '/me/orders/${Uri.encodeComponent(orderId)}/cancel',
      body: const <String, dynamic>{},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid cancellation response.'),
    );
    if (!response.success) {
      _errorMessage = response.error ?? 'Unable to cancel this order.';
      notifyListeners();
      return false;
    }
    final order = _orders[index];
    _orders[index] = Order(
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
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
