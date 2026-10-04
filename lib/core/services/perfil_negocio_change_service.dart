import 'dart:async';

class PerfilNegocioChangeService {
  PerfilNegocioChangeService._();

  static final PerfilNegocioChangeService instance =
      PerfilNegocioChangeService._();

  final StreamController<String> _changes =
      StreamController<String>.broadcast(sync: true);

  Stream<String> get changes => _changes.stream;

  void notifyChanged(String companyId) {
    final String normalized = companyId.trim();
    if (normalized.isEmpty) return;
    _changes.add(normalized);
  }
}
