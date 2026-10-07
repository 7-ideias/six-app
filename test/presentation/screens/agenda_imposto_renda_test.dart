import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_comprovante_picker.dart';
import 'package:sixpos/data/models/agenda_imposto_renda.dart';
import 'package:sixpos/presentation/components/mobile/agenda_imposto_renda_mobile_fields.dart';
import 'package:sixpos/presentation/components/web/agenda_imposto_renda_web_fields.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aM1sAAAAASUVORK5CYII=';

class _Picker extends AgendaComprovantePicker {
  @override
  Future<AgendaComprovanteIr?> selecionar({bool camera = false}) async =>
      AgendaComprovanteIr(nome: 'recibo.png', conteudoBase64: _png);
}

void main() {
  test('reabre dados persistidos e envia remoção explícita', () {
    final draft = AgendaImpostoRenda.fromJson({
      'dadosEdicao': {
        'separarImpostoRenda': true,
        'comprovantesImpostoRenda': [
          {'nome': 'recibo.png', 'conteudoBase64': _png},
        ],
      },
    });
    expect(draft.marcado, isTrue);
    expect(draft.comprovantes.single.nome, 'recibo.png');
    expect(
      AgendaComprovanteIr.imagemValida(draft.comprovantes.single.bytes),
      isTrue,
    );
    draft.marcado = false;
    draft.comprovantes.clear();
    expect(draft.toPayload(), {
      'atualizarImpostoRenda': true,
      'separarImpostoRenda': false,
      'comprovantesImpostoRenda': [],
    });
  });

  for (final web in [true, false]) {
    testWidgets('$web: marca, anexa, visualiza e remove comprovante', (
      tester,
    ) async {
      final draft = AgendaImpostoRenda();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) => SingleChildScrollView(
                child: web
                    ? AgendaImpostoRendaWebFields(
                        draft: draft,
                        picker: _Picker(),
                        onChanged: () => setState(() {}),
                      )
                    : AgendaImpostoRendaMobileFields(
                        draft: draft,
                        picker: _Picker(),
                        onChanged: () => setState(() {}),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('ir-mark')));
      await tester.pumpAndSettle();
      expect(draft.marcado, isTrue);
      await tester.tap(find.byKey(const ValueKey('ir-add')));
      await tester.pumpAndSettle();
      expect(find.text('recibo.png'), findsOneWidget);
      expect(draft.carregando, isFalse);
      expect(draft.toPayload()['comprovantesImpostoRenda'], hasLength(1));
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(draft.comprovantes, isEmpty);
      expect(tester.takeException(), isNull);
    });
    testWidgets('$web: detalhe permite visualizar sem alterar marcação', (
      tester,
    ) async {
      final draft = AgendaImpostoRenda()..marcado = true;
      draft.comprovantes.add(
        AgendaComprovanteIr(nome: 'recibo.png', conteudoBase64: _png),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: web
                ? AgendaImpostoRendaWebFields(
                    draft: draft,
                    enabled: false,
                    onChanged: () => fail('readonly'),
                  )
                : AgendaImpostoRendaMobileFields(
                    draft: draft,
                    enabled: false,
                    onChanged: () => fail('readonly'),
                  ),
          ),
        ),
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const ValueKey('ir-mark')))
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.delete_outline),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
