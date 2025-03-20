import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'on_boarding.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedLanguage = prefs.getString('selectedLanguage');
  Locale initialLocale = savedLanguage != null
      ? Locale(savedLanguage.split("_")[0], savedLanguage.split("_")[1])
      : Locale('en', 'US');

  bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(initialLocale: initialLocale, hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.initialLocale, required this.hasSeenOnboarding});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  /// 🔄 Atualiza o idioma globalmente
  void updateLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: _locale,
      supportedLocales: [
        Locale('en', 'US'),
        Locale('pt', 'BR'),
        Locale('es', 'ES'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.hasSeenOnboarding ? LoginPage() : OnboardingScreen(),
    );
  }
}
