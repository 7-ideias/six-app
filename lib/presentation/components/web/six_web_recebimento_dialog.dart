import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/recebimento_forma_input.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

enum SixWebRecebimentoTipo { total, parcial }

class SixWebRecebimentoResultado {
  const SixWebRecebimentoResultado({
    required this.tipo,
    required this.valor,
    required this.codigoTipoRecebimento,
    required this.descricaoTipoRecebimento,
    required this.formaPagamentoBackend,
    required this.recebimentos,
    this.observacao,
  });

  final SixWebRecebimentoTipo tipo;
  final double valor;
  final String codigoTipoRecebimento;
  final String descricaoTipoRecebimento;
  final String formaPagamentoBackend;
  final List<RecebimentoFormaInput> recebimentos;
  final String? observacao;

  bool get total => tipo == SixWebRecebimentoTipo.total;
  bool get parcial => tipo == SixWebRecebimentoTipo.parcial;
}

class SixWebTipoRecebimentoOpcao {
  const SixWebTipoRecebimentoOpcao({
    required this.codigoTipo,
    required this.descricao,
    required this.formaPagamentoBackend,
  });

  final String codigoTipo;
  final String descricao;
  final String formaPagamentoBackend;
}

class SixWebRecebimentoDialog extends StatefulWidget {
  const SixWebRecebimentoDialog({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.valorAberto,
    this.caixaApiClient,
    this.contato,
    this.permitirParcial = true,
    this.observacaoInicial,
    this.codigoTipoInicial,
  });

  final String titulo;
  final String descricao;
  final double valorAberto;
  final CaixaApiClient? caixaApiClient;
  final String? contato;
  final bool permitirParcial;
  final String? observacaoInicial;
  final String? codigoTipoInicial;

  static Future<SixWebRecebimentoResultado?> show(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required double valorAberto,
    String? contato,
    bool permitirParcial = true,
    String? observacaoInicial,
    String? codigoTipoInicial,
    CaixaApiClient? caixaApiClient,
  }) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return showGeneralDialog<SixWebRecebimentoResultado>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
      pageBuilder: (
        BuildContext routeContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return _RecebimentoRouteSurface(
          animation: animation,
          reduceMotion: reduceMotion,
          child: SixWebRecebimentoDialog(
            titulo: titulo,
            descricao: descricao,
            valorAberto: valorAberto,
            caixaApiClient: caixaApiClient,
            contato: contato,
            permitirParcial: permitirParcial,
            observacaoInicial: observacaoInicial,
            codigoTipoInicial: codigoTipoInicial,
          ),
        );
      },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
    );
  }

  @override
  State<SixWebRecebimentoDialog> createState() =>
      _SixWebRecebimentoDialogState();
}

