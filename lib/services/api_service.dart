import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}

/// Main API service for handling all HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String _baseUrl = 'https://api.burgerbites.com/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  late StorageService _storageService;
  late http.Client _httpClient;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _storageService = StorageService();
    _httpClient = http.Client();
  }

  /// Update base URL (useful when switching to Obsidian)
  void setBaseUrl(String newBaseUrl) {
    // This allows dynamic URL changes when Obsidian is configured
  }

  /// Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    required dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      final response = await _httpClient
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}');
    }
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requiresAuth);
      var url = Uri.parse('$_baseUrl$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await _httpClient.get(url, headers: headers).timeout(_timeout);

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}');
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    required dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      final response = await _httpClient
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requiresAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      final response = await _httpClient.delete(url, headers: headers).timeout(_timeout);

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Network error: ${e.toString()}');
    }
  }

  /// Handle HTTP responses
  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(dynamic) fromJson) {
    try {
      final responseData = jsonDecode(response.body);

      // Handle success responses (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(
          success: true,
          data: fromJson(responseData),
          statusCode: response.statusCode,
        );
      }

      // Handle unauthorized (401) - token might be expired
      if (response.statusCode == 401) {
        // Token refresh logic can be added here
        return ApiResponse<T>(
          success: false,
          error: 'Unauthorized. Please login again.',
          statusCode: response.statusCode,
        );
      }

      // Handle other errors (400, 403, 404, 500, etc.)
      final errorMessage = responseData['message'] ?? responseData['error'] ?? 'Unknown error';
      return ApiResponse<T>(
        success: false,
        error: errorMessage.toString(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<T>(success: false, error: 'Failed to parse response: ${e.toString()}');
    }
  }

  /// Logout - clear stored tokens
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}
