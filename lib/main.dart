import 'package:appplanilha/core/services/websocket_service.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:appplanilha/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:appplanilha/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:appplanilha/presentation/screens/login_mobile.dart';
import 'package:appplanilha/presentation/screens/login_page_web.dart';
import 'package:appplanilha/presentation/screens/on_boarding_screen.dart';
import 'package:appplanilha/presentation/screens/cliente_auto_cadastro_publico_page.dart';
import 'package:appplanilha/presentation/screens/on_boarding_screen.dart';
import 'package:appplanilha/presentation/screens/ordem_servico_publica_page.dart';
import 'package:appplanilha/providers/empresa_provider.dart';
import 'package:appplanilha/providers/locale_settings_provider.dart';
import 'package:appplanilha/providers/produtos_list_provider.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:appplanilha/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/produto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  Widget _resolveInitialPage() {
    if (kIsWeb) {
      final Uri currentUri = Uri.base;
      final bool isPublicOsRoute =
          currentUri.pathSegments.isNotEmpty &&
          currentUri.pathSegments.first == 'ordem-servico';
      final bool isPublicClienteAutoCadastroRoute =
          currentUri.pathSegments.length >= 2 &&
          currentUri.pathSegments[0] == 'cliente' &&
          currentUri.pathSegments[1] == 'auto-cadastro';

      if (isPublicClienteAutoCadastroRoute) {
        return ClienteAutoCadastroPublicoPage(initialUri: currentUri);
      }

      if (isPublicOsRoute) {
        final String ordemId =
            currentUri.pathSegments.length > 1
                ? currentUri.pathSegments[1]
                : 'os-sem-id';

        return OrdemServicoPublicaPage(
          ordemId: ordemId,
          initialUri: currentUri,
        );
      }

      return const LoginPageWeb();
    }

    return hasSeenOnboarding ? const LoginPageMobile() : OnboardingScreen();
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
      home: _resolveInitialPage(),
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
