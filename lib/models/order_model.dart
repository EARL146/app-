/// Order item model for items within an order
class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? productImage;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.productImage,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      productImage: json['product_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'product_image': productImage,
    };
  }
}

/// Order status enum
enum OrderStatus {
  pending('Pending'),
  processing('Processing'),
  ready('Ready'),
  shipped('Shipped'),
  delivered('Delivered'),
  canceled('Canceled');

  final String displayName;
  const OrderStatus(this.displayName);
}

/// Order model representing customer orders
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final OrderStatus status;
  final String? notes;
  final String? deliveryAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.total,
    required this.status,
    this.notes,
    this.deliveryAddress,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  Status get statusBadge {
    switch (status) {
      case OrderStatus.pending:
        return Status('Pending', 'orange');
      case OrderStatus.processing:
        return Status('Processing', 'blue');
      case OrderStatus.ready:
        return Status('Ready', 'green');
      case OrderStatus.shipped:
        return Status('Shipped', 'purple');
      case OrderStatus.delivered:
        return Status('Delivered', 'green');
      case OrderStatus.canceled:
        return Status('Canceled', 'red');
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    OrderStatus statusEnum;

    try {
      statusEnum = OrderStatus.values.firstWhere(
        (e) => e.name == statusStr.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      statusEnum = OrderStatus.pending;
    }

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
      shippingCost: (json['shipping_cost'] as num? ?? 0).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      status: statusEnum,
      notes: json['notes'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping_cost': shippingCost,
      'total': total,
      'status': status.name,
      'notes': notes,
      'delivery_address': deliveryAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

/// Status badge data
class Status {
  final String label;
  final String color;

  Status(this.label, this.color);
}
