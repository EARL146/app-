import 'package:burger_bites/screens/customer/greetings_screen.dart';
import 'package:burger_bites/screens/customer/sign_in_screen.dart';
import 'package:burger_bites/screens/customer/splash_screen.dart';
import 'package:burger_bites/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup shows logo, greetings, then sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.generateRoute,
        home: const SplashScreen(restoreSession: false),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(GreetingsScreen), findsOneWidget);
    expect(find.text('Welcome to BurgerBites'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
