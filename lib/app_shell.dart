import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'providers/app_preferences_provider.dart';
import 'providers/calendar_reminders_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'widgets/app_scaffold_messenger.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<CalendarRemindersProvider>(
          lazy: false,
          create: (context) => CalendarRemindersProvider(
            context.read<AuthService>(),
            ApiService(),
          ),
        ),
        ChangeNotifierProvider<AppPreferencesProvider>(
          create: (context) => AppPreferencesProvider(
            authService: context.read<AuthService>(),
            apiService: ApiService(),
            storageService: StorageService(),
          ),
        ),
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
    final preferences = context.watch<AppPreferencesProvider>();
    return MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'BurgerBites',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: preferences.materialThemeMode,
      locale: preferences.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fil'),
        Locale('es'),
        Locale('ja'),
        Locale('ko'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
