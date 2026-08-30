class OperationalProcedurePendingExecutionStore {
  OperationalProcedurePendingExecutionStore._();

  static final OperationalProcedurePendingExecutionStore instance =
      OperationalProcedurePendingExecutionStore._();

  final Set<String> _saleExecutionIds = <String>{};

  List<String> get pendingSaleExecutionIds =>
      List<String>.unmodifiable(_saleExecutionIds);

  void addSaleExecutions(Iterable<String> ids) {
    _saleExecutionIds.addAll(ids.where((String id) => id.trim().isNotEmpty));
  }

  void beginSaleFlow() => _saleExecutionIds.clear();

  void markSaleLinked(Iterable<String> ids) {
    _saleExecutionIds.removeAll(ids);
  }
}
