import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/helpers/six_theme_resolver.dart';
import '../design_system/themes/app_theme.dart';
import '../design_system/themes/six_mobile_typography.dart';
import '../domain/models/aparencia_models.dart';

abstract class ThemePreferenceStorage {
  Future<String?> readThemeMode();

  Future<void> writeThemeMode(String code);
}

class SharedPreferencesThemePreferenceStorage
    implements ThemePreferenceStorage {
  const SharedPreferencesThemePreferenceStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> readThemeMode() async {
    return _preferences.getString(ThemeProvider.themeModePreferenceKey);
  }

  @override
  Future<void> writeThemeMode(String code) async {
    await _preferences.setString(ThemeProvider.themeModePreferenceKey, code);
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({
    bool enableLocalPersistence = !kIsWeb,
    ThemePreferenceStorage? storage,
    TemaSistema initialTheme = TemaSistema.claro,
  }) : _enableLocalPersistence = enableLocalPersistence,
       _storage = enableLocalPersistence ? storage : null {
    _resolver.atualizarTema(
      enableLocalPersistence
          ? _supportedLocalTheme(initialTheme)
          : initialTheme,
    );
    _resolver.addListener(_handleResolverChanged);
  }

  static const String themeModePreferenceKey = 'six.theme.mode';

  final bool _enableLocalPersistence;
  final ThemePreferenceStorage? _storage;
  final SixThemeResolver _resolver = SixThemeResolver();

  bool get usesLocalPersistence => _enableLocalPersistence;

  static Future<ThemeProvider> load({
    bool enableLocalPersistence = !kIsWeb,
    ThemePreferenceStorage? storage,
    TemaSistema fallbackTheme = TemaSistema.claro,
  }) async {
    final ThemePreferenceStorage? effectiveStorage =
        enableLocalPersistence
            ? storage ?? await _tryCreateSharedPreferencesStorage()
            : null;
    final TemaSistema initialTheme =
        enableLocalPersistence
            ? await _readStoredTheme(
              storage: effectiveStorage,
              fallbackTheme: fallbackTheme,
            )
            : SixThemeResolver().tema;

    return ThemeProvider(
      enableLocalPersistence: enableLocalPersistence,
      storage: effectiveStorage,
      initialTheme: initialTheme,
    );
  }

  @override
  void dispose() {
    _resolver.removeListener(_handleResolverChanged);
    super.dispose();
  }

  ThemeMode get themeMode => _resolver.themeMode;

  ThemeData get lightTheme {
    final ThemeData theme = AppTheme.getThemeWithScheme(
      _resolver.getLightScheme(),
      isDark: false,
      visualDensity: _resolver.visualDensity,
    );

    return kIsWeb ? theme : SixMobileTypography.apply(theme);
  }

  ThemeData get darkTheme {
    final ThemeData theme = AppTheme.getThemeWithScheme(
      _resolver.getDarkScheme(),
      isDark: true,
      visualDensity: _resolver.visualDensity,
    );

    return kIsWeb ? theme : SixMobileTypography.apply(theme);
  }

  Future<void> toggleTheme(bool isDarkMode) {
    return setTheme(isDarkMode ? TemaSistema.escuro : TemaSistema.claro);
  }

  Future<void> setTheme(TemaSistema tema) async {
    final TemaSistema effectiveTheme =
        _enableLocalPersistence ? _supportedLocalTheme(tema) : tema;
    if (_resolver.tema == effectiveTheme) {
      return;
    }

    _resolver.atualizarTema(effectiveTheme);

    if (!_enableLocalPersistence) {
      return;
    }

    try {
      await _storage?.writeThemeMode(effectiveTheme.name);
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar preferência local de tema: $error\n$stackTrace',
      );
    }
  }

  void _handleResolverChanged() {
    notifyListeners();
  }

  static Future<ThemePreferenceStorage?>
  _tryCreateSharedPreferencesStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return SharedPreferencesThemePreferenceStorage(prefs);
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao inicializar armazenamento local de tema: $error\n$stackTrace',
      );
      return null;
    }
  }

  static Future<TemaSistema> _readStoredTheme({
    required ThemePreferenceStorage? storage,
    required TemaSistema fallbackTheme,
  }) async {
    if (storage == null) {
      return _supportedLocalTheme(fallbackTheme);
    }

    try {
      final String? savedTheme = await storage.readThemeMode();
      return _themeFromCode(savedTheme) ?? _supportedLocalTheme(fallbackTheme);
    } catch (error, stackTrace) {
      debugPrint('Erro ao ler preferência local de tema: $error\n$stackTrace');
      return _supportedLocalTheme(fallbackTheme);
    }
  }

  static TemaSistema? _themeFromCode(String? code) {
    switch (code) {
      case 'claro':
        return TemaSistema.claro;
      case 'escuro':
        return TemaSistema.escuro;
      default:
        return null;
    }
  }

  static TemaSistema _supportedLocalTheme(TemaSistema tema) {
    return tema == TemaSistema.escuro ? TemaSistema.escuro : TemaSistema.claro;
  }
}
