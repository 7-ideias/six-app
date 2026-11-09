import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/storage_plan.dart';
import 'package:sixpos/data/services/storage/storage_usage_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/controllers/storage_plans_controller.dart';
import 'package:sixpos/presentation/screens/storage_plans_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class _Auth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Locale extends ChangeNotifier implements LocaleSettingsProvider {
  @override
  String formatDecimal(num value) => value.toString();
  @override
  Locale get currentLocale => const Locale('en', 'US');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller extends StoragePlansController {
  _Controller()
    : super(
        companyId: 'a',
        client: StorageUsageApiClient(
          auth: _Auth(),
          client: MockClient((_) async => http.Response('[]', 200)),
        ),
      ) {
    loaded = true;
    plans = [
      const StoragePlan(
        id: 'pro',
        code: 'PRO',
        status: 'PUBLICADO',
        names: {},
        limits: StorageLimits(fileLimitBytes: 1000000),
      ),
    ];
  }
  @override
  Future<void> load() async {}
}

void main() {
  testWidgets(
    'dark storage management uses semantic surfaces and visible actions',
    (tester) async {
      final locale = _Locale();
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<LocaleSettingsProvider>.value(
          value: locale,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: StoragePlansMobileScreen(
              companyId: 'a',
              controller: _Controller(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('Plans and allowances'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  SixMobileColorScheme.dark.surface,
        ),
        findsWidgets,
      );
    },
  );
}
