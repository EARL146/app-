import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../navigation/app_routes.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_orders_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminOrdersProvider>().loadOrders();
      context.read<AdminDashboardProvider>().load();
    });
  }

  void _onNavItemTapped(int index) {
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.adminOrders);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.adminProducts);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.adminCustomers);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.adminMore);
        break;
      default:
        setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Consumer2<AdminOrdersProvider, AdminDashboardProvider>(
          builder: (context, orderProvider, dashboardProvider, _) {
            final recentOrders = orderProvider.orders.take(3).toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: IconButton(
                              tooltip: 'Open admin tools',
                              onPressed: () =>
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.adminMore),
                              icon: const Icon(Icons.menu_rounded, size: 19),
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Burger',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bites',
                                    style: TextStyle(
                                      color: AppColors.brandOrange,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 17),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open pending orders',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.adminOrders,
                            ),
                            icon: Badge(
                              isLabelVisible:
                                  dashboardProvider.pendingOrders > 0,
                              label: Text(
                                dashboardProvider.pendingOrders > 99
                                    ? '99+'
                                    : dashboardProvider.pendingOrders
                                          .toString(),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Admin profile',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.adminProfile,
                            ),
                            icon: const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.brandOrange,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dashboardProvider.errorMessage != null)
                        TextButton.icon(
                          onPressed: dashboardProvider.load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(dashboardProvider.errorMessage!),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4D7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Good morning, Admin 👋',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Here’s your restaurant overview for today.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Live account totals',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.fastfood_rounded,
                              color: AppColors.brandOrange,
                              size: 39,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisExtent: 104,
                        children: [
                          _MetricCard(
                            label: 'Total orders',
                            value: '${dashboardProvider.totalOrders}',
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFFFF7C38),
                            trend: 'All time',
                          ),
                          _MetricCard(
                            label: 'Revenue',
                            value:
                                '₱${dashboardProvider.deliveredRevenue.toStringAsFixed(0)}',
                            icon: Icons.payments_outlined,
                            color: const Color(0xFF1EAD8B),
                            trend: 'Delivered',
                          ),
                          _MetricCard(
                            label: 'Customers',
                            value: '${dashboardProvider.totalCustomers}',
                            icon: Icons.people_outline_rounded,
                            color: const Color(0xFF4387F5),
                            trend: 'Registered',
                          ),
                          _MetricCard(
                            label: 'Products',
                            value: '${dashboardProvider.totalProducts}',
                            icon: Icons.lunch_dining_rounded,
                            color: const Color(0xFF8963E8),
                            trend: 'Catalog',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'Sales overview',
                        trailing: 'Last 7 days',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '₱${dashboardProvider.deliveredRevenue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Spacer(),
                                const Text(
                                  'Order value',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            SizedBox(
                              height: 105,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _RevenueChartPainter(
                                  dashboardProvider.dailyRevenue,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: dashboardProvider.dailyRevenueLabels
                                  .map(
                                    (label) => Text(
                                      label,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 8,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionHeader(title: 'Quick actions', trailing: ''),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_box_outlined,
                              label: 'Add product',
                              color: AppColors.brandOrange,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.adminAddProduct,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.receipt_long_outlined,
                              label: 'View orders',
                              color: AppColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.adminOrders,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.people_outline_rounded,
                              label: 'Customers',
                              color: AppColors.success,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.adminCustomers,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _SectionHeader(
                        title: 'Recent orders',
                        trailing: 'See all',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.adminOrders),
                      ),
                      const SizedBox(height: 8),
                      if (recentOrders.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No orders yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      else
                        ...recentOrders.map(
                          (order) => _LatestOrderRow(order: order),
                        ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.brandOrange,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                dashboardProvider.errorMessage ?? 'Order, product and customer totals plus the seven-day order value chart are loaded from SQL.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (dashboardProvider.errorMessage != null)
                              IconButton(
                                tooltip: 'Retry dashboard load',
                                visualDensity: VisualDensity.compact,
                                onPressed: dashboardProvider.isLoading
                                    ? null
                                    : dashboardProvider.load,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Text(
              trend,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.onTap,
  });
  final String title;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ),
      if (trailing.isNotEmpty)
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandOrange,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            trailing,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _LatestOrderRow extends StatelessWidget {
  const _LatestOrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.processing ||
      OrderStatus.ready ||
      OrderStatus.shipped => AppColors.info,
      OrderStatus.canceled => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.lunch_dining_rounded,
              color: AppColors.brandOrange,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.items.isEmpty ? 'Order' : order.items.first.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱${order.total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> values;

  _RevenueChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final pathPaint = Paint()
      ..color = AppColors.brandOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.brandOrange.withValues(alpha: .2),
          AppColors.brandOrange.withValues(alpha: .01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final chartValues = values.length == 7 ? values : List<double>.filled(7, 0);
    final maximum = chartValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final points = List<Offset>.generate(7, (index) {
      final x = size.width * (index / 6);
      final normalized = maximum <= 0 ? 0 : chartValues[index] / maximum;
      final y = size.height * (.88 - normalized * .76);
      return Offset(x, y);
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, pathPaint);
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        3,
        Paint()
          ..color = AppColors.brandOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
