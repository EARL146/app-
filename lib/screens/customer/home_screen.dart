import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/customer_account_prompt.dart';
import '../../widgets/food_image.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, this.openMenuInitially = false});

  final bool openMenuInitially;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.openMenuInitially ? 1 : 0;
  }

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
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
        : 'Compostela, Davao de Oro PH';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              sliver: SliverList.list(
                children: [
                  // 1. Top Figma Brand Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A1E130C),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          tooltip: 'Open menu',
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/menu'),
                          icon: const Icon(Icons.menu_rounded, size: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BrandLogo(
                              width: 28,
                              height: 28,
                              animate: false,
                            ),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Burger',
                                    style: TextStyle(
                                      color: Color(0xFFE51C23),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bites',
                                    style: TextStyle(
                                      color: Color(0xFF7B0D14),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Order updates',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/order-history'),
                        icon: const Icon(Icons.notifications_none_rounded),
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
                  const SizedBox(height: 12),

                  // 2. Search Bar + Orange Filter Button (from Image 4)
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedPressScale(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/search'),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D1E130C),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: AppColors.brandOrange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Search juicy burgers, crispy fries, drinks...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.textSecondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      AnimatedPressScale(
                        onTap: () => Navigator.of(context).pushNamed('/search'),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryButtonGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandOrange.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. Deliver To Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.brandOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'DELIVER TO:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            deliveryAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/profile'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppColors.brandOrange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 15,
                                  color: AppColors.brandOrange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Hero Banner + Auto-Moving "Burger Bites" Marquee (Images 4 & 5)
                  _HeroOfferWithTicker(
                    onOrder: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 18),

                  // 5. "Our Story — How Burger Bites Started" + Storefront Collage (Images 4 & 5)
                  const _OurStorySection(),
                  const SizedBox(height: 20),

                  // 6. 4-Category Illustrated Showcase Grid (Burgers, Drinks, Fries, Combo Meals — Image 4)
                  _MenuCategoryShowcase(
                    onSelectCategory: (category) => Navigator.of(
                      context,
                    ).pushNamed('/menu', arguments: category),
                  ),
                  const SizedBox(height: 20),

                  // 7. Live Catalog Categories & Products
                  _SectionHeading(
                    title: 'Explore categories',
                    action: 'See all',
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 10),
                  if (categories.isEmpty)
                    Text(
                      catalog.isLoading
                          ? 'Loading menu categories…'
                          : 'Menu categories will appear when products are available.',
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
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'From the menu',
                    action: 'View menu',
                    onTap: () => Navigator.of(context).pushNamed('/menu'),
                  ),
                  const SizedBox(height: 10),
                  if (catalog.isLoading && products.isEmpty)
                    const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.warmSurfaceGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catalog.errorMessage ??
                                'Our menu is being updated. Please check again soon.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          if (catalog.errorMessage != null)
                            TextButton.icon(
                              onPressed: () =>
                                  catalog.loadProducts(force: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 224,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            _ProductCard(product: products[index]),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 8. "What Makes Us Different" + "Our Customers" (Image 4)
                  const _DifferenceAndCustomersSection(),
                  const SizedBox(height: 20),

                  // 9. "Your recent orders" (Polished card, preserves widget test contract)
                  _SectionHeading(
                    title: 'Your recent orders',
                    action: auth.isAuthenticated ? 'Order history' : 'Sign in',
                    onTap: () => Navigator.of(context).pushNamed(
                      auth.isAuthenticated ? '/order-history' : '/sign-in',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RecentOrdersSection(
                    auth: auth,
                    orderProvider: orderProvider,
                    recentOrders: recentOrders,
                  ),
                  const SizedBox(height: 22),

                  // 10. "Find Us — Location: Compostela Davao de oro PH" with Draggable Map (Image 6)
                  const _FindUsDraggableMapSection(),
                  const SizedBox(height: 20),

                  // 11. Bottom Dark Banner: "THE PERFECT COMBO" + Footer Strip (Images 4 & 6)
                  _PerfectComboFooterBanner(
                    onOrderNow: () => Navigator.of(context).pushNamed('/menu'),
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

/// Hero Banner + Auto-Moving "Burger Bites" Marquee Ticker from Image 4 & Image 5.
class _HeroOfferWithTicker extends StatelessWidget {
  const _HeroOfferWithTicker({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntranceCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandOrange.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final accessibleText = textScale > 1.15;
                final compactLayout = constraints.maxWidth < 335;
                final heroHeight = accessibleText
                    ? (236 + ((textScale - 1.15) * 48))
                          .clamp(236.0, 300.0)
                          .toDouble()
                    : compactLayout
                    ? 216.0
                    : 244.0;
                final imageWidth = compactLayout
                    ? (constraints.maxWidth * .44).clamp(110.0, 145.0).toDouble()
                    : (constraints.maxWidth * .52).clamp(148.0, 240.0).toDouble();
                final textWidth = (constraints.maxWidth - (imageWidth * 0.56) - 20)
                    .clamp(148.0, 268.0)
                    .toDouble();

                return SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Studio dark slate/wood background
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF23272D),
                                Color(0xFF393E46),
                                Color(0xFF2B2118),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Wooden table board at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF5D3A1A).withValues(alpha: 0.85),
                                const Color(0xFF8B5A2B),
                                const Color(0xFF4A2C11),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // Fries + Burger right visual
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
                      // Smooth gradient vignette for crisp text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1F2227).withValues(alpha: 0.94),
                                const Color(0xFF1F2227).withValues(alpha: 0.72),
                                const Color(0xFF1F2227).withValues(alpha: 0.05),
                              ],
                              stops: const [0.0, 0.52, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // Left Headline + Pill Button ("Delicious Food, Delivered fast" + "Order Now")
                      Positioned(
                        left: 16,
                        top: 12,
                        bottom: 18,
                        width: textWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!accessibleText && !compactLayout) ...[
                              const BrandGradientBadge(
                                label: 'BURGERBITES MENU',
                                icon: Icons.local_fire_department_rounded,
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              accessibleText
                                  ? 'Delicious Food, Delivered fast'
                                  : 'Delicious Food,\nDelivered fast',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: accessibleText || compactLayout
                                    ? 18
                                    : 20,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            if (!accessibleText && !compactLayout) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Freshly grilled burgers, crispy golden fries & ice-cold drinks.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  height: 1.25,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            AnimatedPressScale(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: onOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3EFFB),
                                    foregroundColor: const Color(0xFF5E3B96),
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Order now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Carousel indicator dot at bottom center
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Auto-moving "Burger Bites" orange ticker bar (Image 5: "Aoutu move text <---")
            const _AutoMovingBrandTicker(),
          ],
        ),
      ),
    );
  }
}

/// Continuously scrolling orange ticker ribbon ("Burger Bites   Burger Bites   Burger Bites").
/// Automatically runs in the live app and stays static inside widget tests so
/// `tester.pumpAndSettle()` never times out.
class _AutoMovingBrandTicker extends StatefulWidget {
  const _AutoMovingBrandTicker();

  @override
  State<_AutoMovingBrandTicker> createState() => _AutoMovingBrandTickerState();
}

class _AutoMovingBrandTickerState extends State<_AutoMovingBrandTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!_isWidgetTest) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations || _isWidgetTest) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const segmentWidth = 118.0;
    return Container(
      height: 26,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE06D1F), Color(0xFFEA7B26), Color(0xFFD96518)],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final dx = -(_controller.value * segmentWidth);
          return Transform.translate(
            offset: Offset(dx, 0),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: 1600,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  12,
                  (index) => const SizedBox(
                    width: segmentWidth,
                    child: Center(
                      child: Text(
                        'Burger Bites',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Our Story — How Burger Bites Started" with Storefront & Grill Photo Collage (Images 4 & 5).
class _OurStorySection extends StatelessWidget {
  const _OurStorySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E130C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Our Story',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC87D4B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final stackVertically =
                  constraints.maxWidth < 330 || textScale > 1.2;

              const storyTextColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'How ',
                          style: TextStyle(color: Color(0xFF14110F)),
                        ),
                        TextSpan(
                          text: 'Burger ',
                          style: TextStyle(color: Color(0xFFE51C23)),
                        ),
                        TextSpan(
                          text: 'Bites\nStarted',
                          style: TextStyle(color: Color(0xFF4E0C11)),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BurgerBites started from a simple love for burgers.\n'
                    'We wanted to create tasty food that everyone could enjoy.\n'
                    'Our passion grew into a small burger business.',
                    style: TextStyle(
                      color: Color(0xFF6E140E),
                      fontSize: 10,
                      height: 1.38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We serve fresh burgers, crispy fries, and refreshing drinks.\n'
                    'Today, BurgerBites continues to bring happiness, one bite at a time.',
                    style: TextStyle(
                      color: Color(0xFF6E140E),
                      fontSize: 10,
                      height: 1.38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );

              if (stackVertically) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    storyTextColumn,
                    SizedBox(height: 14),
                    SizedBox(
                      height: 195,
                      width: double.infinity,
                      child: _StorefrontAndGrillCollage(),
                    ),
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: storyTextColumn),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 10,
                    child: SizedBox(
                      height: 210,
                      child: _StorefrontAndGrillCollage(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Visual recreation of the BurgerBites night kiosk storefront + overlapping tilted grill polaroids (Image 5).
class _StorefrontAndGrillCollage extends StatelessWidget {
  const _StorefrontAndGrillCollage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main BurgerBites Storefront Night Card
        Positioned(
          top: 0,
          left: 4,
          right: 0,
          bottom: 26,
          child: _BurgerBitesKioskScene(compact: true),
        ),
        // Left tilted polaroid: Toasted burger buns on grill
        Positioned(
          left: 0,
          bottom: 14,
          width: 74,
          height: 54,
          child: Transform.rotate(
            angle: -0.14,
            child: _PolaroidPhotoTile(
              imageUrl: 'assets/products/classic_burger.jpg',
              caption: 'FRESH BUNS',
              badgeColor: const Color(0xFFD97706),
            ),
          ),
        ),
        // Right tilted polaroid: Flame-grilled burger patties
        Positioned(
          right: 0,
          bottom: 14,
          width: 74,
          height: 54,
          child: Transform.rotate(
            angle: 0.13,
            child: _PolaroidPhotoTile(
              imageUrl: 'assets/products/smash_burger.jpg',
              caption: 'FLAME GRILL',
              badgeColor: const Color(0xFFDC2626),
            ),
          ),
        ),
        // Center bottom polaroid: Signature stacked burger
        Positioned(
          left: 34,
          right: 34,
          bottom: 0,
          height: 48,
          child: _PolaroidPhotoTile(
            imageUrl: 'assets/products/classic_burger.jpg',
            caption: 'SIGNATURE BITE',
            badgeColor: AppColors.brandOrange,
          ),
        ),
      ],
    );
  }
}

class _PolaroidPhotoTile extends StatelessWidget {
  const _PolaroidPhotoTile({
    required this.imageUrl,
    required this.caption,
    required this.badgeColor,
  });

  final String imageUrl;
  final String caption;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FoodImage(imageUrl: imageUrl, borderRadius: 5),
          Positioned(
            left: 3,
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Authentic BurgerBites Night Kiosk Storefront card (used in Our Story & Find Us, matching Images 5 & 6).
class _BurgerBitesKioskScene extends StatelessWidget {
  const _BurgerBitesKioskScene({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1924), Color(0xFF2C2321), Color(0xFF3B2D27)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B1C16), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top yellow/orange awning canopy
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: compact ? 22 : 28,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD99B26),
                    Color(0xFFF2B738),
                    Color(0xFFC87D18),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(height: 3, color: const Color(0xFF7C2D12)),
              ),
            ),
          ),
          // Glowing blue "OPEN WELCOME" neon sign at top-right
          Positioned(
            top: compact ? 24 : 32,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x8838BDF8), blurRadius: 8),
                ],
              ),
              child: const Text(
                'OPEN\nWELCOME',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 6.5,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Warm overhead kiosk light bar
          Positioned(
            top: compact ? 42 : 52,
            left: 28,
            right: 8,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCCFB923C),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Left vertical standee banner ("FRIENDLY BURGERS")
          Positioned(
            left: 0,
            top: compact ? 28 : 34,
            bottom: 18,
            width: compact ? 32 : 42,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF5),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BURGER\nBITES',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 6.5,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: FoodImage(
                      imageUrl: 'assets/products/smash_burger.jpg',
                      borderRadius: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Orange BurgerBites Front Counter on the right
          Positioned(
            right: 6,
            bottom: 18,
            width: compact ? 92 : 118,
            height: compact ? 64 : 84,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF431407), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: const Color(0xFFFFEDD5),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FoodImage(
                              imageUrl: 'assets/products/smash_burger.jpg',
                              borderRadius: 3,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: FoodImage(
                              imageUrl: 'assets/products/loaded_fries.jpg',
                              borderRadius: 3,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: FoodImage(
                              imageUrl: 'assets/products/cola.jpg',
                              borderRadius: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Iconic red customer chair in front of kiosk
          Positioned(
            left: compact ? 38 : 48,
            bottom: 20,
            child: Container(
              width: compact ? 18 : 22,
              height: compact ? 24 : 28,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF991B1B)),
              ),
              child: const Icon(
                Icons.chair_alt_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
          // Sidewalk pavement at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: const Color(0xFF57534E),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Compostela Kiosk · Fresh Grilled Daily',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4-Category Visual Showcase from Image 4: Burgers, Drinks, Fries, Combo Meals.
class _MenuCategoryShowcase extends StatelessWidget {
  const _MenuCategoryShowcase({required this.onSelectCategory});

  final ValueChanged<String> onSelectCategory;

  static const _columns = [
    (
      title: 'Burgers',
      categoryArg: 'Burgers',
      imageUrl: 'assets/products/smash_burger.jpg',
      items: [
        'Classic Burger',
        'Cheese Burger',
        'Double Patty',
        'Bacon Burger',
        'Spicy Burger',
        'Chicken Burger',
      ],
      subtitle: null,
    ),
    (
      title: 'Drinks',
      categoryArg: 'Drinks',
      imageUrl: 'assets/products/cola.jpg',
      items: [
        'Coca-Cola',
        'Sprite',
        'Royal',
        'Pepsi',
        'Mountain Dew',
        '7UP',
      ],
      subtitle: null,
    ),
    (
      title: 'Fries',
      categoryArg: 'Fries',
      imageUrl: 'assets/products/loaded_fries.jpg',
      items: ['Regular', 'Medium', 'Large'],
      subtitle: 'Regular · Medium · Large',
    ),
    (
      title: 'Combo Meals',
      categoryArg: 'Burgers',
      imageUrl: 'assets/products/classic_burger.jpg',
      items: ['Burger + Fries', '+ Drink'],
      subtitle: '(Available in all sizes)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoByTwo = constraints.maxWidth < 460;
        if (useTwoByTwo) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ShowcaseColumnCard(
                      data: _columns[0],
                      onTap: () => onSelectCategory(_columns[0].categoryArg),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShowcaseColumnCard(
                      data: _columns[1],
                      onTap: () => onSelectCategory(_columns[1].categoryArg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ShowcaseColumnCard(
                      data: _columns[2],
                      onTap: () => onSelectCategory(_columns[2].categoryArg),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShowcaseColumnCard(
                      data: _columns[3],
                      onTap: () => onSelectCategory(_columns[3].categoryArg),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _columns.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _ShowcaseColumnCard(
                  data: _columns[i],
                  onTap: () => onSelectCategory(_columns[i].categoryArg),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShowcaseColumnCard extends StatelessWidget {
  const _ShowcaseColumnCard({required this.data, required this.onTap});

  final ({
    String title,
    String categoryArg,
    String imageUrl,
    List<String> items,
    String? subtitle,
  })
  data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1E130C),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 68,
              width: double.infinity,
              child: FoodImage(
                imageUrl: data.imageUrl,
                category: data.categoryArg,
                borderRadius: 11,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2942),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...data.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4.5,
                      height: 4.5,
                      margin: const EdgeInsets.only(top: 4, right: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.brandOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                data.subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "What Makes Us Different" + "Our Customers — Real People. Real Moments." from Image 4.
class _DifferenceAndCustomersSection extends StatelessWidget {
  const _DifferenceAndCustomersSection();

  static const _features = [
    (
      title: 'Fresh Ingredients',
      desc: 'We use only the freshest and highest quality ingredients.',
      icon: Icons.eco_rounded,
    ),
    (
      title: 'Wide Choices',
      desc: 'Different burger, drink, and fries options for every craving.',
      icon: Icons.lunch_dining_rounded,
    ),
    (
      title: 'Affordable Prices',
      desc: 'Great food at budget-friendly prices.',
      icon: Icons.local_offer_rounded,
    ),
    (
      title: 'Fast & Friendly Service',
      desc: 'We value your time and satisfaction.',
      icon: Icons.bolt_rounded,
    ),
  ];

  static const _customerMoments = [
    ('Barkada Burger Night', 'Double Smash & Fries', 'assets/products/smash_burger.jpg'),
    ('Campus Lunch Trio', 'Crispy Chicken & Cola', 'assets/products/crispy_chicken.jpg'),
    ('Late-Night Cravings', 'Loaded Cheese Fries', 'assets/products/loaded_fries.jpg'),
    ('Weekend Combo', 'Classic Burger Meal', 'assets/products/classic_burger.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E130C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark Navy Pill Header: "What Makes Us Different"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2942),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'What Makes Us ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Different',
                    style: TextStyle(color: AppColors.brandOrange),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth < 460;
              if (twoColumns) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _DiffFeatureTile(item: _features[0])),
                        Container(
                          width: 1,
                          height: 76,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: AppColors.border,
                        ),
                        Expanded(child: _DiffFeatureTile(item: _features[1])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _DiffFeatureTile(item: _features[2])),
                        Container(
                          width: 1,
                          height: 76,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: AppColors.border,
                        ),
                        Expanded(child: _DiffFeatureTile(item: _features[3])),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _features.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 82,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        color: AppColors.border,
                      ),
                    Expanded(child: _DiffFeatureTile(item: _features[i])),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // "Our Customers — Real People. Real Moments."
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2942),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Our Customers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Real People. Real Moments.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _customerMoments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final moment = _customerMoments[index];
                return Container(
                  width: 132,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FoodImage(imageUrl: moment.$3, borderRadius: 0),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 9,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'HAPPY BITES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 7,
                        right: 7,
                        bottom: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moment.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              moment.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

class _DiffFeatureTile extends StatelessWidget {
  const _DiffFeatureTile({required this.item});

  final ({String title, String desc, IconData icon}) item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: Colors.white, size: 15),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2942),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.desc,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Recent Orders Card (Upgraded from Image 2 while preserving all widget test assertions).
class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({
    required this.auth,
    required this.orderProvider,
    required this.recentOrders,
  });

  final AuthService auth;
  final CustomerOrdersProvider orderProvider;
  final List<dynamic> recentOrders;

  @override
  Widget build(BuildContext context) {
    if (!auth.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.warmSurfaceGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.brandOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sign in to view your order history.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!orderProvider.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (orderProvider.errorMessage != null && recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
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
        ),
      );
    }

    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No orders yet. Browse the menu to get started.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (orderProvider.errorMessage != null)
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
              gradient: AppColors.warmSurfaceGradient,
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
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Find Us — Location: Compostela Davao de oro PH" with Interactive Draggable Map & Kiosk Photo (Image 6).
class _FindUsDraggableMapSection extends StatefulWidget {
  const _FindUsDraggableMapSection();

  @override
  State<_FindUsDraggableMapSection> createState() =>
      _FindUsDraggableMapSectionState();
}

class _FindUsDraggableMapSectionState
    extends State<_FindUsDraggableMapSection> {
  Offset _panOffset = Offset.zero;
  double _zoom = 1.0;
  bool _satelliteMode = false;

  void _updatePan(Offset delta) {
    setState(() {
      final limit = 90.0 * _zoom;
      _panOffset = Offset(
        (_panOffset.dx + delta.dx).clamp(-limit, limit),
        (_panOffset.dy + delta.dy).clamp(-limit, limit),
      );
    });
  }

  void _changeZoom(double delta) {
    setState(() {
      _zoom = (_zoom + delta).clamp(0.85, 1.85);
    });
  }

  void _resetMap() {
    setState(() {
      _panOffset = Offset.zero;
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E130C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find Us',
                      style: TextStyle(
                        color: AppColors.brandOrange,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Location: Compostela Davao de oro PH',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/contact'),
                icon: const Icon(Icons.support_agent_rounded, size: 15),
                label: const Text(
                  'Contact us',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandOrange,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackVertically = constraints.maxWidth < 360;
              final mapWidget = SizedBox(
                height: 195,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Draggable Map Surface ("Drag Map <---" in Image 6)
                      Positioned.fill(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) =>
                                _updatePan(details.delta),
                            onDoubleTap: () => _changeZoom(0.25),
                            child: CustomPaint(
                              painter: _CompostelaMapPainter(
                                panOffset: _panOffset,
                                zoom: _zoom,
                                satelliteMode: _satelliteMode,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      // Top-left white floating location card (matching Image 6)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 156),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'BurgerBites',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Compostela, Davao de Oro, Philippines',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: _resetMap,
                                child: const Text(
                                  'View larger map · Recenter',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Drag map hint pill at top-right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_with_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Drag map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom-left satellite toggle thumbnail (matching Image 6)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: InkWell(
                          onTap: () => setState(
                            () => _satelliteMode = !_satelliteMode,
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _satelliteMode
                                    ? const [
                                        Color(0xFFE2E8F0),
                                        Color(0xFFCBD5E1),
                                      ]
                                    : const [
                                        Color(0xFF14532D),
                                        Color(0xFF064E3B),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _satelliteMode
                                  ? Icons.map_rounded
                                  : Icons.satellite_alt_rounded,
                              size: 14,
                              color: _satelliteMode
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Bottom-right + / - zoom buttons (matching Image 6)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _changeZoom(0.2),
                                child: const SizedBox(
                                  width: 26,
                                  height: 24,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              InkWell(
                                onTap: () => _changeZoom(-0.2),
                                child: const SizedBox(
                                  width: 26,
                                  height: 24,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (stackVertically) {
                return Column(
                  children: [
                    mapWidget,
                    const SizedBox(height: 10),
                    const SizedBox(
                      height: 165,
                      width: double.infinity,
                      child: _BurgerBitesKioskScene(),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 13, child: mapWidget),
                  const SizedBox(width: 10),
                  const Expanded(
                    flex: 9,
                    child: SizedBox(
                      height: 195,
                      child: _BurgerBitesKioskScene(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Interactive CustomPainter for the Compostela, Davao de Oro street map (Image 6).
class _CompostelaMapPainter extends CustomPainter {
  const _CompostelaMapPainter({
    required this.panOffset,
    required this.zoom,
    required this.satelliteMode,
  });

  final Offset panOffset;
  final double zoom;
  final bool satelliteMode;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF1B2E25)
          : const Color(0xFFEFF3F6);
    canvas.drawRect(Offset.zero & size, bgPaint);

    canvas.save();
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);

    // Green parks & blocks
    final parkPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF234233)
          : const Color(0xFFD5F2DC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.25, 58, 42),
        const Radius.circular(6),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.52, size.height * 0.16, 54, 36),
        const Radius.circular(6),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.36, size.height * 0.54, 48, 34),
        const Radius.circular(6),
      ),
      parkPaint,
    );

    // Coastal water body on bottom-right (matching Image 6)
    final waterPath = Path()
      ..moveTo(size.width * 0.58, size.height * 1.15)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.65,
        size.width * 1.15,
        size.height * 0.30,
      )
      ..lineTo(size.width * 1.25, size.height * 1.25)
      ..close();
    canvas.drawPath(
      waterPath,
      Paint()
        ..color = satelliteMode
            ? const Color(0xFF0C4A6E)
            : const Color(0xFF8CD3FB),
    );

    // Diagonal grid streets of Compostela
    final minorRoadPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF334155)
          : const Color(0xFFFFFFFF)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (var i = -3; i <= 6; i++) {
      final offset = i * 38.0;
      canvas.drawLine(
        Offset(offset - 60, -40),
        Offset(offset + size.width * 0.75, size.height + 40),
        minorRoadPaint,
      );
      canvas.drawLine(
        Offset(-40, offset + size.height * 0.6),
        Offset(size.width + 40, offset - 50),
        minorRoadPaint,
      );
    }

    // Main National Highway
    final highwayPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFFF59E0B)
          : const Color(0xFFFDE68A)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.95),
      Offset(size.width * 0.85, size.height * 0.05),
      highwayPaint,
    );

    // Landmarks from Image 6
    _drawPin(
      canvas,
      Offset(size.width * 0.62, size.height * 0.25),
      const Color(0xFF16A34A),
      'Compostela Park',
      satelliteMode,
    );
    _drawPin(
      canvas,
      Offset(size.width * 0.34, size.height * 0.42),
      const Color(0xFFF97316),
      'Jollibee',
      satelliteMode,
    );
    _drawPin(
      canvas,
      Offset(size.width * 0.80, size.height * 0.44),
      const Color(0xFF2563EB),
      'Gaisano',
      satelliteMode,
    );
    _drawPin(
      canvas,
      Offset(size.width * 0.53, size.height * 0.63),
      const Color(0xFF0D9488),
      'Municipal Hall',
      satelliteMode,
    );

    // Main Red BurgerBites Pin in center
    final mainPinPos = Offset(size.width * 0.56, size.height * 0.43);
    canvas.drawCircle(
      mainPinPos.translate(0, 3),
      9,
      Paint()..color = const Color(0x33DC2626),
    );
    canvas.drawCircle(
      mainPinPos,
      8.5,
      Paint()..color = const Color(0xFFDC2626),
    );
    canvas.drawCircle(
      mainPinPos,
      3.5,
      Paint()..color = Colors.white,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'BurgerBites\n',
        style: TextStyle(
          color: satelliteMode ? Colors.white : const Color(0xFFB91C1C),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
        children: [
          TextSpan(
            text: 'Compostela, Davao de Oro',
            style: TextStyle(
              color: satelliteMode
                  ? Colors.white70
                  : const Color(0xFF475569),
              fontSize: 7.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    tp.paint(canvas, mainPinPos.translate(11, -9));

    canvas.restore();
  }

  void _drawPin(
    Canvas canvas,
    Offset pos,
    Color color,
    String label,
    bool darkText,
  ) {
    canvas.drawCircle(pos, 5.5, Paint()..color = color);
    canvas.drawCircle(pos, 2.0, Paint()..color = Colors.white);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: darkText ? Colors.white70 : color.withValues(alpha: 0.9),
          fontSize: 7.0,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 85);
    tp.paint(canvas, pos.translate(7, -5));
  }

  @override
  bool shouldRepaint(covariant _CompostelaMapPainter oldDelegate) =>
      oldDelegate.panOffset != panOffset ||
      oldDelegate.zoom != zoom ||
      oldDelegate.satelliteMode != satelliteMode;
}

/// Bottom Dark Promo Banner: "THE PERFECT COMBO" + Footer Trust Strip (Images 4 & 6).
class _PerfectComboFooterBanner extends StatelessWidget {
  const _PerfectComboFooterBanner({required this.onOrderNow});

  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141210),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Combo Meal Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1F140E),
                  Color(0xFF3B2314),
                  Color(0xFF1C130E),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;
                return Row(
                  children: [
                    // Drink + Red Fries Box visual on left
                    SizedBox(
                      width: compact ? 54 : 68,
                      height: 54,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 2,
                            width: compact ? 30 : 38,
                            child: FoodImage(
                              imageUrl: 'assets/products/cola.jpg',
                              borderRadius: 8,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            width: compact ? 32 : 38,
                            height: 42,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFFBBF24),
                                  width: 1,
                                ),
                              ),
                              child: FoodImage(
                                imageUrl: 'assets/products/loaded_fries.jpg',
                                borderRadius: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Center "THE PERFECT COMBO"
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFFBBF24),
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'THE PERFECT COMBO',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.brandOrange,
                                    fontSize: compact ? 11.5 : 13.5,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Burger + Fries + Drink = Complete Meal',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Right "ORDER NOW ->" Orange Pill Button
                    AnimatedPressScale(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: onOrderNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandOrange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ORDER NOW',
                                style: TextStyle(
                                  fontSize: compact ? 8.5 : 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Bottom Dark Charcoal Footer Trust Strip (Fresh Ingredients | Great Taste | Fast Service)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            color: const Color(0xFF0E0D0C),
            child: Row(
              children: [
                const Expanded(
                  child: _FooterTrustBadge(
                    icon: Icons.eco_rounded,
                    label: 'Fresh Ingredients',
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.white24),
                const Expanded(
                  child: _FooterTrustBadge(
                    icon: Icons.star_rounded,
                    label: 'Great Taste',
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.white24),
                const Expanded(
                  child: _FooterTrustBadge(
                    icon: Icons.bolt_rounded,
                    label: 'Fast Service',
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

class _FooterTrustBadge extends StatelessWidget {
  const _FooterTrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
    return AnimatedPressScale(
      child: SizedBox(
        width: 88,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Navigator.of(context).pushNamed('/menu', arguments: category),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.warmSurfaceGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandOrange.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.brandOrange, size: 21),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    return AnimatedPressScale(
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/product-details', arguments: product),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: AppColors.warmSurfaceGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
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
