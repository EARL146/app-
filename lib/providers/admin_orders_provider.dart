import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';

class AdminOrdersProvider extends ChangeNotifier {
  AdminOrdersProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final List<Order> _orders = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _successMessage;
  Order? _selectedOrder;
  OrderStatus? _filterStatus;

  List<Order> get orders => List.unmodifiable(_filteredOrders);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get successMessage => _successMessage;
  Order? get selectedOrder => _selectedOrder;
  OrderStatus? get filterStatus => _filterStatus;
  int get totalOrders => _orders.length;
  int get pendingOrders =>
      _orders.where((order) => order.status == OrderStatus.pending).length;
  int get processingOrders => _orders
      .where(
        (order) =>
            order.status == OrderStatus.processing ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.shipped,
      )
      .length;
  int get deliveredOrders =>
      _orders.where((order) => order.status == OrderStatus.delivered).length;
  int get cancelledOrders =>
      _orders.where((order) => order.status == OrderStatus.canceled).length;
  double get totalRevenue => _orders
      .where((order) => order.status == OrderStatus.delivered)
      .fold(0, (sum, order) => sum + order.total);

  List<Order> get _filteredOrders => _filterStatus == null
      ? _orders
      : _orders.where((order) => order.status == _filterStatus).toList();

  Future<void> loadOrders({bool force = false}) async {
    if (_isLoading || (!force && _hasLoaded)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/admin/orders',
        fromJson: _asMap,
      );
      if (!response.success || response.data == null) {
        _errorMessage = response.error ?? 'Unable to load orders.';
      } else {
        try {
          final rows = response.data!['orders'];
          if (rows is! List) {
            throw const FormatException('Invalid orders list.');
          }
          _orders
            ..clear()
            ..addAll(
              rows.whereType<Map<String, dynamic>>().map(Order.fromJson),
            );
        } catch (_) {
          _errorMessage = 'The server returned an invalid order list.';
        }
      }
    } catch (_) {
      _errorMessage = 'Unable to load orders. Please try again.';
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setFilterStatus(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void selectOrder(Order order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void deselectOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      _errorMessage = 'Order not found.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    final apiStatus = switch (newStatus) {
      OrderStatus.pending => 'pending',
      OrderStatus.processing => 'preparing',
      OrderStatus.ready => 'ready',
      OrderStatus.shipped => 'out_for_delivery',
      OrderStatus.delivered => 'delivered',
      OrderStatus.canceled => 'cancelled',
    };
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/admin/orders/${Uri.encodeComponent(orderId)}',
        body: {'status': apiStatus},
        fromJson: _asMap,
      );
      if (!response.success) {
        _errorMessage = response.error ?? 'Unable to update the order.';
        return false;
      }
      final old = _orders[index];
      final updated = _withStatus(old, newStatus);
      _orders[index] = updated;
      if (_selectedOrder?.id == orderId) _selectedOrder = updated;
      _successMessage = 'Order status updated to ${newStatus.displayName}.';
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update the order. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) =>
      updateOrderStatus(orderId, OrderStatus.canceled);

  List<Order> searchOrders(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _filteredOrders;
    return _filteredOrders
        .where((order) => order.id.toLowerCase().contains(normalized))
        .toList();
  }

  List<Order> getOrdersByDateRange(DateTime start, DateTime end) =>
      _filteredOrders
          .where(
            (order) =>
                !order.createdAt.isBefore(start) &&
                !order.createdAt.isAfter(end.add(const Duration(days: 1))),
          )
          .toList();

  Order _withStatus(Order order, OrderStatus status) => Order(
    id: order.id,
    userId: order.userId,
    items: order.items,
    subtotal: order.subtotal,
    tax: order.tax,
    shippingCost: order.shippingCost,
    total: order.total,
    status: status,
    notes: order.notes,
    deliveryAddress: order.deliveryAddress,
    createdAt: order.createdAt,
    updatedAt: DateTime.now(),
    deliveredAt: status == OrderStatus.delivered
        ? DateTime.now()
        : order.deliveredAt,
  );

  static Map<String, dynamic> _asMap(dynamic json) =>
      json is Map<String, dynamic>
      ? json
      : throw const FormatException('Invalid order response.');
}
