import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../providers/cart_provider.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    MenuScreenButton(),
    _OrdersTab(),
    ProfileScreenButton(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.brandOrange),
              const SizedBox(width: 8),
              const Text(
                'Mandaue City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pushNamed('/cart'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                      ),
                      if (cart.items.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.brandOrange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${cart.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Good morning, John',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.brandOrange,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Fresh tastes, fast delivery',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Discover hot deals and signature burgers.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.fastfood_rounded, size: 72, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/menu'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: DemoData.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final product = DemoData.products[index];
                return _ProductCard(product: product);
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/order-history'),
                child: const Text('View all'),
              ),
            ],
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: DemoData.customerOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final order = DemoData.customerOrders[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppColors.brandOrange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.items[0].productName} • ${order.status.displayName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, super.key});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/product-details', arguments: product),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    _productIcon(product.category ?? 'Burgers'),
                    size: 62,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${product.rating ?? 4.8}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '₱${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _productIcon(String category) {
    switch (category) {
      case 'Burgers':
        return Icons.lunch_dining_rounded;
      case 'Chicken':
        return Icons.kebab_dining_rounded;
      case 'Sides':
        return Icons.local_pizza_rounded;
      case 'Drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }
}

class MenuScreenButton extends StatelessWidget {
  const MenuScreenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const MenuScreen();
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderHistoryScreen();
  }
}

class ProfileScreenButton extends StatelessWidget {
  const ProfileScreenButton();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
