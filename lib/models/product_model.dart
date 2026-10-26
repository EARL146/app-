/// Product model representing food items in the menu
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountPercent;
  final String discountScope;
  final String? imageUrl;
  final List<String> imageUrls;
  final DateTime? discountStartsAt;
  final DateTime? discountEndsAt;
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
    this.imageUrls = const [],
    this.discountStartsAt,
    this.discountEndsAt,
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
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.whereType<String>()
              .where((image) => image.trim().isNotEmpty)
              .take(3)
              .toList(growable: false) ??
          const [],
      discountStartsAt: DateTime.tryParse(
        json['discount_starts_at'] as String? ?? '',
      ),
      discountEndsAt: DateTime.tryParse(
        json['discount_ends_at'] as String? ?? '',
      ),
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
      'image_urls': imageUrls,
      'discount_starts_at': discountStartsAt?.toUtc().toIso8601String(),
      'discount_ends_at': discountEndsAt?.toUtc().toIso8601String(),
      'category': category,
      'rating': rating,
      'review_count': reviewCount,
      'stock_quantity': stockQuantity,
      'available': available,
      'created_at': createdAt.toIso8601String(),
    };
  }

  List<String> get galleryImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    final single = imageUrl?.trim();
    return single == null || single.isEmpty ? const [] : [single];
  }

  bool get hasActiveDiscount {
    if (discountPercent <= 0) return false;
    final now = DateTime.now().toUtc();
    final starts = discountStartsAt?.toUtc();
    final ends = discountEndsAt?.toUtc();
    return (starts == null || !now.isBefore(starts)) &&
        (ends == null || now.isBefore(ends));
  }

  bool get hasCurrentOrUpcomingDiscount {
    if (discountPercent <= 0) return false;
    final now = DateTime.now().toUtc();
    return discountEndsAt == null || now.isBefore(discountEndsAt!.toUtc());
  }

  bool discountApplies({String size = 'Regular', String? drinkBrand}) {
    if (!hasActiveDiscount) return false;
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
