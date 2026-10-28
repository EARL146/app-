import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_translations.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/customer_account_prompt.dart';
import '../../widgets/food_image.dart';
import '../../widgets/product_image_carousel.dart';
import '../../widgets/discount_sale_badge.dart';
import '../../widgets/discount_sale_section.dart';
import '../../widgets/find_us_google_map.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.openMenuInitially = false,
    this.initialMenuCategory = 'All',
    this.initialTabIndex,
  });

  final bool openMenuInitially;
  final String initialMenuCategory;
  final int? initialTabIndex;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  Timer? _catalogRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex =
        widget.initialTabIndex ?? (widget.openMenuInitially ? 1 : 0);
    // Customer sessions can stay open while an admin updates the shared
    // catalog from another device or browser. Keep the visible catalog in
    // sync with the database without requiring a sign-out or app restart.
    _catalogRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshCatalog(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCatalog());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshCatalog();
  }

  void _refreshCatalog() {
    if (!mounted) return;
    final catalog = context.read<CatalogProvider>();
    if (!catalog.isLoading) {
      unawaited(catalog.loadProducts(force: true));
    }
  }

  @override
  void dispose() {
    _catalogRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<Widget> get _screens => [
    const _HomeTab(),
    MenuScreenButton(initialCategory: widget.initialMenuCategory),
    const _OrdersTab(),
    const ProfileScreenButton(),
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
          border: Border(top: BorderSide(color: AppColors.border)),
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
          onTap: (index) {
            ScaffoldMessenger.of(context).clearSnackBars();
            setState(() => _selectedIndex = index);
            if (index <= 1) _refreshCatalog();
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home'.tr,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu'.tr,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Orders'.tr,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile'.tr,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showHomeNavigationMenu(BuildContext context) async {
  const items = <({IconData icon, String label, String route})>[
    (icon: Icons.home_outlined, label: 'Home', route: ''),
    (icon: Icons.menu_rounded, label: 'Menu', route: '/menu'),
    (icon: Icons.mail_outline_rounded, label: 'Contact', route: '/contact'),
    (icon: Icons.info_outline_rounded, label: 'About', route: '/about'),
    (icon: Icons.palette_outlined, label: 'Color themes', route: '/themes'),
    (
      icon: Icons.translate_rounded,
      label: 'Change language',
      route: '/language',
    ),
    (
      icon: Icons.calendar_month_outlined,
      label: 'Calendar',
      route: '/calendar',
    ),
    (icon: Icons.settings_outlined, label: 'Settings', route: '/settings'),
  ];

  final destination = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close navigation menu',
    barrierColor: Colors.black.withValues(alpha: 0.48),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final screen = MediaQuery.sizeOf(dialogContext);
      final menuWidth = math.min(340.0, screen.width * 0.88);
      return SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: menuWidth,
            height: double.infinity,
            child: Material(
              color: AppColors.surfaceElevated,
              elevation: 20,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(26),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
                    child: Row(
                      children: [
                        const BrandLogo(width: 58, height: 58),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BurgerBites',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Explore your app'.tr,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close menu'.tr,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HomeNavigationSectionLabel('DISCOVER'),
                          for (var index = 0; index < 4; index++) ...[
                            if (index > 0) const SizedBox(height: 4),
                            _HomeNavigationMenuButton(
                              icon: items[index].icon,
                              label: items[index].label,
                              selected: index == 0,
                              onPressed: () =>
                                  Navigator.of(dialogContext)
                                      .pop(items[index].route),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const _HomeNavigationSectionLabel('PREFERENCES'),
                          for (
                            var index = 4;
                            index < items.length;
                            index++
                          ) ...[
                            if (index > 4) const SizedBox(height: 4),
                            _HomeNavigationMenuButton(
                              icon: items[index].icon,
                              label: items[index].label,
                              onPressed: () =>
                                  Navigator.of(dialogContext)
                                      .pop(items[index].route),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: AppColors.brandOrange,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fresh bites, happy moments'.tr,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(-0.24, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );

  if (!context.mounted || destination == null || destination.isEmpty) return;
  Navigator.of(context).pushNamed(destination);
}

class _HomeNavigationMenuButton extends StatelessWidget {
  const _HomeNavigationMenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tileColor = selected
        ? AppColors.brandOrange.withValues(alpha: 0.1)
        : Colors.transparent;
    final iconColor = selected
        ? AppColors.brandOrange
        : AppColors.textSecondary;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.brandOrangeDark
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.65),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavigationSectionLabel extends StatelessWidget {
  const _HomeNavigationSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Text(
        label.tr,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
            .map((product) {
              final cat = product.category?.trim();
              if (cat == 'Sides' && product.name.toLowerCase().contains('fries')) {
                return 'Fries';
              }
              return cat;
            })
            .whereType<String>()
            .where((category) => category.isNotEmpty)
            .where((category) => category.toLowerCase() != 'discount sale')
            .toSet()
            .toList()
          ..sort();
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
                          tooltip: 'Open menu'.tr,
                          onPressed: () => _showHomeNavigationMenu(context),
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
                        tooltip: 'Order updates'.tr,
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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: AppColors.brandOrange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Search juicy burgers, crispy fries, drinks...'
                                        .tr,
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
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.brandOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'DELIVER TO:'.tr,
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
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change'.tr,
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
                    onSelectCategory: (category) =>
                        Navigator.of(context)
                            .pushNamed('/menu', arguments: category),
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
                      catalog.isLoading ? 'Loading menu categories…' : 'Menu categories will appear when products are available.',
                      style: TextStyle(
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
                  const SizedBox(height: 12),
                  DiscountSaleSection(
                    products: products,
                    isLoading: catalog.isLoading,
                    onSeeAll: () =>
                        Navigator.of(context)
                            .pushNamed('/menu', arguments: 'Discount Sale'),
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
                            catalog.errorMessage ?? 'Our menu is being updated. Please check again soon.',
                            style: TextStyle(
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

                  // Find Us — Location: Compostela Davao de oro PH
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
class _HeroOfferWithTicker extends StatefulWidget {
  const _HeroOfferWithTicker({required this.onOrder});

  final VoidCallback onOrder;

  @override
  State<_HeroOfferWithTicker> createState() => _HeroOfferWithTickerState();
}

class _HeroOfferWithTickerState extends State<_HeroOfferWithTicker> {
  static const _heroImages = [
    'assets/products/hero_burger_lifestyle.webp',
    'assets/products/hero_drinks_showcase.jpg',
    'assets/products/hero_loaded_fries.jpg',
  ];
  static const _heroLabels = ['Burger', 'Drinks', 'Loaded fries'];
  static const _indicatorLabels = ['burger', 'drinks', 'fries'];

  Timer? _autoAdvanceTimer;
  int _activeSlide = 0;
  bool _reduceMotion = false;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_isWidgetTest) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
    } else {
      _autoAdvanceTimer ??= Timer.periodic(
        const Duration(seconds: 4),
        (_) => _advanceSlide(),
      );
    }
  }

  void _advanceSlide() {
    if (!mounted) return;
    setState(() => _activeSlide = (_activeSlide + 1) % _heroImages.length);
  }

  void _selectSlide(int index) {
    setState(() => _activeSlide = index);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

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
                    ? (260 + ((textScale - 1.15) * 48))
                          .clamp(260.0, 320.0)
                          .toDouble()
                    : compactLayout
                    ? 240.0
                    : 282.0;
                final textWidth = (constraints.maxWidth - 32)
                    .clamp(128.0, 310.0)
                    .toDouble();

                return SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // One full-bleed photo per slide; the three supplied
                      // photos still rotate through this single image area.
                      Positioned.fill(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < 0) {
                              _selectSlide(
                                (_activeSlide + 1) % _heroImages.length,
                              );
                            } else if (velocity > 0) {
                              _selectSlide(
                                (_activeSlide - 1 + _heroImages.length) %
                                    _heroImages.length,
                              );
                            }
                          },
                          child: AnimatedSwitcher(
                            duration: _reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 700),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0.12, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: Semantics(
                              key: ValueKey(_heroImages[_activeSlide]),
                              image: true,
                              label: _heroLabels[_activeSlide],
                              child: FoodImage(
                                imageUrl: _heroImages[_activeSlide],
                                borderRadius: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xD91A1715),
                                Color(0xA61A1715),
                                Color(0x001A1715),
                              ],
                              stops: [0, 0.55, 1],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.48),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
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
                              BrandGradientBadge(
                                label: 'BURGERBITES MENU'.tr,
                                icon: Icons.local_fire_department_rounded,
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              accessibleText
                                  ? 'Delicious food,\ndelivered fast'.tr
                                        .replaceAll('\n', ' ')
                                  : 'Delicious food,\ndelivered fast'.tr,
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
                              Text(
                                'Freshly grilled burgers, crispy golden fries & ice-cold drinks.'
                                    .tr,
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
                                  onPressed: widget.onOrder,
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
                                  child: Text(
                                    'Order now'.tr,
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
                      // Tappable carousel indicators track the visible food image.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_heroImages.length, (index) {
                            final isActive = index == _activeSlide;
                            return Semantics(
                              button: true,
                              selected: isActive,
                              label:
                                  'Show ${_indicatorLabels[index]} hero image',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: InkWell(
                                  onTap: () => _selectSlide(index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AnimatedContainer(
                                      duration: _reduceMotion
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      width: isActive ? 10 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: isActive ? 1 : 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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
      duration: const Duration(seconds: 3),
      animationBehavior: AnimationBehavior.preserve,
    );
    if (!_isWidgetTest) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isWidgetTest) {
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
                final collageHeight = (constraints.maxWidth / .85)
                    .clamp(220.0, 360.0)
                    .toDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    storyTextColumn,
                    const SizedBox(height: 14),
                    SizedBox(
                      height: collageHeight,
                      width: double.infinity,
                      child: const _StorefrontAndGrillCollage(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.white,
        child: Image.asset(
          'assets/products/our_story_collage.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          semanticLabel: 'BurgerBites storefront with oven, flame grill, and burger photos',
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.storefront_rounded, color: AppColors.brandOrange),
          ),
        ),
      ),
    );
  }
}

/// Illustrated BurgerBites Night Kiosk Storefront used in the Find Us section.
class _BurgerBitesKioskScene extends StatelessWidget {
  const _BurgerBitesKioskScene();

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
            height: 28,
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
            top: 32,
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
            top: 52,
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
            top: 34,
            bottom: 18,
            width: 42,
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
            width: 118,
            height: 84,
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
            left: 48,
            bottom: 20,
            child: Container(
              width: 22,
              height: 28,
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
      items: ['Coca-Cola', 'Sprite', 'Royal', 'Pepsi', 'Mountain Dew', '7UP'],
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
      imageUrl: 'assets/products/smash_burger.jpg',
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
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
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
                  borderRadius: 12,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.title.tr,
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
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        margin: const EdgeInsets.only(top: 4, right: 5),
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.tr,
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
              const Spacer(),
              Text(
                data.subtitle ?? '${data.items.length} options',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
    (
      'Barkada Burger Night',
      'Double Smash & Fries',
      'assets/products/smash_burger.jpg',
    ),
    (
      'Campus Lunch Trio',
      'Crispy Chicken & Cola',
      'assets/products/crispy_chicken.jpg',
    ),
    (
      'Late-Night Cravings',
      'Loaded Cheese Fries',
      'assets/products/loaded_fries.jpg',
    ),
    (
      'Weekend Combo',
      'Classic Burger Meal',
      'assets/products/smash_burger.jpg',
    ),
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
            child: Text.rich(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
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
          decoration: BoxDecoration(
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
          style: TextStyle(
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

class _FindUsDraggableMapSection extends StatelessWidget {
  const _FindUsDraggableMapSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Find Us',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.brandOrange,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFFB91C1C), size: 15),
            SizedBox(width: 3),
            Flexible(
              child: Text(
                'Location: Poblacion, Compostela, Davao de Oro PH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically = constraints.maxWidth < 580;
            final mapHeight = stackVertically ? 275.0 : 320.0;
            final storefrontHeight = stackVertically
                ? (constraints.maxWidth * 0.84).clamp(230.0, 320.0).toDouble()
                : mapHeight;
            final mapWidget = FindUsGoogleMap(height: mapHeight);
            final storefront = _FindUsStorefrontPhoto(height: storefrontHeight);

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [mapWidget, const SizedBox(height: 12), storefront],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: mapWidget),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: storefront),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FindUsStorefrontPhoto extends StatelessWidget {
  const _FindUsStorefrontPhoto({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF171717), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/products/find_us_storefront.png',
            fit: BoxFit.cover,
            semanticLabel: 'BurgerBites storefront in Compostela',
            errorBuilder: (context, error, stackTrace) =>
                const _BurgerBitesKioskScene(),
          ),
        ),
      ),
    );
  }
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
                              const Icon(Icons.arrow_forward_rounded, size: 12),
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
            title.tr,
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
            action.tr,
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
                label.tr,
                style: TextStyle(
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
    final originalPrice = product.discountTargetBasePrice;
    final salePricePreview = product.previewDiscountPrice(originalPrice);
    final displayPrice =
        salePricePreview ?? product.applyDiscount(originalPrice);

    return AnimatedPressScale(
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .pushNamed('/product-details', arguments: product),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductImageCarousel(
                          images: product.galleryImages,
                          category: product.category,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 7,
                      bottom: 7,
                      child: DiscountSaleBadge(product: product),
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
                    child: Row(
                      children: [
                        Text(
                          '₱${displayPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.brandOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        if (salePricePreview != null) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₱${originalPrice.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${product.name} added to cart',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
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
  const MenuScreenButton({super.key, this.initialCategory = 'All'});

  final String initialCategory;

  @override
  Widget build(BuildContext context) =>
      MenuScreen(initialCategory: initialCategory);
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
