import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/app_preferences_provider.dart';
import 'admin_route_gate.dart';
import 'customer_route_gate.dart';
import '../screens/customer/about_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/calendar_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/contact_screen.dart';
import '../screens/customer/favorites_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/language_screen.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/customer/order_success_screen.dart';
import '../screens/customer/product_details_screen.dart';
import '../screens/customer/register_screen.dart';
import '../screens/customer/search_screen.dart';
import '../screens/customer/settings_screen.dart';
import '../screens/customer/splash_screen.dart';
import '../screens/customer/sign_in_screen.dart';
import '../screens/customer/theme_screen.dart';
import '../screens/customer/welcome_screen.dart';
import '../screens/admin/admin_add_product_screen.dart';
import '../screens/admin/admin_customers_screen.dart';
import '../screens/admin/admin_edit_product_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_more_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_support_screen.dart';
import '../screens/admin/admin_store_profile_screen.dart';

class AppRouter {
  static MaterialPageRoute<T> _pageRoute<T>({required WidgetBuilder builder}) =>
      MaterialPageRoute<T>(
        builder: (context) => Consumer<AppPreferencesProvider>(
          builder: (context, _, _) => builder(context),
        ),
      );

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/splash':
        return _pageRoute(builder: (_) => const SplashScreen());
      case '/welcome':
        return _pageRoute(builder: (_) => const WelcomeScreen());
      case '/sign-in':
        return _pageRoute<bool>(
          builder: (_) =>
              SignInScreen(returnToCaller: settings.arguments == true),
        );
      case '/register':
        return _pageRoute<bool>(
          builder: (_) =>
              RegisterScreen(returnToCaller: settings.arguments == true),
        );
      case '/customer-home':
        return _pageRoute(
          builder: (_) =>
              CustomerHomeScreen(openMenuInitially: settings.arguments == true),
        );
      case '/search':
        return _pageRoute(builder: (_) => const SearchScreen());
      case '/favorites':
        return _pageRoute(builder: (_) => const FavoritesScreen());
      case '/menu':
        final category = settings.arguments is String
            ? settings.arguments as String
            : 'All';
        return _pageRoute(
          builder: (_) => CustomerHomeScreen(
            openMenuInitially: true,
            initialMenuCategory: category,
          ),
        );
      case '/product-details':
        final argument = settings.arguments;
        if (argument is! Product) {
          return _missingRecordRoute(
            argument == null
                ? 'Product was not selected.'
                : 'Product information is invalid.',
          );
        }
        return _pageRoute(
          builder: (_) => ProductDetailsScreen(product: argument),
        );
      case '/cart':
        return _pageRoute(builder: (_) => const CartScreen());
      case '/checkout':
        return _pageRoute(builder: (_) => const CheckoutScreen());
      case '/order-success':
        final argument = settings.arguments;
        if (argument is! String || argument.trim().isEmpty) {
          return _missingRecordRoute('Order confirmation is unavailable.');
        }
        return _pageRoute(
          builder: (_) => OrderSuccessScreen(orderId: argument),
        );
      case '/order-history':
        return _pageRoute(builder: (_) => const OrderHistoryScreen());
      case '/profile':
        return _pageRoute(
          builder: (_) => const CustomerHomeScreen(initialTabIndex: 3),
        );
      case '/settings':
        return _pageRoute(
          builder: (_) => const CustomerRouteGate(
            action: 'manage your account settings',
            child: SettingsScreen(),
          ),
        );
      case '/themes':
        return _pageRoute(builder: (_) => const ThemeScreen());
      case '/language':
        return _pageRoute(builder: (_) => const LanguageScreen());
      case '/calendar':
        return _pageRoute(
          builder: (_) => const CustomerRouteGate(
            action: 'view your calendar and reminders',
            child: CalendarScreen(),
          ),
        );
      case '/contact':
        return _pageRoute(
          builder: (_) => const CustomerRouteGate(
            action: 'contact BurgerBites support',
            child: ContactScreen(),
          ),
        );
      case '/about':
        return _pageRoute(builder: (_) => const AboutScreen());
      case '/admin-home':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminHomeScreen()),
        );
      case '/admin-profile':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminProfileScreen()),
        );
      case '/admin-orders':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminOrdersScreen()),
        );
      case '/admin-products':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminProductsScreen()),
        );
      case '/admin-add-product':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminAddProductScreen()),
        );
      case '/admin-edit-product':
        final argument = settings.arguments;
        if (argument is! Product) {
          return _missingRecordRoute(
            argument == null
                ? 'Product was not selected.'
                : 'Product information is invalid.',
          );
        }
        return _pageRoute(
          builder: (_) =>
              AdminRouteGate(child: AdminEditProductScreen(product: argument)),
        );
      case '/admin-customers':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminCustomersScreen()),
        );
      case '/admin-more':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminMoreScreen()),
        );
      case '/admin-support':
        return _pageRoute(
          builder: (_) => const AdminRouteGate(child: AdminSupportScreen()),
        );
      case '/admin-store-profile':
        return _pageRoute(
          builder: (_) =>
              const AdminRouteGate(child: AdminStoreProfileScreen()),
        );
      default:
        return _pageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Screen not found'))),
        );
    }
  }

  static Route<dynamic> _missingRecordRoute(String message) => _pageRoute(
    builder: (_) => Scaffold(body: Center(child: Text(message))),
  );
}
