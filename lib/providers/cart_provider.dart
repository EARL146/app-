import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<OrderItem> _items = [];
  String? _errorMessage;
  bool _isSubmitting = false;
  String? _lastOrderId;

  List<OrderItem> get items => List.unmodifiable(_items);
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isEmpty => _items.isEmpty;
  String? get lastOrderId => _lastOrderId;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get deliveryFee => _items.isEmpty ? 0 : 25;
  double get tax => subtotal * 0.12;
  double get total => subtotal + deliveryFee + tax;

  void addItem(Product product, {int quantity = 1}) {
    if (!product.available) {
      _errorMessage = 'This item is currently unavailable.';
      notifyListeners();
      return;
    }

    if (quantity <= 0) {
      _errorMessage = 'Quantity must be greater than zero.';
      notifyListeners();
      return;
    }

    final index = _items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final item = _items[index];
      _items[index] = OrderItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity + quantity,
        productImage: item.productImage,
      );
    } else {
      _items.add(
        OrderItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: quantity,
          productImage: product.imageUrl,
        ),
      );
    }

    _errorMessage = null;
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index == -1) return;

    final item = _items[index];
    _items[index] = OrderItem(
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      quantity: quantity,
      productImage: item.productImage,
    );
    _errorMessage = null;
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _lastOrderId = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> submitOrder({
    required String customerName,
    required String deliveryAddress,
  }) async {
    if (_items.isEmpty) {
      _errorMessage = 'Your cart is empty.';
      notifyListeners();
      return null;
    }

    if (customerName.trim().length < 2) {
      _errorMessage = 'Customer name is required.';
      notifyListeners();
      return null;
    }

    if (deliveryAddress.trim().length < 8) {
      _errorMessage = 'Enter a valid delivery address.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    final orderId = 'BB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _lastOrderId = orderId;
    _isSubmitting = false;
    _items.clear();
    notifyListeners();

    return orderId;
  }
}
