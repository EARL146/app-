import 'dart:io';

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
}
