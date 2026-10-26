/// Order item model for items within an order
class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final double originalUnitPrice;
  final double saleDiscountPercent;
  final double saleDiscountAmount;
  final int quantity;
  final String? productImage;
  final String? productCategory;
  final Map<String, dynamic> customizations;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.originalUnitPrice = 0,
    this.saleDiscountPercent = 0,
    this.saleDiscountAmount = 0,
    required this.quantity,
    this.productImage,
    this.productCategory,
    this.customizations = const {},
  });

  double get subtotal => price * quantity;
  double get originalSubtotal => originalUnitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final unitPrice = ((json['price'] ?? json['unit_price']) as num).toDouble();
    return OrderItem(
      productId: json['product_id'].toString(),
      productName: json['product_name'] as String? ?? 'Product',
      price: unitPrice,
      originalUnitPrice:
          (json['original_unit_price'] as num?)?.toDouble() ?? unitPrice,
      saleDiscountPercent:
          (json['sale_discount_percent'] as num?)?.toDouble() ?? 0,
      saleDiscountAmount:
          (json['sale_discount_amount'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num).toInt(),
      productImage: (json['product_image'] ?? json['image_url']) as String?,
      productCategory: json['product_category'] as String?,
      customizations: json['customizations'] is Map<String, dynamic>
          ? json['customizations'] as Map<String, dynamic>
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'original_unit_price': originalUnitPrice,
      'sale_discount_percent': saleDiscountPercent,
      'sale_discount_amount': saleDiscountAmount,
      'quantity': quantity,
      'product_image': productImage,
      'product_category': productCategory,
      'customizations': customizations,
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
  final String customerName;
  final String customerPhone;
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
    this.customerName = '',
    this.customerPhone = '',
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
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    final statusEnum = switch (statusStr) {
      'confirmed' || 'preparing' => OrderStatus.processing,
      'cancelled' => OrderStatus.canceled,
      _ => OrderStatus.values.firstWhere(
        (value) => value.name == statusStr,
        orElse: () => OrderStatus.pending,
      ),
    };

    return Order(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['phone'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
      shippingCost:
          ((json['shipping_cost'] ?? json['delivery_fee']) as num? ?? 0)
              .toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      status: statusEnum,
      notes: json['notes'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'phone': customerPhone,
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
