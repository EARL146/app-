/// Product model representing food items in the menu
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountPercent;
  final String discountScope;
  final String? imageUrl;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final int stockQuantity;
  final bool available;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPercent = 0,
    this.discountScope = 'all',
    this.imageUrl,
    this.category,
    this.rating,
    this.reviewCount,
    this.stockQuantity = 0,
    this.available = true,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountScope: json['discount_scope'] as String? ?? 'all',
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      available: json['available'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_percent': discountPercent,
      'discount_scope': discountScope,
      'image_url': imageUrl,
      'category': category,
      'rating': rating,
      'review_count': reviewCount,
      'stock_quantity': stockQuantity,
      'available': available,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool discountApplies({String size = 'Regular', String? drinkBrand}) {
    if (discountPercent <= 0) return false;
    if (discountScope == 'all') return true;
    if (discountScope.startsWith('size:')) {
      return discountScope.substring(5) == size;
    }
    if (discountScope.startsWith('brand:')) {
      return discountScope.substring(6) == drinkBrand;
    }
    return false;
  }

  double applyDiscount(
    double amount, {
    String size = 'Regular',
    String? drinkBrand,
  }) => discountApplies(size: size, drinkBrand: drinkBrand)
      ? amount * (100 - discountPercent) / 100
      : amount;
}
