import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../design_system/helpers/six_theme_resolver.dart';
import '../design_system/themes/app_theme.dart';
import '../design_system/themes/six_mobile_typography.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadTheme();
    SixThemeResolver().addListener(notifyListeners);
  }

  @override
  void dispose() {
    SixThemeResolver().removeListener(notifyListeners);
    super.dispose();
  }

  ThemeMode get themeMode => SixThemeResolver().themeMode;

  ThemeData get lightTheme {
    final SixThemeResolver resolver = SixThemeResolver();
    final ThemeData theme = AppTheme.getThemeWithScheme(
      resolver.getLightScheme(),
      isDark: false,
      visualDensity: resolver.visualDensity,
    );

    return kIsWeb ? theme : SixMobileTypography.apply(theme);
  }

  ThemeData get darkTheme {
    final SixThemeResolver resolver = SixThemeResolver();
    final ThemeData theme = AppTheme.getThemeWithScheme(
      resolver.getDarkScheme(),
      isDark: true,
      visualDensity: resolver.visualDensity,
    );

    return kIsWeb ? theme : SixMobileTypography.apply(theme);
  }

  void toggleTheme(bool isDarkMode) async {
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    // Implementação futura: carregar do backend ou localmente.
  }
}
