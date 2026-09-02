import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';
import 'six_web_animated_dialog.dart';

class SixWebAtendimentoDateFilterResult {
  const SixWebAtendimentoDateFilterResult({
    required this.dataInicio,
    required this.dataFim,
  });

  final DateTime? dataInicio;
  final DateTime? dataFim;
}

Future<SixWebAtendimentoDateFilterResult?>
showSixWebAtendimentoDateFilterDialog({
  required BuildContext context,
  required DateTime? dataInicio,
  required DateTime? dataFim,
  required String Function(DateTime?) formatarData,
  required String dateFormatPattern,
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  return showSixWebAnimatedDialog<SixWebAtendimentoDateFilterResult>(
    context: context,
    barrierLabel: context.t(
      'atendimentoTecnico.web.dateFilterDialog.barrierLabel',
      fallback: 'Fechar filtro de data',
    ),
    overlayColor: const Color(0xB80B1324),
    overlayBlurSigma: 12,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 320),
    builder:
        (BuildContext dialogContext) => SixWebAtendimentoDateFilterDialog(
          dataInicio: dataInicio,
          dataFim: dataFim,
          formatarData: formatarData,
          dateFormatPattern: dateFormatPattern,
        ),
  );
}

class SixWebAtendimentoDateFilterDialog extends StatefulWidget {
  const SixWebAtendimentoDateFilterDialog({
    super.key,
    required this.dataInicio,
    required this.dataFim,
    required this.formatarData,
    required this.dateFormatPattern,
  });

  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String Function(DateTime?) formatarData;
  final String dateFormatPattern;

  @override
  State<SixWebAtendimentoDateFilterDialog> createState() =>
      _SixWebAtendimentoDateFilterDialogState();
}

