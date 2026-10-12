import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../navigation/app_routes.dart';
import '../../providers/admin_customers_provider.dart';
import '../../providers/admin_orders_provider.dart';
import '../../providers/admin_products_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Home - stay on home
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.adminOrders);
        setState(() => _selectedIndex = 0);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.adminProducts);
        setState(() => _selectedIndex = 0);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.adminCustomers);
        setState(() => _selectedIndex = 0);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.adminMore);
        setState(() => _selectedIndex = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Consumer3<AdminOrdersProvider, AdminProductsProvider,
            AdminCustomersProvider>(
          builder: (context, orderProvider, productProvider, customerProvider,
              _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'BurgerBites',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(Icons.notifications_none_rounded, size: 28),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.brandOrange,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Administrator',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _MetricCard(
                        label: 'Total Orders',
                        value: orderProvider.totalOrders.toString(),
                        accent: AppColors.brandOrange,
                      ),
                      _MetricCard(
                        label: 'Total Revenue',
                        value:
                            '₱${orderProvider.totalRevenue.toStringAsFixed(0)}',
                        accent: AppColors.info,
                      ),
                      _MetricCard(
                        label: 'Total Customers',
                        value: customerProvider.totalCustomers.toString(),
                        accent: AppColors.success,
                      ),
                      _MetricCard(
                        label: 'Total Products',
                        value: productProvider.totalProducts.toString(),
                        accent: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Latest Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: orderProvider.orders.isEmpty
                        ? const Center(
                            child: Text('No orders yet'),
                          )
                        : ListView.builder(
                            itemCount: orderProvider.orders.take(3).length,
                            itemBuilder: (context, index) {
                              final order =
                                  orderProvider.orders.toList()[index];
                              String statusLabel = _statusToLabel(order.status);
                              return _LatestOrderRow(
                                title: order.items.isNotEmpty
                                    ? order.items.first.productName
                                    : 'Order',
                                orderId: order.id,
                                status: statusLabel,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.textSecondary,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.trending_up, color: accent, size: 18),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestOrderRow extends StatelessWidget {
  const _LatestOrderRow({required this.title, required this.orderId, required this.status});

  final String title;
  final String orderId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_outlined, color: AppColors.brandOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(orderId, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'Paid'
                  ? AppColors.success.withValues(alpha: 0.12)
                  : status == 'Processing'
                  ? AppColors.info.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: status == 'Paid'
                    ? AppColors.success
                    : status == 'Processing'
                    ? AppColors.info
                    : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
