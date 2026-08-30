import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web sale procedure is deferred until first cart item inclusion', () {
    final String source =
        File('lib/pagina_principal_web.dart').readAsStringSync();

    expect(
      source,
      contains('_deveExecutarProcedimentoNaPrimeiraInclusaoNoCarrinho'),
    );
    expect(
      source,
      contains('_executarProcedimentoAposPrimeiroItemSeNecessario'),
    );
    expect(source, contains('await _adicionarProdutoSelecionado(result);'));
    expect(source, contains('await _adicionarProdutosSelecionados(produtos);'));

    final RegExp iniciarVendaBlock = RegExp(
      r'Future<void> _iniciarVenda\(\) async \{[\s\S]*?\n  \}',
    );
    final String iniciarVendaSource =
        iniciarVendaBlock.firstMatch(source)?.group(0) ?? '';

    expect(
      iniciarVendaSource,
      isNot(contains('_procedureCoordinator.execute')),
    );
    expect(
      iniciarVendaSource,
      contains('_moduloAtual = ModuloCentralPDV.vendas'),
    );
  });
}
