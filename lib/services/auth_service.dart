import 'package:flutter/material.dart';

import 'api_service.dart';
import 'storage_service.dart';

/// Authentication service for managing user login/registration
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  late ApiService _apiService;
  late StorageService _storageService;

  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _errorMessage;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _apiService = ApiService();
    _storageService = StorageService();
    _initializeAuth();
  }

  /// Initialize authentication state from stored data
  Future<void> _initializeAuth() async {
    final token = await _storageService.getToken();
    final userId = await _storageService.getUserId();
    final email = await _storageService.getUserEmail();

    _isAuthenticated = token != null && token.isNotEmpty;
    _currentUserId = userId;
    _currentUserEmail = email;

    notifyListeners();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get errorMessage => _errorMessage;

  /// Register new user
  Future<bool> register({required String email, required String password}) async {
    try {
      _errorMessage = null;

      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/register',
        fromJson: (json) => json as Map<String, dynamic>,
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final token = response.data!['token'] as String?;
        final userId = response.data!['user_id'] as String?;

        if (token != null && userId != null) {
          await _storageService.saveToken(token);
          await _storageService.saveUserId(userId);
          await _storageService.saveUserEmail(email);

          _isAuthenticated = true;
          _currentUserId = userId;
          _currentUserEmail = email;

          notifyListeners();
          return true;
        }
      }

      _errorMessage = response.error ?? 'Registration failed';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    try {
      _errorMessage = null;

      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/login',
        fromJson: (json) => json as Map<String, dynamic>,
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final token = response.data!['token'] as String?;
        final userId = response.data!['user_id'] as String?;
        final refreshToken = response.data!['refresh_token'] as String?;

        if (token != null && userId != null) {
          await _storageService.saveToken(token);
          await _storageService.saveUserId(userId);
          await _storageService.saveUserEmail(email);

          if (refreshToken != null) {
            await _storageService.saveRefreshToken(refreshToken);
          }

          _isAuthenticated = true;
          _currentUserId = userId;
          _currentUserEmail = email;

          notifyListeners();
          return true;
        }
      }

      _errorMessage = response.error ?? 'Login failed';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiService.logout();

      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Check if user is still authenticated
  Future<bool> checkAuthStatus() async {
    final hasToken = await _storageService.hasToken();
    _isAuthenticated = hasToken;
    notifyListeners();
    return hasToken;
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null) {
        await logout();
        return false;
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/refresh',
        fromJson: (json) => json as Map<String, dynamic>,
        body: {'refresh_token': refreshToken},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final newToken = response.data!['token'] as String?;

        if (newToken != null) {
          await _storageService.saveToken(newToken);
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }

      // If refresh fails, logout
      await logout();
      return false;
    } catch (e) {
      _errorMessage = 'Token refresh failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
