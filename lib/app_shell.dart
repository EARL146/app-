import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/favorites_provider.dart';
import 'providers/admin_customers_provider.dart';
import 'providers/admin_orders_provider.dart';
import 'providers/admin_products_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/customer_orders_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/admin_system_status_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (context) =>
              FavoritesProvider(context.read<AuthService>(), ApiService()),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (context) =>
              CartProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider()..loadProducts(),
        ),
        ChangeNotifierProvider<CustomerOrdersProvider>(
          create: (context) =>
              CustomerOrdersProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<AdminProductsProvider>(
          create: (_) => AdminProductsProvider(),
        ),
        ChangeNotifierProvider<AdminDashboardProvider>(
          create: (_) => AdminDashboardProvider(),
        ),
        ChangeNotifierProvider<AdminSystemStatusProvider>(
          create: (_) => AdminSystemStatusProvider(),
        ),
        ChangeNotifierProvider<AdminOrdersProvider>(
          create: (_) => AdminOrdersProvider(),
        ),
        ChangeNotifierProvider<AdminCustomersProvider>(
          create: (_) => AdminCustomersProvider(),
        ),
      ],
      child: const _AppShellContent(),
    );
  }
}

class _AppShellContent extends StatelessWidget {
  const _AppShellContent();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BurgerBites',
      theme: AppTheme.lightTheme(),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
