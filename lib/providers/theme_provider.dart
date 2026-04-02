import 'package:flutter/material.dart';
import '../design_system/helpers/six_theme_resolver.dart';
import '../design_system/themes/app_colors.dart';
import '../design_system/themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadTheme();
    // Ouve o SixThemeResolver para propagar mudanças
    SixThemeResolver().addListener(notifyListeners);
  }

  @override
  void dispose() {
    SixThemeResolver().removeListener(notifyListeners);
    super.dispose();
  }

  ThemeMode get themeMode => SixThemeResolver().themeMode;

  ThemeData get lightTheme {
    final resolver = SixThemeResolver();
    return AppTheme.getThemeWithScheme(
      resolver.getLightScheme(),
      isDark: false,
    );
  }

  ThemeData get darkTheme {
    final resolver = SixThemeResolver();
    return AppTheme.getThemeWithScheme(
      resolver.getDarkScheme(),
      isDark: true,
    );
  }

  void toggleTheme(bool isDarkMode) async {
    // Esta lógica pode precisar ser adaptada se quisermos salvar no backend via SixThemeResolver
    // Por enquanto, apenas para compatibilidade
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    // Implementação futura: carregar do backend ou localmente via SixThemeResolver
  }
}
