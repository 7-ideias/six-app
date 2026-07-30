import 'package:flutter/material.dart';

enum CatalogHealthMetricType {
  products,
  services,
  missingPhoto,
  outOfStock,
  lowStock,
  incompleteRegistration,
  missingCategory,
}

enum CatalogHealthMetricSeverity { neutral, attention, restricted }

class CatalogHealthSummary {
  const CatalogHealthSummary({
    required this.metrics,
    required this.isDemonstrationData,
  });

  final List<CatalogHealthMetric> metrics;
  final bool isDemonstrationData;

  bool get isEmpty =>
      metrics.every((CatalogHealthMetric metric) => metric.value == 0);

  int get attentionItems => metrics
      .where((CatalogHealthMetric metric) => metric.countsAsAttention)
      .fold<int>(
        0,
        (int total, CatalogHealthMetric metric) => total + metric.value,
      );

  CatalogHealthMetric? metric(CatalogHealthMetricType type) {
    for (final CatalogHealthMetric metric in metrics) {
      if (metric.type == type) return metric;
    }
    return null;
  }
}

class CatalogHealthMetric {
  const CatalogHealthMetric({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.severity = CatalogHealthMetricSeverity.neutral,
    this.requiresStockPermission = false,
    this.countsAsAttention = false,
  });

  final CatalogHealthMetricType type;
  final String title;
  final String subtitle;
  final int value;
  final IconData icon;
  final CatalogHealthMetricSeverity severity;
  final bool requiresStockPermission;
  final bool countsAsAttention;

  bool get isPositive => value == 0 && countsAsAttention;
}
