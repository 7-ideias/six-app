enum StockMovementType {
  entry('ENTRADA'),
  exit('SAIDA');

  const StockMovementType(this.apiValue);

  final String apiValue;
}

class StockMovementRequest {
  const StockMovementRequest({
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    this.unitCost,
  });

  final String productId;
  final StockMovementType type;
  final double quantity;
  final double? unitCost;
  final String reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'produtoId': productId,
      'tipo': type.apiValue,
      'quantidade': quantity,
      if (type == StockMovementType.entry && unitCost != null)
        'valorCusto': unitCost,
      'motivo': reason.trim(),
    };
  }
}

class StockMovementResult {
  const StockMovementResult({
    required this.movementId,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousBalance,
    required this.currentBalance,
    required this.origin,
    this.registeredAt,
  });

  factory StockMovementResult.fromJson(Map<String, dynamic> json) {
    return StockMovementResult(
      movementId: json['movimentacaoId']?.toString() ?? '',
      productId: json['produtoId']?.toString() ?? '',
      type: json['tipo']?.toString() ?? '',
      quantity: _toDouble(json['quantidade']),
      previousBalance: _toDouble(json['saldoAnterior']),
      currentBalance: _toDouble(json['saldoAtual']),
      origin: json['origem']?.toString() ?? '',
      registeredAt: DateTime.tryParse(json['registradaEm']?.toString() ?? ''),
    );
  }

  final String movementId;
  final String productId;
  final String type;
  final double quantity;
  final double previousBalance;
  final double currentBalance;
  final String origin;
  final DateTime? registeredAt;
}

class StockMovementException implements Exception {
  const StockMovementException({
    required this.statusCode,
    required this.errorCode,
  });

  final int statusCode;
  final String errorCode;

  @override
  String toString() {
    return 'StockMovementException(statusCode: $statusCode, errorCode: $errorCode)';
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
