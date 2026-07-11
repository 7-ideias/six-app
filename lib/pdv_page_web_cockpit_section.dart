part of 'pdv_page_web.dart';

extension _PdvPageWebCockpitSection on _PDVWebState {
  Widget _buildCockpitEstrategico() {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final ColorScheme colors = Theme.of(context).colorScheme;
          final bool compact = constraints.maxWidth < 900;
          final double horizontalPadding = compact ? 16 : 24;

          return ColoredBox(
            color: colors.surfaceContainerLowest,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                24,
              ),
              child: _buildSalesGaugeGrid(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesGaugeGrid(BuildContext context) {
    final _SalesGaugeTexts texts = _SalesGaugeTexts.of(context);
    final List<_SalesGaugeData> gauges = <_SalesGaugeData>[
      _SalesGaugeData(
        title: texts.monthlyGoal,
        subtitle: texts.monthlyGoalSubtitle,
        value: 72,
        centerValue: '72%',
        footer: 'R\$ 72.000 / R\$ 100.000',
        icon: Icons.track_changes_rounded,
        type: _SalesGaugeType.range,
      ),
      _SalesGaugeData(
        title: texts.averageTicket,
        subtitle: texts.averageTicketSubtitle,
        value: 68,
        centerValue: 'R\$ 680',
        footer: texts.averageTicketFooter,
        icon: Icons.shopping_bag_outlined,
        type: _SalesGaugeType.needle,
      ),
      _SalesGaugeData(
        title: texts.conversion,
        subtitle: texts.conversionSubtitle,
        value: 41,
        centerValue: '41%',
        footer: texts.conversionFooter,
        icon: Icons.trending_up_rounded,
        type: _SalesGaugeType.segmented,
      ),
      _SalesGaugeData(
        title: texts.salesVolume,
        subtitle: texts.salesVolumeSubtitle,
        value: 84,
        centerValue: '84',
        footer: texts.salesVolumeFooter,
        icon: Icons.point_of_sale_rounded,
        type: _SalesGaugeType.linear,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1280
            ? 4
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        const double spacing = 16;
        final double cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: gauges
              .map(
                (_SalesGaugeData data) => SizedBox(
                  width: cardWidth,
                  child: _buildSalesGaugeCard(context, data),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSalesGaugeCard(
    BuildContext context,
    _SalesGaugeData data,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: colors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildGauge(context, data)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.footer,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(BuildContext context, _SalesGaugeData data) {
    switch (data.type) {
      case _SalesGaugeType.needle:
        return _buildNeedleGauge(context, data);
      case _SalesGaugeType.segmented:
        return _buildSegmentedGauge(context, data);
      case _SalesGaugeType.linear:
        return _buildLinearGauge(context, data);
      case _SalesGaugeType.range:
        return _buildRangeGauge(context, data);
    }
  }

  Widget _buildRangeGauge(BuildContext context, _SalesGaugeData data) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          startAngle: 145,
          endAngle: 35,
          showLabels: false,
          showTicks: false,
          axisLineStyle: AxisLineStyle(
            thickness: .16,
            thicknessUnit: GaugeSizeUnit.factor,
            color: colors.surfaceContainerHighest,
          ),
          pointers: <GaugePointer>[
            RangePointer(
              value: data.value,
              width: .16,
              sizeUnit: GaugeSizeUnit.factor,
              color: colors.primary,
              cornerStyle: CornerStyle.bothCurve,
              enableAnimation: true,
              animationDuration: 900,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              positionFactor: .08,
              widget: _buildGaugeValue(context, data.centerValue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNeedleGauge(BuildContext context, _SalesGaugeData data) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          startAngle: 150,
          endAngle: 30,
          interval: 20,
          axisLabelStyle: GaugeTextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          majorTickStyle: MajorTickStyle(
            length: 7,
            thickness: 1.5,
            color: colors.outline,
          ),
          minorTicksPerInterval: 0,
          axisLineStyle: AxisLineStyle(
            thickness: .11,
            thicknessUnit: GaugeSizeUnit.factor,
            color: colors.surfaceContainerHighest,
          ),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: data.value,
              needleColor: colors.primary,
              knobStyle: KnobStyle(
                color: colors.primary,
                borderColor: colors.surface,
                borderWidth: 0.04,
              ),
              enableAnimation: true,
              animationDuration: 900,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              angle: 90,
              positionFactor: .72,
              widget: _buildGaugeValue(context, data.centerValue, fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedGauge(BuildContext context, _SalesGaugeData data) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          startAngle: 145,
          endAngle: 35,
          showLabels: false,
          showTicks: false,
          axisLineStyle: const AxisLineStyle(thickness: 0),
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 0,
              endValue: 35,
              color: colors.error.withValues(alpha: .72),
              startWidth: 18,
              endWidth: 18,
            ),
            GaugeRange(
              startValue: 36,
              endValue: 70,
              color: Colors.orange.withValues(alpha: .82),
              startWidth: 18,
              endWidth: 18,
            ),
            GaugeRange(
              startValue: 71,
              endValue: 100,
              color: colors.primary,
              startWidth: 18,
              endWidth: 18,
            ),
          ],
          pointers: <GaugePointer>[
            MarkerPointer(
              value: data.value,
              markerType: MarkerType.circle,
              markerHeight: 16,
              markerWidth: 16,
              color: colors.onSurface,
              borderColor: colors.surface,
              borderWidth: 3,
              enableAnimation: true,
              animationDuration: 900,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              positionFactor: .08,
              widget: _buildGaugeValue(context, data.centerValue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinearGauge(BuildContext context, _SalesGaugeData data) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildGaugeValue(context, data.centerValue),
          const SizedBox(height: 22),
          SfLinearGauge(
            minimum: 0,
            maximum: 100,
            interval: 20,
            showTicks: true,
            showLabels: true,
            axisTrackStyle: LinearAxisTrackStyle(
              thickness: 14,
              edgeStyle: LinearEdgeStyle.bothCurve,
              color: colors.surfaceContainerHighest,
            ),
            barPointers: <LinearBarPointer>[
              LinearBarPointer(
                value: data.value,
                thickness: 14,
                color: colors.primary,
                edgeStyle: LinearEdgeStyle.bothCurve,
                enableAnimation: true,
                animationDuration: 900,
              ),
            ],
            markerPointers: <LinearMarkerPointer>[
              LinearShapePointer(
                value: data.value,
                shapeType: LinearShapePointerType.invertedTriangle,
                color: colors.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeValue(
    BuildContext context,
    String value, {
    double fontSize = 26,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Text(
      value,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -.6,
      ),
    );
  }
}

enum _SalesGaugeType { range, needle, segmented, linear }

class _SalesGaugeData {
  const _SalesGaugeData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.centerValue,
    required this.footer,
    required this.icon,
    required this.type,
  });

  final String title;
  final String subtitle;
  final double value;
  final String centerValue;
  final String footer;
  final IconData icon;
  final _SalesGaugeType type;
}

class _SalesGaugeTexts {
  const _SalesGaugeTexts({
    required this.monthlyGoal,
    required this.monthlyGoalSubtitle,
    required this.averageTicket,
    required this.averageTicketSubtitle,
    required this.averageTicketFooter,
    required this.conversion,
    required this.conversionSubtitle,
    required this.conversionFooter,
    required this.salesVolume,
    required this.salesVolumeSubtitle,
    required this.salesVolumeFooter,
  });

  final String monthlyGoal;
  final String monthlyGoalSubtitle;
  final String averageTicket;
  final String averageTicketSubtitle;
  final String averageTicketFooter;
  final String conversion;
  final String conversionSubtitle;
  final String conversionFooter;
  final String salesVolume;
  final String salesVolumeSubtitle;
  final String salesVolumeFooter;

  factory _SalesGaugeTexts.of(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    if (language == 'en') {
      return const _SalesGaugeTexts(
        monthlyGoal: 'Monthly sales goal',
        monthlyGoalSubtitle: 'Progress toward the simulated monthly target',
        averageTicket: 'Average ticket',
        averageTicketSubtitle: 'Average value per completed sale',
        averageTicketFooter: 'Example target: R\$ 1,000',
        conversion: 'Sales conversion',
        conversionSubtitle: 'Quotes converted into completed sales',
        conversionFooter: '41 conversions per 100 quotes',
        salesVolume: 'Sales volume',
        salesVolumeSubtitle: 'Completed sales in the current period',
        salesVolumeFooter: 'Example target: 100 sales',
      );
    }
    if (language == 'es') {
      return const _SalesGaugeTexts(
        monthlyGoal: 'Meta mensual de ventas',
        monthlyGoalSubtitle: 'Avance sobre la meta mensual simulada',
        averageTicket: 'Ticket promedio',
        averageTicketSubtitle: 'Valor promedio por venta finalizada',
        averageTicketFooter: 'Meta de ejemplo: R\$ 1.000',
        conversion: 'Conversión de ventas',
        conversionSubtitle: 'Presupuestos convertidos en ventas',
        conversionFooter: '41 conversiones por cada 100 presupuestos',
        salesVolume: 'Volumen de ventas',
        salesVolumeSubtitle: 'Ventas concluidas en el período actual',
        salesVolumeFooter: 'Meta de ejemplo: 100 ventas',
      );
    }
    return const _SalesGaugeTexts(
      monthlyGoal: 'Meta mensal de vendas',
      monthlyGoalSubtitle: 'Avanço sobre a meta mensal simulada',
      averageTicket: 'Ticket médio',
      averageTicketSubtitle: 'Valor médio por venda concluída',
      averageTicketFooter: 'Meta de exemplo: R\$ 1.000',
      conversion: 'Conversão de vendas',
      conversionSubtitle: 'Orçamentos convertidos em vendas concluídas',
      conversionFooter: '41 conversões a cada 100 orçamentos',
      salesVolume: 'Volume de vendas',
      salesVolumeSubtitle: 'Vendas concluídas no período atual',
      salesVolumeFooter: 'Meta de exemplo: 100 vendas',
    );
  }
}
