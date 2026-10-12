import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/order_model.dart';

class AdminOrdersProvider extends ChangeNotifier {
  final List<Order> _orders = List.from(DemoData.customerOrders);
  String? _errorMessage;
  bool _isLoading = false;
  String? _successMessage;
  Order? _selectedOrder;
  OrderStatus? _filterStatus;

  List<Order> get orders => List.unmodifiable(_filteredOrders);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  Order? get selectedOrder => _selectedOrder;
  OrderStatus? get filterStatus => _filterStatus;

  List<Order> get _filteredOrders {
    if (_filterStatus == null) return _orders;
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  int get totalOrders => _orders.length;
  int get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).length;
  int get processingOrders =>
      _orders.where((o) => o.status == OrderStatus.processing).length;
  int get deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.canceled).length;

  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0, (sum, order) => sum + order.total);

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
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      _isLoading = false;
      _errorMessage = 'Order not found.';
      notifyListeners();
      return false;
    }

    final oldOrder = _orders[index];
    _orders[index] = Order(
      id: oldOrder.id,
      userId: oldOrder.userId,
      items: oldOrder.items,
      subtotal: oldOrder.subtotal,
      tax: oldOrder.tax,
      shippingCost: oldOrder.shippingCost,
      total: oldOrder.total,
      status: newStatus,
      createdAt: oldOrder.createdAt,
      deliveredAt:
          newStatus == OrderStatus.delivered ? DateTime.now() : oldOrder.deliveredAt,
    );

    if (_selectedOrder?.id == orderId) {
      _selectedOrder = _orders[index];
    }

    _isLoading = false;
    _successMessage = 'Order status updated to ${_statusDisplayName(newStatus)}.';
    notifyListeners();
    return true;
  }

  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      _isLoading = false;
      _errorMessage = 'Order not found.';
      notifyListeners();
      return false;
    }

    final order = _orders[index];
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.canceled) {
      _isLoading = false;
      _errorMessage = 'Cannot cancel ${_statusDisplayName(order.status).toLowerCase()} orders.';
      notifyListeners();
      return false;
    }

    _orders[index] = Order(
      id: order.id,
      userId: order.userId,
      items: order.items,
      subtotal: order.subtotal,
      tax: order.tax,
      shippingCost: order.shippingCost,
      total: order.total,
      status: OrderStatus.canceled,
      createdAt: order.createdAt,
    );

    _isLoading = false;
    _successMessage = 'Order ${orderId} cancelled successfully!';
    if (_selectedOrder?.id == orderId) {
      _selectedOrder = _orders[index];
    }
    notifyListeners();
    return true;
  }

  String _statusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  List<Order> searchOrders(String query) {
    if (query.isEmpty) return _filteredOrders;
    final lowerQuery = query.toLowerCase();
    return _filteredOrders
        .where((o) => o.id.toLowerCase().contains(lowerQuery))
        .toList();
  }

  List<Order> getOrdersByDateRange(DateTime start, DateTime end) {
    return _filteredOrders
        .where((o) =>
            o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            o.createdAt.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }
}
