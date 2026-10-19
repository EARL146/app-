import 'package:burger_bites/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local API default is limited to web debug builds', () {
    final explicitlyConfigured = const String.fromEnvironment(
      'BURGER_BITES_API_BASE_URL',
    ).isNotEmpty;
    expect(ApiService().isConfigured, explicitlyConfigured || kIsWeb);
  });
}
