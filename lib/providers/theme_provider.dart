import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/themes/app_colors.dart';
import '../design_system/themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppPalette _currentPalette = AppPalette.corporate;

  ThemeMode get themeMode => _themeMode;
  AppPalette get currentPalette => _currentPalette;

  ThemeData get lightTheme => AppTheme.getTheme(_currentPalette, isDark: false);
  ThemeData get darkTheme => AppTheme.getTheme(_currentPalette, isDark: true);

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  void setPalette(AppPalette palette) async {
    _currentPalette = palette;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedPalette', palette.index);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Carregar Dark Mode
    bool isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Carregar Paleta
    int paletteIndex = prefs.getInt('selectedPalette') ?? AppPalette.corporate.index;
    _currentPalette = AppPalette.values[paletteIndex];

    notifyListeners();
  }
}
