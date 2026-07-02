import 'dart:async';

import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/pdv_page_web.dart';
import 'package:sixpos/presentation/screens/auth_gate_mobile.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';
import 'package:sixpos/presentation/screens/register_page_web.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_web.dart';
import 'package:sixpos/presentation/screens/on_boarding_screen.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_publico_page.dart';
import 'package:sixpos/presentation/screens/ordem_servico_publica_page.dart';
import 'package:sixpos/presentation/pages/web_root/web_root_page.dart';
import 'package:sixpos/presentation/screens/web_checkout_page.dart';
import 'package:sixpos/presentation/screens/web_trial_onboarding_page.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/firebase_push_notification_service.dart';

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

  if (!kIsWeb) {
    unawaited(FirebasePushNotificationService.initializeOnAppStart());
  }
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

    if (!kIsWeb) {
      return MaterialPageRoute(
        builder: (_) => AuthGateMobile(hasSeenOnboarding: hasSeenOnboarding),
        settings: settings,
      );
    }

    if (routeUri.path == '/cliente') {
      return MaterialPageRoute(
        builder: (_) => ClienteAutoCadastroPublicoPage(uri: routeUri),
        settings: settings,
      );
    }

    if (routeUri.path == '/os') {
      return MaterialPageRoute(
        builder: (_) => OrdemServicoPublicaPage(uri: routeUri),
        settings: settings,
      );
    }

    if (routeUri.path == '/checkout') {
      return MaterialPageRoute(
        builder: (_) => WebCheckoutPage(uri: routeUri),
        settings: settings,
      );
    }

    if (routeUri.path == '/trial') {
      return MaterialPageRoute(
        builder: (_) => WebTrialOnboardingPage(uri: routeUri),
        settings: settings,
      );
    }

    switch (routeUri.path) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginPageWeb(),
          settings: settings,
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterPageWeb(),
          settings: settings,
        );
      case '/esqueceu-senha':
        return MaterialPageRoute(
          builder: (_) => const EsqueceuSenhaWeb(),
          settings: settings,
        );
      case '/pdv':
        return MaterialPageRoute(
          builder: (_) => const PDVPageWeb(),
          settings: settings,
        );
      case '/':
      case '':
        return MaterialPageRoute(
          builder: (_) => const WebRootPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const WebRootPage(),
          settings: settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleSettingsProvider>(
      builder: (context, themeProvider, localeSettings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Six',
          theme: themeProvider.themeData,
          locale: localeSettings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: kIsWeb ? _resolveInitialWebRoute() : '/',
          onGenerateRoute: _onGenerateWebRoute,
        );
      },
    );
  }
}
