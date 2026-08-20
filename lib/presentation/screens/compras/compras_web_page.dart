import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/six_web_select_field.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

part 'compras_demo_models.dart';
part 'compras_demo_store.dart';
part 'compras_web_i18n.dart';
part 'compras_web_i18n_en.dart';
part 'compras_web_i18n_es.dart';
part 'compras_web_editor.dart';
part 'compras_web_widgets.dart';

/// Protótipo funcional do módulo de Compras para Flutter Web.
///
/// Os dados permanecem somente em memória. Não há chamadas HTTP, persistência
/// local ou integração com estoque/financeiro. O objetivo é validar a jornada e
/// as funcionalidades antes da implementação definitiva no backend.
class ComprasWebPage extends StatefulWidget {
  const ComprasWebPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ComprasWebPage> createState() => _ComprasWebPageState();
}

class _ComprasWebPageState extends State<ComprasWebPage> {
  final _ComprasDemoStore _store = _ComprasDemoStore.instance;
  final TextEditingController _buscaController = TextEditingController();

  _CompraDemo? _compraSelecionada;
  _CompraDemoStep _etapaAtual = _CompraDemoStep.dados;
  _CompraFiltroStatus _filtroStatus = _CompraFiltroStatus.todos;
  _CompraOrdenacao _ordenacao = _CompraOrdenacao.maisRecentes;
  _CompraPeriodo _periodo = _CompraPeriodo.todos;

