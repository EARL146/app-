import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'storage_service.dart';

/// API-backed identity and session state.
///
/// This class deliberately has no local demo credential fallback. Until an API
/// base URL is configured, login and registration return a setup error.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  final ApiService _apiService;
  final StorageService _storageService;
  late final Future<void> initialization;

  bool _isAuthenticated = false;
  bool _isInitializing = true;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  String? _currentUserRole;
  String? _currentUserPhone;
  String? _currentUserBranch;
  String? _currentUserAddress;
  String? _errorMessage;

  factory AuthService() => _instance;

  AuthService._internal()
    : _apiService = ApiService(),
      _storageService = StorageService() {
    initialization = _initializeAuth();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  String? get currentUserRole => _currentUserRole;
  String? get currentUserPhone => _currentUserPhone;
  String? get currentUserBranch => _currentUserBranch;
  String? get currentUserAddress => _currentUserAddress;
  String? get errorMessage => _errorMessage;

  Future<void> _initializeAuth() async {
    try {
      final token = await _storageService.getToken();
      final userId = await _storageService.getUserId();
      final role = await _storageService.getUserRole();
      _currentUserId = userId;
      _currentUserEmail = await _storageService.getUserEmail();
      _currentUserName = await _storageService.getUserName();
      _currentUserRole = role?.toLowerCase();
      _currentUserPhone = await _storageService.getUserPhone();
      _currentUserBranch = await _storageService.getUserBranch();
      _currentUserAddress = await _storageService.getUserAddress();
      final hasCompleteLocalSession =
          token != null &&
          token.isNotEmpty &&
          userId != null &&
          {'customer', 'admin'}.contains(_currentUserRole);
      if (!hasCompleteLocalSession || !_apiService.isConfigured) {
        if (token != null) await _storageService.clearAll();
        _clearIdentity();
        return;
      }

      var response = await _apiService.get<Map<String, dynamic>>(
        '/me',
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid profile response.'),
      );
      if (response.statusCode == 401 && await refreshToken()) {
        response = await _apiService.get<Map<String, dynamic>>(
          '/me',
          fromJson: (json) => json is Map<String, dynamic>
              ? json
              : throw const FormatException('Invalid profile response.'),
        );
      }
      final data = response.data;
      final user = data?['user'] is Map<String, dynamic>
          ? data!['user'] as Map<String, dynamic>
          : data;
      final serverId = user?['id']?.toString();
      final serverRole = user?['role']?.toString().toLowerCase();
      if (!response.success ||
          user == null ||
          serverId != _currentUserId ||
          !{'customer', 'admin'}.contains(serverRole)) {
        await _storageService.clearAll();
        _clearIdentity();
        return;
      }

      _currentUserName = _userName(user);
      _currentUserEmail = user['email']?.toString() ?? _currentUserEmail;
      _currentUserRole = serverRole;
      _currentUserPhone = user['phone']?.toString();
      _currentUserBranch = user['branch_name']?.toString();
      _currentUserAddress = user['default_address']?.toString();
      await _storageService.saveUserRole(serverRole!);
      if (_currentUserName != null) {
        await _storageService.saveUserName(_currentUserName!);
      }
      if (_currentUserEmail != null) {
        await _storageService.saveUserEmail(_currentUserEmail!);
      }
      if (_currentUserPhone != null) {
        await _storageService.saveUserPhone(_currentUserPhone!);
      }
      if (_currentUserBranch != null) {
        await _storageService.saveUserBranch(_currentUserBranch!);
      }
      if (_currentUserAddress != null) {
        await _storageService.saveUserAddress(_currentUserAddress!);
      }
      _isAuthenticated = true;
    } catch (_) {
      try {
        await _storageService.clearAll();
      } catch (_) {}
      _clearIdentity();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _clearIdentity() {
    _isAuthenticated = false;
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    _currentUserRole = null;
    _currentUserPhone = null;
    _currentUserBranch = null;
    _currentUserAddress = null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/register',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid registration response.'),
      body: {
        'full_name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );
    return _acceptAuthentication(response, emailFallback: email);
  }

  Future<bool> login({required String email, required String password}) async {
    _errorMessage = null;
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/login',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid login response.'),
      body: {'email': email.trim().toLowerCase(), 'password': password},
      requiresAuth: false,
    );
    return _acceptAuthentication(response, emailFallback: email);
  }

  Future<bool> _acceptAuthentication(
    ApiResponse<Map<String, dynamic>> response, {
    required String emailFallback,
  }) async {
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to authenticate this account.';
      notifyListeners();
      return false;
    }

    final data = response.data!;
    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    final token = data['token'];
    final userId = data['user_id'] ?? user['id'];
    final role = (data['role'] ?? user['role'])?.toString().toLowerCase();
    if (token is! String ||
        token.isEmpty ||
        userId == null ||
        !{'customer', 'admin'}.contains(role)) {
      _errorMessage = 'The server returned an incomplete account session.';
      notifyListeners();
      return false;
    }

    final email = (user['email'] ?? data['email'] ?? emailFallback)
        .toString()
        .trim()
        .toLowerCase();
    final name = _userName(user);
    final phone = user['phone']?.toString();
    final branch = user['branch_name']?.toString();
    final address = user['default_address']?.toString();

    try {
      await _storageService.clearAll();
      await _storageService.saveToken(token);
      await _storageService.saveUserId(userId.toString());
      await _storageService.saveUserEmail(email);
      await _storageService.saveUserRole(role!);
      if (name != null) await _storageService.saveUserName(name);
      if (phone != null) await _storageService.saveUserPhone(phone);
      if (branch != null) await _storageService.saveUserBranch(branch);
      if (address != null) await _storageService.saveUserAddress(address);
      final refreshToken = data['refresh_token'];
      if (refreshToken is String && refreshToken.isNotEmpty) {
        await _storageService.saveRefreshToken(refreshToken);
      }
    } catch (_) {
      try {
        await _storageService.clearAll();
      } catch (_) {}
      _errorMessage = 'Unable to securely save your session on this device.';
      notifyListeners();
      return false;
    }

    _currentUserId = userId.toString();
    _currentUserEmail = email;
    _currentUserName = name;
    _currentUserRole = role;
    _currentUserPhone = phone;
    _currentUserBranch = branch;
    _currentUserAddress = address;
    _isAuthenticated = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  String? _userName(Map<String, dynamic> user) {
    final fullName = user['full_name'] ?? user['name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? null : combined;
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? branch,
    String? address,
  }) async {
    _errorMessage = null;
    final response = await _apiService.put<Map<String, dynamic>>(
      '/me',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid profile response.'),
      body: {
        'full_name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (branch != null) 'branch_name': branch.trim(),
        if (address != null) 'default_address': address.trim(),
      },
    );
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to save profile changes.';
      notifyListeners();
      return false;
    }

    final data = response.data!;
    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    final savedName = _userName(user) ?? name.trim();
    final savedEmail = user['email']?.toString() ?? _currentUserEmail;
    final savedPhone = user['phone']?.toString() ?? phone ?? _currentUserPhone;
    final savedBranch =
        user['branch_name']?.toString() ?? branch ?? _currentUserBranch;
    final savedAddress =
        user['default_address']?.toString() ?? address ?? _currentUserAddress;

    try {
      await _storageService.saveUserName(savedName);
      if (savedEmail != null) await _storageService.saveUserEmail(savedEmail);
      if (savedPhone != null) await _storageService.saveUserPhone(savedPhone);
      if (savedBranch != null) {
        await _storageService.saveUserBranch(savedBranch);
      }
      if (savedAddress != null) {
        await _storageService.saveUserAddress(savedAddress);
      }
    } catch (_) {
      _errorMessage = 'The server saved your profile, but local session data could not be updated.';
      notifyListeners();
      return false;
    }

    _currentUserName = savedName;
    _currentUserEmail = savedEmail;
    _currentUserPhone = savedPhone;
    _currentUserBranch = savedBranch;
    _currentUserAddress = savedAddress;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _errorMessage = null;
    if (_isAuthenticated && _apiService.isConfigured) {
      await _apiService.post<Map<String, dynamic>>(
        '/auth/logout',
        fromJson: (json) =>
            json is Map<String, dynamic> ? json : <String, dynamic>{},
        body: const {},
      );
    }
    try {
      await _apiService.logout();
    } finally {
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
      _currentUserRole = null;
      _currentUserPhone = null;
      _currentUserBranch = null;
      _currentUserAddress = null;
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    await initialization;
    return _isAuthenticated;
  }

  Future<bool> refreshToken() async {
    _errorMessage = null;
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || !_apiService.isConfigured) {
      await logout();
      return false;
    }

    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/refresh',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid refresh response.'),
      body: {'refresh_token': refreshToken},
      requiresAuth: false,
    );
    final token = response.data?['token'];
    final rotatedRefreshToken = response.data?['refresh_token'];
    if (response.success &&
        token is String &&
        token.isNotEmpty &&
        rotatedRefreshToken is String &&
        rotatedRefreshToken.isNotEmpty) {
      try {
        await _storageService.saveToken(token);
        await _storageService.saveRefreshToken(rotatedRefreshToken);
      } catch (_) {
        await logout();
        _errorMessage = 'Unable to securely save your refreshed session.';
        notifyListeners();
        return false;
      }
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    final refreshError =
        response.error ?? 'Your session has expired. Sign in again.';
    await logout();
    _errorMessage = refreshError;
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
