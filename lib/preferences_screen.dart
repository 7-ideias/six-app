import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:appplanilha/theme_provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'main.dart';

class PreferencesScreen extends StatefulWidget {
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  Locale? _selectedLocale;
  bool _isDarkMode = false;

  final List<Map<String, dynamic>> _languages = [
    {"name": "English", "locale": Locale("en", "US"), "flag": "🇺🇸"},
    {"name": "Português", "locale": Locale("pt", "BR"), "flag": "🇧🇷"},
    {"name": "Español", "locale": Locale("es", "ES"), "flag": "🇪🇸"},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Carrega as preferências salvas do usuário (idioma e tema)
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('selectedLanguage');
    bool? savedTheme = prefs.getBool('darkMode');

    setState(() {
      _selectedLocale = savedLanguage != null
          ? Locale(savedLanguage.split("_")[0], savedLanguage.split("_")[1])
          : Locale('en', 'US');
      _isDarkMode = savedTheme ?? false;
    });
  }

  /// Atualiza e salva o idioma escolhido pelo usuário e força a atualização do `MaterialApp`
  Future<void> _changeLanguage(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', locale.toString());

    setState(() {
      _selectedLocale = locale;
    });

    // 🔄 Atualiza o idioma no `MaterialApp`
    MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
    appState?.updateLocale(locale);
  }

  /// Alterna entre modo escuro e claro
  Future<void> _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    setState(() {
      _isDarkMode = value;
    });

    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
  }

  @override
  Widget build(BuildContext context) {

    if (_selectedLocale == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('preferences_title')),
      // ✅ Tradução
      // appBar: AppBar(title: Text(AppLocalizations.of(context)!.preferences_title)), // ✅ Tradução
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('preferences_title'),
            // ✅ Tradução
            // title: Text(AppLocalizations.of(context)!.preferences_language), // ✅ Tradução
            subtitle: Text(
              _languages.firstWhere((element) => element['locale'] == _selectedLocale)['name'],
            ),
            trailing: PopupMenuButton<Locale>(
              onSelected: _changeLanguage,
              itemBuilder: (BuildContext context) {
                return _languages.map((Map<String, dynamic> language) {
                  return PopupMenuItem<Locale>(
                    value: language["locale"],
                    child: Text("${language['flag']} ${language['name']}"),
                  );
                }).toList();
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode),,
            title: Text('preferences_dark_mode'),
            // ✅ Tradução
            // title: Text(AppLocalizations.of(context)!.preferences_dark_mode), // ✅ Traduçãtrailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}
