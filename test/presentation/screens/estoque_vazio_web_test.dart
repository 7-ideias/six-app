import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';
import 'package:sixpos/presentation/screens/estoque_dashboard_web_page.dart';

class _StockService extends ProdutoService {
  int productCount = 0;

  @override
  Future<EstoqueDashboardModel> buscarDashboardEstoque() async =>
      EstoqueDashboardModel.fromJson({'totalProdutos': productCount});
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('first product unlocks stock operations in $brightness', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final service = _StockService();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: EstoqueDashboardWebPage(
              produtoService: service,
              onCreateProduct: () async {
                service.productCount = 1;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Atualizar'), findsNothing);
      expect(find.text('Entrada'), findsNothing);
      expect(find.text('Saída'), findsNothing);
      await tester.tap(find.text('New product'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Saída'), findsOneWidget);
    });
  }
}
