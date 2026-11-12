import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

/// Presentation only: all totals and drill-down actions come from the agenda.
class AgendaResumoPeriodoWeb extends StatelessWidget {
  const AgendaResumoPeriodoWeb({
    super.key,
    required this.receberAberto,
    required this.pagarAberto,
    required this.saldoARealizar,
    required this.recebido,
    required this.pago,
    required this.realizado,
    required this.projetado,
    required this.formatarMoeda,
    required this.onRecebido,
    required this.onPago,
  });

  final double receberAberto, pagarAberto, saldoARealizar;
  final double recebido, pago, realizado, projetado;
  final String Function(double) formatarMoeda;
  final VoidCallback onRecebido, onPago;

  String _t(BuildContext context, String key) =>
      context.t('agenda.periodSummary.$key');

  Widget _amount(
    BuildContext context,
    String id,
    double value, {
    double size = 17,
    Color? color,
  }) => TweenAnimationBuilder<double>(
    key: ValueKey('$id-$value'),
    tween: Tween<double>(begin: 0, end: value),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    builder: (_, amount, __) => Text(
      formatarMoeda(amount),
      softWrap: true,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? WebThemeTokens.of(context).primaryText,
      ),
    ),
  );

  Widget _line(
    BuildContext context,
    String key,
    double value, {
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final tokens = WebThemeTokens.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              _t(context, key),
              style: TextStyle(color: tokens.primaryText),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: _amount(context, key, value, color: color),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: tokens.secondaryText),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Tooltip(
      message: context.t('agenda.summary.viewEntries'),
      child: InkWell(
        key: ValueKey('period-summary-$key'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool highlight = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Material(
      key: ValueKey('period-summary-panel-$title'),
      color: highlight
          ? Color.alphaBlend(tokens.info.withValues(alpha: .08), tokens.cardBackground)
          : tokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: highlight ? tokens.info : tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: highlight ? tokens.info : tokens.primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t(context, title), style: TextStyle(
                        color: tokens.primaryText, fontSize: 19,
                        fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 4),
                      Text(_t(context, subtitle), style: TextStyle(
                        color: tokens.secondaryText, fontSize: 13,
                      )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _total(BuildContext context, String label, double value, String hint) {
    final tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 24, color: tokens.divider),
        Text(_t(context, label), style: TextStyle(color: tokens.secondaryText)),
        const SizedBox(height: 6),
        _amount(context, label, value, size: 28),
        const SizedBox(height: 6),
        Text(_t(context, hint), style: TextStyle(color: tokens.secondaryText, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final open = _panel(context,
      title: 'open', subtitle: 'dueDates', icon: Icons.pending_actions_outlined,
      children: [
        _line(context, 'receivable', receberAberto, icon: Icons.south_west_rounded, color: tokens.financialPositive),
        Divider(height: 1, color: tokens.divider),
        _line(context, 'payable', pagarAberto, icon: Icons.north_east_rounded, color: tokens.financialNegative),
        _total(context, 'remaining', saldoARealizar, 'remainingHint'),
      ],
    );
    final actual = _panel(context,
      title: 'actual', subtitle: 'actualDates', icon: Icons.check_circle_outline,
      children: [
        _line(context, 'received', recebido, icon: Icons.south_west_rounded, color: tokens.financialPositive, onTap: onRecebido),
        Divider(height: 1, color: tokens.divider),
        _line(context, 'paid', pago, icon: Icons.north_east_rounded, color: tokens.financialNegative, onTap: onPago),
        _total(context, 'actualResult', realizado, 'actualHint'),
      ],
    );
    final forecast = _panel(context,
      title: 'forecast', subtitle: 'forecastHint', icon: Icons.query_stats_rounded,
      highlight: true,
      children: [
        _amount(context, 'forecast', projetado, size: 34, color: tokens.info),
        const SizedBox(height: 12),
        Divider(height: 1, color: tokens.divider),
        _line(context, 'actual', realizado),
        _line(context, 'remaining', saldoARealizar),
        Divider(height: 16, color: tokens.divider),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 17, color: tokens.info),
          const SizedBox(width: 8),
          Expanded(child: Text(_t(context, 'estimate'), style: TextStyle(
            color: tokens.secondaryText, fontSize: 12,
          ))),
        ]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t(context, 'title'), style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: tokens.primaryText, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          const gap = 16.0;
          final scaledWidth = constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1);
          final columns = scaledWidth >= 1140 ? 3 : scaledWidth >= 760 ? 2 : 1;
          Widget equalHeightRow(List<Widget> panels) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < panels.length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  Expanded(child: panels[index]),
                ],
              ],
            ),
          );
          if (columns == 3) {
            return equalHeightRow([open, actual, forecast]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (columns == 2)
                equalHeightRow([open, actual])
              else ...[
                open,
                const SizedBox(height: gap),
                actual,
              ],
              const SizedBox(height: gap),
              forecast,
            ],
          );
        }),
        const SizedBox(height: 10),
        Text(_t(context, 'scopeHint'), style: TextStyle(color: tokens.secondaryText, fontSize: 12)),
      ],
    );
  }
}
