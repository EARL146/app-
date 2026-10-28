import 'dart:io';

import 'package:burger_bites/models/product_model.dart';
import 'package:burger_bites/providers/catalog_provider.dart';
import 'package:burger_bites/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  test('catalog connection failure waits for an explicit retry', () async {
    final api = ApiService();
    api.setBaseUrl('http://127.0.0.1:8081/api/v1');
    var requestCount = 0;
    final previousClient = api.replaceHttpClientForTesting(
      MockClient((_) async {
        requestCount++;
        throw const SocketException('Connection refused');
      }),
    );
    addTearDown(() {
      api.replaceHttpClientForTesting(previousClient).close();
    });

    final catalog = CatalogProvider(apiService: api);
    addTearDown(catalog.dispose);

    await catalog.loadProducts();

    expect(catalog.isLoading, isFalse);
    expect(catalog.products, isEmpty);
    expect(catalog.errorMessage, contains('Unable to connect'));
    expect(requestCount, 1);

    await catalog.loadProducts();
    expect(requestCount, 1);

    await catalog.loadProducts(force: true);
    expect(requestCount, 2);
    expect(catalog.isLoading, isFalse);
  });

  test('categories exclude Discount Sale button label', () {
    final catalog = CatalogProvider(apiService: ApiService());
    addTearDown(catalog.dispose);

    catalog.upsertProduct(
      Product(
        id: '1',
        name: 'Classic Burger',
        description: 'Juicy beef patty',
        price: 130,
        discountPercent: 20,
        category: 'Burgers',
        stockQuantity: 10,
        createdAt: DateTime.utc(2026, 10, 28),
      ),
    );
    catalog.upsertProduct(
      Product(
        id: '2',
        name: 'Loaded Fries',
        description: 'Crispy fries',
        price: 95,
        discountPercent: 25,
        category: 'Fries',
        stockQuantity: 10,
        createdAt: DateTime.utc(2026, 10, 28),
      ),
    );

    expect(catalog.categories, ['All', 'Burgers', 'Fries']);
    expect(catalog.categories, isNot(contains('Discount Sale')));
  });
}