  void _rebuild(VoidCallback mutation) {
    if (!mounted) {
      return;
    }
    setState(mutation);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _formatarMoeda(double valor, {String? codigoMoeda}) {
    final LocaleSettingsProvider regionalizacao =
        context.read<LocaleSettingsProvider>();
    final String codigo = codigoMoeda ?? regionalizacao.currencyCode;
    final String simbolo = LocaleSettingsProvider.currencySymbolForCode(codigo);
    return '$simbolo ${regionalizacao.formatCurrency(valor, showCurrencySymbol: false)}';
  }

  String _formatarData(DateTime data) {
    return context.read<LocaleSettingsProvider>().formatDate(data);
  }

  String _formatarDataHora(DateTime data) {
    final LocaleSettingsProvider regionalizacao =
        context.read<LocaleSettingsProvider>();
    return '${regionalizacao.formatDate(data)} • ${regionalizacao.formatTime(data)}';
  }

  double _parseNumero(String value) {
    final String normalized = value
        .trim()
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String _numeroEditavel(num value) {
    final double decimal = value.toDouble();
    if (decimal == decimal.roundToDouble()) {
      return decimal.toInt().toString();
    }
    return decimal
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  List<_CompraDemo> get _comprasFiltradas {
    final String query = _buscaController.text.trim().toLowerCase();
    final DateTime agora = DateTime.now();
    final List<_CompraDemo> resultado = _store.compras
        .where((_CompraDemo compra) {
          final bool statusValido = switch (_filtroStatus) {
            _CompraFiltroStatus.todos => true,
            _CompraFiltroStatus.rascunho =>
              compra.status == _CompraDemoStatus.rascunho,
            _CompraFiltroStatus.confirmada =>
              compra.status == _CompraDemoStatus.confirmada,
            _CompraFiltroStatus.cancelada =>
              compra.status == _CompraDemoStatus.cancelada,
          };
          if (!statusValido) {
            return false;
          }

          final bool periodoValido = switch (_periodo) {
            _CompraPeriodo.todos => true,
            _CompraPeriodo.seteDias => compra.atualizadaEm.isAfter(
              agora.subtract(const Duration(days: 7)),
            ),
            _CompraPeriodo.trintaDias => compra.atualizadaEm.isAfter(
              agora.subtract(const Duration(days: 30)),
            ),
            _CompraPeriodo.mesAtual =>
              compra.atualizadaEm.year == agora.year &&
                  compra.atualizadaEm.month == agora.month,
          };
          if (!periodoValido) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }
          final String searchable =
              <String>[
                compra.identificadorVisual,
                compra.fornecedorNome,
                compra.fornecedorDocumento,
                compra.numeroDocumento,
                compra.tipoDocumento,
                ...compra.itens.map((_CompraDemoItem item) => item.descricao),
              ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);

    resultado.sort((_CompraDemo a, _CompraDemo b) {
      return switch (_ordenacao) {
        _CompraOrdenacao.maisRecentes => b.atualizadaEm.compareTo(
          a.atualizadaEm,
        ),
        _CompraOrdenacao.maisAntigas => a.atualizadaEm.compareTo(
          b.atualizadaEm,
        ),
        _CompraOrdenacao.maiorValor => b.totalCompra.compareTo(a.totalCompra),
        _CompraOrdenacao.menorValor => a.totalCompra.compareTo(b.totalCompra),
      };
    });
    return resultado;
  }

  double get _totalConfirmado {
    return _store.compras
        .where(
          (_CompraDemo compra) => compra.status == _CompraDemoStatus.confirmada,
        )
        .fold<double>(
          0,
          (double sum, _CompraDemo compra) => sum + compra.totalCompra,
        );
  }

  double get _totalContasPagar {
    return _store.compras
        .where(
          (_CompraDemo compra) =>
              compra.status != _CompraDemoStatus.cancelada &&
              compra.gerarContaPagar &&
              !compra.jaPago,
        )
        .fold<double>(
          0,
          (double sum, _CompraDemo compra) => sum + compra.totalCompra,
        );
  }

  int get _quantidadeRascunhos =>
      _store.compras
          .where(
            (_CompraDemo compra) => compra.status == _CompraDemoStatus.rascunho,
          )
          .length;

  int get _itensComEntrada => _store.compras
      .where(
        (_CompraDemo compra) => compra.status == _CompraDemoStatus.confirmada,
      )
      .fold<int>(
        0,
        (int sum, _CompraDemo compra) => sum + compra.itensComEstoque,
      );

  void _novaCompra() {
    final String moeda = context.read<LocaleSettingsProvider>().currencyCode;
    final _CompraDemo compra = _store.criarRascunho(moeda: moeda);
    setState(() {
      _compraSelecionada = compra;
      _etapaAtual = _CompraDemoStep.dados;
    });
  }

  void _abrirCompra(_CompraDemo compra) {
    setState(() {
      _compraSelecionada = compra;
      _etapaAtual =
          compra.editavel ? _CompraDemoStep.dados : _CompraDemoStep.resumo;
    });
  }

  void _voltarParaLista() {
    setState(() {
      _compraSelecionada = null;
      _etapaAtual = _CompraDemoStep.dados;
    });
  }

  void _duplicarCompra(_CompraDemo compra) {
    final _CompraDemo copia = _store.duplicar(compra);
    setState(() {
      _compraSelecionada = copia;
      _etapaAtual = _CompraDemoStep.dados;
    });
    _mostrarMensagem(context.comprasT('compras.message.duplicated'));
  }

  Future<void> _redefinirDemonstracao() async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(context.comprasT('compras.reset.title')),
          content: Text(context.comprasT('compras.reset.description')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.comprasT('common.cancel')),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.comprasT('compras.reset.action')),
            ),
          ],
        );
      },
    );
    if (confirmado != true || !mounted) {
      return;
    }
    setState(() {
      _store.reset();
      _compraSelecionada = null;
      _buscaController.clear();
      _filtroStatus = _CompraFiltroStatus.todos;
      _periodo = _CompraPeriodo.todos;
      _ordenacao = _CompraOrdenacao.maisRecentes;
    });
    _mostrarMensagem(context.comprasT('compras.message.reset'));
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: erro ? tokens.danger : tokens.primaryText,
          content: Text(mensagem),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider>();
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: tokens.surfaceMuted,
            foregroundColor: tokens.info,
            disabledBackgroundColor: tokens.disabledBackground,
            disabledForegroundColor: tokens.disabledForeground,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(
              color: tokens.info.withValues(alpha: 0.24),
              width: 1.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: tokens.info,
            foregroundColor: const Color(0xFF08111F),
            disabledBackgroundColor: tokens.disabledBackground,
            disabledForegroundColor: tokens.disabledForeground,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: tokens.secondaryText,
            disabledForegroundColor: tokens.disabledForeground,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: ColoredBox(
        color: tokens.workspaceBackground,
        child: AnimatedSwitcher(
          duration: WebThemeTokens.transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child:
              _compraSelecionada == null
                  ? _buildListaCompras()
                  : _buildEditorCompra(_compraSelecionada!),
        ),
      ),
    );
  }

  Widget _buildListaCompras() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<_CompraDemo> compras = _comprasFiltradas;
    return LayoutBuilder(
      key: const ValueKey<String>('compras-lista'),
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 840;
        final EdgeInsets padding = EdgeInsets.fromLTRB(
          compacto ? 16 : 26,
          compacto ? 16 : 24,
          compacto ? 16 : 26,
          26,
        );
        return Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: padding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        _buildCabecalhoLista(compacto),
                        const SizedBox(height: 14),
                        const _CompraDemoBanner(),
                        const SizedBox(height: 18),
                        _buildIndicadores(compacto),
                        const SizedBox(height: 18),
                        _buildFiltros(compacto),
                        const SizedBox(height: 14),
                        if (compras.isEmpty)
                          _CompraSurfaceCard(
                            child: _CompraEmptyState(
                              icon: Icons.search_off_outlined,
                              title: context.comprasT(
                                'compras.empty.filtered.title',
                              ),
                              description: context.comprasT(
                                'compras.empty.filtered.description',
                              ),
                              action: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _buscaController.clear();
                                    _filtroStatus = _CompraFiltroStatus.todos;
                                    _periodo = _CompraPeriodo.todos;
                                  });
                                },
                                icon: const Icon(Icons.filter_alt_off_outlined),
                                label: Text(
                                  context.comprasT('compras.filters.clear'),
                                ),
                              ),
                            ),
                          )
                        else
                          ...compras.indexed.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildCompraCard(
                                compra: entry.$2,
                                compacto: compacto,
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compacto ? 16 : 26,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.cardBorder)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  Text(
                    context
                        .comprasT('compras.footer.count')
                        .replaceAll('{count}', compras.length.toString()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _redefinirDemonstracao,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(context.comprasT('compras.reset.action')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCabecalhoLista(bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (widget.onBack != null) ...<Widget>[
              IconButton(
                tooltip: context.comprasT('common.back'),
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tokens.selectedBackground,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: tokens.selectedBorder),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.comprasT('compras.title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.comprasT('compras.subtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          texto,
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _novaCompra,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.comprasT('compras.new')),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: texto),
        const SizedBox(width: 18),
        FilledButton.icon(
          onPressed: _novaCompra,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.comprasT('compras.new')),
        ),
      ],
    );
  }

  Widget _buildIndicadores(bool compacto) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double largura = constraints.maxWidth;
        final int colunas =
            largura >= 1100
                ? 4
                : largura >= 580
                ? 2
                : 1;
        final double itemWidth = (largura - ((colunas - 1) * 12)) / colunas;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _CompraKpiCard(
                icon: Icons.receipt_long_outlined,
                label: context.comprasT('compras.kpi.confirmedValue'),
                value: _formatarMoeda(_totalConfirmado),
                helper: context.comprasT('compras.kpi.confirmedValue.helper'),
                accent: tokens.success,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _CompraKpiCard(
                icon: Icons.account_balance_wallet_outlined,
                label: context.comprasT('compras.kpi.payables'),
                value: _formatarMoeda(_totalContasPagar),
                helper: context.comprasT('compras.kpi.payables.helper'),
                accent: tokens.info,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _CompraKpiCard(
                icon: Icons.edit_note_outlined,
                label: context.comprasT('compras.kpi.drafts'),
                value: _quantidadeRascunhos.toString(),
                helper: context.comprasT('compras.kpi.drafts.helper'),
                accent: tokens.warning,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _CompraKpiCard(
                icon: Icons.inventory_2_outlined,
                label: context.comprasT('compras.kpi.stockItems'),
                value: _itensComEntrada.toString(),
                helper: context.comprasT('compras.kpi.stockItems.helper'),
                accent: tokens.financialPositive,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltros(bool compacto) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return _CompraSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth < 760;
          final Widget busca = TextField(
            controller: _buscaController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.comprasT('compras.filters.search'),
              hintText: context.comprasT('compras.filters.searchHint'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  _buscaController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: context.comprasT('common.clear'),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: tokens.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          final List<String> statusOptions = <String>[
            context.comprasT('common.all'),
            context.comprasT('compras.status.draft'),
            context.comprasT('compras.status.confirmed'),
            context.comprasT('compras.status.cancelled'),
          ];
          final Widget status = SixWebSelectField(
            label: context.comprasT('compras.filters.status'),
            value: _labelFiltroStatus(_filtroStatus),
            items: statusOptions,
            icon: Icons.flag_outlined,
            width: double.infinity,
            onSelected: (String selected) {
              setState(() => _filtroStatus = _statusPorLabel(selected));
            },
          );
          final List<String> periodoOptions = <String>[
            context.comprasT('compras.period.all'),
            context.comprasT('compras.period.7days'),
            context.comprasT('compras.period.30days'),
            context.comprasT('compras.period.currentMonth'),
          ];
          final Widget periodo = SixWebSelectField(
            label: context.comprasT('compras.filters.period'),
            value: _labelPeriodo(_periodo),
            items: periodoOptions,
            icon: Icons.calendar_today_outlined,
            width: double.infinity,
            onSelected: (String selected) {
              setState(() => _periodo = _periodoPorLabel(selected));
            },
          );
          final List<String> ordenacaoOptions = <String>[
            context.comprasT('compras.sort.recent'),
            context.comprasT('compras.sort.oldest'),
            context.comprasT('compras.sort.highest'),
            context.comprasT('compras.sort.lowest'),
          ];
          final Widget ordenacao = SixWebSelectField(
            label: context.comprasT('compras.filters.sort'),
            value: _labelOrdenacao(_ordenacao),
            items: ordenacaoOptions,
            icon: Icons.swap_vert_rounded,
            width: double.infinity,
            onSelected: (String selected) {
              setState(() => _ordenacao = _ordenacaoPorLabel(selected));
            },
          );
          if (narrow) {
            return Column(
              children: <Widget>[
                busca,
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: status),
                    const SizedBox(width: 10),
                    Expanded(child: periodo),
                  ],
                ),
                const SizedBox(height: 10),
                ordenacao,
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(flex: 3, child: busca),
              const SizedBox(width: 10),
              Expanded(child: status),
              const SizedBox(width: 10),
              Expanded(child: periodo),
              const SizedBox(width: 10),
              Expanded(child: ordenacao),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompraCard({
    required _CompraDemo compra,
    required bool compacto,
  }) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String fornecedor =
        compra.fornecedorNome.trim().isEmpty
            ? context.comprasT('compras.supplier.notSelected')
            : compra.fornecedorNome;
    final String documento =
        compra.numeroDocumento.trim().isEmpty
            ? context.comprasT('compras.document.notInformed')
            : '${compra.tipoDocumento} ${compra.numeroDocumento}';

    final Widget resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              compra.identificadorVisual,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            _CompraStatusBadge(status: compra.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          fornecedor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: <Widget>[
            _metadataCard(Icons.receipt_long_outlined, documento),
            _metadataCard(
              Icons.inventory_2_outlined,
              context
                  .comprasT('compras.list.itemsCount')
                  .replaceAll('{count}', compra.itens.length.toString()),
            ),
            _metadataCard(
              Icons.event_outlined,
              _formatarData(compra.dataEntrada),
            ),
            if (compra.gerarContaPagar &&
                compra.status != _CompraDemoStatus.cancelada)
              _metadataCard(
                Icons.account_balance_wallet_outlined,
                context
                    .comprasT('compras.list.installments')
                    .replaceAll(
                      '{count}',
                      compra.quantidadeParcelas.toString(),
                    ),
              ),
          ],
        ),
      ],
    );

    final Widget valores = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 185),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              context.comprasT('compras.list.total'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.secondaryText,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatarMoeda(compra.totalCompra, codigoMoeda: compra.moeda),
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              context
                  .comprasT('compras.list.updated')
                  .replaceAll('{date}', _formatarDataHora(compra.atualizadaEm)),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.mutedText,
              ),
            ),
          ],
        ),
      ),
    );

    final Widget acoes = Wrap(
      spacing: 7,
      runSpacing: 7,
      alignment: WrapAlignment.end,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: () => _abrirCompra(compra),
          icon: Icon(
            compra.editavel ? Icons.edit_outlined : Icons.visibility_outlined,
            size: 18,
          ),
          label: Text(
            compra.editavel
                ? context.comprasT('common.edit')
                : context.comprasT('compras.action.view'),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: context.comprasT('compras.action.more'),
          onSelected: (String action) {
            switch (action) {
              case 'duplicate':
                _duplicarCompra(compra);
                return;
              case 'cancel':
                _solicitarCancelamento(compra);
                return;
            }
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'duplicate',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(context.comprasT('compras.action.duplicate')),
                  ),
                ),
                if (compra.status != _CompraDemoStatus.cancelada)
                  PopupMenuItem<String>(
                    value: 'cancel',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.cancel_outlined,
                        color: tokens.danger,
                      ),
                      title: Text(
                        context.comprasT('compras.action.cancel'),
                        style: TextStyle(color: tokens.danger),
                      ),
                    ),
                  ),
              ],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              border: Border.all(color: tokens.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: tokens.secondaryText,
            ),
          ),
        ),
      ],
    );

    return _CompraSurfaceCard(
      padding: const EdgeInsets.all(16),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  resumo,
                  const SizedBox(height: 14),
                  valores,
                  const SizedBox(height: 12),
                  acoes,
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: tokens.secondaryText,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: resumo),
                  const SizedBox(width: 16),
                  valores,
                  const SizedBox(width: 14),
                  acoes,
                ],
              ),
    );
  }

  Widget _metadataCard(IconData icon, String text) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: tokens.mutedText),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
        ),
      ],
    );
  }

  String _labelFiltroStatus(_CompraFiltroStatus status) {
    switch (status) {
      case _CompraFiltroStatus.todos:
        return context.comprasT('common.all');
      case _CompraFiltroStatus.rascunho:
        return context.comprasT('compras.status.draft');
      case _CompraFiltroStatus.confirmada:
        return context.comprasT('compras.status.confirmed');
      case _CompraFiltroStatus.cancelada:
        return context.comprasT('compras.status.cancelled');
    }
  }

  _CompraFiltroStatus _statusPorLabel(String label) {
    if (label == context.comprasT('compras.status.draft')) {
      return _CompraFiltroStatus.rascunho;
    }
    if (label == context.comprasT('compras.status.confirmed')) {
      return _CompraFiltroStatus.confirmada;
    }
    if (label == context.comprasT('compras.status.cancelled')) {
      return _CompraFiltroStatus.cancelada;
    }
    return _CompraFiltroStatus.todos;
  }

  String _labelPeriodo(_CompraPeriodo periodo) {
    switch (periodo) {
      case _CompraPeriodo.todos:
        return context.comprasT('compras.period.all');
      case _CompraPeriodo.seteDias:
        return context.comprasT('compras.period.7days');
      case _CompraPeriodo.trintaDias:
        return context.comprasT('compras.period.30days');
      case _CompraPeriodo.mesAtual:
        return context.comprasT('compras.period.currentMonth');
    }
  }

  _CompraPeriodo _periodoPorLabel(String label) {
    if (label == context.comprasT('compras.period.7days')) {
      return _CompraPeriodo.seteDias;
    }
    if (label == context.comprasT('compras.period.30days')) {
      return _CompraPeriodo.trintaDias;
    }
    if (label == context.comprasT('compras.period.currentMonth')) {
      return _CompraPeriodo.mesAtual;
    }
    return _CompraPeriodo.todos;
  }

  String _labelOrdenacao(_CompraOrdenacao ordenacao) {
    switch (ordenacao) {
      case _CompraOrdenacao.maisRecentes:
        return context.comprasT('compras.sort.recent');
      case _CompraOrdenacao.maisAntigas:
        return context.comprasT('compras.sort.oldest');
      case _CompraOrdenacao.maiorValor:
        return context.comprasT('compras.sort.highest');
      case _CompraOrdenacao.menorValor:
        return context.comprasT('compras.sort.lowest');
    }
  }

  _CompraOrdenacao _ordenacaoPorLabel(String label) {
    if (label == context.comprasT('compras.sort.oldest')) {
      return _CompraOrdenacao.maisAntigas;
    }
    if (label == context.comprasT('compras.sort.highest')) {
      return _CompraOrdenacao.maiorValor;
    }
    if (label == context.comprasT('compras.sort.lowest')) {
      return _CompraOrdenacao.menorValor;
    }
    return _CompraOrdenacao.maisRecentes;
  }
}
