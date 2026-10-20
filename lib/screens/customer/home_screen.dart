import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/food_image.dart';
import '../../widgets/customer_account_prompt.dart';
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
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.products;
    final categories =
        products
            .map((product) => product.category?.trim())
            .whereType<String>()
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final orderProvider = context.watch<CustomerOrdersProvider>();
    final recentOrders = orderProvider.orders.take(2).toList();
    final auth = context.watch<AuthService>();
    final deliveryAddress = auth.currentUserAddress?.trim().isNotEmpty == true
        ? auth.currentUserAddress!
        : auth.currentUserBranch?.trim().isNotEmpty == true
        ? auth.currentUserBranch!
        : 'Add your delivery address';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          tooltip: 'Open menu',
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/menu'),
                          icon: const Icon(Icons.menu_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Burger',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              TextSpan(
                                text: 'Bites',
                                style: TextStyle(
                                  color: AppColors.brandRed,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search menu',
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/search'),
                        icon: const Icon(Icons.search_rounded),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) => _CartButton(
                          count: cart.items.fold<int>(
                            0,
                            (s, i) => s + i.quantity,
                          ),
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
                      Expanded(
                        child: Text(
                          deliveryAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/profile'),
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
                  const SizedBox(height: 16),
                  _SectionHeading(
                    title: 'Explore categories',
                    action: 'See all',
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    Text(
                      catalog.isLoading ? 'Loading menu categories…' : 'Menu categories will appear when products are available.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    )
                  else
                    SizedBox(
                      height: 74,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryBubble(
                            label: category,
                            category: category,
                            icon: _categoryIcon(category),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'From the menu',
                    action: 'View menu',
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 12),
                  if (catalog.isLoading && products.isEmpty)
                    const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalog.errorMessage ?? 'Our menu is being updated. Please check again soon.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (catalog.errorMessage != null)
                          TextButton.icon(
                            onPressed: () => catalog.loadProducts(force: true),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                      ],
                    )
                  else
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
                  const SizedBox(height: 16),
                  _HomeInfoCard(
                    eyebrow: 'OUR STORY',
                    title: 'A little about BurgerBites',
                    description: 'Browse available menu items, add your picks to the cart, and review saved orders in one place.',
                    icon: Icons.lunch_dining_rounded,
                    actionLabel: 'Explore the menu',
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Your recent orders',
                    action: auth.isAuthenticated ? 'Order history' : 'Sign in',
                    onTap: () => Navigator.of(context).pushNamed(
                      auth.isAuthenticated ? '/order-history' : '/sign-in',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!auth.isAuthenticated)
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Sign in to view your order history.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/sign-in'),
                          child: const Text('Sign in'),
                        ),
                      ],
                    )
                  else if (!orderProvider.hasLoaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (orderProvider.errorMessage != null &&
                      recentOrders.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: orderProvider.isLoading
                              ? null
                              : () => orderProvider.loadOrders(force: true),
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: const Text('Retry'),
                        ),
                      ],
                    )
                  else if (recentOrders.isEmpty)
                    const Text(
                      'No orders yet. Browse the menu to get started.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (orderProvider.errorMessage != null &&
                      recentOrders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Could not refresh. Showing saved orders.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: orderProvider.isLoading
                                ? null
                                : () => orderProvider.loadOrders(force: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ...recentOrders.map(
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
                  const SizedBox(height: 12),
                  const _DifferenceSection(),
                  const SizedBox(height: 18),
                  _HomeInfoCard(
                    eyebrow: 'FIND US',
                    title: 'Store and contact',
                    description: 'Open Contact Us for published store details and support options.',
                    icon: Icons.location_on_rounded,
                    actionLabel: 'View contact details',
                    onTap: () => Navigator.of(context).pushNamed('/contact'),
                  ),
                  const SizedBox(height: 16),
                  _OrderCallToAction(
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroOffer extends StatelessWidget {
  const _HeroOffer({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final accessibleText = textScale > 1.15;
    final heroHeight = accessibleText
        ? (230 + ((textScale - 1.15) * 50)).clamp(230.0, 300.0).toDouble()
        : 240.0;
    final imageWidth = accessibleText ? 145.0 : 174.0;
    return Container(
      height: heroHeight,
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
            width: imageWidth,
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
              mainAxisAlignment: accessibleText
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!accessibleText)
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
                      'BURGERBITES MENU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                if (!accessibleText) const Spacer(),
                Text(
                  accessibleText
                      ? 'Delicious food, delivered fast.'
                      : 'Delicious food,\ndelivered fast.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: accessibleText ? 18 : 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!accessibleText) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Browse the menu and add your picks to the cart.',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
                SizedBox(height: accessibleText ? 10 : 11),
                SizedBox(
                  height: accessibleText ? 48 : 32,
                  child: ElevatedButton.icon(
                    onPressed: onOrder,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(
                      'Order now',
                      style: TextStyle(fontSize: accessibleText ? 12 : 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 0,
                      ),
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

class _HomeInfoCard extends StatelessWidget {
  const _HomeInfoCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.brandOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: AppColors.brandOrange,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandOrange,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
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

class _DifferenceSection extends StatelessWidget {
  const _DifferenceSection();

  static const _features = [
    (
      'Browse the menu',
      'See the items currently listed.',
      Icons.menu_book_rounded,
    ),
    (
      'Build your cart',
      'Collect your picks before checkout.',
      Icons.shopping_bag_outlined,
    ),
    (
      'Review orders',
      'Check your saved order details.',
      Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What makes us different',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 119,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _features.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final feature = _features[index];
              return SizedBox(
                width: 142,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(feature.$3, color: AppColors.brandOrange, size: 19),
                      const Spacer(),
                      Text(
                        feature.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        feature.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderCallToAction extends StatelessWidget {
  const _OrderCallToAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.brandOrange,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to order?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Browse the menu and choose what you would like.',
            style: TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 17),
              label: const Text('Browse menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  final name = category.toLowerCase();
  if (name.contains('burger')) return Icons.lunch_dining_rounded;
  if (name.contains('drink') || name.contains('beverage')) {
    return Icons.local_drink_rounded;
  }
  if (name.contains('side') || name.contains('fries')) {
    return Icons.fastfood_rounded;
  }
  if (name.contains('chicken')) return Icons.kebab_dining_rounded;
  return Icons.restaurant_menu_rounded;
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
                  if (product.rating != null)
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
                              product.rating!.toStringAsFixed(1),
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
                      onPressed: () async {
                        if (!await requireCustomerAccount(
                          context,
                          action: 'add this item to your cart',
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
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
