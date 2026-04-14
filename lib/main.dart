import 'package:appplanilha/core/services/websocket_service.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:appplanilha/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:appplanilha/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:appplanilha/presentation/screens/login_mobile.dart';
import 'package:appplanilha/presentation/screens/login_page_web.dart';
import 'package:appplanilha/presentation/screens/on_boarding_screen.dart';
import 'package:appplanilha/presentation/screens/cliente_auto_cadastro_publico_page.dart';
import 'package:appplanilha/presentation/screens/ordem_servico_publica_page.dart';
import 'package:appplanilha/presentation/screens/web_checkout_page.dart';
import 'package:appplanilha/presentation/screens/web_home_page.dart';
import 'package:appplanilha/presentation/screens/web_trial_onboarding_page.dart';
import 'package:appplanilha/providers/empresa_provider.dart';
import 'package:appplanilha/providers/locale_settings_provider.dart';
import 'package:appplanilha/providers/produtos_list_provider.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:appplanilha/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/produto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create:
              (_) => ProdutosListProvider<ProdutoModel>(
                fetchFunction: ProdutoService().produtosList,
              ),
        ),
        ChangeNotifierProvider(create: (_) => EmpresaProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create:
              (_) => LocaleSettingsProvider(
                regionalizacaoService: RegionalizacaoService(
                  apiClient: HttpRegionalizacaoApiClient(),
                ),
              )..initialize(),
        ),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );

  connectStomp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;

  String _resolveInitialWebRoute() {
    final Uri currentUri = Uri.base;
    final String path = currentUri.path.isEmpty ? '/' : currentUri.path;
    final String query = currentUri.hasQuery ? '?${currentUri.query}' : '';
    return '$path$query';
  }

  Route<dynamic> _onGenerateWebRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';
    final Uri routeUri = Uri.parse(routeName);

    if (routeUri.path == '/' || routeUri.path == '/home') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const WebHomePage(),
      );
    }

    if (routeUri.path == '/login') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPageWeb(),
      );
    }

    if (routeUri.path == '/onboarding') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => WebTrialOnboardingPage(initialUri: routeUri),
      );
    }

    if (routeUri.path == '/checkout') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => WebCheckoutPage(initialUri: routeUri),
      );
    }

    final bool isPublicOsRoute =
        routeUri.pathSegments.isNotEmpty &&
        routeUri.pathSegments.first == 'ordem-servico';
    final bool isPublicClienteAutoCadastroRoute =
        routeUri.pathSegments.length >= 2 &&
        routeUri.pathSegments[0] == 'cliente' &&
        routeUri.pathSegments[1] == 'auto-cadastro';

    if (isPublicClienteAutoCadastroRoute) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ClienteAutoCadastroPublicoPage(initialUri: routeUri),
      );
    }

    if (isPublicOsRoute) {
      final String ordemId =
          routeUri.pathSegments.length > 1
              ? routeUri.pathSegments[1]
              : 'os-sem-id';

      return MaterialPageRoute<void>(
        settings: settings,
        builder:
            (_) =>
                OrdemServicoPublicaPage(ordemId: ordemId, initialUri: routeUri),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const WebHomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleSettingsProvider>();

    return MaterialApp(
      onGenerateTitle:
          (context) => AppLocalizations.of(context)?.appTitle ?? 'Six',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      locale: localeProvider.currentLocale,
      supportedLocales: LocaleSettingsProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home:
          kIsWeb
              ? null
              : (hasSeenOnboarding
                  ? const LoginPageMobile()
                  : OnboardingScreen()),
      initialRoute: kIsWeb ? _resolveInitialWebRoute() : null,
      onGenerateRoute: kIsWeb ? _onGenerateWebRoute : null,
    );
  }
}

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appTitle = l10n?.appTitle ?? 'Six';

    return Scaffold(
      appBar: AppBar(title: Text('$appTitle - $slug')),
      body: Center(child: Text('Catálogo: $slug')),
    );
  }
}
