import 'package:burger_bites/screens/customer/splash_screen.dart';
import 'package:burger_bites/screens/customer/welcome_screen.dart';
import 'package:burger_bites/screens/admin/admin_profile_screen.dart';
import 'package:burger_bites/screens/admin/admin_store_profile_screen.dart';
import 'package:burger_bites/navigation/app_router.dart';
import 'package:burger_bites/services/auth_service.dart';
import 'package:burger_bites/screens/customer/settings_screen.dart';
import 'package:burger_bites/screens/customer/contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('fresh startup assembles the burger and opens welcome actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/register' || settings.name == '/sign-in') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name!)),
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
      frame < 60 && find.byType(WelcomeScreen).evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Your Cravings,\nOur Burgers'), findsOneWidget);
    expect(
      find.text('Freshly made favorites, ready when you are.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Get Started'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('/register'), findsOneWidget);

    await tester.binding.handlePopRoute();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Log In'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('/sign-in'), findsOneWidget);
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
