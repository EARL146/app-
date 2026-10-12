import '../models/order_model.dart';
import '../models/product_model.dart';

class DemoData {
  static final List<Product> products = [
    Product(
      id: 'classic-burger',
      name: 'Classic Burger',
      description: 'A juicy double patty with cheddar, lettuce, and signature sauce.',
      price: 280,
      imageUrl: 'burger',
      category: 'Burgers',
      rating: 4.8,
      reviewCount: 216,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Product(
      id: 'smash-burger',
      name: 'Smash Burger',
      description: 'Thin crispy patties stacked with caramelized onions and pickles.',
      price: 260,
      imageUrl: 'burger',
      category: 'Burgers',
      rating: 4.7,
      reviewCount: 184,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    Product(
      id: 'chicken-wrap',
      name: 'Chicken Wrap',
      description: 'Grilled chicken, crisp greens, and smoky mayo wrapped to go.',
      price: 220,
      imageUrl: 'wrap',
      category: 'Chicken',
      rating: 4.6,
      reviewCount: 139,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Product(
      id: 'loaded-fries',
      name: 'Loaded Fries',
      description: 'Crispy fries topped with cheese sauce and herb seasoning.',
      price: 180,
      imageUrl: 'fries',
      category: 'Sides',
      rating: 4.5,
      reviewCount: 201,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Product(
      id: 'crispy-chicken',
      name: 'Crispy Chicken',
      description: 'Golden fried chicken with crunchy slaw and honey glaze.',
      price: 240,
      imageUrl: 'chicken',
      category: 'Chicken',
      rating: 4.9,
      reviewCount: 168,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: 'mocha-shake',
      name: 'Mocha Shake',
      description: 'Creamy mocha shake with a hint of espresso and cocoa.',
      price: 150,
      imageUrl: 'shake',
      category: 'Drinks',
      rating: 4.4,
      reviewCount: 112,
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
    ),
  ];

  static final List<String> categories = ['All', 'Burgers', 'Chicken', 'Sides', 'Drinks'];

  static final List<Order> customerOrders = [
    Order(
      id: 'BB-2049',
      userId: 'user-001',
      items: [
        OrderItem(
          productId: 'classic-burger',
          productName: 'Classic Burger',
          price: 280,
          quantity: 2,
        ),
      ],
      subtotal: 560,
      tax: 44.8,
      shippingCost: 0,
      total: 604.8,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Order(
      id: 'BB-2052',
      userId: 'user-001',
      items: [
        OrderItem(productId: 'loaded-fries', productName: 'Loaded Fries', price: 180, quantity: 1),
        OrderItem(productId: 'mocha-shake', productName: 'Mocha Shake', price: 150, quantity: 1),
      ],
      subtotal: 330,
      tax: 26.4,
      shippingCost: 30,
      total: 386.4,
      status: OrderStatus.processing,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
