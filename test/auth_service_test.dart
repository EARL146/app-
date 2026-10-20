import 'dart:convert';

import 'package:burger_bites/services/api_service.dart';
import 'package:burger_bites/services/auth_service.dart';
import 'package:burger_bites/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;
  http.Client? previousHttpClient;
  late int meStatus;
  late int refreshStatus;
  String? failurePath;
  late Map<String, dynamic>? meResponseBody;
  late List<String> requestPaths;
  late List<int> responseStatuses;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'cached-access-token',
      'refresh_token': 'cached-refresh-token',
      'user_id': 'customer-42',
      'user_email': 'customer@example.test',
      'user_name': 'Cached Customer',
      'user_role': 'customer',
      'user_phone': '5550100',
      'user_branch': 'Main',
      'user_default_address': '1 Example Street',
    });
    meStatus = 503;
    refreshStatus = 503;
    failurePath = null;
    meResponseBody = null;
    requestPaths = [];
    responseStatuses = [];
    mockClient = MockClient((request) async {
      final status = request.url.path.endsWith('/auth/refresh')
          ? refreshStatus
          : meStatus;
      requestPaths.add(request.url.path);
      if (failurePath == request.url.path) {
        throw http.ClientException(
          'Simulated transport failure.',
          request.url,
        );
      }
      responseStatuses.add(status);
      final body = request.url.path.endsWith('/me') &&
              status >= 200 &&
              status < 300
          ? (meResponseBody ??
                {
                  'user': {
                    'id': 'customer-42',
                    'role': 'customer',
                    'full_name': 'Cached Customer',
                  },
                })
          : {'message': 'temporary service error'};
      return http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    previousHttpClient = ApiService().replaceHttpClientForTesting(mockClient);
    ApiService().setBaseUrl('https://burgerbites.test/api/v1');
    expect(ApiService().isConfigured, isTrue);
  });

  tearDown(() async {
    if (previousHttpClient != null) {
      ApiService().replaceHttpClientForTesting(previousHttpClient!);
    }
    mockClient.close();
  });

  test(
    'preserves cached session when profile validation returns 503',
    () async {
      final auth = AuthService.forTesting();
      await auth.initialization;

      expect(requestPaths, ['/api/v1/me']);
      expect(responseStatuses, [503]);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserId, 'customer-42');
      expect(auth.currentUserEmail, 'customer@example.test');
      expect(auth.currentUserName, 'Cached Customer');
      expect(auth.currentUserRole, 'customer');
      expect(await StorageService().getToken(), 'cached-access-token');
      expect(await StorageService().getRefreshToken(), 'cached-refresh-token');
    },
  );

  test('clears orphaned refresh and profile data when access token is missing', () async {
    FlutterSecureStorage.setMockInitialValues({
      'refresh_token': 'orphaned-refresh-token',
      'user_id': 'customer-42',
      'user_role': 'customer',
    });

    final auth = AuthService.forTesting();
    await auth.initialization;

    expect(requestPaths, isEmpty);
    expect(auth.isAuthenticated, isFalse);
    expect(await StorageService().getToken(), isNull);
    expect(await StorageService().getRefreshToken(), isNull);
    expect(await StorageService().getUserId(), isNull);
  });

  test('preserves cached session when token refresh returns 503', () async {
    meStatus = 401;
    refreshStatus = 503;

    final auth = AuthService.forTesting();
    await auth.initialization;

    expect(requestPaths, ['/api/v1/me', '/api/v1/auth/refresh']);
    expect(responseStatuses, [401, 503]);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUserName, 'Cached Customer');
    expect(await StorageService().getToken(), 'cached-access-token');
    expect(await StorageService().getRefreshToken(), 'cached-refresh-token');
  });

  test(
    'preserves cached session when profile validation has a transport error',
    () async {
      failurePath = '/api/v1/me';

      final auth = AuthService.forTesting();
      await auth.initialization;

      expect(requestPaths, ['/api/v1/me']);
      expect(responseStatuses, isEmpty);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserId, 'customer-42');
      expect(await StorageService().getToken(), 'cached-access-token');
      expect(await StorageService().getRefreshToken(), 'cached-refresh-token');
    },
  );

  test(
    'preserves cached session when token refresh has a transport error',
    () async {
      meStatus = 401;
      failurePath = '/api/v1/auth/refresh';

      final auth = AuthService.forTesting();
      await auth.initialization;

      expect(requestPaths, ['/api/v1/me', '/api/v1/auth/refresh']);
      expect(responseStatuses, [401]);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserId, 'customer-42');
      expect(await StorageService().getToken(), 'cached-access-token');
      expect(await StorageService().getRefreshToken(), 'cached-refresh-token');
    },
  );

  test('clears cached session after refresh confirms 401', () async {
    meStatus = 401;
    refreshStatus = 401;

    final auth = AuthService.forTesting();
    await auth.initialization;

    expect(requestPaths, ['/api/v1/me', '/api/v1/auth/refresh']);
    expect(responseStatuses, [401, 401]);
    expect(auth.isAuthenticated, isFalse);
    expect(await StorageService().getToken(), isNull);
    expect(await StorageService().getRefreshToken(), isNull);
  });

  test(
    'clears cached session when a successful profile response is inconsistent',
    () async {
      meStatus = 200;
      meResponseBody = {
        'user': {
          'id': 'different-customer',
          'role': 'customer',
          'full_name': 'Different Customer',
        },
      };

      final auth = AuthService.forTesting();
      await auth.initialization;

      expect(requestPaths, ['/api/v1/me']);
      expect(responseStatuses, [200]);
      expect(auth.isAuthenticated, isFalse);
      expect(await StorageService().getToken(), isNull);
      expect(await StorageService().getRefreshToken(), isNull);
    },
  );
}
