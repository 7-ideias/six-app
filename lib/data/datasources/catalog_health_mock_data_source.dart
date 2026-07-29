import 'package:flutter/material.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';

enum CatalogHealthMockScenario { success, empty, error }

class CatalogHealthMockDataSource {
  const CatalogHealthMockDataSource({
    this.scenario = CatalogHealthMockScenario.success,
    this.delay = const Duration(milliseconds: 520),
  });

  final CatalogHealthMockScenario scenario;
  final Duration delay;

  Future<CatalogHealthSummary> fetchSummary() async {
    await Future<void>.delayed(delay);

    switch (scenario) {
      case CatalogHealthMockScenario.empty:
        return const CatalogHealthSummary(
          isDemonstrationData: true,
          metrics: <CatalogHealthMetric>[],
        );
      case CatalogHealthMockScenario.error:
        throw CatalogHealthMockException();
      case CatalogHealthMockScenario.success:
        return const CatalogHealthSummary(
          isDemonstrationData: true,
          metrics: <CatalogHealthMetric>[
            CatalogHealthMetric(
              type: CatalogHealthMetricType.products,
              title: 'Produtos',
              subtitle: 'Itens cadastrados para venda',
              value: 59,
              icon: Icons.inventory_2_outlined,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.services,
              title: 'Serviços',
              subtitle: 'Serviços disponíveis no catálogo',
              value: 12,
              icon: Icons.design_services_outlined,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.missingPhoto,
              title: 'Sem foto',
              subtitle: 'Produtos que precisam de imagem',
              value: 8,
              icon: Icons.photo_library_outlined,
              severity: CatalogHealthMetricSeverity.attention,
              countsAsAttention: true,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.outOfStock,
              title: 'Sem estoque',
              subtitle: 'Produtos sem saldo disponível',
              value: 5,
              icon: Icons.remove_shopping_cart_outlined,
              severity: CatalogHealthMetricSeverity.restricted,
              requiresStockPermission: true,
              countsAsAttention: true,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.lowStock,
              title: 'Estoque baixo',
              subtitle: 'Produtos abaixo do mínimo',
              value: 7,
              icon: Icons.production_quantity_limits_outlined,
              severity: CatalogHealthMetricSeverity.restricted,
              requiresStockPermission: true,
              countsAsAttention: true,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.incompleteRegistration,
              title: 'Cadastro incompleto',
              subtitle: 'Itens com informações pendentes',
              value: 6,
              icon: Icons.fact_check_outlined,
              severity: CatalogHealthMetricSeverity.attention,
              countsAsAttention: true,
            ),
            CatalogHealthMetric(
              type: CatalogHealthMetricType.missingCategory,
              title: 'Sem categoria',
              subtitle: 'Itens sem organização definida',
              value: 4,
              icon: Icons.category_outlined,
              severity: CatalogHealthMetricSeverity.attention,
              countsAsAttention: true,
            ),
          ],
        );
    }
  }
}

class CatalogHealthMockException implements Exception {
  const CatalogHealthMockException();

  @override
  String toString() {
    return 'Não foi possível carregar os dados demonstrativos do catálogo.';
  }
}
