import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/subscription_billing.dart';
import 'package:sixpos/presentation/screens/subscription_mobile_screen.dart';
import 'package:sixpos/presentation/screens/subscription_web_page.dart';
import 'package:sixpos/presentation/theme/subscription_visuals.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

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
  for (final mobile in [true, false]) {
    testWidgets(
      'catalog content and accessible CTA on ${mobile ? 'mobile' : 'web'}',
      (tester) async {
        final regionalization = Regionalization();
        addTearDown(regionalization.dispose);
        var taps = 0;
        await tester.pumpWidget(
          ChangeNotifierProvider<LocaleSettingsProvider>.value(
            value: regionalization,
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 280,
                    child: SingleChildScrollView(
                      child: mobile
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
                    SubscriptionVisuals.highlightedSurface,
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
