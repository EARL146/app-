import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for managing sensitive data like tokens
class StorageService {
  static final StorageService _instance = StorageService._internal();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  static const String _userPhoneKey = 'user_phone';
  static const String _userBranchKey = 'user_branch';
  static const String _userAddressKey = 'user_default_address';

  late FlutterSecureStorage _storage;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        resetOnError: true,
      ),
    );
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  Future<void> saveUserName(String name) async =>
      _storage.write(key: _userNameKey, value: name);

  Future<String?> getUserName() async => _storage.read(key: _userNameKey);

  Future<void> saveUserRole(String role) async =>
      _storage.write(key: _userRoleKey, value: role);

  Future<String?> getUserRole() async => _storage.read(key: _userRoleKey);

  Future<void> saveUserPhone(String phone) async =>
      _storage.write(key: _userPhoneKey, value: phone);

  Future<String?> getUserPhone() async => _storage.read(key: _userPhoneKey);

  Future<void> saveUserBranch(String branch) async =>
      _storage.write(key: _userBranchKey, value: branch);

  Future<String?> getUserBranch() async => _storage.read(key: _userBranchKey);

  Future<void> saveUserAddress(String address) async =>
      _storage.write(key: _userAddressKey, value: address);

  Future<String?> getUserAddress() async => _storage.read(key: _userAddressKey);

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
