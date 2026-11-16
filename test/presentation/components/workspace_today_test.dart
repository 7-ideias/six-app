import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';
import 'package:sixpos/presentation/components/mobile/workspace_today_mobile.dart';
import 'package:sixpos/presentation/components/web/workspace_today_web.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/workspace_home_provider.dart';

void main() {
  for (final mobile in [true, false]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${mobile ? 'mobile' : 'web'} $brightness text scale $scale',
          (tester) async {
            tester.view.physicalSize = Size(mobile ? 360 : 1280, 1100);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final provider = WorkspaceHomeProvider(service: _HomeService());
            final locale = LocaleSettingsProvider(
              regionalizacaoService: RegionalizacaoService(
                apiClient: HttpRegionalizacaoApiClient(),
              ),
            );
            addTearDown(provider.dispose);
            addTearDown(locale.dispose);
            await provider.load();
            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: locale,
                child: MaterialApp(
                  theme: ThemeData(brightness: brightness),
                  locale: const Locale('pt', 'BR'),
                  supportedLocales: const [Locale('pt', 'BR')],
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: Builder(
                    builder:
                        (context) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                            disableAnimations: true,
                          ),
                          child: Scaffold(
                            body: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child:
                                    mobile
                                        ? WorkspaceTodayMobile(
                                          provider: provider,
                                          companyName: 'Oficina Michelli',
                                          onOpen: (_) {},
                                          onSale: () {},
                                          onService: () {},
                                          onReceive: () {},
                                        )
                                        : WorkspaceTodayWeb(
                                          provider: provider,
                                          companyName: 'Oficina Michelli',
                                          onOpen: (_) {},
                                        ),
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Meu dia'), findsOneWidget);
            expect(find.text('A receber hoje'), findsOneWidget);
            expect(find.text('Recebimentos atrasados'), findsOneWidget);
            expect(find.text('Caixa aberto'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

class _HomeService implements WorkspaceHomeService {
  @override
  Future<WorkspaceHomeModel> buscarHome() async => WorkspaceHomeModel.fromJson({
    'date': '2026-11-16',
    'timeZone': 'America/Sao_Paulo',
    'cash': {'available': true, 'open': true},
    'financial': {
      'available': true,
      'receivableToday': {'count': 7, 'amount': 1234567.89},
      'payableToday': {'count': 2, 'amount': 100},
      'overdueReceivable': {'count': 1, 'amount': 10},
      'overduePayable': {'count': 0, 'amount': 0},
    },
    'technicalServices': {
      'available': true,
      'active': 8,
      'late': 2,
      'waitingApproval': 3,
      'readyForPickup': 1,
    },
    'stock': {
      'available': true,
      'belowMinimum': 2,
      'negative': 0,
      'withoutStock': 1,
    },
    'reservations': {'available': true, 'received': 2, 'inReview': 1},
  });
}
