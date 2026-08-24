import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/web/six_web_atendimento_details_dialog.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows structured service details with navy backdrop', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do atendimento'), findsOneWidget);
    expect(find.text('2237 esse'), findsOneWidget);
    expect(find.text('AT-c555400dc6da4...'), findsOneWidget);
    expect(find.text('Resumo financeiro'), findsOneWidget);
    expect(find.text('Progresso do serviço'), findsOneWidget);
    expect(find.text('Receber'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes the dialog with escape in interactive state', (
    WidgetTester tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.text('Abrir detalhes'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do atendimento'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do atendimento'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHarness(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder:
              (BuildContext context) => Center(
                child: FilledButton(
                  onPressed: () {
                    showSixWebAtendimentoDetailsDialog(
                      context: context,
                      equipmentTitle: '2237 esse',
                      attendanceNumber: 'AT-c555400dc6da4...',
                      customerLabel: 'Tatiana Cordeiro',
                      technicianLabel: 'Esse nao pode vender',
                      accentColor: const Color(0xFF0F766E),
                      accentIcon: Icons.devices_other_outlined,
                      summaryMetrics: const <SixWebAtendimentoDetailsMetric>[
                        SixWebAtendimentoDetailsMetric(
                          label: 'Status',
                          value: 'Em execução',
                          icon: Icons.flag_outlined,
                        ),
                        SixWebAtendimentoDetailsMetric(
                          label: 'Total',
                          value: 'R\$ 650,00',
                          icon: Icons.payments_outlined,
                        ),
                        SixWebAtendimentoDetailsMetric(
                          label: 'Aberto',
                          value: 'R\$ 60,00',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        SixWebAtendimentoDetailsMetric(
                          label: 'Entrega',
                          value: '11/08/2026',
                          icon: Icons.assignment_turned_in_outlined,
                        ),
                        SixWebAtendimentoDetailsMetric(
                          label: 'Validade',
                          value: '08/08/2026',
                          icon: Icons.event_available_outlined,
                        ),
                      ],
                      statusChips: const <Widget>[
                        Chip(label: Text('Em aberto')),
                        Chip(label: Text('3 item(ns)')),
                        Chip(label: Text('Atualização 11/08/2026')),
                      ],
                      actionContent: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Receber'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Editar'),
                          ),
                        ],
                      ),
                      progressContent: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('Progresso do serviço'),
                      ),
                      detailsContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Resumo financeiro'),
                                SizedBox(height: 8),
                                Text('Total: R\$ 650,00'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Abrir detalhes'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
