import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/food_image.dart';
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
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final products = DemoData.products;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.menu_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Burger',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const Text(
                    'Bites',
                    style: TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Search menu',
                    onPressed: () => Navigator.of(context).pushNamed('/search'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, _) => _CartButton(
                      count: cart.items.fold<int>(0, (s, i) => s + i.quantity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'DELIVER TO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.brandOrange,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Compostela, Cebu',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _showDemoNotice(context, 'Location selection'),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                    ),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HeroOffer(
                onOrder: () => Navigator.of(context).pushNamed('/menu'),
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Explore categories',
                action: 'See all',
                onTap: () => Navigator.of(context).pushNamed('/menu'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 74,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryBubble(
                      label: 'Burgers',
                      category: 'Burgers',
                      icon: Icons.lunch_dining_rounded,
                    ),
                    _CategoryBubble(
                      label: 'Crispy sides',
                      category: 'Sides',
                      icon: Icons.fastfood_rounded,
                    ),
                    _CategoryBubble(
                      label: 'Fizzy drinks',
                      category: 'Drinks',
                      icon: Icons.local_drink_rounded,
                    ),
                    _CategoryBubble(
                      label: 'Chicken',
                      category: 'Chicken',
                      icon: Icons.kebab_dining_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Popular bestsellers',
                action: 'View menu',
                onTap: () => Navigator.of(context).pushNamed('/menu'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _ProductCard(product: products[index]),
                ),
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Your recent orders',
                action: 'Order history',
                onTap: () => Navigator.of(context).pushNamed('/order-history'),
              ),
              const SizedBox(height: 12),
              ...DemoData.customerOrders
                  .take(2)
                  .map(
                    (order) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.brandOrange,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order.items.length} item${order.items.length == 1 ? '' : 's'} · ${order.status.displayName}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₱${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroOffer extends StatelessWidget {
  const _HeroOffer({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF2B1C16),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: .13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 174,
            child: FoodImage(
              imageUrl: 'assets/products/smash_burger.jpg',
              borderRadius: 0,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2B1C16),
                    const Color(0xFF2B1C16).withValues(alpha: .98),
                    const Color(0xFF2B1C16).withValues(alpha: .06),
                  ],
                  stops: const [0, .52, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 17,
            bottom: 17,
            width: 208,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'SPECIAL OFFER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Delicious food.\nDelivered fast.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Get 20% off your first combo order.',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: onOrder,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text(
                      'Order now',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandOrange,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.label,
    required this.category,
    required this.icon,
  });

  final String label;
  final String category;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed('/menu', arguments: category),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.brandOrange, size: 21),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .pushNamed('/product-details', arguments: product),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FoodImage(
                      imageUrl: product.imageUrl,
                      category: product.category,
                      borderRadius: 12,
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating ?? 4.8}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₱${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.brandOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Consumer<CartProvider>(
                  builder: (context, cart, _) => SizedBox(
                    width: 29,
                    height: 29,
                    child: IconButton.filled(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        cart.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 17),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.of(context).pushNamed('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

void _showDemoNotice(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature is a demo option.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class MenuScreenButton extends StatelessWidget {
  const MenuScreenButton({super.key});

  @override
  Widget build(BuildContext context) => const MenuScreen();
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) => const OrderHistoryScreen();
}

class ProfileScreenButton extends StatelessWidget {
  const ProfileScreenButton({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
