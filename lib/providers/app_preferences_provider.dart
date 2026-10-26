import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AppPreferencesProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  AppPreferencesProvider({
    required AuthService authService,
    required ApiService apiService,
    required StorageService storageService,
  }) : this._internal(
         authService: authService,
         apiService: apiService,
         storageService: storageService,
       );

  AppPreferencesProvider._internal({
    required this._authService,
    required this._apiService,
    required this._storageService,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _authService.addListener(_handleAuthChange);
    unawaited(_loadInitialPreferences());
  }

  final AuthService _authService;
  final ApiService _apiService;
  final StorageService _storageService;

  String _themePalette = 'Burger Bites';
  String _themeMode = 'light';
  String _languageCode = 'en';
  bool _isLoading = true;
  bool _remoteLoadInProgress = false;
  String? _loadedRemoteUserId;
  String? _errorMessage;
  bool _isDisposed = false;

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  String get themePalette => _themePalette;
  String get themeMode => _themeMode;
  String get languageCode => _languageCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canSyncToAccount =>
      _authService.isAuthenticated && _apiService.isConfigured;

  ThemeMode get materialThemeMode => switch (_themeMode) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  Locale get locale => switch (_languageCode) {
    'ceb' || 'ilo' || 'war' => const Locale('fil'),
    _ => Locale(_languageCode),
  };

  static const supportedLanguageCodes = {
    'en',
    'fil',
    'ceb',
    'ilo',
    'war',
    'es',
    'ja',
    'ko',
  };

  bool get _effectiveDarkMode {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _applyPreferences() {
    AppColors.configure(palette: _themePalette, darkMode: _effectiveDarkMode);
    AppTranslations.languageCode = _languageCode;
  }

  Future<void> _loadInitialPreferences() async {
    try {
      final values = await Future.wait([
        _storageService.getThemePalette(),
        _storageService.getThemeMode(),
        _storageService.getLanguage(),
      ]);
      final palette = values[0];
      final mode = values[1];
      final language = values[2];
      if (palette != null && AppColors.paletteNames.contains(palette)) {
        _themePalette = palette;
      }
      if (mode != null && {'light', 'dark', 'system'}.contains(mode)) {
        _themeMode = mode;
      }
      if (language != null && supportedLanguageCodes.contains(language)) {
        _languageCode = language;
      }
      _applyPreferences();
      notifyListeners();

      await _authService.initialization;
      if (_authService.isAuthenticated) await _loadRemotePreferences();
    } catch (_) {
      _errorMessage = 'Unable to load saved appearance preferences.';
      _applyPreferences();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _handleAuthChange() {
    if (_isDisposed ||
        _authService.isInitializing ||
        !_authService.isAuthenticated) {
      return;
    }
    unawaited(_loadRemotePreferences());
  }

  Future<void> _loadRemotePreferences() async {
    final userId = _authService.currentUserId;
    if (userId == null ||
        userId == _loadedRemoteUserId ||
        _remoteLoadInProgress ||
        !_apiService.isConfigured) {
      return;
    }
    _remoteLoadInProgress = true;
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/me/preferences',
        fromJson: (json) => json is Map<String, dynamic>
            ? json
            : throw const FormatException('Invalid preferences response.'),
      );
      final preferences = response.data?['preferences'];
      if (!response.success || preferences is! Map<String, dynamic>) return;

      final palette = preferences['theme_palette'];
      final mode = preferences['theme_mode'];
      final language = preferences['language'];
      if (palette is String && AppColors.paletteNames.contains(palette)) {
        _themePalette = palette;
        await _storageService.saveThemePalette(palette);
      }
      if (mode is String && {'light', 'dark', 'system'}.contains(mode)) {
        _themeMode = mode;
        await _storageService.saveThemeMode(mode);
      }
      if (language is String && supportedLanguageCodes.contains(language)) {
        _languageCode = language;
        await _storageService.saveLanguage(language);
      }
      _loadedRemoteUserId = userId;
      _applyPreferences();
      _safeNotifyListeners();
    } catch (_) {
      _errorMessage =
          'Unable to sync appearance preferences from your account.';
      _safeNotifyListeners();
    } finally {
      _remoteLoadInProgress = false;
    }
  }

  void setThemePalette(String palette) {
    if (!AppColors.paletteNames.contains(palette) || palette == _themePalette) {
      return;
    }
    _themePalette = palette;
    _applyPreferences();
    notifyListeners();
    unawaited(_storageService.saveThemePalette(palette));
  }

  void setThemeMode(String mode) {
    if (!{'light', 'dark', 'system'}.contains(mode) || mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    _applyPreferences();
    notifyListeners();
    unawaited(_storageService.saveThemeMode(mode));
  }

  void setLanguageCode(String code) {
    if (!supportedLanguageCodes.contains(code) || code == _languageCode) return;
    _languageCode = code;
    _applyPreferences();
    notifyListeners();
    unawaited(_storageService.saveLanguage(code));
  }

  Future<bool> saveAppearance() async {
    await _storageService.saveThemePalette(_themePalette);
    await _storageService.saveThemeMode(_themeMode);
    if (!canSyncToAccount) return true;

    final response = await _apiService.put<Map<String, dynamic>>(
      '/me/preferences',
      body: {'theme_palette': _themePalette, 'theme_mode': _themeMode},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    _errorMessage = response.success ? null : response.error;
    notifyListeners();
    return response.success;
  }

  Future<bool> saveLanguage() async {
    await _storageService.saveLanguage(_languageCode);
    if (!canSyncToAccount) return true;

    final response = await _apiService.put<Map<String, dynamic>>(
      '/me/preferences',
      body: {'language': _languageCode},
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid preferences response.'),
    );
    _errorMessage = response.success ? null : response.error;
    notifyListeners();
    return response.success;
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode != 'system') return;
    _applyPreferences();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _authService.removeListener(_handleAuthChange);
    super.dispose();
  }
}
