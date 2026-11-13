import 'package:flutter/material.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/six_web_action_styles.dart';
import '../../theme/web_theme_tokens.dart';

/// A draft: opening or dismissing the panel never changes the agenda filters.
class AgendaFiltrosAvancados {
  AgendaFiltrosAvancados({
    Set<String> pagamentos = const {},
    Set<String> centros = const {},
    this.somenteImpostoRenda = false,
    this.mostrarCancelados = false,
  }) : pagamentos = Set.unmodifiable(pagamentos),
       centros = Set.unmodifiable(centros);

  final Set<String> pagamentos;
  final Set<String> centros;
  final bool somenteImpostoRenda;
  final bool mostrarCancelados;
}

Future<AgendaFiltrosAvancados?> showAgendaFiltrosAvancadosWeb({
  required BuildContext context,
  required AgendaFiltrosAvancados initial,
  required List<String> pagamentos,
  required List<String> centros,
  required String espaco,
  bool statusCancelado = false,
  Future<String?> Function(String)? onEditarPagamento,
}) => showGeneralDialog<AgendaFiltrosAvancados>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.t('common.close'),
  barrierColor: WebThemeTokens.of(
    context,
  ).workspaceBackground.withValues(alpha: .65),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 220),
  pageBuilder: (dialogContext, _, _) => Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      width: MediaQuery.sizeOf(dialogContext).width.clamp(0, 460).toDouble(),
      height: double.infinity,
      child: InheritedTheme.captureAll(
        context,
        AgendaFiltrosAvancadosWeb(
          initial: initial,
          pagamentos: pagamentos,
          centros: centros,
          espaco: espaco,
          statusCancelado: statusCancelado,
          onEditarPagamento: onEditarPagamento,
        ),
      ),
    ),
  ),
  transitionBuilder: (_, animation, _, child) => SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

class AgendaFiltrosAvancadosWeb extends StatefulWidget {
  const AgendaFiltrosAvancadosWeb({
    super.key,
    required this.initial,
    required this.pagamentos,
    required this.centros,
    required this.espaco,
    this.statusCancelado = false,
    this.onEditarPagamento,
  });

  final AgendaFiltrosAvancados initial;
  final List<String> pagamentos, centros;
  final String espaco;
  final bool statusCancelado;
  final Future<String?> Function(String)? onEditarPagamento;

  @override
  State<AgendaFiltrosAvancadosWeb> createState() =>
      _AgendaFiltrosAvancadosWebState();
}

class _AgendaFiltrosAvancadosWebState extends State<AgendaFiltrosAvancadosWeb> {
  late final Set<String> _pagamentos = {...widget.initial.pagamentos};
  late final Set<String> _centros = {...widget.initial.centros};
  late final List<String> _opcoesPagamento = [...widget.pagamentos];
  late bool _impostoRenda = widget.initial.somenteImpostoRenda;
  late bool _cancelados = widget.initial.mostrarCancelados;
  bool _editando = false;

  Future<void> _editar(String nome) async {
    setState(() => _editando = true);
    try {
      final novoNome = await widget.onEditarPagamento!(nome);
      if (!mounted || novoNome == null) return;
      setState(() {
        _opcoesPagamento[_opcoesPagamento.indexOf(nome)] = novoNome;
        if (_pagamentos.remove(nome)) _pagamentos.add(novoNome);
      });
    } finally {
      if (mounted) setState(() => _editando = false);
    }
  }

  Widget _opcoes(
    String title,
    List<String> values,
    Set<String> selected, {
    bool editavel = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selected.isEmpty
              ? context.t('common.all')
              : context
                    .t('agenda.web.selectedCount')
                    .replaceAll('{count}', '${selected.length}'),
          style: TextStyle(color: tokens.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.t('agenda.web.noOptions'),
              style: TextStyle(color: tokens.secondaryText),
            ),
          ),
        for (final value in values)
          CheckboxListTile(
            value: selected.contains(value),
            onChanged: _editando
                ? null
                : (checked) => setState(() {
                    checked == true
                        ? selected.add(value)
                        : selected.remove(value);
                  }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(value, style: TextStyle(color: tokens.primaryText)),
            secondary: editavel && widget.onEditarPagamento != null
                ? IconButton(
                    tooltip: context.t('paymentSettings.edit'),
                    onPressed: _editando ? null : () => _editar(value),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  )
                : null,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    return PopScope(
      canPop: !_editando,
      child: Material(
        color: tokens.surfaceElevated,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('agenda.web.moreFilters'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.espaco,
                            style: TextStyle(color: tokens.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('common.close'),
                      onPressed: _editando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      context.t('agenda.web.filtersHint'),
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                    const SizedBox(height: 24),
                    _opcoes(
                      context.t('agenda.web.paymentType'),
                      _opcoesPagamento,
                      _pagamentos,
                      editavel: true,
                    ),
                    Divider(height: 32, color: tokens.divider),
                    _opcoes(
                      context.t('agenda.web.costCenter'),
                      widget.centros,
                      _centros,
                    ),
                    Divider(height: 32, color: tokens.divider),
                    SwitchListTile(
                      key: const ValueKey('ir-filter'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('ir.filter')),
                      value: _impostoRenda,
                      onChanged: _editando
                          ? null
                          : (value) => setState(() => _impostoRenda = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.t('agenda.list.showCanceled')),
                      subtitle: widget.statusCancelado
                          ? Text(context.t('agenda.web.canceledStatusHint'))
                          : null,
                      value: widget.statusCancelado || _cancelados,
                      onChanged: _editando || widget.statusCancelado
                          ? null
                          : (value) => setState(() => _cancelados = value),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _editando
                          ? null
                          : () => setState(() {
                              _pagamentos.clear();
                              _centros.clear();
                              _impostoRenda = false;
                              _cancelados = false;
                            }),
                      child: Text(context.t('common.clear')),
                    ),
                    TextButton(
                      onPressed: _editando
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(context.t('common.cancel')),
                    ),
                    FilledButton(
                      key: const ValueKey('agenda-apply-filters'),
                      style: SixWebActionStyles.primary(context),
                      onPressed: _editando
                          ? null
                          : () => Navigator.pop(
                              context,
                              AgendaFiltrosAvancados(
                                pagamentos: _pagamentos,
                                centros: _centros,
                                somenteImpostoRenda: _impostoRenda,
                                mostrarCancelados: _cancelados,
                              ),
                            ),
                      child: Text(context.t('agenda.mobile.applyFilters')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
