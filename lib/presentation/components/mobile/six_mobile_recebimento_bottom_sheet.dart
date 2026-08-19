import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/caixa_models.dart';
import '../../../data/models/recebimento_forma_input.dart';
import '../../../data/services/caixa/caixa_api_client.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/locale_settings_provider.dart';
import '../mobile_motion.dart';

enum SixMobileRecebimentoTipo { total, parcial }

class SixMobileRecebimentoResultado {
  const SixMobileRecebimentoResultado({
    required this.tipo,
    required this.valor,
    required this.codigoTipoRecebimento,
    required this.descricaoTipoRecebimento,
    required this.formaPagamentoBackend,
    required this.recebimentos,
    this.observacao,
  });

  final SixMobileRecebimentoTipo tipo;
  final double valor;
  final String codigoTipoRecebimento;
  final String descricaoTipoRecebimento;
  final String formaPagamentoBackend;
  final List<RecebimentoFormaInput> recebimentos;
  final String? observacao;

  bool get total => tipo == SixMobileRecebimentoTipo.total;
  bool get parcial => tipo == SixMobileRecebimentoTipo.parcial;
}

class SixMobileTipoRecebimentoOpcao {
  const SixMobileTipoRecebimentoOpcao({
    required this.codigoTipo,
    required this.descricao,
    required this.formaPagamentoBackend,
    required this.icon,
  });

  final String codigoTipo;
  final String descricao;
  final String formaPagamentoBackend;
  final IconData icon;
}

class SixMobileRecebimentoBottomSheet extends StatefulWidget {
  const SixMobileRecebimentoBottomSheet({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.valorAberto,
    this.valorOriginal,
    this.valorJaRecebido,
    this.contato,
    this.permitirParcial = true,
    this.observacaoInicial,
    this.codigoTipoInicial,
    this.caixaApiClient,
  });

  final String titulo;
  final String descricao;
  final double valorAberto;
  final double? valorOriginal;
  final double? valorJaRecebido;
  final String? contato;
  final bool permitirParcial;
  final String? observacaoInicial;
  final String? codigoTipoInicial;
  final CaixaApiClient? caixaApiClient;

  static Future<SixMobileRecebimentoResultado?> show(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required double valorAberto,
    double? valorOriginal,
    double? valorJaRecebido,
    String? contato,
    bool permitirParcial = true,
    String? observacaoInicial,
    String? codigoTipoInicial,
    CaixaApiClient? caixaApiClient,
  }) {
    return showModalBottomSheet<SixMobileRecebimentoResultado>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SixMobileRecebimentoBottomSheet(
            titulo: titulo,
            descricao: descricao,
            valorAberto: valorAberto,
            valorOriginal: valorOriginal,
            valorJaRecebido: valorJaRecebido,
            contato: contato,
            permitirParcial: permitirParcial,
            observacaoInicial: observacaoInicial,
            codigoTipoInicial: codigoTipoInicial,
            caixaApiClient: caixaApiClient,
          ),
    );
  }

  @override
  State<SixMobileRecebimentoBottomSheet> createState() =>
      _SixMobileRecebimentoBottomSheetState();
}

