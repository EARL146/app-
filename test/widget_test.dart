import 'package:burger_bites/screens/customer/splash_screen.dart';
import 'package:burger_bites/screens/customer/welcome_screen.dart';
import 'package:burger_bites/screens/admin/admin_profile_screen.dart';
import 'package:burger_bites/screens/admin/admin_store_profile_screen.dart';
import 'package:burger_bites/screens/admin/admin_home_screen.dart';
import 'package:burger_bites/screens/customer/home_screen.dart';
import 'package:burger_bites/screens/customer/menu_screen.dart';
import 'package:burger_bites/screens/customer/register_screen.dart';
import 'package:burger_bites/screens/customer/search_screen.dart';
import 'package:burger_bites/screens/customer/sign_in_screen.dart';
import 'package:burger_bites/screens/customer/product_details_screen.dart';
import 'package:burger_bites/navigation/app_router.dart';
import 'package:burger_bites/providers/admin_dashboard_provider.dart';
import 'package:burger_bites/providers/admin_orders_provider.dart';
import 'package:burger_bites/providers/cart_provider.dart';
import 'package:burger_bites/providers/catalog_provider.dart';
import 'package:burger_bites/providers/customer_orders_provider.dart';
import 'package:burger_bites/providers/favorites_provider.dart';
import 'package:burger_bites/models/product_model.dart';
import 'package:burger_bites/services/api_service.dart';
import 'package:burger_bites/services/auth_service.dart';
import 'package:burger_bites/screens/customer/settings_screen.dart';
import 'package:burger_bites/screens/customer/contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('fresh startup opens the menu after the burger intro', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/sign-in' ||
              settings.name == '/customer-home') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                body: Text('${settings.name}:${settings.arguments}'),
              ),
            );
          }
          return AppRouter.generateRoute(settings);
        },
        home: const SplashScreen(restoreSession: false),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    for (
      var frame = 0;
      frame < 60 && find.text('/customer-home:true').evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('/customer-home:true'), findsOneWidget);
  });

  testWidgets('splash intro fits a short viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 103);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(restoreSession: false)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome and auth screens fit common phone widths', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in [320, 360, 390, 430]) {
      tester.view.physicalSize = Size(width.toDouble(), 700);
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'welcome at $width px');

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: AuthService(),
          child: const MaterialApp(home: SignInScreen()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'sign-in at $width px');

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: AuthService(),
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'register at $width px');
    }
  });

  testWidgets('customer home fits phone widths and its menu control works', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final auth = AuthService();

    for (final width in [320, 360, 390, 430]) {
      tester.view.physicalSize = Size(width.toDouble(), 844);
      await tester.pumpWidget(_customerHomeHarness(auth));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'home at $width px');
      expect(find.text('Home'), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('guest menu scrolls in a short viewport without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 150);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _customerHomeHarness(AuthService(), openMenuInitially: true),
    );
    await tester.pump();

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest home identifies that order history needs sign in', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_customerHomeHarness(AuthService()));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Your recent orders'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Sign in to view your order history.'), findsOneWidget);
    expect(find.text('Your saved orders will appear here.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search starts with real empty state, not sample search history',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(),
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('No menu items yet'), findsOneWidget);
      expect(find.text('Double Bacon Smash'), findsNothing);
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product details shows description, sizes, and prices', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthService();
    final product = Product(
      id: 'burger-1',
      name: 'Crispy Chicken Stack',
      description: 'Crispy chicken, fresh lettuce, and house sauce.',
      price: 220,
      category: 'Burgers',
      stockQuantity: 12,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => CartProvider(authService: auth),
          ),
          ChangeNotifierProvider(
            create: (_) => FavoritesProvider(auth, ApiService()),
          ),
        ],
        child: MaterialApp(home: ProductDetailsScreen(product: product)),
      ),
    );
    await tester.pump();

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Crispy Chicken Stack'), findsOneWidget);
    expect(find.text('₱220'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('About this item'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Crispy chicken, fresh lettuce, and house sauce.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Burger size'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
    expect(find.text('Double'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Crispy bacon'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Extra cheese'), findsOneWidget);
    expect(find.text('+ ₱25'), findsOneWidget);
    expect(find.text('Crispy bacon'), findsOneWidget);
    expect(find.text('+ ₱45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin dashboard fits common phone widths', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in [320, 360, 390, 430]) {
      tester.view.physicalSize = Size(width.toDouble(), 844);
      await tester.pumpWidget(_adminHomeHarness());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'admin home at $width px');
    }
  });

  testWidgets('admin dashboard does not present initial zeroes as live data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_adminHomeHarness());
    await tester.pumpAndSettle();

    expect(find.text('Live account totals'), findsNothing);
    expect(find.text('No orders yet'), findsNothing);
    expect(find.text('SQL totals unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin profile exposes account, password, and logout controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: AuthService(),
        child: const MaterialApp(home: AdminProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin profile'), findsOneWidget);
    expect(find.text('Profile details'), findsOneWidget);
    expect(find.text('Admin access'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    await tester.ensureVisible(find.text('Change password'));
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your current password.'), findsOneWidget);
  });

  testWidgets('admin store profile exposes public business fields', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AdminStoreProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Store profile'), findsOneWidget);
    expect(find.text('Public business details'), findsOneWidget);
    expect(find.text('Store name'), findsOneWidget);
    expect(find.text('Support email'), findsOneWidget);
    expect(find.text('Delivery coverage'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save store profile'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save store profile'), findsOneWidget);
  });

  testWidgets('customer settings shows profile and notification preferences', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: AuthService(),
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Default delivery address'), findsOneWidget);
    expect(find.text('House/building, street, barangay, city'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('SMS order update preference'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('SMS order update preference'), findsOneWidget);
    expect(find.text('Email receipt preference'), findsOneWidget);
    expect(find.text('Promotional alert preference'), findsOneWidget);
  });

  testWidgets(
    'contact screen hides unverified store details and keeps support form',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ContactScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BURGERBITES SUPPORT'), findsOneWidget);
      expect(find.textContaining('Verified store phone'), findsOneWidget);
      expect(find.text('support@burgerbites.app'), findsNothing);
      expect(find.text('+63 912 345 6789'), findsNothing);
      expect(find.text('Open today · 10:00 AM – 10:00 PM'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Send message'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Send message'), findsOneWidget);
    },
  );
}

Widget _customerHomeHarness(
  AuthService auth, {
  bool openMenuInitially = false,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthService>.value(value: auth),
    ChangeNotifierProvider(create: (_) => CatalogProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider(authService: auth)),
    ChangeNotifierProvider(create: (_) => CustomerOrdersProvider(auth)),
  ],
  child: MaterialApp(
    onGenerateRoute: AppRouter.generateRoute,
    home: CustomerHomeScreen(openMenuInitially: openMenuInitially),
  ),
);

Widget _adminHomeHarness() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AdminOrdersProvider()),
    ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
  ],
  child: const MaterialApp(home: AdminHomeScreen()),
);
