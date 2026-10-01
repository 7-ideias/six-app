import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/admin/admin_visual_assets_catalog.dart';

void main() {
  test('catálogo reflete os mapeamentos atuais do Atendimento Mobile', () {
    final records = AdminVisualAssetsCatalog.records;

    AdminVisualAssetRecord find({
      required String segmento,
      String? subsegmento,
      required AdminVisualAssetSlot slot,
    }) {
      return records.firstWhere(
        (record) =>
            record.contexto.segmento == segmento &&
            record.contexto.subsegmento == subsegmento &&
            record.slot == slot,
      );
    }

    final auto = find(
      segmento: 'AUTOMOTIVO',
      slot: AdminVisualAssetSlot.servicos,
    );
    expect(auto.status, AdminVisualAssetStatus.disponivel);
    expect(auto.profileFolder, 'automotivo');
    expect(auto.fullCard, isTrue);
    expect(
      auto.imageUrl,
      contains(
        '/atendimento/mobile/automotivo/servicos-v1.webp?rev=20261001-fullcard',
      ),
    );

    final moda = find(
      segmento: 'MODA',
      subsegmento: 'ROUPAS',
      slot: AdminVisualAssetSlot.vendas,
    );
    expect(moda.status, AdminVisualAssetStatus.disponivel);
    expect(moda.profileFolder, 'moda');
    expect(moda.fullCard, isTrue);

    final celular = find(
      segmento: 'ELETRONICOS',
      subsegmento: 'CELULARES',
      slot: AdminVisualAssetSlot.servicos,
    );
    expect(celular.status, AdminVisualAssetStatus.disponivel);
    expect(celular.profileFolder, 'eletronicos-celulares');
    expect(celular.fullCard, isFalse);
  });

  test('catálogo expõe combinações futuras sem inventar imagem', () {
    final record = AdminVisualAssetsCatalog.records.firstWhere(
      (record) =>
          record.contexto.segmento == 'AUTOMOTIVO' &&
          record.contexto.subsegmento == 'MOTOS' &&
          record.slot == AdminVisualAssetSlot.servicos,
    );

    expect(record.status, AdminVisualAssetStatus.planejado);
    expect(record.profileFolder, isNull);
    expect(record.imageUrl, isNull);
  });

  test('catálogo mantém cinco CTAs por contexto de negócio', () {
    final contexts = AdminVisualAssetsCatalog.contextos;

    for (final context in contexts) {
      final records =
          AdminVisualAssetsCatalog.records
              .where((record) => record.contexto.id == context.id)
              .toList(growable: false);
      expect(
        records.length,
        AdminVisualAssetSlot.values.length,
        reason: context.id,
      );
    }
  });
}
