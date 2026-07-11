import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../core/services/auth_service.dart';
import '../../pagina_principal_web.dart' as legacy;
import '../admin/admin_portal_components.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebDashboardState();
}

class _PDVWebDashboardState extends State<PDVWeb> {
  final AuthService _authService = AuthService();

  String? _userName;
  bool _dashboardVisivel = true;

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

  void _ocultarDashboardAoInteragir(PointerDownEvent event) {
    if (!_dashboardVisivel) return;
    setState(() => _dashboardVisivel = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _ocultarDashboardAoInteragir,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const legacy.PaginaPrincipalWeb(),
          Positioned.fill(
            top: 84,
            left: 16,
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _dashboardVisivel ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _SalesDashboard(userName: _userName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesDashboard extends StatelessWidget {
  const _SalesDashboard({required this.userName});

  final String? userName;

  static const List<_GaugeData> _mockedGauges = <_GaugeData>[
    _GaugeData(
      titleKey: 'monthlyGoal',
      value: 76,
      mainValue: 'R\$ 76.400',
      supportingValue: 'Meta: R\$ 100.000',
      icon: Icons.flag_rounded,
    ),
    _GaugeData(
      titleKey: 'profitMargin',
      value: 31,
      mainValue: '31%',
      supportingValue: '+3,2 p.p. no mês',
      icon: Icons.trending_up_rounded,
    ),
    _GaugeData(
      titleKey: 'conversion',
      value: 68,
      mainValue: '68%',
      supportingValue: '204 de 300 atendimentos',
      icon: Icons.swap_horiz_rounded,
    ),
    _GaugeData(
      titleKey: 'averageTicket',
      value: 84,
      mainValue: 'R\$ 418',
      supportingValue: 'Referência: R\$ 500',
      icon: Icons.shopping_bag_rounded,
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
                            child: _SalesGaugeCard(
                              data: data,
                              title: texts.titleFor(data.titleKey),
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

class _SalesGaugeCard extends StatelessWidget {
  const _SalesGaugeCard({required this.data, required this.title});

  final _GaugeData data;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

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
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: colorScheme.primary, size: 21),
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
                      color: colorScheme.primary,
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
                      color: colorScheme.primary,
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
                              color: colorScheme.primary,
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
            data.supportingValue,
            maxLines: 1,
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
    required this.supportingValue,
    required this.icon,
  });

  final String titleKey;
  final double value;
  final String mainValue;
  final String supportingValue;
  final IconData icon;
}

class _DashboardTexts {
  const _DashboardTexts({required this.language});

  final String language;

  factory _DashboardTexts.of(BuildContext context) {
    return _DashboardTexts(
      language: Localizations.localeOf(context).languageCode.toLowerCase(),
    );
  }

  String get userFallback =>
      language == 'en' ? 'there' : language == 'es' ? 'usuario' : 'usuário';

  String get title => language == 'en'
      ? 'Sales performance overview'
      : language == 'es'
          ? 'Resumen del rendimiento de ventas'
          : 'Visão geral dos resultados de vendas';

  String get subtitle => language == 'en'
      ? 'Track the main commercial indicators of your business.'
      : language == 'es'
          ? 'Acompaña los principales indicadores comerciales de tu negocio.'
          : 'Acompanhe os principais indicadores comerciais do seu negócio.';

  String get mockNotice => language == 'en'
      ? 'Demonstration data. These indicators are not connected to the backend yet.'
      : language == 'es'
          ? 'Datos de demostración. Estos indicadores aún no están conectados al backend.'
          : 'Dados demonstrativos. Estes indicadores ainda não estão conectados ao backend.';

  String titleFor(String key) {
    final Map<String, Map<String, String>> values = <String, Map<String, String>>{
      'monthlyGoal': <String, String>{
        'pt': 'Meta mensal de vendas',
        'en': 'Monthly sales goal',
        'es': 'Meta mensual de ventas',
      },
      'profitMargin': <String, String>{
        'pt': 'Margem comercial',
        'en': 'Commercial margin',
        'es': 'Margen comercial',
      },
      'conversion': <String, String>{
        'pt': 'Conversão de atendimentos',
        'en': 'Service conversion',
        'es': 'Conversión de atenciones',
      },
      'averageTicket': <String, String>{
        'pt': 'Ticket médio vs. referência',
        'en': 'Average ticket vs. benchmark',
        'es': 'Ticket promedio vs. referencia',
      },
    };
    final String normalized = language == 'en' || language == 'es'
        ? language
        : 'pt';
    return values[key]?[normalized] ?? key;
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
