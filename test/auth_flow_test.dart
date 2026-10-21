import 'dart:convert';

import 'package:burger_bites/navigation/app_router.dart';
import 'package:burger_bites/providers/cart_provider.dart';
import 'package:burger_bites/providers/catalog_provider.dart';
import 'package:burger_bites/providers/customer_orders_provider.dart';
import 'package:burger_bites/screens/customer/order_history_screen.dart';
import 'package:burger_bites/services/api_service.dart';
import 'package:burger_bites/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;
  http.Client? previousHttpClient;
  late AuthService auth;
  final requestPaths = <String>[];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    requestPaths.clear();
    mockClient = MockClient((request) async {
      requestPaths.add(request.url.path);
      return http.Response(
        jsonEncode({
          'token': 'test-access-token',
          'refresh_token': 'test-refresh-token',
          'user': {
            'id': 'customer-1',
            'role': 'customer',
            'full_name': 'Test Customer',
            'email': 'customer@example.test',
          },
        }),
        request.url.path.endsWith('/auth/register') ? 201 : 200,
        headers: const {'content-type': 'application/json'},
      );
    });
    previousHttpClient = ApiService().replaceHttpClientForTesting(mockClient);
    ApiService().setBaseUrl('https://burgerbites.test/api/v1');
    auth = AuthService.forTesting();
    await auth.initialization;
  });

  tearDown(() {
    if (previousHttpClient != null) {
      ApiService().replaceHttpClientForTesting(previousHttpClient!);
    }
    mockClient.close();
  });

  for (final flow in [
    (startRoute: '/sign-in', link: 'Create one', form: 'register'),
    (startRoute: '/register', link: 'Sign in', form: 'login'),
  ]) {
    testWidgets(
      '${flow.startRoute} preserves the caller through ${flow.form}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthService>.value(
            value: auth,
            child: MaterialApp(
              onGenerateRoute: AppRouter.generateRoute,
              home: _FlowHarness(startRoute: flow.startRoute),
            ),
          ),
        );

        await tester.tap(find.text('Open protected action'));
        await _pumpFrames(tester);
        await tester.tap(find.text(flow.link));
        await _pumpFrames(tester);

        if (flow.form == 'register') {
          await tester.enterText(
            find.byType(TextFormField).at(0),
            'Test Customer',
          );
          await tester.enterText(
            find.byType(TextFormField).at(1),
            'customer@example.test',
          );
          await tester.enterText(
            find.byType(TextFormField).at(2),
            'A-secure-test-pass-123',
          );
          await tester.ensureVisible(find.text('Create account'));
          await tester.tap(find.text('Create account'));
        } else {
          await tester.enterText(
            find.byType(TextFormField).at(0),
            'customer@example.test',
          );
          await tester.enterText(
            find.byType(TextFormField).at(1),
            'A-secure-test-pass-123',
          );
          await tester.tap(find.text('Continue'));
        }
        await _pumpFrames(tester);

        expect(find.text('Protected action resumed'), findsOneWidget);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.currentUserRole, 'customer');
        expect(requestPaths, contains('/api/v1/auth/${flow.form}'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('router handles missing and invalid record arguments safely', (
    tester,
  ) async {
    final cases = [
      (
        route: '/product-details',
        arguments: 'not a Product',
        label: 'Open invalid product',
        message: 'Product information is invalid.',
      ),
      (
        route: '/order-success',
        arguments: null,
        label: 'Open missing order',
        message: 'Order confirmation is unavailable.',
      ),
      (
        route: '/admin-edit-product',
        arguments: 'not a Product',
        label: 'Open invalid admin product',
        message: 'Product information is invalid.',
      ),
    ];

    for (final item in cases) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(item.route),
          onGenerateRoute: AppRouter.generateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(item.route, arguments: item.arguments),
                child: Text(item.label),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(item.label));
      await tester.pumpAndSettle();
      expect(find.text(item.message), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'guest order history asks for an account instead of showing empty',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: auth),
            ChangeNotifierProvider(
              create: (_) => CartProvider(authService: auth),
            ),
            ChangeNotifierProvider(create: (_) => CatalogProvider()),
            ChangeNotifierProvider(create: (_) => CustomerOrdersProvider(auth)),
          ],
          child: MaterialApp(home: const OrderHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to see your orders'), findsOneWidget);
      expect(find.text('No orders yet'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FlowHarness extends StatefulWidget {
  const _FlowHarness({required this.startRoute});

  final String startRoute;

  @override
  State<_FlowHarness> createState() => _FlowHarnessState();
}

class _FlowHarnessState extends State<_FlowHarness> {
  bool _resumed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _resumed
          ? const Text('Protected action resumed')
          : TextButton(
              onPressed: () async {
                final authenticated = await Navigator.of(context)
                    .pushNamed<bool>(widget.startRoute, arguments: true);
                if (!mounted) return;
                setState(() => _resumed = authenticated == true);
              },
              child: const Text('Open protected action'),
            ),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
