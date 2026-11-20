import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/permissao_colaborador.dart';
import 'package:sixpos/presentation/components/mobile/permissoes_colaborador_mobile.dart';
import 'package:sixpos/presentation/components/web/permissoes_colaborador_web.dart';

void main() {
  for (final mobile in [true, false]) {
    for (final brilho in Brightness.values) {
      testWidgets(
        'permissões de catálogo independentes (mobile=$mobile, $brilho)',
        (tester) async {
          final selecao = PermissaoColaborador.iniciais();
          await tester.binding.setSurfaceSize(Size(mobile ? 375 : 1024, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brilho),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      void alterar(PermissaoColaborador permissao, bool valor) {
                        setState(() {
                          if (valor) {
                            selecao.add(permissao);
                          } else {
                            selecao.remove(permissao);
                          }
                        });
                      }

                      return mobile
                          ? PermissoesColaboradorMobile(
                            marcadas: selecao,
                            onChanged: alterar,
                          )
                          : PermissoesColaboradorWeb(
                            marcadas: selecao,
                            onChanged: alterar,
                          );
                    },
                  ),
                ),
              ),
            ),
          );
          expect(find.byType(SwitchListTile), findsNWidgets(19));
          final servicos = find.widgetWithText(
            SwitchListTile,
            'Create services',
          );
          await tester.ensureVisible(servicos);
          await tester.tap(servicos);
          await tester.pumpAndSettle();
          expect(selecao.contains(PermissaoColaborador.servicos), isTrue);
          expect(selecao.contains(PermissaoColaborador.produtos), isFalse);
          expect(selecao.contains(PermissaoColaborador.receber), isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
