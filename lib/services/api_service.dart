import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
}

/// HTTP client for the BurgerBites API. The base URL is supplied at build time.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String _compileTimeBaseUrl = String.fromEnvironment(
    'BURGER_BITES_API_BASE_URL',
  );
  static const Duration _timeout = Duration(seconds: 15);

  static bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  static String _initialBaseUrl() {
    final configured = _compileTimeBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }

    // Let local Edge/Chrome development use the documented PHP API by
    // default, while keeping native tests isolated.
    if (kIsWeb) {
      return 'http://127.0.0.1:8081/api/v1';
    }
    return '';
  }

  final StorageService _storageService;
  http.Client _httpClient;
  String _baseUrl;

  factory ApiService() => _instance;

  ApiService._internal()
    : _storageService = StorageService(),
      _httpClient = http.Client(),
      _baseUrl = _initialBaseUrl();

  bool get isConfigured {
    final uri = Uri.tryParse(_baseUrl);
    return uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        const {'http', 'https'}.contains(uri.scheme) &&
        (!kReleaseMode || uri.scheme == 'https' || _isLoopback(uri.host));
  }

  void setBaseUrl(String newBaseUrl) {
    final normalized = newBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https' && !_isLoopback(uri.host))) {
      throw ArgumentError.value(
        newBaseUrl,
        'newBaseUrl',
        'Expected an HTTP(S) API URL.',
      );
    }
    _baseUrl = normalized;
  }

  @visibleForTesting
  http.Client replaceHttpClientForTesting(http.Client client) {
    final previousClient = _httpClient;
    _httpClient = client;
    return previousClient;
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _endpoint(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    return queryParams == null || queryParams.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParams);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    required dynamic body,
    bool requiresAuth = true,
  }) async {
    if (!isConfigured) return _configurationError<T>();
    try {
      final response = await _httpClient
          .post(
            _endpoint(endpoint),
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        error: 'The server took too long to respond. Try again.',
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        error: 'Unable to reach BurgerBites. Check that the API server is running and the app API URL is correct.',
      );
    }
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    if (!isConfigured) return _configurationError<T>();
    try {
      final response = await _httpClient
          .get(
            _endpoint(endpoint, queryParams),
            headers: await _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(_timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        error: 'The server took too long to respond. Try again.',
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        error: 'Unable to connect to BurgerBites. Check the API URL and connection.',
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    required dynamic body,
    bool requiresAuth = true,
  }) async {
    if (!isConfigured) return _configurationError<T>();
    try {
      final response = await _httpClient
          .put(
            _endpoint(endpoint),
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        error: 'The server took too long to respond. Try again.',
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        error: 'Unable to connect to BurgerBites. Check the API URL and connection.',
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    bool requiresAuth = true,
  }) async {
    if (!isConfigured) return _configurationError<T>();
    try {
      final response = await _httpClient
          .delete(
            _endpoint(endpoint),
            headers: await _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(_timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        error: 'The server took too long to respond. Try again.',
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        error: 'Unable to connect to BurgerBites. Check the API URL and connection.',
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) {
    dynamic responseData;
    try {
      responseData = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      return ApiResponse<T>(
        success: false,
        error: 'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return ApiResponse<T>(
          success: true,
          data: fromJson(responseData),
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ApiResponse<T>(
          success: false,
          error: 'The server response did not match the expected format.',
          statusCode: response.statusCode,
        );
      }
    }

    final responseMap = responseData is Map<String, dynamic>
        ? responseData
        : const <String, dynamic>{};
    final errorMessage = responseMap['message'] ?? responseMap['error'];
    return ApiResponse<T>(
      success: false,
      error: errorMessage is String && errorMessage.isNotEmpty
          ? errorMessage
          : response.statusCode == 401
          ? 'Your session has expired. Sign in again.'
          : 'BurgerBites could not complete the request. Try again.',
      statusCode: response.statusCode,
    );
  }

  ApiResponse<T> _configurationError<T>() => ApiResponse<T>(
    success: false,
    error: 'The BurgerBites API is not configured. Set BURGER_BITES_API_BASE_URL and restart the app.',
  );

  Future<void> logout() => _storageService.clearAuthentication();
}
