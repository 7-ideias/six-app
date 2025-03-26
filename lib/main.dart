import 'package:appplanilha/core/services/websocket_service.dart';
import 'package:appplanilha/login_page_mobile.dart';
import 'package:appplanilha/providers/BaseProviderParaListas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/produto_service.dart';
import 'data/models/produto_model.dart';
import 'design_system/themes/app_theme.dart';
import 'login_page_web.dart';
import 'on_boarding.dart';
import 'providers/theme_provider.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedLanguage = prefs.getString('selectedLanguage');
  Locale initialLocale = savedLanguage != null
      ? Locale(savedLanguage.split("_")[0], savedLanguage.split("_")[1])
      : Locale('en', 'US');

  bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              BaseProviderParaListas<ProdutoModel>(
                fetchFunction: ProdutoService().ProdutosList,
              ),
        ),
      ],
      child: MyApp(
        initialLocale: initialLocale,
        hasSeenOnboarding: hasSeenOnboarding,
      ),
    ),
  );
  connectStomp();
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

  // late final GoRouter _router = GoRouter(
  //   routes: [
  //     GoRoute(
  //       path: '/catalogo/:slug',
  //       builder: (context, state) {
  //         final slug = state.pathParameters['slug']!;
  //         return CatalogoPage(slug: slug);
  //       },
  //     ),
  //     // Rota principal
  //     GoRoute(
  //       path: '/',
  //       builder: (context, state) => widget.hasSeenOnboarding
  //           ? kIsWeb
  //           ? LoginPageWeb()
  //           : LoginPageMobile()
  //           : OnboardingScreen(),
  //     ),
  //   ],
  // );

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
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.hasSeenOnboarding ? kIsWeb ? LoginPageWeb() : LoginPageMobile() : OnboardingScreen(),
    );
  }
}

// 🔹 Tela simples para exibir o catálogo (mock)
class CatalogoPage extends StatelessWidget {
  final String slug;

  const CatalogoPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catálogo de $slug')),
      body: Center(child: Text('Exibir catálogo para: $slug')),
    );
  }
}
