import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/caixa_models.dart';
import '../../../data/models/recebimento_forma_input.dart';
import '../../../data/services/caixa/caixa_api_client.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/locale_settings_provider.dart';

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
    this.contato,
    this.permitirParcial = true,
    this.observacaoInicial,
    this.codigoTipoInicial,
  });

  final String titulo;
  final String descricao;
  final double valorAberto;
  final String? contato;
  final bool permitirParcial;
  final String? observacaoInicial;
  final String? codigoTipoInicial;

  static Future<SixMobileRecebimentoResultado?> show(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required double valorAberto,
    String? contato,
    bool permitirParcial = true,
    String? observacaoInicial,
    String? codigoTipoInicial,
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
            contato: contato,
            permitirParcial: permitirParcial,
            observacaoInicial: observacaoInicial,
            codigoTipoInicial: codigoTipoInicial,
          ),
    );
  }

  @override
  State<SixMobileRecebimentoBottomSheet> createState() =>
      _SixMobileRecebimentoBottomSheetState();
}

class _SixMobileRecebimentoBottomSheetState
    extends State<SixMobileRecebimentoBottomSheet> {
  static const Color _accent = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF64748B);
  static const Color _title = Color(0xFF0F172A);

  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();
  final TextEditingController _observacaoController = TextEditingController();
  final List<_RecebimentoFormaDraft> _formas = <_RecebimentoFormaDraft>[];

  bool _carregandoTipos = true;
  String? _erroValor;
  SixMobileRecebimentoTipo _tipo = SixMobileRecebimentoTipo.total;
  List<SixMobileTipoRecebimentoOpcao> _opcoes = _opcoesFallback;

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
    final List<RecebimentoFormaInput> recebimentos = <RecebimentoFormaInput>[];
    for (final _RecebimentoFormaDraft forma in _formas) {
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
            color: theme.colorScheme.surface,
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
                      color: theme.colorScheme.outlineVariant,
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
                              color: _muted,
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
                      style: const TextStyle(
                        color: _muted,
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
                    labelText: 'Observação',
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
                        ? 'Receber total'
                        : 'Receber parcial',
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
                  label: const Text('Voltar'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Valor em aberto',
              style: TextStyle(color: _title, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            _formatarMoeda(widget.valorAberto),
            style: const TextStyle(
              color: _title,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoSelector() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _tipoPill(
            label: 'Total',
            icon: Icons.done_all_rounded,
            tipo: SixMobileRecebimentoTipo.total,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tipoPill(
            label: 'Parcial',
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: selecionado ? _accent : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selecionado ? _accent : const Color(0xFFCBD5E1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _alterarTipo(tipo),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: selecionado ? Colors.white : _accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : _title,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formasRecebimentoSection() {
    if (_carregandoTipos) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Carregando tipos de recebimento...',
              style: TextStyle(fontWeight: FontWeight.w800),
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
                style: const TextStyle(
                  color: _title,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${context.t('recebimento.restante', fallback: 'Restante')} ${_formatarMoeda(restante < 0 ? 0 : restante)}',
              style: const TextStyle(
                color: _muted,
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
          onPressed: _adicionarForma,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fillColor: Colors.white,
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
                    onTap:
                        () => setState(() {
                          forma.opcao = opcao;
                          _erroValor = null;
                        }),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        color: selecionado ? _accent : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selecionado ? _accent : const Color(0xFFCBD5E1),
        ),
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
                color: selecionado ? Colors.white : _accent,
              ),
              const SizedBox(width: 7),
              Text(
                opcao.descricao,
                style: TextStyle(
                  color: selecionado ? Colors.white : _title,
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
    setState(() {
      final double totalAtual = _formas.fold<double>(
        0,
        (double total, _RecebimentoFormaDraft forma) =>
            total + _parseValor(forma.controller.text),
      );
      final double restante = widget.valorAberto - totalAtual;
      _formas.add(
        _RecebimentoFormaDraft(
          opcao: _resolverInicial(_opcoes),
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