class _SixWebAtendimentoDateFilterDialogState
    extends State<SixWebAtendimentoDateFilterDialog> {
  late DateTime? _inicio = widget.dataInicio;
  late DateTime? _fim = widget.dataFim;
  late final TextEditingController _inicioController = TextEditingController(
    text: _inicio == null ? '' : widget.formatarData(_inicio),
  );
  late final TextEditingController _fimController = TextEditingController(
    text: _fim == null ? '' : widget.formatarData(_fim),
  );
  String? _erro;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final String title = _txt(
      'atendimentoTecnico.web.dateFilterDialog.title',
      'Filtrar por data',
    );
    final Size size = MediaQuery.sizeOf(context);
    final double maxHeight = size.height > 96 ? size.height - 48 : size.height;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancelar,
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: true,
          child: Semantics(
            namesRoute: true,
            label: title,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF020617).withValues(alpha: 0.32),
                      blurRadius: 42,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    key: const ValueKey<String>(
                      'six-web-atendimento-date-filter-dialog',
                    ),
                    color: tokens.surfaceElevated,
                    surfaceTintColor: Colors.transparent,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(height: 3, color: accent),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildHeader(theme, tokens, accent, title),
                              const SizedBox(height: 22),
                              _buildSummary(theme, tokens),
                              const SizedBox(height: 18),
                              _buildDateFields(theme, tokens),
                              const SizedBox(height: 14),
                              _buildQuickPeriods(theme, tokens),
                              AnimatedSwitcher(
                                duration: Duration(
                                  milliseconds: _reduceMotion ? 1 : 180,
                                ),
                                child:
                                    _erro == null
                                        ? const SizedBox.shrink()
                                        : Padding(
                                          key: const ValueKey<String>(
                                            'date-filter-error',
                                          ),
                                          padding: const EdgeInsets.only(
                                            top: 14,
                                          ),
                                          child: _buildError(theme, tokens),
                                        ),
                              ),
                              const SizedBox(height: 22),
                              Divider(height: 1, color: tokens.divider),
                              const SizedBox(height: 18),
                              _buildActions(tokens),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    WebThemeTokens tokens,
    Color accent,
    String title,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _DateFilterImpactIcon(accent: accent, reduceMotion: _reduceMotion),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _txt(
                  'atendimentoTecnico.web.dateFilterDialog.subtitle',
                  'Defina o intervalo de atualização dos atendimentos.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.secondaryText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: _txt('common.close', 'Fechar'),
          child: IconButton(
            onPressed: _cancelar,
            style: IconButton.styleFrom(
              backgroundColor: tokens.surfaceMuted,
              foregroundColor: tokens.secondaryText,
              hoverColor: tokens.hoverBackground,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme, WebThemeTokens tokens) {
    final List<_DateFilterSummaryItem> items = <_DateFilterSummaryItem>[
      _DateFilterSummaryItem(
        icon: Icons.manage_search_rounded,
        label: _txt(
          'atendimentoTecnico.web.dateFilterDialog.fieldLabel',
          'Campo',
        ),
        value: _txt(
          'atendimentoTecnico.web.dateFilterDialog.fieldValueUpdatedAt',
          'Atualização',
        ),
      ),
      _DateFilterSummaryItem(
        icon: Icons.date_range_rounded,
        label: _txt(
          'atendimentoTecnico.web.dateFilterDialog.currentRangeLabel',
          'Intervalo',
        ),
        value: _periodoResumoAtual(),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 460;
          if (compact) {
            return Column(
              children: <Widget>[
                for (int index = 0; index < items.length; index++) ...<Widget>[
                  _buildSummaryItem(theme, tokens, items[index]),
                  if (index < items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: tokens.divider),
                    ),
                ],
              ],
            );
          }

          return Row(
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                Expanded(child: _buildSummaryItem(theme, tokens, items[index])),
                if (index < items.length - 1)
                  Container(
                    width: 1,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: tokens.divider,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    WebThemeTokens tokens,
    _DateFilterSummaryItem item,
  ) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: tokens.info, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFields(ThemeData theme, WebThemeTokens tokens) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 500;
        final Widget start = _dateInput(
          theme,
          tokens,
          key: const ValueKey<String>('six-date-filter-start-field'),
          controller: _inicioController,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.startLabel',
            'Início',
          ),
          textInputAction:
              compact ? TextInputAction.done : TextInputAction.next,
        );
        final Widget end = _dateInput(
          theme,
          tokens,
          key: const ValueKey<String>('six-date-filter-end-field'),
          controller: _fimController,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.endLabel',
            'Fim',
          ),
          textInputAction: TextInputAction.done,
        );

        if (compact) {
          return Column(
            children: <Widget>[start, const SizedBox(height: 12), end],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: start),
            const SizedBox(width: 12),
            Expanded(child: end),
          ],
        );
      },
    );
  }

  Widget _dateInput(
    ThemeData theme,
    WebThemeTokens tokens, {
    required Key key,
    required TextEditingController controller,
    required String label,
    required TextInputAction textInputAction,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.datetime,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.primaryText,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: _dateHint(),
        prefixIcon: Icon(Icons.event_outlined, color: tokens.info),
        filled: true,
        fillColor: tokens.inputBackground,
        labelStyle: TextStyle(color: tokens.secondaryText),
        hintStyle: TextStyle(color: tokens.mutedText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.selectedBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.danger.withValues(alpha: 0.72)),
        ),
      ),
      onChanged: (_) {
        setState(() => _erro = null);
      },
      onSubmitted: (_) => _aplicar(),
    );
  }

  Widget _buildQuickPeriods(ThemeData theme, WebThemeTokens tokens) {
    final DateTime now = DateTime.now();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.today_outlined,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickToday',
            'Hoje',
          ),
          onPressed: () => _setPeriodo(now, now),
        ),
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.history_rounded,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickLast7Days',
            'Últimos 7 dias',
          ),
          onPressed:
              () => _setPeriodo(now.subtract(const Duration(days: 6)), now),
        ),
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.event_available_outlined,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickNext7Days',
            'Próximos 7 dias',
          ),
          onPressed: () => _setPeriodo(now, now.add(const Duration(days: 6))),
        ),
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.notification_important_outlined,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickOverdue',
            'Vencidos',
          ),
          onPressed:
              () => _setPeriodoAte(now.subtract(const Duration(days: 1))),
        ),
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.calendar_view_week_outlined,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickLast30Days',
            'Últimos 30 dias',
          ),
          onPressed:
              () => _setPeriodo(now.subtract(const Duration(days: 29)), now),
        ),
        _quickPeriodChip(
          theme,
          tokens,
          icon: Icons.calendar_month_outlined,
          label: _txt(
            'atendimentoTecnico.web.dateFilterDialog.quickThisMonth',
            'Este mês',
          ),
          onPressed: () => _setPeriodo(DateTime(now.year, now.month), now),
        ),
      ],
    );
  }

  Widget _quickPeriodChip(
    ThemeData theme,
    WebThemeTokens tokens, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: tokens.info),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: tokens.primaryText,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: tokens.cardBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      pressElevation: 0,
      side: BorderSide(color: tokens.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onPressed,
    );
  }

  Widget _buildError(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _erro!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(WebThemeTokens tokens) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          TextButton.icon(
            onPressed: _limpar,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            style: _secondaryActionStyle(tokens),
            label: Text(
              _txt(
                'atendimentoTecnico.web.dateFilterDialog.clearAction',
                'Limpar',
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _cancelar,
            icon: const Icon(Icons.close_rounded, size: 18),
            style: _secondaryActionStyle(tokens),
            label: Text(
              _txt(
                'atendimentoTecnico.web.dateFilterDialog.cancelAction',
                'Cancelar',
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _aplicar,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _txt(
                'atendimentoTecnico.web.dateFilterDialog.applyAction',
                'Aplicar',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.info,
              foregroundColor: tokens.onInfo,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _secondaryActionStyle(WebThemeTokens tokens) {
    return TextButton.styleFrom(
      foregroundColor: tokens.secondaryText,
      backgroundColor: tokens.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _aplicar() {
    final DateTime? inicio = _parseData(_inicioController.text);
    final DateTime? fim = _parseData(_fimController.text);

    if (inicio == null && _inicioController.text.trim().isNotEmpty) {
      setState(() {
        _erro = _txt(
          'atendimentoTecnico.web.dateFilterDialog.startInvalid',
          'Informe a data inicial em um formato válido.',
        );
      });
      return;
    }
    if (fim == null && _fimController.text.trim().isNotEmpty) {
      setState(() {
        _erro = _txt(
          'atendimentoTecnico.web.dateFilterDialog.endInvalid',
          'Informe a data final em um formato válido.',
        );
      });
      return;
    }
    if (inicio != null && fim != null && fim.isBefore(inicio)) {
      setState(() {
        _erro = _txt(
          'atendimentoTecnico.web.dateFilterDialog.endBeforeStart',
          'A data final não pode ser anterior à inicial.',
        );
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(SixWebAtendimentoDateFilterResult(dataInicio: inicio, dataFim: fim));
  }

  void _limpar() {
    Navigator.of(context).pop(
      const SixWebAtendimentoDateFilterResult(dataInicio: null, dataFim: null),
    );
  }

  void _cancelar() {
    Navigator.of(context).maybePop();
  }

  DateTime? _parseData(String value) {
    final String text = value.trim();
    if (text.isEmpty) return null;
    final RegExpMatch? iso = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$',
    ).firstMatch(text);
    if (iso != null) {
      return _validDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final RegExpMatch? local = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$',
    ).firstMatch(text);
    if (local == null) return null;

    final int first = int.parse(local.group(1)!);
    final int second = int.parse(local.group(2)!);
    final int rawYear = int.parse(local.group(3)!);
    final int year = rawYear < 100 ? rawYear + 2000 : rawYear;
    final bool monthFirst = widget.dateFormatPattern.startsWith('MM');

    final DateTime? preferred =
        monthFirst
            ? _validDate(year, first, second)
            : _validDate(year, second, first);
    if (preferred != null) return preferred;

    return monthFirst
        ? _validDate(year, second, first)
        : _validDate(year, first, second);
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || year > DateTime.now().year + 5) return null;
    final DateTime date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
      _inicioController.text = widget.formatarData(_inicio);
      _fimController.text = widget.formatarData(_fim);
      _erro = null;
    });
  }

  void _setPeriodoAte(DateTime fim) {
    setState(() {
      _inicio = null;
      _fim = DateTime(fim.year, fim.month, fim.day);
      _inicioController.clear();
      _fimController.text = widget.formatarData(_fim);
      _erro = null;
    });
  }

  String _periodoResumoAtual() {
    final String inicio = _inicioController.text.trim();
    final String fim = _fimController.text.trim();
    if (inicio.isEmpty && fim.isEmpty) {
      return _txt(
        'atendimentoTecnico.web.dateFilterDialog.allDates',
        'Todas as datas',
      );
    }
    if (inicio.isNotEmpty && fim.isNotEmpty) {
      return _txt(
        'atendimentoTecnico.web.dateFilterDialog.dateRange',
        '{start} até {end}',
      ).replaceAll('{start}', inicio).replaceAll('{end}', fim);
    }
    if (inicio.isNotEmpty) {
      return _txt(
        'atendimentoTecnico.web.dateFilterDialog.dateFrom',
        'A partir de {date}',
      ).replaceAll('{date}', inicio);
    }
    return _txt(
      'atendimentoTecnico.web.dateFilterDialog.dateUntil',
      'Até {date}',
    ).replaceAll('{date}', fim);
  }

  String _dateHint() {
    final String pattern = widget.dateFormatPattern.trim();
    if (pattern.isNotEmpty) return pattern;
    return _txt(
      'atendimentoTecnico.web.dateFilterDialog.dateHint',
      'dd/MM/yyyy',
    );
  }
}

class _DateFilterImpactIcon extends StatelessWidget {
  const _DateFilterImpactIcon({
    required this.accent,
    required this.reduceMotion,
  });

  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 1 : 680),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        final double ringScale = 0.82 + (0.34 * value);
        final double iconScale = 0.86 + (0.14 * value);
        return SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Opacity(
                opacity: (1 - value) * 0.28,
                child: Transform.scale(
                  scale: ringScale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: iconScale,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: accent,
                    size: 29,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Transform.scale(
                  scale: Curves.easeOutBack.transform(value),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WebThemeTokens.of(context).surfaceElevated,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateFilterSummaryItem {
  const _DateFilterSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
