import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';

void main() {
  for (final width in [390.0, 900.0, 1500.0]) {
    testWidgets(
      'filtros consultam a agenda ao selecionar e aplicar em largura $width',
      (tester) async {
        final requests = <Map<String, dynamic>>[];
        await http.runWithClient(
          () async {
            SharedPreferences.setMockInitialValues({
              'accessToken': 'test-token',
              'accessTokenExpiresAt':
                  DateTime.now().add(const Duration(days: 2)).toIso8601String(),
              'idUnicoDaEmpresa': 'test-company',
            });
            UsuarioProvider().setUsuario(
              UsuarioModel.fromJson({'nome': 'Teste'}),
            );
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create:
                    (_) => LocaleSettingsProvider(
                      regionalizacaoService: RegionalizacaoService(
                        apiClient: HttpRegionalizacaoApiClient(),
                      ),
                    ),
                child: MaterialApp(
                  theme: ThemeData.dark(),
                  locale: const Locale('pt'),
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  supportedLocales: const [Locale('pt')],
                  home: const Scaffold(
                    body: AgendaFinanceiraWeb(embedded: true),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(requests, isNotEmpty);
            final before = requests.length;
            await tester.tap(find.text('Próximos 7 dias').first);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Hoje').last);
            await tester.pumpAndSettle();
            expect(requests.length, before + 1);
            expect((requests.last['periodo'] as Map)['modo'], 'HOJE');
            final more = find.byKey(const ValueKey('agenda-more-filters'));
            await tester.ensureVisible(more);
            await tester.tap(more);
            await tester.pumpAndSettle();
            final ir = find.byKey(const ValueKey('ir-filter'));
            await tester.ensureVisible(ir);
            await tester.tap(ir);
            await tester.pumpAndSettle();
            expect(requests.length, before + 1);
            await tester.tap(
              find.byKey(const ValueKey('agenda-apply-filters')),
            );
            await tester.pumpAndSettle();
            expect(
              (requests.last['filtros'] as Map)['somenteImpostoRenda'],
              true,
            );
            expect(find.text('Mais filtros · 1'), findsOneWidget);
            final chip = find.byType(InputChip);
            await tester.ensureVisible(chip);
            await tester.tap(
              find.descendant(
                of: chip,
                matching: find.byTooltip('Remover filtro'),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              (requests.last['filtros'] as Map)['somenteImpostoRenda'],
              false,
            );
            expect(find.byType(InputChip), findsNothing);

            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
          () => MockClient((request) async {
            final path = request.url.path;
            if (path.endsWith('/consultar')) {
              requests.add(jsonDecode(request.body) as Map<String, dynamic>);
              return http.Response('{"gruposAgenda":[]}', 200);
            }
            if (path.endsWith('/valores-confirmados')) {
              return http.Response('{"itens":[]}', 200);
            }
            if (path.endsWith('/centros-custo')) {
              return http.Response('[]', 200);
            }
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
      },
    );
  }
}
