import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/subscription_billing.dart';
import 'package:sixpos/presentation/screens/billing_access_web_page.dart';
import 'package:sixpos/presentation/screens/subscription_mobile_screen.dart';
import 'package:sixpos/presentation/screens/configuracoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/subscription_web_page.dart';
import 'package:sixpos/presentation/theme/subscription_visuals.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/presentation/screens/storage_usage_web_page.dart';

class Regionalization extends ChangeNotifier implements LocaleSettingsProvider {
  @override
  Locale get currentLocale => const Locale('en', 'US');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AccountPermissions extends ColaboradorAutorizacoesProvider {
  AccountPermissions(this.profile, {this.superUser = false});
  final String profile;
  final bool superUser;
  @override
  String get tipoPerfilUsuario => profile;
  @override
  bool get ehSuperUsuario => superUser;
}

void main() {
  test('plan visibility requires an explicit admin profile or SUPER', () {
    expect(AccountPermissions('ADMIN').podeConsultarPlanoEConsumo, isTrue);
    expect(
      AccountPermissions(
        'DESCONHECIDO',
        superUser: true,
      ).podeConsultarPlanoEConsumo,
      isTrue,
    );
    expect(
      AccountPermissions('COLABORADOR').podeConsultarPlanoEConsumo,
      isFalse,
    );
    expect(
      AccountPermissions('DESCONHECIDO').podeConsultarPlanoEConsumo,
      isFalse,
    );
  });
  testWidgets(
    'direct subscription route hides billing and usage for a collaborator',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
          create: (_) => AccountPermissions('COLABORADOR'),
          child: const MaterialApp(home: SubscriptionWebPage()),
        ),
      );
      expect(find.byType(SubscriptionWebPanel), findsNothing);
      expect(find.byType(StorageUsageWebPage), findsNothing);
      expect(
        find.text('You do not have permission for this action.'),
        findsOneWidget,
      );
    },
  );
  const offer = BillingOffer(
    planId: 'pro',
    name: 'Professional',
    interval: 'year',
    currency: 'USD',
    amountMinor: 100,
    description: 'Your business',
    benefits: ['Inventory', 'Technical services'],
    featured: true,
  );
  testWidgets('mobile settings hide both entries for collaborators', (
    tester,
  ) async {
    for (final profile in ['COLABORADOR', 'ADMIN']) {
      await tester.pumpWidget(
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
          key: ValueKey(profile),
          create: (_) => AccountPermissions(profile),
          child: const MaterialApp(home: ConfiguracoesMobileScreen()),
        ),
      );
      final expected = profile == 'ADMIN' ? findsOneWidget : findsNothing;
      expect(find.text('Plans and payment'), expected);
      expect(find.text('Storage'), expected);
    }
  });
  for (final theme in [ThemeData.light(), ThemeData.dark()]) {
    testWidgets('billing gate inherits the ${theme.brightness} workspace', (
      tester,
    ) async {
      final themed = WebThemeTokens.applyTo(theme);
      await tester.pumpWidget(
        ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
          create: (_) => AccountPermissions('COLABORADOR'),
          child: MaterialApp(
            theme: themed,
            home: const BillingAccessWebPage(companyId: 'test'),
          ),
        ),
      );
      final title = find.text('Restore business access');
      final context = tester.element(title);
      expect(Theme.of(context).brightness, theme.brightness);
      final tokens = WebThemeTokens.resolve(theme);
      expect(
        context.findAncestorWidgetOfExactType<Material>()!.color,
        tokens.workspaceBackground,
      );
      expect(tester.widget<Text>(title).style?.color, tokens.primaryText);
    });
    testWidgets(
      'Account dialog shows usage and returns to opener in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ColaboradorAutorizacoesProvider>(
                create: (_) => AccountPermissions('ADMIN'),
              ),
              ChangeNotifierProvider<LocaleSettingsProvider>(
                create: (_) => Regionalization(),
              ),
              ChangeNotifierProvider<EmpresaProvider>.value(
                value: EmpresaProvider(),
              ),
            ],
            child: MaterialApp(
              theme: theme,
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => showSubscriptionWebDialog(context),
                        child: const Text('Open'),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(StorageUsageWebPage), findsOneWidget);
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.foregroundColor, WebThemeTokens.resolve(theme).primaryText);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }
  for (final mobile in [true, false]) {
    for (final theme
        in mobile
            ? [ThemeData.dark()]
            : [ThemeData.dark(), ThemeData.light()]) {
      testWidgets(
        'catalog content and accessible CTA on ${mobile ? 'mobile' : 'web'} ${theme.brightness}',
        (tester) async {
          final regionalization = Regionalization();
          addTearDown(regionalization.dispose);
          var taps = 0;
          await tester.pumpWidget(
            ChangeNotifierProvider<LocaleSettingsProvider>.value(
              value: regionalization,
              child: MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 280,
                      child: SingleChildScrollView(
                        child:
                            mobile
                                ? SubscriptionOfferMobileCard(
                                  offer: offer,
                                  selected: false,
                                  onSubscribe: () => taps++,
                                )
                                : SubscriptionOfferWebCard(
                                  offer: offer,
                                  selected: false,
                                  onSubscribe: () => taps++,
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Professional'), findsOneWidget);
          if (!mobile) {
            final primary = WebThemeTokens.resolve(theme).primaryText;
            expect(
              tester.widget<Text>(find.text('Professional')).style?.color,
              primary,
            );
            expect(
              tester.widget<Text>(find.textContaining('1.00')).style?.color,
              primary,
            );
          }
          expect(find.text('Your business'), findsOneWidget);
          expect(find.text('Inventory'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color ==
                      (mobile
                          ? SubscriptionVisuals.highlightedSurface
                          : WebThemeTokens.resolve(theme).selectedBackground),
            ),
            findsOneWidget,
          );
          await tester.ensureVisible(find.byType(FilledButton));
          await tester.tap(find.byType(FilledButton));
          expect(taps, 1);
        },
      );
    }
  }
}
