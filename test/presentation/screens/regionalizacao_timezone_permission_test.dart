import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/screens/regionalizacao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/regionalizacao_configuracao_content.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class _Api implements RegionalizacaoApiClient {
  _Api(this.admin);
  final bool admin;
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async =>
      ConfiguracaoRegionalizacaoResponse.fromJson({
        'timeZone': 'America/Sao_Paulo',
        'podeAlterarFusoHorario': admin,
      });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final mobile in [true, false]) {
    for (final admin in [true, false]) {
      testWidgets(
        'fuso ${mobile ? 'mobile' : 'web'} permite escolha somente com autorização da empresa: $admin',
        (tester) async {
          final provider = LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _Api(admin),
            ),
          );
          addTearDown(provider.dispose);
          await tester.binding.setSurfaceSize(Size(mobile ? 390 : 1200, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: provider,
              child: MaterialApp(
                home:
                    mobile
                        ? const RegionalizacaoMobileScreen()
                        : const Scaffold(
                          body: RegionalizacaoConfiguracaoContent(),
                        ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          final zone = find.byKey(const ValueKey('company-time-zone'));
          expect(zone, findsOneWidget);
          final controls = tester.widgetList<InkWell>(
            find.descendant(of: zone, matching: find.byType(InkWell)),
          );
          expect(controls, isNotEmpty);
          expect(controls.every((control) => control.onTap != null), admin);
          if (!admin) expect(controls.length, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
