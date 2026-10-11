import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';
import 'package:sixpos/presentation/screens/fornecedores_web_page.dart';

class _ApiFalsa implements FornecedorUsuarioApiClient {
  @override
  Future<List<FornecedorUsuario>> listar() async => [
    FornecedorUsuario.fromJson({
      'id': 'f1', 'idUnicoDaEmpresa': 'empresa-1', 'nome': 'Distribuidora A',
      'documento': '123', 'ativo': true,
    }),
    FornecedorUsuario.fromJson({
      'id': 'f2', 'idUnicoDaEmpresa': 'empresa-1', 'nome': 'Fornecedor B',
      'documento': '456', 'ativo': false,
    }),
  ];

  @override
  Future<FornecedorUsuario> buscar(String id) async => (await listar()).first;

  @override
  Future<FornecedorUsuario> cadastrar(FornecedorUsuarioDraft fornecedor) async =>
      throw UnimplementedError();

  @override
  Future<FornecedorUsuario> atualizar(String id, FornecedorUsuarioDraft fornecedor) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('lista, busca e filtra fornecedores sem dados simulados na tela',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: FornecedoresWebPage(apiClient: _ApiFalsa()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Distribuidora A'), findsOneWidget);
    expect(find.text('Fornecedor B'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fornecedor-busca')), 'Distribuidora');
    await tester.pumpAndSettle();
    expect(find.text('Distribuidora A'), findsOneWidget);
    expect(find.text('Fornecedor B'), findsNothing);

    await tester.enterText(find.byKey(const Key('fornecedor-busca')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inativos').first);
    await tester.pumpAndSettle();
    expect(find.text('Distribuidora A'), findsNothing);
    expect(find.text('Fornecedor B'), findsOneWidget);
  });
}
