import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../core/services/auth_service.dart';
import '../admin/admin_portal_components.dart';

class DashboardGestaoWeb extends StatefulWidget {
  const DashboardGestaoWeb({super.key});

  @override
  State<DashboardGestaoWeb> createState() =>
      _DashboardGestaoWebState();
}

class _DashboardGestaoWebState
    extends State<DashboardGestaoWeb> {
  final AuthService _authService = AuthService();

  String? _userName;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;

    setState(() {
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalizado = email?.trim() ?? '';
    if (normalizado.isEmpty || !normalizado.contains('@')) return null;

    final String prefixo = normalizado
        .split('@')
        .first
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (prefixo.isEmpty) return null;

    return prefixo
        .split(RegExp(r'\s+'))
        .where((String parte) => parte.isNotEmpty)
        .map((String parte) {
      if (parte.length == 1) return parte.toUpperCase();
      return '${parte[0].toUpperCase()}${parte.substring(1).toLowerCase()}';
    })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return _OperationalDashboard(userName: _userName);
  }
}

class _OperationalDashboard extends StatelessWidget {
  const _OperationalDashboard({required this.userName});

  final String? userName;

  static const List<_GaugeData> _mockedGauges = <_GaugeData>[
    _GaugeData(
      titleKey: 'salesGoal',
      value: 82,
      mainValue: 'R\$ 82.000',
      supportingKey: 'salesGoalSupport',
      icon: Icons.track_changes_rounded,
      color: Color(0xFF2563EB),
    ),
    _GaugeData(
      titleKey: 'settledSalesGoal',
      value: 74,
      mainValue: 'R\$ 59.200',
      supportingKey: 'settledSalesGoalSupport',
      icon: Icons.verified_rounded,
      color: Color(0xFF16A34A),
    ),
    _GaugeData(
      titleKey: 'unsettledSales',
      value: 24,
      mainValue: 'R\$ 18.400',
      supportingKey: 'unsettledSalesSupport',
      icon: Icons.pending_actions_rounded,
      color: Color(0xFFF59E0B),
    ),
    _GaugeData(
      titleKey: 'pendingServices',
      value: 36,
      mainValue: '18',
      supportingKey: 'pendingServicesSupport',
      icon: Icons.build_circle_outlined,
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final _DashboardTexts texts = _DashboardTexts.of(context);
    final String displayName = userName?.trim().isNotEmpty == true
        ? userName!.trim()
        : texts.userFallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: AdminPalette.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _GreetingHeader(displayName: displayName, texts: texts),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int columns = constraints.maxWidth >= 1320
                      ? 4
                      : constraints.maxWidth >= 760
                      ? 2
                      : 1;
                  const double spacing = 18;
                  final double cardWidth =
                      (constraints.maxWidth - ((columns - 1) * spacing)) /
                          columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _mockedGauges
                        .map(
                          (_GaugeData data) => SizedBox(
                        width: cardWidth,
                        child: _OperationalGaugeCard(
                          data: data,
                          title: texts.textFor(data.titleKey),
                          supportingText:
                          texts.textFor(data.supportingKey),
                        ),
                      ),
                    )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 18),
              _MockDataNotice(text: texts.mockNotice),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.displayName, required this.texts});

  final String displayName;
  final _DashboardTexts texts;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String greeting = texts.greetingFor(DateTime.now(), displayName);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminPalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminPalette.activeGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AdminPalette.dark,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  greeting,
                  style: textTheme.titleMedium?.copyWith(
                    color: AdminPalette.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  texts.title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AdminPalette.dark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  texts.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AdminPalette.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalGaugeCard extends StatelessWidget {
  const _OperationalGaugeCard({
    required this.data,
    required this.title,
    required this.supportingText,
  });

  final _GaugeData data;
  final String title;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminPalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminPalette.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 145,
                  endAngle: 35,
                  showLabels: false,
                  showTicks: false,
                  radiusFactor: 0.96,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.16,
                    thicknessUnit: GaugeSizeUnit.factor,
                    color: Color(0xFFE5E7EB),
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: data.value,
                      width: 0.16,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: data.color,
                      cornerStyle: CornerStyle.bothCurve,
                      enableAnimation: true,
                      animationDuration: 900,
                      animationType: AnimationType.easeOutBack,
                    ),
                    MarkerPointer(
                      value: data.value,
                      markerHeight: 12,
                      markerWidth: 12,
                      markerType: MarkerType.circle,
                      color: data.color,
                      borderColor: Colors.white,
                      borderWidth: 3,
                      enableAnimation: true,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.05,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${data.value.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AdminPalette.dark,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.mainValue,
                            style: TextStyle(
                              color: data.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            supportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminPalette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockDataNotice extends StatelessWidget {
  const _MockDataNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.science_outlined,
            size: 18,
            color: AdminPalette.mutedText,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AdminPalette.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeData {
  const _GaugeData({
    required this.titleKey,
    required this.value,
    required this.mainValue,
    required this.supportingKey,
    required this.icon,
    required this.color,
  });

  final String titleKey;
  final double value;
  final String mainValue;
  final String supportingKey;
  final IconData icon;
  final Color color;
}

class _DashboardTexts {
  const _DashboardTexts({required this.language});

  final String language;

  factory _DashboardTexts.of(BuildContext context) {
    return _DashboardTexts(
      language: Localizations.localeOf(context).languageCode.toLowerCase(),
    );
  }

  String get normalizedLanguage =>
      language == 'en' || language == 'es' ? language : 'pt';

  String get userFallback =>
      language == 'en' ? 'there' : language == 'es' ? 'usuario' : 'usuário';

  String get title => language == 'en'
      ? 'Business performance overview'
      : language == 'es'
      ? 'Resumen del rendimiento del negocio'
      : 'Visão geral dos resultados do negócio';

  String get subtitle => language == 'en'
      ? 'Compare goals, settlements and pending service operations.'
      : language == 'es'
      ? 'Compara metas, liquidaciones y atenciones pendientes.'
      : 'Compare metas, liquidações e atendimentos pendentes.';

  String get mockNotice => language == 'en'
      ? 'Demonstration data. These indicators are not connected to the backend yet.'
      : language == 'es'
      ? 'Datos de demostración. Estos indicadores aún no están conectados al backend.'
      : 'Dados demonstrativos. Estes indicadores ainda não estão conectados ao backend.';

  String textFor(String key) {
    const Map<String, Map<String, String>> values =
    <String, Map<String, String>>{
      'salesGoal': <String, String>{
        'pt': 'Resultado de vendas vs. meta',
        'en': 'Sales result vs. goal',
        'es': 'Resultado de ventas vs. meta',
      },
      'salesGoalSupport': <String, String>{
        'pt': 'Meta mensal: R\$ 100.000',
        'en': 'Monthly goal: R\$ 100,000',
        'es': 'Meta mensual: R\$ 100.000',
      },
      'settledSalesGoal': <String, String>{
        'pt': 'Vendas liquidadas vs. meta',
        'en': 'Settled sales vs. goal',
        'es': 'Ventas liquidadas vs. meta',
      },
      'settledSalesGoalSupport': <String, String>{
        'pt': 'Meta liquidada: R\$ 80.000',
        'en': 'Settlement goal: R\$ 80,000',
        'es': 'Meta liquidada: R\$ 80.000',
      },
      'unsettledSales': <String, String>{
        'pt': 'Vendas não liquidadas',
        'en': 'Unsettled sales',
        'es': 'Ventas no liquidadas',
      },
      'unsettledSalesSupport': <String, String>{
        'pt': '12 vendas aguardando recebimento',
        'en': '12 sales awaiting settlement',
        'es': '12 ventas pendientes de liquidación',
      },
      'pendingServices': <String, String>{
        'pt': 'Atendimentos pendentes',
        'en': 'Pending service orders',
        'es': 'Atenciones pendientes',
      },
      'pendingServicesSupport': <String, String>{
        'pt': '18 de 50 atendimentos • 7 em atraso',
        'en': '18 of 50 service orders • 7 overdue',
        'es': '18 de 50 atenciones • 7 atrasadas',
      },
    };

    return values[key]?[normalizedLanguage] ?? key;
  }

  String greetingFor(DateTime now, String name) {
    final String period;
    if (now.hour < 12) {
      period = language == 'en'
          ? 'Good morning'
          : language == 'es'
          ? 'Buenos días'
          : 'Bom dia';
    } else if (now.hour < 18) {
      period = language == 'en'
          ? 'Good afternoon'
          : language == 'es'
          ? 'Buenas tardes'
          : 'Boa tarde';
    } else {
      period = language == 'en'
          ? 'Good evening'
          : language == 'es'
          ? 'Buenas noches'
          : 'Boa noite';
    }
    return '$period, $name';
  }
}
