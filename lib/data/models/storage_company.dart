import '../../core/services/admin_portal_service.dart';

class StorageCompany {
  const StorageCompany(this.id, this.name);
  final String id;
  final String name;

  static List<StorageCompany> fromUser(AdminUsuarioDetalhe detail) {
    final companies = <String, StorageCompany>{};
    for (final company in detail.empresas) {
      final id = company['idUnicoDaEmpresa']?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final data = company['dadosDaEmpresa'];
      final name =
          (data is Map ? data['nomeFantasia'] ?? data['nomeEmpresa'] : null) ??
          company['nomeFantasia'] ??
          company['nomeEmpresa'] ??
          '';
      companies[id] = StorageCompany(id, name.toString());
    }
    for (final id in detail.idsUnicosDasEmpresas) {
      if (id.trim().isNotEmpty)
        companies.putIfAbsent(id, () => StorageCompany(id, ''));
    }
    return companies.values.toList(growable: false);
  }
}
