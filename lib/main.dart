import 'dart:async';

import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/pagina_principal_web.dart';
import 'package:sixpos/presentation/screens/admin_portal_web_page.dart';
import 'package:sixpos/presentation/screens/admin_novas_ideias_web_page.dart';
import 'package:sixpos/presentation/screens/admin_usuarios_ativos_web_page.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';
import 'package:sixpos/presentation/screens/register_page_web.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_web.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_publico_page.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_publico_web_page.dart';
import 'package:sixpos/presentation/screens/ordem_servico_publica_page.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_assinatura_publica_page.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_status_publico_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/status_atendimento_tecnico_config_web_page.dart';
import 'package:sixpos/presentation/screens/web_auth_gate.dart';
import 'package:sixpos/presentation/pages/web_root/web_root_page.dart';
import 'package:sixpos/presentation/screens/web_checkout_page.dart';
import 'package:sixpos/presentation/screens/web_trial_onboarding_page.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_theme_transition_overlay.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/streak_provider.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:sixpos/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/firebase_push_notification_service.dart';

import 'core/services/produto_service.dart';
import 'core/ui/app_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  final SharedPreferences? prefs = await _loadSharedPreferences();
  final hasSeenOnboarding = prefs?.getBool('hasSeenOnboarding') ?? false;
  final ThemeProvider themeProvider = await ThemeProvider.load(
    enableLocalPersistence: !kIsWeb,
    storage:
        prefs == null ? null : SharedPreferencesThemePreferenceStorage(prefs),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(
          create:
              (_) => ProdutosListProvider<ProdutoModel>(
                fetchFunction: ProdutoService().produtosList,
              ),
        ),
        ChangeNotifierProvider(create: (_) => EmpresaProvider()),
        ChangeNotifierProvider(
          create: (_) => ColaboradorAutorizacoesProvider(),
        ),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
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

Future<SharedPreferences?> _loadSharedPreferences() async {
  try {
    return SharedPreferences.getInstance();
  } catch (error, stackTrace) {
    debugPrint('Erro ao inicializar SharedPreferences: $error\n$stackTrace');
    return null;
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

    if (routeUri.path == '/' || routeUri.path == '/home') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const WebRootPage(),
      );
    }
    if (routeUri.path == '/login') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPageWeb(),
      );
    }
    if (routeUri.path == '/admin') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPageWeb(),
      );
    }
    if (routeUri.path == '/admin/dashboard') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminPortalWebPage(),
      );
    }
    if (routeUri.path == '/admin/usuarios') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminUsuariosAtivosWebPage(),
      );
    }
    if (routeUri.path == '/admin/novas-ideias') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminNovasIdeiasWebPage(),
      );
    }
    if (routeUri.path == '/register') {
      return _slidePageRoute(settings: settings, page: const RegisterPageWeb());
    }
    if (routeUri.path == '/forgot-password') {
      return _slidePageRoute(
        settings: settings,
        page: const EsqueceuSenhaWeb(),
      );
    }
    if (routeUri.path == '/app') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(),
      );
    }
    if (routeUri.path == '/app/atendimentos-tecnicos') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const AtendimentosTecnicosWebPage(),
      );
    }
    if (routeUri.path == '/app/atendimentos-tecnicos/criados') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const AtendimentosTecnicosListaWebPage(),
      );
    }
    if (routeUri.path == '/app/configuracoes/status-atendimento-tecnico') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const StatusAtendimentoTecnicoConfigWebPage(),
      );
    }
    if (routeUri.path == '/atendimento/assinatura') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder:
            (_) =>
                AtendimentoTecnicoAssinaturaPublicaPage(initialUri: routeUri),
      );
    }
    if (routeUri.path == '/atendimento/status') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder:
            (_) => AtendimentoTecnicoStatusPublicoPage(initialUri: routeUri),
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
    final bool isPublicColaboradorConviteRoute =
        routeUri.pathSegments.length >= 3 &&
        routeUri.pathSegments[0] == 'colaborador' &&
        routeUri.pathSegments[1] == 'convites';

    if (isPublicColaboradorConviteRoute) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder:
            (_) => ColaboradorConvitePublicoWebPage(
              codigo: routeUri.pathSegments[2],
              initialUri: routeUri,
            ),
      );
    }
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

    if (isAuthenticatedWebAppRoute(routeUri)) {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const WebRootPage(),
    );
  }

  MaterialPageRoute<void> _authenticatedWebRoute({
    required RouteSettings settings,
    required Widget page,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder:
          (_) => WebAuthGate(requestedLocation: settings.name, child: page),
    );
  }

  PageRouteBuilder<void> _slidePageRoute({
    required RouteSettings settings,
    required Widget page,
  }) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        );
        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleSettingsProvider>();

    return MaterialApp(
      scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
      onGenerateTitle:
          (context) => AppLocalizations.of(context)?.appTitle ?? 'Six',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeAnimationDuration:
          kIsWeb ? kThemeAnimationDuration : const Duration(milliseconds: 320),
      themeAnimationCurve: kIsWeb ? Curves.linear : Curves.easeOutCubic,
      builder: (BuildContext context, Widget? child) {
        final Widget resolvedChild = child ?? const SizedBox.shrink();
        if (kIsWeb) return resolvedChild;
        return SixMobileThemeTransitionOverlay(child: resolvedChild);
      },
      locale: localeProvider.currentLocale,
      supportedLocales: LocaleSettingsProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: kIsWeb ? null : SplashScreen(hasSeenOnboarding: hasSeenOnboarding),
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
