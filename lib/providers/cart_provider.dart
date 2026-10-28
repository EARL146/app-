import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../constants/drink_options.dart';
import '../constants/fries_options.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({this.authService}) {
    final auth = authService;
    if (auth != null) {
      auth.addListener(_handleAuthChange);
      unawaited(auth.initialization.then((_) => _handleAuthChange()));
    }
  }

  final ApiService _apiService = ApiService();
  final AuthService? authService;
  final List<OrderItem> _items = [];
  Timer? _syncDebounce;
  Future<void> _saveQueue = Future<void>.value();
  String? _activeUserId;
  String? _errorMessage;
  String? _syncErrorMessage;
  bool _isSubmitting = false;
  bool _isLoadingRemoteCart = false;
  bool _isSyncing = false;
  bool _hasLoadedRemoteCart = false;
  bool _disposed = false;
  String? _lastOrderId;

  List<OrderItem> get items => List.unmodifiable(_items);
  String? get errorMessage => _errorMessage;
  String? get syncErrorMessage => _syncErrorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingRemoteCart => _isLoadingRemoteCart;
  bool get isSyncing => _isSyncing;
  bool get isEmpty => _items.isEmpty;
  String? get lastOrderId => _lastOrderId;

  @override
  void dispose() {
    _disposed = true;
    _syncDebounce?.cancel();
    authService?.removeListener(_handleAuthChange);
    super.dispose();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get deliveryFee => _items.isEmpty ? 0 : 25;
  double get tax => subtotal * 0.12;
  double get total => subtotal + deliveryFee + tax;

  void addItem(
    Product product, {
    int quantity = 1,
    double? unitPrice,
    String? displayName,
    Map<String, dynamic> customizations = const {},
  }) {
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

    final customizationKey = _customizationsKey(customizations);
    final size = customizations['size'] as String? ?? 'Regular';
    final drinkBrand = customizations['drink_brand'] as String?;
    final baseUnitPrice =
        unitPrice ?? _customizedBasePrice(product, customizations, size);
    final effectiveUnitPrice = product.applyDiscount(
      baseUnitPrice,
      size: size,
      drinkBrand: drinkBrand,
    );
    final index = _items.indexWhere(
      (item) =>
          item.productId == product.id &&
          _customizationsKey(item.customizations) == customizationKey,
    );
    if (index >= 0) {
      final item = _items[index];
      _items[index] = OrderItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity + quantity,
        productImage: item.productImage,
        customizations: item.customizations,
      );
    } else {
      _items.add(
        OrderItem(
          productId: product.id,
          productName: displayName ?? product.name,
          price: effectiveUnitPrice,
          quantity: quantity,
          productImage: product.imageUrl,
          customizations: customizations,
        ),
      );
    }

    _errorMessage = null;
    notifyListeners();
    _scheduleRemoteSave();
  }

  double _customizedBasePrice(
    Product product,
    Map<String, dynamic> customizations,
    String size,
  ) {
    final category = product.category?.trim().toLowerCase();
    if (category == 'drinks') return DrinkOptions.priceForSize(size);
    if (FriesOptions.isFries(category, product.name)) {
      return FriesOptions.priceForSize(size);
    }
    if (category == 'burgers') {
      var price =
          product.price +
          switch (size) {
            'Large' => 80.0,
            'Double' => 120.0,
            _ => 0.0,
          };
      final toppings = customizations['toppings'];
      if (toppings is List) {
        for (final topping in toppings) {
          if (topping == 'Extra cheese') price += 25;
          if (topping == 'Crispy bacon') price += 45;
        }
      }
      return price;
    }
    return product.price;
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    _updateItemAt(index, quantity);
  }

  void updateCartItemQuantity(OrderItem target, int quantity) {
    final index = _items.indexWhere((item) => identical(item, target));
    _updateItemAt(index, quantity);
  }

  void _updateItemAt(int index, int quantity) {
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
      _errorMessage = null;
      notifyListeners();
      _scheduleRemoteSave();
      return;
    }

    final item = _items[index];
    _items[index] = OrderItem(
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      quantity: quantity,
      productImage: item.productImage,
      customizations: item.customizations,
    );
    _errorMessage = null;
    notifyListeners();
    _scheduleRemoteSave();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _errorMessage = null;
    notifyListeners();
    _scheduleRemoteSave();
  }

  void clear() {
    _items.clear();
    _lastOrderId = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleAuthChange() {
    final auth = authService;
    if (_disposed || auth == null) return;
    final userId = auth.isAuthenticated && auth.currentUserRole == 'customer'
        ? auth.currentUserId
        : null;
    if (userId == _activeUserId) {
      if (auth.isAuthenticated &&
          auth.currentUserRole != 'customer' &&
          _items.isNotEmpty) {
        _items.clear();
        notifyListeners();
      }
      return;
    }

    _syncDebounce?.cancel();
    if (userId == null) {
      _activeUserId = null;
      _hasLoadedRemoteCart = false;
      _isLoadingRemoteCart = false;
      _isSyncing = false;
      _syncErrorMessage = null;
      _items.clear();
      notifyListeners();
      return;
    }

    final guestItems = _activeUserId == null
        ? List<OrderItem>.of(_items)
        : <OrderItem>[];
    if (_activeUserId != null) _items.clear();
    _activeUserId = userId;
    _hasLoadedRemoteCart = false;
    _isSyncing = false;
    _syncErrorMessage = null;
    unawaited(_loadRemoteCart(userId, guestItems));
  }

  Future<void> _loadRemoteCart(
    String userId,
    List<OrderItem> guestItems,
  ) async {
    _isLoadingRemoteCart = true;
    _syncErrorMessage = null;
    notifyListeners();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/me/cart',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid saved cart response.'),
    );
    if (_disposed || userId != _activeUserId) return;

    _isLoadingRemoteCart = false;
    final rawItems = response.data?['items'];
    if (!response.success || rawItems is! List) {
      _syncErrorMessage = response.error ?? 'Unable to load your saved cart.';
      notifyListeners();
      return;
    }

    final localItems = [...guestItems, ..._items];
    _items
      ..clear()
      ..addAll(
        rawItems.whereType<Map<String, dynamic>>().map(OrderItem.fromJson),
      );
    for (final item in localItems) {
      _mergeItem(item);
    }
    _hasLoadedRemoteCart = true;
    _syncErrorMessage = null;
    notifyListeners();
    if (localItems.isNotEmpty) _scheduleRemoteSave();
  }

  void _mergeItem(OrderItem incoming) {
    final key = _itemKey(incoming);
    final index = _items.indexWhere((item) => _itemKey(item) == key);
    if (index < 0) {
      _items.add(incoming);
      return;
    }
    final current = _items[index];
    _items[index] = OrderItem(
      productId: current.productId,
      productName: current.productName,
      price: current.price,
      quantity: (current.quantity + incoming.quantity).clamp(1, 99).toInt(),
      productImage: current.productImage,
      customizations: current.customizations,
    );
  }

  String _itemKey(OrderItem item) =>
      '${item.productId}:${_customizationsKey(item.customizations)}';

  String _customizationsKey(Map<String, dynamic> customizations) {
    final toppings =
        (customizations['toppings'] as List<dynamic>? ?? [])
            .map((value) => value.toString())
            .toList()
          ..sort();
    return jsonEncode({
      'size': customizations['size']?.toString() ?? 'Regular',
      'toppings': toppings,
      'drink_brand': customizations['drink_brand']?.toString(),
    });
  }

  void _scheduleRemoteSave() {
    if (_activeUserId == null || !_hasLoadedRemoteCart) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_saveRemoteCart());
    });
  }

  Future<void> _saveRemoteCart() {
    final userId = _activeUserId;
    if (userId == null || !_hasLoadedRemoteCart) return Future<void>.value();
    final snapshot = _items
        .map(
          (item) => {
            'product_id': item.productId,
            'quantity': item.quantity,
            if (item.customizations.isNotEmpty)
              'customizations': item.customizations,
          },
        )
        .toList(growable: false);

    final request = _saveQueue.then((_) async {
      if (_disposed || userId != _activeUserId) return;
      _isSyncing = true;
      notifyListeners();
      final response = await _apiService.put<Map<String, dynamic>>(
        '/me/cart',
        body: {'items': snapshot},
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid saved cart response.'),
      );
      if (_disposed || userId != _activeUserId) return;
      _isSyncing = false;
      _syncErrorMessage = response.success
          ? null
          : response.error ?? 'Unable to sync your cart.';
      notifyListeners();
    });
    _saveQueue = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  Future<void> _waitForRemoteWrites() async {
    _syncDebounce?.cancel();
    await _saveQueue;
  }

  Future<String?> submitOrder({
    required String customerName,
    required String deliveryAddress,
    required String phone,
    required String paymentMethod,
    String? notes,
    bool redeemRewards = false,
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
    if (phone.replaceAll(RegExp(r'\D'), '').length < 7) {
      _errorMessage = 'Enter a valid mobile number.';
      notifyListeners();
      return null;
    }
    if (paymentMethod != 'cod') {
      _errorMessage =
          'Online payment is not configured. Choose cash on delivery.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    await _waitForRemoteWrites();

    final response = await _apiService.post<Map<String, dynamic>>(
      '/orders',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid order response.'),
      body: {
        'customer_name': customerName.trim(),
        'delivery_address': deliveryAddress.trim(),
        'phone': phone.trim(),
        'payment_method': paymentMethod,
        'redeem_rewards': redeemRewards,
        if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        'items': _items
            .map(
              (item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                if (item.customizations.isNotEmpty)
                  'customizations': item.customizations,
              },
            )
            .toList(),
      },
    );
    final order = response.data?['order'];
    final result = order is Map<String, dynamic> ? order : response.data;
    final id = result?['order_id'] ?? result?['id'];
    if (!response.success || id == null || id.toString().isEmpty) {
      _isSubmitting = false;
      _errorMessage =
          response.error ??
          'The server did not confirm the order. Your cart is unchanged.';
      notifyListeners();
      _scheduleRemoteSave();
      return null;
    }

    final orderId = id.toString();
    _lastOrderId = orderId;
    _isSubmitting = false;
    _syncDebounce?.cancel();
    _items.clear();
    _syncErrorMessage = null;
    notifyListeners();

    return orderId;
  }
}