class _SixWebRecebimentoDialogState extends State<SixWebRecebimentoDialog>
    with SingleTickerProviderStateMixin {
  late final CaixaApiClient _caixaApiClient;
  final TextEditingController _observacaoController = TextEditingController();
  final List<_RecebimentoFormaDraft> _formas = <_RecebimentoFormaDraft>[];
  late final AnimationController _iconController;

  bool _carregandoTipos = true;
  bool _processando = false;
  String? _erroValor;
  SixWebRecebimentoTipo _tipo = SixWebRecebimentoTipo.total;
  List<SixWebTipoRecebimentoOpcao> _opcoes = _opcoesFallback;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static const List<SixWebTipoRecebimentoOpcao> _opcoesFallback =
      <SixWebTipoRecebimentoOpcao>[
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo1',
          descricao: 'Dinheiro',
          formaPagamentoBackend: 'DINHEIRO',
        ),
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo2',
          descricao: 'Pix',
          formaPagamentoBackend: 'PIX',
        ),
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo3',
          descricao: 'Cartão de crédito',
          formaPagamentoBackend: 'CARTAO_CREDITO',
        ),
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo4',
          descricao: 'Cartão de débito',
          formaPagamentoBackend: 'CARTAO_DEBITO',
        ),
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo5',
          descricao: 'Boleto',
          formaPagamentoBackend: 'BOLETO',
        ),
        SixWebTipoRecebimentoOpcao(
          codigoTipo: 'tipo7',
          descricao: 'Débito automático',
          formaPagamentoBackend: 'DEBITO_AUTOMATICO',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _caixaApiClient = widget.caixaApiClient ?? HttpCaixaApiClient();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _formas.add(
      _RecebimentoFormaDraft(
        opcao: _resolverInicial(_opcoes),
        controller: TextEditingController(
          text: _formatarValorDigitavel(widget.valorAberto),
        ),
      ),
    );
    _observacaoController.text = widget.observacaoInicial ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
    _carregarTipos();
  }

  @override
  void dispose() {
    for (final _RecebimentoFormaDraft forma in _formas) {
      forma.controller.dispose();
    }
    _iconController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTipos() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<SixWebTipoRecebimentoOpcao> opcoes = _montarOpcoes(
        informacoes.tiposRecebimento,
      );
      if (!mounted) return;
      setState(() {
        if (opcoes.isNotEmpty) _opcoes = opcoes;
        _sincronizarOpcoesDasFormas();
        _carregandoTipos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sincronizarOpcoesDasFormas();
        _carregandoTipos = false;
      });
    }
  }

  List<SixWebTipoRecebimentoOpcao> _montarOpcoes(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos =
        tipos
            .where((TiposRecebimento tipo) => tipo.ativo)
            .where(
              (TiposRecebimento tipo) =>
                  tipo.naturezaRecebimento.trim().toUpperCase() != 'FUTURO',
            )
            .toList()
          ..sort(
            (TiposRecebimento a, TiposRecebimento b) =>
                a.ordemExibicao.compareTo(b.ordemExibicao),
          );

    final List<SixWebTipoRecebimentoOpcao> opcoes =
        <SixWebTipoRecebimentoOpcao>[];
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toLowerCase();
      final String? backend = _formaPagamentoBackendPorCodigo(codigo);
      if (backend == null) continue;
      final String descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : _descricaoPadraoPorBackend(backend);
      if (descricao.isEmpty) continue;
      if (opcoes.any(
        (SixWebTipoRecebimentoOpcao opcao) => opcao.codigoTipo == codigo,
      )) {
        continue;
      }
      opcoes.add(
        SixWebTipoRecebimentoOpcao(
          codigoTipo: codigo,
          descricao: descricao,
          formaPagamentoBackend: backend,
        ),
      );
    }
    return opcoes;
  }

  SixWebTipoRecebimentoOpcao _resolverInicial(
    List<SixWebTipoRecebimentoOpcao> opcoes,
  ) {
    final String inicial = widget.codigoTipoInicial?.trim().toLowerCase() ?? '';
    if (inicial.isNotEmpty) {
      for (final SixWebTipoRecebimentoOpcao opcao in opcoes) {
        if (opcao.codigoTipo == inicial) return opcao;
      }
    }
    return opcoes.isEmpty ? _opcoesFallback.first : opcoes.first;
  }

  void _sincronizarOpcoesDasFormas() {
    for (final _RecebimentoFormaDraft forma in _formas) {
      final String codigo = forma.opcao.codigoTipo;
      forma.opcao = _opcoes.firstWhere(
        (SixWebTipoRecebimentoOpcao opcao) => opcao.codigoTipo == codigo,
        orElse: () => _resolverInicial(_opcoes),
      );
    }
  }

  void _alterarTipo(SixWebRecebimentoTipo tipo) {
    setState(() {
      _tipo = tipo;
      _erroValor = null;
      if (tipo == SixWebRecebimentoTipo.total && _formas.length == 1) {
        _formas.first.controller.text = _formatarValorDigitavel(
          widget.valorAberto,
        );
      }
    });
  }

  void _confirmar() {
    if (_processando) return;
    final Set<String> codigos = <String>{};
    final List<RecebimentoFormaInput> recebimentos = <RecebimentoFormaInput>[];
    for (final _RecebimentoFormaDraft forma in _formas) {
      if (!codigos.add(forma.opcao.codigoTipo)) {
        setState(
          () =>
              _erroValor = context.t(
                'recebimento.erroFormaDuplicada',
                fallback:
                    'Cada forma de recebimento pode ser usada apenas uma vez.',
              ),
        );
        return;
      }
      final double valorForma = _parseValor(forma.controller.text);
      if (valorForma <= 0) {
        setState(
          () =>
              _erroValor = context.t(
                'recebimento.erroValoresMaioresQueZero',
                fallback: 'Informe valores maiores que zero.',
              ),
        );
        return;
      }
      recebimentos.add(
        RecebimentoFormaInput(
          codigo: forma.opcao.codigoTipo,
          descricao: forma.opcao.descricao,
          valor: valorForma,
        ),
      );
    }

    final double valor = recebimentos.fold<double>(
      0,
      (double total, RecebimentoFormaInput forma) => total + forma.valor,
    );
    if (valor <= 0) {
      setState(
        () =>
            _erroValor = context.t(
              'recebimento.erroValorMaiorQueZero',
              fallback: 'Informe um valor maior que zero.',
            ),
      );
      return;
    }
    if (_tipo == SixWebRecebimentoTipo.parcial && valor >= widget.valorAberto) {
      setState(
        () =>
            _erroValor = context.t(
              'recebimento.erroParcialMenorQueAberto',
              fallback: 'Para parcial, informe um valor menor que o aberto.',
            ),
      );
      return;
    }
    if (_tipo == SixWebRecebimentoTipo.total &&
        (valor - widget.valorAberto).abs() > 0.009) {
      setState(
        () =>
            _erroValor = context.t(
              'recebimento.erroTotalIgualSaldo',
              fallback: 'Para total, o valor precisa quitar o saldo em aberto.',
            ),
      );
      return;
    }

    final _RecebimentoFormaDraft primeiraForma = _formas.first;
    setState(() => _processando = true);
    final SixWebRecebimentoResultado resultado = SixWebRecebimentoResultado(
      tipo: _tipo,
      valor: valor,
      codigoTipoRecebimento: primeiraForma.opcao.codigoTipo,
      descricaoTipoRecebimento: primeiraForma.opcao.descricao,
      formaPagamentoBackend: primeiraForma.opcao.formaPagamentoBackend,
      recebimentos: recebimentos,
      observacao:
          _observacaoController.text.trim().isEmpty
              ? null
              : _observacaoController.text.trim(),
    );
    Future<void>.delayed(Duration(milliseconds: _reduceMotion ? 80 : 220), () {
      if (!mounted) return;
      Navigator.of(context).pop(resultado);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final Color surface =
        theme.brightness == Brightness.dark
            ? const Color(0xFF17253A)
            : tokens.surfaceElevated;
    final Color outline =
        theme.brightness == Brightness.dark
            ? const Color(0xFF2E4467)
            : tokens.cardBorder;
    final Color accentSofter = Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      tokens.surfaceMuted,
    );
    final ButtonStyle primaryActionStyle = FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: tokens.onInfo,
      disabledBackgroundColor: tokens.disabledBackground,
      disabledForegroundColor: tokens.disabledForeground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    final ButtonStyle cancelActionStyle = TextButton.styleFrom(
      foregroundColor:
          theme.brightness == Brightness.dark ? tokens.primaryText : accent,
      backgroundColor:
          theme.brightness == Brightness.dark
              ? tokens.surfaceMuted.withValues(alpha: 0.92)
              : accent.withValues(alpha: 0.08),
      disabledForegroundColor: tokens.disabledForeground,
      disabledBackgroundColor: tokens.disabledBackground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    return PopScope(
      canPop: !_processando,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent intent) {
                if (_processando) return null;
                Navigator.of(context).maybePop();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: widget.titulo,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: outline),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.30),
                        blurRadius: 44,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: surface,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _RecebimentoDialogIcon(
                                      animation: _iconController,
                                      accent: accent,
                                      surfaceColor: surface,
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            widget.titulo,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  color: tokens.primaryText,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.12,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.descricao,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: tokens.secondaryText,
                                                  height: 1.45,
                                                ),
                                          ),
                                          if (widget.contato != null &&
                                              widget.contato!
                                                  .trim()
                                                  .isNotEmpty) ...<Widget>[
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.contato!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color: tokens.mutedText,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                _buildSummaryHighlights(
                                  theme,
                                  tokens,
                                  accent,
                                  accentSofter,
                                ),
                                const SizedBox(height: 18),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        if (widget.permitirParcial)
                                          Theme(
                                            data: theme.copyWith(
                                              segmentedButtonTheme: SegmentedButtonThemeData(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.resolveWith((
                                                        Set<WidgetState> states,
                                                      ) {
                                                        if (states.contains(
                                                          WidgetState.selected,
                                                        )) {
                                                          return accent.withValues(
                                                            alpha:
                                                                theme.brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? 0.18
                                                                    : 0.12,
                                                          );
                                                        }
                                                        return surface;
                                                      }),
                                                  foregroundColor:
                                                      WidgetStateProperty.resolveWith((
                                                        Set<WidgetState> states,
                                                      ) {
                                                        return states.contains(
                                                              WidgetState
                                                                  .selected,
                                                            )
                                                            ? accent
                                                            : tokens
                                                                .secondaryText;
                                                      }),
                                                  side: WidgetStateProperty.resolveWith(
                                                    (Set<WidgetState> states) {
                                                      return BorderSide(
                                                        color:
                                                            states.contains(
                                                                  WidgetState
                                                                      .selected,
                                                                )
                                                                ? accent
                                                                    .withValues(
                                                                      alpha:
                                                                          0.65,
                                                                    )
                                                                : outline,
                                                      );
                                                    },
                                                  ),
                                                  overlayColor:
                                                      WidgetStateProperty.all(
                                                        accent.withValues(
                                                          alpha: 0.08,
                                                        ),
                                                      ),
                                                  textStyle:
                                                      WidgetStateProperty.all(
                                                        theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                  shape: WidgetStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  padding: WidgetStateProperty.all(
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            child: SegmentedButton<
                                              SixWebRecebimentoTipo
                                            >(
                                              selected: <SixWebRecebimentoTipo>{
                                                _tipo,
                                              },
                                              onSelectionChanged:
                                                  (
                                                    Set<SixWebRecebimentoTipo>
                                                    value,
                                                  ) =>
                                                      _alterarTipo(value.first),
                                              segments: <
                                                ButtonSegment<
                                                  SixWebRecebimentoTipo
                                                >
                                              >[
                                                ButtonSegment<
                                                  SixWebRecebimentoTipo
                                                >(
                                                  value:
                                                      SixWebRecebimentoTipo
                                                          .total,
                                                  label: Text(
                                                    context.t(
                                                      'recebimento.total',
                                                      fallback: 'Total',
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.done_all_rounded,
                                                  ),
                                                ),
                                                ButtonSegment<
                                                  SixWebRecebimentoTipo
                                                >(
                                                  value:
                                                      SixWebRecebimentoTipo
                                                          .parcial,
                                                  label: Text(
                                                    context.t(
                                                      'recebimento.parcial',
                                                      fallback: 'Parcial',
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.call_split_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (widget.permitirParcial)
                                          const SizedBox(height: 16),
                                        _formasRecebimentoSection(),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller: _observacaoController,
                                          minLines: 2,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: context.t(
                                              'recebimento.observacao',
                                              fallback: 'Observação',
                                            ),
                                            filled: true,
                                            fillColor: tokens.inputBackground,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: outline,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: accent.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    TextButton(
                                      style: cancelActionStyle,
                                      onPressed:
                                          _processando
                                              ? null
                                              : () =>
                                                  Navigator.of(context).pop(),
                                      child: Text(
                                        context.t(
                                          'common.cancel',
                                          fallback: 'Cancelar',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      style: primaryActionStyle,
                                      onPressed:
                                          _carregandoTipos || _processando
                                              ? null
                                              : _confirmar,
                                      icon:
                                          _processando
                                              ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : const Icon(
                                                Icons.payments_rounded,
                                              ),
                                      label: Text(
                                        _processando
                                            ? context.t(
                                              'vendasAReceber.processingTitle',
                                              fallback:
                                                  'Processando recebimento',
                                            )
                                            : _tipo ==
                                                SixWebRecebimentoTipo.total
                                            ? context.t(
                                              'recebimento.receberTotal',
                                              fallback: 'Receber total',
                                            )
                                            : context.t(
                                              'recebimento.receberParcial',
                                              fallback: 'Receber parcial',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_processando)
                            Positioned.fill(
                              child: _RecebimentoProcessingOverlay(
                                title: context.t(
                                  'vendasAReceber.processingTitle',
                                  fallback: 'Processando recebimento',
                                ),
                                subtitle: context.t(
                                  'vendasAReceber.processingSubtitle',
                                  fallback:
                                      'Aguarde enquanto a operação financeira é sincronizada.',
                                ),
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
      ),
    );
  }

  Widget _buildSummaryHighlights(
    ThemeData theme,
    WebThemeTokens tokens,
    Color accent,
    Color surfaceSoft,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _buildSummaryPill(
          theme: theme,
          tokens: tokens,
          accent: accent,
          surfaceSoft: surfaceSoft,
          icon: Icons.account_balance_wallet_rounded,
          label: context.t(
            'recebimento.valorEmAberto',
            fallback: 'Valor em aberto',
          ),
          value: _formatarMoeda(widget.valorAberto),
        ),
        _buildSummaryPill(
          theme: theme,
          tokens: tokens,
          accent: accent,
          surfaceSoft: surfaceSoft,
          icon: Icons.rule_folder_outlined,
          label: context.t('recebimento.summaryType', fallback: 'Tipo'),
          value:
              _tipo == SixWebRecebimentoTipo.total
                  ? context.t('recebimento.total', fallback: 'Total')
                  : context.t('recebimento.parcial', fallback: 'Parcial'),
        ),
        _buildSummaryPill(
          theme: theme,
          tokens: tokens,
          accent: accent,
          surfaceSoft: surfaceSoft,
          icon: Icons.layers_outlined,
          label: context.t(
            'recebimento.formasRecebimento',
            fallback: 'Formas de recebimento',
          ),
          value: _formas.length.toString(),
        ),
      ],
    );
  }

  Widget _buildSummaryPill({
    required ThemeData theme,
    required WebThemeTokens tokens,
    required Color accent,
    required Color surfaceSoft,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 186),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formasRecebimentoSection() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final ButtonStyle addMethodStyle = OutlinedButton.styleFrom(
      foregroundColor:
          theme.brightness == Brightness.dark ? accent : tokens.primaryText,
      backgroundColor:
          theme.brightness == Brightness.dark
              ? accent.withValues(alpha: 0.10)
              : Colors.transparent,
      disabledForegroundColor: tokens.disabledForeground,
      disabledBackgroundColor: tokens.disabledBackground,
      side: BorderSide(
        color:
            theme.brightness == Brightness.dark
                ? accent.withValues(alpha: 0.34)
                : tokens.cardBorder,
      ),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    if (_carregandoTipos) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.t(
                  'recebimento.carregandoTipos',
                  fallback: 'Carregando tipos de recebimento...',
                ),
                style: TextStyle(color: tokens.primaryText),
              ),
            ),
          ],
        ),
      );
    }

    final double totalInformado = _formas.fold<double>(
      0,
      (double total, _RecebimentoFormaDraft forma) =>
          total + _parseValor(forma.controller.text),
    );
    final double restante = widget.valorAberto - totalInformado;
    final bool podeAdicionar = _formas.length < _opcoes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(
                  'recebimento.formasRecebimento',
                  fallback: 'Formas de recebimento',
                ),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${context.t('recebimento.restante', fallback: 'Restante')}: ${_formatarMoeda(restante < 0 ? 0 : restante)}',
              style: TextStyle(
                color: tokens.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._formas.asMap().entries.map(
          (MapEntry<int, _RecebimentoFormaDraft> entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _formaRecebimentoCard(entry.key, entry.value),
          ),
        ),
        if (_erroValor != null) ...<Widget>[
          Text(
            _erroValor!,
            style: TextStyle(
              color: tokens.danger,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: podeAdicionar ? _adicionarForma : null,
          style: addMethodStyle,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            context.t(
              'recebimento.adicionarForma',
              fallback: 'Adicionar forma',
            ),
          ),
        ),
      ],
    );
  }

  Widget _formaRecebimentoCard(int index, _RecebimentoFormaDraft forma) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Set<String> codigosEmUso =
        _formas
            .where((_RecebimentoFormaDraft item) => !identical(item, forma))
            .map((_RecebimentoFormaDraft item) => item.opcao.codigoTipo)
            .toSet();
    final List<SixWebTipoRecebimentoOpcao> opcoesDisponiveis = _opcoes
        .where(
          (SixWebTipoRecebimentoOpcao opcao) =>
              opcao.codigoTipo == forma.opcao.codigoTipo ||
              !codigosEmUso.contains(opcao.codigoTipo),
        )
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: forma.controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() => _erroValor = null),
                  decoration: InputDecoration(
                    labelText:
                        '${context.t('recebimento.valorForma', fallback: 'Valor da forma')} ${index + 1}',
                    prefixText:
                        '${context.read<LocaleSettingsProvider>().currencySymbol} ',
                    filled: true,
                    fillColor: tokens.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: tokens.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: tokens.selectedBorder),
                    ),
                  ),
                ),
              ),
              if (_formas.length > 1) ...<Widget>[
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => _removerForma(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: context.t(
                    'recebimento.removerForma',
                    fallback: 'Remover forma',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _TipoRecebimentoDropdown(
            label: context.t(
              'recebimento.tipoRecebimento',
              fallback: 'Tipo de recebimento',
            ),
            value: forma.opcao,
            options: opcoesDisponiveis,
            onSelected: (SixWebTipoRecebimentoOpcao value) {
              setState(() {
                forma.opcao = value;
                _erroValor = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _adicionarForma() {
    final Set<String> usados =
        _formas
            .map((_RecebimentoFormaDraft forma) => forma.opcao.codigoTipo)
            .toSet();
    SixWebTipoRecebimentoOpcao? novaOpcao;
    for (final SixWebTipoRecebimentoOpcao opcao in _opcoes) {
      if (!usados.contains(opcao.codigoTipo)) {
        novaOpcao = opcao;
        break;
      }
    }
    final SixWebTipoRecebimentoOpcao? opcaoDisponivel = novaOpcao;
    if (opcaoDisponivel == null) return;

    final double totalAtual = _formas.fold<double>(
      0,
      (double total, _RecebimentoFormaDraft forma) =>
          total + _parseValor(forma.controller.text),
    );
    final double restante = widget.valorAberto - totalAtual;
    setState(() {
      _formas.add(
        _RecebimentoFormaDraft(
          opcao: opcaoDisponivel,
          controller: TextEditingController(
            text: _formatarValorDigitavel(restante > 0 ? restante : 0),
          ),
        ),
      );
      _erroValor = null;
    });
  }

  void _removerForma(int index) {
    setState(() {
      final _RecebimentoFormaDraft forma = _formas.removeAt(index);
      forma.controller.dispose();
      _erroValor = null;
    });
  }

  String _formatarMoeda(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);
  String _formatarValorDigitavel(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  double _parseValor(String value) {
    final LocaleSettingsProvider regionalizacao =
        context.read<LocaleSettingsProvider>();
    final String texto = regionalizacao.stripCurrencyMarkers(value);
    final String normalizado =
        texto.contains(',') && texto.contains('.')
            ? texto.replaceAll('.', '').replaceAll(',', '.')
            : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  String? _formaPagamentoBackendPorCodigo(String codigoTipo) {
    switch (codigoTipo.trim().toLowerCase()) {
      case 'tipo1':
        return 'DINHEIRO';
      case 'tipo2':
        return 'PIX';
      case 'tipo3':
        return 'CARTAO_CREDITO';
      case 'tipo4':
        return 'CARTAO_DEBITO';
      case 'tipo5':
        return 'BOLETO';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      default:
        return null;
    }
  }

  String _descricaoPadraoPorBackend(String backend) {
    switch (backend) {
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'PIX':
        return 'Pix';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'BOLETO':
        return 'Boleto';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      default:
        return backend;
    }
  }
}

class _TipoRecebimentoDropdown extends StatefulWidget {
  const _TipoRecebimentoDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final SixWebTipoRecebimentoOpcao value;
  final List<SixWebTipoRecebimentoOpcao> options;
  final ValueChanged<SixWebTipoRecebimentoOpcao> onSelected;

  @override
  State<_TipoRecebimentoDropdown> createState() =>
      _TipoRecebimentoDropdownState();
}

class _TipoRecebimentoDropdownState extends State<_TipoRecebimentoDropdown> {
  bool _open = false;
  bool _hover = false;

  Future<void> _showOptions() async {
    if (widget.options.isEmpty) return;
    setState(() => _open = true);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    final SixWebTipoRecebimentoOpcao? selected =
        await showMenu<SixWebTipoRecebimentoOpcao>(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromLTWH(
              position.dx,
              position.dy + box.size.height + 8,
              box.size.width,
              box.size.height,
            ),
            Offset.zero & overlay.size,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 12,
          color: tokens.menuBackground,
          surfaceTintColor: Colors.transparent,
          constraints: BoxConstraints.tightFor(width: box.size.width),
          items: widget.options
              .map(
                (SixWebTipoRecebimentoOpcao option) =>
                    PopupMenuItem<SixWebTipoRecebimentoOpcao>(
                      value: option,
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: _TipoRecebimentoDropdownItem(
                        label: option.descricao,
                        selected: option.codigoTipo == widget.value.codigoTipo,
                      ),
                    ),
              )
              .toList(growable: false),
        );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected.codigoTipo != widget.value.codigoTipo) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = _open || _hover;
    final Color borderColor =
        active ? tokens.selectedBorder : tokens.cardBorder;
    final Color backgroundColor =
        active
            ? Color.alphaBlend(
              tokens.info.withValues(alpha: 0.10),
              tokens.surfaceElevated,
            )
            : tokens.inputBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          button: true,
          enabled: true,
          label: '${widget.label}: ${widget.value.descricao}',
          child: Tooltip(
            message: widget.label,
            waitDuration: const Duration(milliseconds: 450),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _showOptions,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow:
                          active
                              ? <BoxShadow>[
                                BoxShadow(
                                  color: tokens.info.withValues(alpha: 0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                active
                                    ? tokens.info.withValues(alpha: 0.16)
                                    : tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: tokens.info,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: tokens.secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.value.descricao,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color:
                                active
                                    ? tokens.info.withValues(alpha: 0.16)
                                    : tokens.surfaceMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: AnimatedRotation(
                              turns: _open ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: active ? tokens.info : tokens.mutedText,
                                size: 18,
                              ),
                            ),
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
      ],
    );
  }
}

class _TipoRecebimentoDropdownItem extends StatelessWidget {
  const _TipoRecebimentoDropdownItem({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? tokens.info : tokens.mutedText,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecebimentoFormaDraft {
  _RecebimentoFormaDraft({required this.opcao, required this.controller});

  SixWebTipoRecebimentoOpcao opcao;
  final TextEditingController controller;
}

class _RecebimentoRouteSurface extends StatelessWidget {
  const _RecebimentoRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress =
            reduceMotion ? 1 : Curves.easeOutCubic.transform(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 12 * progress,
                sigmaY: 12 * progress,
              ),
              child: ColoredBox(
                color: const Color(
                  0xFF081120,
                ).withValues(alpha: 0.78 * progress),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - progress)),
                      child: Transform.scale(
                        scale: 0.96 + (0.04 * progress),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _RecebimentoDialogIcon extends StatelessWidget {
  const _RecebimentoDialogIcon({
    required this.animation,
    required this.accent,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double halo = Curves.easeOutCubic.transform(
          const Interval(0, 0.72).transform(animation.value),
        );
        final double settle = Curves.easeOutBack
            .transform(const Interval(0.30, 1).transform(animation.value))
            .clamp(0.0, 1.0);
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Opacity(
                opacity: (1 - halo) * 0.28,
                child: Transform.scale(
                  scale: 0.74 + (halo * 0.42),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.20),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.92 + (settle * 0.08),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.38)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Transform.translate(
                          offset: Offset(0, 4 * (1 - settle)),
                          child: Icon(
                            Icons.payments_outlined,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Opacity(
                            opacity: (0.45 + (0.55 * settle)).clamp(0.0, 1.0),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _RecebimentoProcessingOverlay extends StatelessWidget {
  const _RecebimentoProcessingOverlay({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;

    return IgnorePointer(
      child: Container(
        color: const Color(0xFF081120).withValues(alpha: 0.34),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.30),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
