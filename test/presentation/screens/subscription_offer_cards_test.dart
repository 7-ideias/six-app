import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/subscription_billing.dart';
import 'package:sixpos/presentation/screens/subscription_mobile_screen.dart';
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

void main() {
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
  for (final theme in [ThemeData.light(), ThemeData.dark()]) {
    testWidgets(
      'Account dialog shows usage and returns to opener in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
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