class _SixMobileRecebimentoBottomSheetState
    extends State<SixMobileRecebimentoBottomSheet> {
  static const Duration _numberMotionDuration = Duration(milliseconds: 680);

  late final CaixaApiClient _caixaApiClient;
  final TextEditingController _observacaoController = TextEditingController();
  final List<_RecebimentoFormaDraft> _formas = <_RecebimentoFormaDraft>[];

  bool _carregandoTipos = true;
  String? _erroValor;
  SixMobileRecebimentoTipo _tipo = SixMobileRecebimentoTipo.total;
  List<SixMobileTipoRecebimentoOpcao> _opcoes = _opcoesFallback;

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _accent => _colors.accent;
  Color get _muted => _colors.mutedText;
  Color get _title => _colors.titleText;
  Color get _received => _colors.error;

  static const List<SixMobileTipoRecebimentoOpcao> _opcoesFallback =
      <SixMobileTipoRecebimentoOpcao>[
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo1',
          descricao: 'Dinheiro',
          formaPagamentoBackend: 'DINHEIRO',
          icon: Icons.payments_outlined,
        ),
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo2',
          descricao: 'Pix',
          formaPagamentoBackend: 'PIX',
          icon: Icons.qr_code_2_outlined,
        ),
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo3',
          descricao: 'Cartão de crédito',
          formaPagamentoBackend: 'CARTAO_CREDITO',
          icon: Icons.credit_card_outlined,
        ),
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo4',
          descricao: 'Cartão de débito',
          formaPagamentoBackend: 'CARTAO_DEBITO',
          icon: Icons.point_of_sale_outlined,
        ),
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo5',
          descricao: 'Boleto',
          formaPagamentoBackend: 'BOLETO',
          icon: Icons.receipt_long_outlined,
        ),
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: 'tipo7',
          descricao: 'Débito automático',
          formaPagamentoBackend: 'DEBITO_AUTOMATICO',
          icon: Icons.event_repeat_outlined,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _caixaApiClient = widget.caixaApiClient ?? HttpCaixaApiClient();
    _formas.add(
      _RecebimentoFormaDraft(
        opcao: _resolverInicial(_opcoes),
        controller: TextEditingController(
          text: _formatarValorDigitavel(widget.valorAberto),
        ),
      ),
    );
    _observacaoController.text = widget.observacaoInicial ?? '';
    _carregarTipos();
  }

  @override
  void dispose() {
    for (final _RecebimentoFormaDraft forma in _formas) {
      forma.controller.dispose();
    }
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTipos() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<SixMobileTipoRecebimentoOpcao> opcoes = _montarOpcoes(
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

  List<SixMobileTipoRecebimentoOpcao> _montarOpcoes(
    List<TiposRecebimento> tipos,
  ) {
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

    final List<SixMobileTipoRecebimentoOpcao> opcoes =
        <SixMobileTipoRecebimentoOpcao>[];
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
        (SixMobileTipoRecebimentoOpcao opcao) => opcao.codigoTipo == codigo,
      )) {
        continue;
      }
      opcoes.add(
        SixMobileTipoRecebimentoOpcao(
          codigoTipo: codigo,
          descricao: descricao,
          formaPagamentoBackend: backend,
          icon: _iconePorBackend(backend),
        ),
      );
    }
    return opcoes;
  }

  SixMobileTipoRecebimentoOpcao _resolverInicial(
    List<SixMobileTipoRecebimentoOpcao> opcoes,
  ) {
    final String inicial = widget.codigoTipoInicial?.trim().toLowerCase() ?? '';
    if (inicial.isNotEmpty) {
      for (final SixMobileTipoRecebimentoOpcao opcao in opcoes) {
        if (opcao.codigoTipo == inicial) return opcao;
      }
    }
    return opcoes.isEmpty ? _opcoesFallback.first : opcoes.first;
  }

  void _sincronizarOpcoesDasFormas() {
    for (final _RecebimentoFormaDraft forma in _formas) {
      forma.opcao = _opcaoPorCodigo(forma.opcao.codigoTipo);
    }
  }

  SixMobileTipoRecebimentoOpcao _opcaoPorCodigo(String codigoTipo) {
    final String codigo = codigoTipo.trim().toLowerCase();
    for (final SixMobileTipoRecebimentoOpcao opcao in _opcoes) {
      if (opcao.codigoTipo == codigo) return opcao;
    }
    return _resolverInicial(_opcoes);
  }

  void _alterarTipo(SixMobileRecebimentoTipo tipo) {
    setState(() {
      _tipo = tipo;
      _erroValor = null;
      if (tipo == SixMobileRecebimentoTipo.total && _formas.length == 1) {
        _formas.first.controller.text = _formatarValorDigitavel(
          widget.valorAberto,
        );
      }
    });
  }

  void _confirmar() {
    final Set<String> codigos = <String>{};
    final List<RecebimentoFormaInput> recebimentos = <RecebimentoFormaInput>[];
    for (final _RecebimentoFormaDraft forma in _formas) {
      if (!codigos.add(forma.opcao.codigoTipo)) {
        setState(
          () => _erroValor = context.t(
            'recebimento.erroFormaDuplicada',
            fallback:
                'Cada forma de recebimento pode ser usada apenas uma vez.',
          ),
        );
        return;
      }
      final double valor = _parseValor(forma.controller.text);
      if (valor <= 0) {
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
          valor: valor,
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
    if (_tipo == SixMobileRecebimentoTipo.parcial &&
        valor >= widget.valorAberto) {
      setState(
        () =>
            _erroValor = context.t(
              'recebimento.erroParcialMenorQueAberto',
              fallback: 'Para parcial, informe um valor menor que o aberto.',
            ),
      );
      return;
    }
    if (_tipo == SixMobileRecebimentoTipo.total &&
        (valor - widget.valorAberto).abs() > 0.009) {
      setState(
        () =>
            _erroValor = context.t(
              'recebimento.erroTotalIgualSaldo',
              fallback: 'Para total, o valor precisa quitar o saldo aberto.',
            ),
      );
      return;
    }

    final _RecebimentoFormaDraft primeiraForma = _formas.first;
    Navigator.of(context).pop(
      SixMobileRecebimentoResultado(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SixMobileColorScheme colors = _colors;
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    _modalIcon(Icons.payments_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.titulo,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.contato != null && widget.contato!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.contato!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _resumoValor(),
                const SizedBox(height: 14),
                if (widget.permitirParcial) _tipoSelector(),
                if (widget.permitirParcial) const SizedBox(height: 14),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _carregandoTipos ? null : _confirmar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _tipo == SixMobileRecebimentoTipo.total
                        ? context.t(
                          'recebimento.receberTotal',
                          fallback: 'Receber total',
                        )
                        : context.t(
                          'recebimento.receberParcial',
                          fallback: 'Receber parcial',
                        ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(context.t('common.back', fallback: 'Voltar')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: _accent),
    );
  }

  Widget _resumoValor() {
    final double valorOriginal = _valorOriginalResumo;
    final double valorRecebidoNegativo = _valorJaRecebidoNegativoResumo;
    final double valorAberto = _valorSeguro(widget.valorAberto);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t(
              'recebimento.valoresTitulo',
              fallback: 'Valores do recebimento',
            ),
            style: TextStyle(color: _title, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _valorResumoItem(
            label: context.t(
              'recebimento.valorOriginal',
              fallback: 'Valor original',
            ),
            value: valorOriginal,
            color: _accent,
            icon: Icons.receipt_long_outlined,
            delay: Duration.zero,
            animationKey: 'original',
          ),
          const SizedBox(height: 8),
          _valorResumoItem(
            label: context.t(
              'recebimento.valorJaRecebido',
              fallback: 'Valor já recebido',
            ),
            value: valorRecebidoNegativo,
            color: _received,
            icon: Icons.remove_circle_outline_rounded,
            delay: const Duration(milliseconds: 70),
            animationKey: 'recebido',
          ),
          const SizedBox(height: 8),
          _valorResumoItem(
            label: context.t(
              'recebimento.valorEmAberto',
              fallback: 'Valor em aberto',
            ),
            value: valorAberto,
            color: _title,
            icon: Icons.account_balance_wallet_outlined,
            delay: const Duration(milliseconds: 140),
            animationKey: 'aberto',
          ),
        ],
      ),
    );
  }

  Widget _valorResumoItem({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required Duration delay,
    required String animationKey,
  }) {
    return SixStaggeredEntry(
      delay: delay,
      duration: const Duration(milliseconds: 320),
      beginOffset: const Offset(0, 0.05),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _valorMonetarioAnimado(
                  value: value,
                  color: color,
                  animationKey: animationKey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valorMonetarioAnimado({
    required double value,
    required Color color,
    required String animationKey,
  }) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('$animationKey-${value.toStringAsFixed(2)}'),
      tween: Tween<double>(begin: 0, end: value),
      duration: reduceMotion ? Duration.zero : _numberMotionDuration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            _formatarMoeda(animatedValue),
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        );
      },
    );
  }

  Widget _tipoSelector() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _tipoPill(
            label: context.t('recebimento.total', fallback: 'Total'),
            icon: Icons.done_all_rounded,
            tipo: SixMobileRecebimentoTipo.total,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tipoPill(
            label: context.t('recebimento.parcial', fallback: 'Parcial'),
            icon: Icons.call_split_rounded,
            tipo: SixMobileRecebimentoTipo.parcial,
          ),
        ),
      ],
    );
  }

  Widget _tipoPill({
    required String label,
    required IconData icon,
    required SixMobileRecebimentoTipo tipo,
  }) {
    final bool selecionado = _tipo == tipo;
    final SixMobileColorScheme colors = _colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: selecionado ? colors.accent : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selecionado ? colors.accent : colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _alterarTipo(tipo),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: selecionado ? colors.onAccent : colors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selecionado ? colors.onAccent : colors.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formasRecebimentoSection() {
    final SixMobileColorScheme colors = _colors;

    if (_carregandoTipos) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontWeight: FontWeight.w800,
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(
                  'recebimento.formasRecebimento',
                  fallback: 'Formas de recebimento',
                ),
                style: TextStyle(
                  color: colors.titleText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${context.t('recebimento.restante', fallback: 'Restante')} ${_formatarMoeda(restante < 0 ? 0 : restante)}',
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._formas.asMap().entries.map((
          MapEntry<int, _RecebimentoFormaDraft> entry,
        ) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _formas.length - 1 ? 0 : 12,
            ),
            child: _formaRecebimentoCard(entry.key, entry.value),
          );
        }),
        if (_erroValor != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _erroValor!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: podeAdicionar ? _adicionarForma : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            context.t(
              'recebimento.adicionarForma',
              fallback: 'Adicionar forma',
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formaRecebimentoCard(int index, _RecebimentoFormaDraft forma) {
    final SixMobileColorScheme colors = _colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
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
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _opcoes
                .map((SixMobileTipoRecebimentoOpcao opcao) {
                  return _tipoRecebimentoPill(
                    opcao: opcao,
                    selecionado: forma.opcao.codigoTipo == opcao.codigoTipo,
                    onTap: () {
                      final bool usadaEmOutraForma = _formas.any(
                        (_RecebimentoFormaDraft item) =>
                            !identical(item, forma) &&
                            item.opcao.codigoTipo == opcao.codigoTipo,
                      );
                      if (usadaEmOutraForma) {
                        setState(
                          () => _erroValor = context.t(
                            'recebimento.erroFormaDuplicada',
                            fallback:
                                'Cada forma de recebimento pode ser usada apenas uma vez.',
                          ),
                        );
                        return;
                      }
                      setState(() {
                        forma.opcao = opcao;
                        _erroValor = null;
                      });
                    },
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _tipoRecebimentoPill({
    required SixMobileTipoRecebimentoOpcao opcao,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    final SixMobileColorScheme colors = _colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        color: selecionado ? colors.accent : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selecionado ? colors.accent : colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                opcao.icon,
                size: 16,
                color: selecionado ? colors.onAccent : colors.accent,
              ),
              const SizedBox(width: 7),
              Text(
                opcao.descricao,
                style: TextStyle(
                  color: selecionado ? colors.onAccent : colors.titleText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _adicionarForma() {
    final Set<String> usados = _formas
        .map((_RecebimentoFormaDraft forma) => forma.opcao.codigoTipo)
        .toSet();
    SixMobileTipoRecebimentoOpcao? novaOpcao;
    for (final SixMobileTipoRecebimentoOpcao opcao in _opcoes) {
      if (!usados.contains(opcao.codigoTipo)) {
        novaOpcao = opcao;
        break;
      }
    }
    if (novaOpcao == null) return;

    setState(() {
      final double totalAtual = _formas.fold<double>(
        0,
        (double total, _RecebimentoFormaDraft forma) =>
            total + _parseValor(forma.controller.text),
      );
      final double restante = widget.valorAberto - totalAtual;
      _formas.add(
        _RecebimentoFormaDraft(
          opcao: novaOpcao!,
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

  double get _valorOriginalResumo {
    final double? informado = widget.valorOriginal;
    if (informado != null && informado.isFinite && informado > 0) {
      return informado;
    }

    final double recebido = _valorJaRecebidoResumo;
    final double aberto = _valorSeguro(widget.valorAberto);
    return aberto + recebido;
  }

  double get _valorJaRecebidoResumo {
    final double? informado = widget.valorJaRecebido;
    if (informado != null && informado.isFinite) {
      return informado < 0 ? -informado : informado;
    }

    final double? originalInformado = widget.valorOriginal;
    if (originalInformado == null || !originalInformado.isFinite) {
      return 0;
    }

    final double recebido =
        originalInformado - _valorSeguro(widget.valorAberto);
    return recebido > 0 ? recebido : 0;
  }

  double get _valorJaRecebidoNegativoResumo {
    final double recebido = _valorJaRecebidoResumo;
    return recebido > 0 ? -recebido : 0;
  }

  double _valorSeguro(double valor) => valor.isFinite ? valor : 0;

  String _formatarMoeda(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);
  String _formatarValorDigitavel(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  double _parseValor(String value) {
    final String texto = value.trim().replaceAll('R\$', '').trim();
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

  IconData _iconePorBackend(String backend) {
    switch (backend) {
      case 'DINHEIRO':
        return Icons.payments_outlined;
      case 'PIX':
        return Icons.qr_code_2_outlined;
      case 'CARTAO_CREDITO':
        return Icons.credit_card_outlined;
      case 'CARTAO_DEBITO':
        return Icons.point_of_sale_outlined;
      case 'BOLETO':
        return Icons.receipt_long_outlined;
      case 'DEBITO_AUTOMATICO':
        return Icons.event_repeat_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

class _RecebimentoFormaDraft {
  _RecebimentoFormaDraft({required this.opcao, required this.controller});

  SixMobileTipoRecebimentoOpcao opcao;
  final TextEditingController controller;
}
