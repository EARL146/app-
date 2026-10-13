import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/product_model.dart';
import '../screens/customer/about_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/calendar_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/contact_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/language_screen.dart';
import '../screens/customer/menu_screen.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/customer/order_success_screen.dart';
import '../screens/customer/product_details_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/register_screen.dart';
import '../screens/customer/search_screen.dart';
import '../screens/customer/settings_screen.dart';
import '../screens/customer/sign_in_screen.dart';
import '../screens/customer/theme_screen.dart';
import '../screens/customer/welcome_screen.dart';
import '../screens/admin/admin_add_product_screen.dart';
import '../screens/admin/admin_customers_screen.dart';
import '../screens/admin/admin_edit_product_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_more_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_products_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/welcome':
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case '/sign-in':
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/customer-home':
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/menu':
        final category = settings.arguments as String? ?? 'All';
        return MaterialPageRoute(
          builder: (_) => MenuScreen(initialCategory: category),
        );
      case '/product-details':
        final product =
            settings.arguments as Product? ?? DemoData.products.first;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        );
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/checkout':
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case '/order-success':
        final orderId = settings.arguments as String? ?? 'BB-0000';
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        );
      case '/order-history':
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/themes':
        return MaterialPageRoute(builder: (_) => const ThemeScreen());
      case '/language':
        return MaterialPageRoute(builder: (_) => const LanguageScreen());
      case '/calendar':
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case '/contact':
        return MaterialPageRoute(builder: (_) => const ContactScreen());
      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case '/admin-home':
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case '/admin-orders':
        return MaterialPageRoute(builder: (_) => const AdminOrdersScreen());
      case '/admin-products':
        return MaterialPageRoute(builder: (_) => const AdminProductsScreen());
      case '/admin-add-product':
        return MaterialPageRoute(builder: (_) => const AdminAddProductScreen());
      case '/admin-edit-product':
        final product =
            settings.arguments as Product? ?? DemoData.products.first;
        return MaterialPageRoute(
          builder: (_) => AdminEditProductScreen(product: product),
        );
      case '/admin-customers':
        return MaterialPageRoute(builder: (_) => const AdminCustomersScreen());
      case '/admin-more':
        return MaterialPageRoute(builder: (_) => const AdminMoreScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Screen not found'))),
        );
    }
  }
}
