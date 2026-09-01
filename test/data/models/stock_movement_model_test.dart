import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/stock_movement_model.dart';

void main() {
  group('StockMovementRequest', () {
    test('serializa entrada com custo e motivo normalizado', () {
      const StockMovementRequest request = StockMovementRequest(
        productId: 'produto-1',
        type: StockMovementType.entry,
        quantity: 2.5,
        unitCost: 12.75,
        reason: '  Recebimento da compra  ',
      );

      expect(request.toJson(), <String, dynamic>{
        'produtoId': 'produto-1',
        'tipo': 'ENTRADA',
        'quantidade': 2.5,
        'valorCusto': 12.75,
        'motivo': 'Recebimento da compra',
      });
    });

    test('nao envia custo em uma saida', () {
      const StockMovementRequest request = StockMovementRequest(
        productId: 'produto-1',
        type: StockMovementType.exit,
        quantity: 1,
        unitCost: 99,
        reason: 'Ajuste',
      );

      expect(request.toJson(), isNot(contains('valorCusto')));
      expect(request.toJson()['tipo'], 'SAIDA');
    });
  });
}
