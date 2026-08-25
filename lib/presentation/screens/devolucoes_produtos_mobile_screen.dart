import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/caixa_models.dart';
import '../../data/models/devolucao_produto_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/devolucao_produto/devolucao_produto_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/devolucao_produto/devolucao_produto_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_selection_sheet.dart';
import '../components/mobile_motion.dart';

class DevolucoesProdutosMobileScreen extends StatefulWidget {
  const DevolucoesProdutosMobileScreen({
    super.key,
    this.showBackButton = true,
    @visibleForTesting this.service,
  });

  final bool showBackButton;
  final DevolucaoProdutoService? service;

  @override
  State<DevolucoesProdutosMobileScreen> createState() =>
      _DevolucoesProdutosMobileScreenState();
}

class _DevolucoesProdutosMobileScreenState
    extends State<DevolucoesProdutosMobileScreen> {
  final TextEditingController _identificadorController =
      TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  late final DevolucaoProdutoService _service;
  VendaElegivelDevolucao? _venda;
  TipoDevolucaoProduto _tipo = TipoDevolucaoProduto.devolucao;
  final Map<String, _ItemDevolucaoMobileEdicao> _itens =
      <String, _ItemDevolucaoMobileEdicao>{};
  final Map<String, _ItemTrocaMobileEdicao> _itensTroca =
      <String, _ItemTrocaMobileEdicao>{};
  List<ProdutoModel> _produtosTroca = <ProdutoModel>[];
  List<TiposRecebimento> _tiposAcerto = <TiposRecebimento>[];
  List<DevolucaoProdutoResponse> _recentes = <DevolucaoProdutoResponse>[];
  String? _codigoTipoRecebimento;
  String? _chaveIdempotenciaAtual;
  String? _erro;
  DevolucaoProdutoResponse? _resultado;
  bool _carregandoApoio = true;
  bool _buscandoVenda = false;
  bool _salvando = false;

  SixMobileColorScheme get _colors => context.sixMobileColors;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DevolucaoProdutoService();
    _carregarApoio();
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _observacoesController.dispose();
    _descartarEditores();
    super.dispose();
  }

  String _t(String key) => context.t(key);

  String _interpolate(String key, Map<String, String> values) {
    String result = _t(key);
    for (final MapEntry<String, String> entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  Future<void> _carregarApoio() async {
    if (mounted) {
      setState(() {
        _carregandoApoio = true;
        _erro = null;
      });
    }
    try {
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _service.listarProdutosParaTroca(),
            _service.listarTiposDeAcertoImediato(),
            _service.listarRecentes(),
          ]);
      if (!mounted) return;
      setState(() {
        _produtosTroca = resultados[0] as List<ProdutoModel>;
        _tiposAcerto = resultados[1] as List<TiposRecebimento>;
        _recentes = resultados[2] as List<DevolucaoProdutoResponse>;
        if (_tiposAcerto.isNotEmpty && _codigoTipoRecebimento == null) {
          _codigoTipoRecebimento = _tiposAcerto.first.codigoTipo;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _carregandoApoio = false);
    }
  }

  Future<void> _buscarVenda() async {
    FocusScope.of(context).unfocus();
    final String identificador = _identificadorController.text.trim();
    if (identificador.isEmpty) {
      _mostrarMensagem(_t('devolucao.mobile.validation.saleRequired'));
      return;
    }
    setState(() {
      _buscandoVenda = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final VendaElegivelDevolucao venda = await _service.buscarVendaElegivel(
        identificador,
      );
      if (!mounted) return;
      _descartarEditores();
      setState(() {
        _venda = venda;
        _tipo = TipoDevolucaoProduto.devolucao;
        _chaveIdempotenciaAtual = null;
        for (final ItemVendaElegivelDevolucao item in venda.itens) {
          if (item.quantidadeDisponivel <= 0) continue;
          _itens[item.idItemVenda] = _ItemDevolucaoMobileEdicao(item);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _venda = null;
        _erro = _mensagemErro(error);
      });
    } finally {
      if (mounted) setState(() => _buscandoVenda = false);
    }
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final VendaElegivelDevolucao? venda = _venda;
    if (venda == null) return;
    final List<ItemDevolvidoRequest> devolvidos = <ItemDevolvidoRequest>[];
    for (final _ItemDevolucaoMobileEdicao edicao in _itens.values) {
      if (!edicao.selecionado) continue;
      final double? quantidade = _numero(edicao.quantidadeController.text);
      if (quantidade == null || quantidade <= 0) {
        _mostrarMensagem(
          _interpolate(
            'devolucao.mobile.validation.invalidQuantity',
            <String, String>{'product': edicao.item.nomeProduto},
          ),
        );
        return;
      }
      if (quantidade - edicao.item.quantidadeDisponivel > 0.0001) {
        _mostrarMensagem(
          _interpolate(
            'devolucao.mobile.validation.quantityExceeded',
            <String, String>{'product': edicao.item.nomeProduto},
          ),
        );
        return;
      }
      final String motivo = edicao.motivoController.text.trim();
      if (motivo.isEmpty) {
        _mostrarMensagem(
          _interpolate(
            'devolucao.mobile.validation.reasonRequired',
            <String, String>{'product': edicao.item.nomeProduto},
          ),
        );
        return;
      }
      devolvidos.add(
        ItemDevolvidoRequest(
          idItemVenda: edicao.item.idItemVenda,
          quantidade: quantidade,
          motivo: motivo,
          condicao: edicao.condicao,
          retornarAoEstoque: edicao.retornarAoEstoque,
        ),
      );
    }
    if (devolvidos.isEmpty) {
      _mostrarMensagem(_t('devolucao.mobile.validation.selectReturnItem'));
      return;
    }
    final List<ItemTrocaRequest> trocas = <ItemTrocaRequest>[];
    if (_tipo == TipoDevolucaoProduto.troca) {
      for (final _ItemTrocaMobileEdicao edicao in _itensTroca.values) {
        final double? quantidade = _numero(edicao.quantidadeController.text);
        if (quantidade == null || quantidade <= 0) {
          _mostrarMensagem(
            _interpolate(
              'devolucao.mobile.validation.invalidQuantity',
              <String, String>{'product': edicao.produto.nomeProduto},
            ),
          );
          return;
        }
        trocas.add(
          ItemTrocaRequest(
            idProduto: edicao.produto.id!,
            quantidade: quantidade,
          ),
        );
      }
      if (trocas.isEmpty) {
        _mostrarMensagem(_t('devolucao.mobile.validation.selectExchangeItem'));
        return;
      }
    }
    final double saldo = _saldoFinanceiro;
    if (saldo.abs() > 0.009 &&
        (_codigoTipoRecebimento == null ||
            _codigoTipoRecebimento!.trim().isEmpty)) {
      _mostrarMensagem(_t('devolucao.mobile.validation.selectPayment'));
      return;
    }
    final String chave = _chaveIdempotenciaAtual ?? _novaChaveIdempotencia();
    _chaveIdempotenciaAtual = chave;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final DevolucaoProdutoResponse resultado = await _service.registrar(
        RegistrarDevolucaoProdutoRequest(
          chaveIdempotencia: chave,
          identificadorVenda: venda.idOperacao,
          tipo: _tipo,
          itensDevolvidos: devolvidos,
          itensTroca: trocas,
          codigoTipoRecebimento: saldo.abs() > 0.009
              ? _codigoTipoRecebimento
              : null,
          observacoes: _observacoesController.text,
        ),
      );
      if (!mounted) return;
      _descartarEditores();
      setState(() {
        _resultado = resultado;
        _venda = null;
        _identificadorController.clear();
        _observacoesController.clear();
        _chaveIdempotenciaAtual = null;
      });
      await _recarregarRecentes();
      if (!mounted) return;
      _mostrarMensagem(
        _interpolate('devolucao.mobile.successMessage', <String, String>{
          'code': resultado.codigoDevolucao,
        }),
        sucesso: true,
      );
    } catch (error) {
      if (mounted) setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _recarregarRecentes() async {
    try {
      final List<DevolucaoProdutoResponse> recentes = await _service
          .listarRecentes();
      if (mounted) setState(() => _recentes = recentes);
    } catch (_) {
      // A operação principal foi concluída; o histórico é apoio visual.
    }
  }

  void _descartarEditores() {
    for (final _ItemDevolucaoMobileEdicao item in _itens.values) {
      item.dispose();
    }
    for (final _ItemTrocaMobileEdicao item in _itensTroca.values) {
      item.dispose();
    }
    _itens.clear();
    _itensTroca.clear();
  }

  void _invalidarChave() {
    _chaveIdempotenciaAtual = null;
    _resultado = null;
  }

  double get _totalDevolvido {
    double total = 0;
    for (final _ItemDevolucaoMobileEdicao edicao in _itens.values) {
      if (edicao.selecionado) {
        total +=
            (_numero(edicao.quantidadeController.text) ?? 0) *
            edicao.item.valorUnitario;
      }
    }
    return total;
  }

  double get _totalTroca {
    if (_tipo != TipoDevolucaoProduto.troca) return 0;
    double total = 0;
    for (final _ItemTrocaMobileEdicao edicao in _itensTroca.values) {
      total +=
          (_numero(edicao.quantidadeController.text) ?? 0) *
          edicao.produto.precoVenda;
    }
    return total;
  }

  double get _saldoFinanceiro => _totalTroca - _totalDevolvido;

  String _novaChaveIdempotencia() {
    final int aleatorio = Random.secure().nextInt(0x7fffffff);
    return 'dev-${DateTime.now().microsecondsSinceEpoch}-$aleatorio';
  }

  double? _numero(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('.') && !trimmed.contains(',')) {
      return double.tryParse(trimmed);
    }
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    final String normalized = trimmed
        .replaceAll(locale.thousandSeparator, '')
        .replaceAll(locale.decimalSeparator, '.');
    return double.tryParse(normalized);
  }

  String _quantidade(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return context.read<LocaleSettingsProvider>().formatDecimal(value);
  }

  String _moeda(double value) =>
      context.read<LocaleSettingsProvider>().formatCurrency(value);

  String _data(DateTime? value) {
    if (value == null) return _t('common.notInformed');
    return context.read<LocaleSettingsProvider>().formatDate(value.toLocal());
  }

  String _mensagemErro(Object error) {
    if (error is DevolucaoProdutoApiException) return error.mensagemUsuario;
    if (error is DevolucaoProdutoValidacaoException) return error.mensagem;
    return _t('devolucao.mobile.unexpectedError');
  }

  void _mostrarMensagem(String mensagem, {bool sucesso = false}) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: sucesso ? _colors.accent : null,
      ),
    );
  }

  Future<void> _selecionarCondicao(_ItemDevolucaoMobileEdicao edicao) async {
    final CondicaoProdutoDevolvido? selecionada =
        await showSixMobileSelectionSheet<CondicaoProdutoDevolvido>(
          context: context,
          title: _t('devolucao.mobile.condition'),
          subtitle: edicao.item.nomeProduto,
          selectedValue: edicao.condicao,
          emptyTitle: _t('common.noResults'),
          options: CondicaoProdutoDevolvido.values
              .map(
                (CondicaoProdutoDevolvido value) =>
                    SixMobileSelectionOption<CondicaoProdutoDevolvido>(
                      value: value,
                      title: _condicaoLabel(value),
                      icon: _condicaoIcon(value),
                    ),
              )
              .toList(growable: false),
        );
    if (selecionada == null || !mounted) return;
    setState(() {
      _invalidarChave();
      edicao.condicao = selecionada;
      if (selecionada == CondicaoProdutoDevolvido.comDefeito ||
          selecionada == CondicaoProdutoDevolvido.avariado) {
        edicao.retornarAoEstoque = false;
      }
    });
  }

  Future<void> _selecionarProdutoTroca() async {
    final Set<String> idsAdicionados = _itensTroca.keys.toSet();
    final List<ProdutoModel> disponiveis = _produtosTroca
        .where((ProdutoModel produto) => !idsAdicionados.contains(produto.id))
        .toList(growable: false);
    final ProdutoModel? produto =
        await showSixMobileSelectionSheet<ProdutoModel>(
          context: context,
          title: _t('devolucao.mobile.selectExchangeProduct'),
          subtitle: _t('devolucao.mobile.exchangeItemsSubtitle'),
          searchHint: _t('devolucao.mobile.searchProduct'),
          selectedValue: null,
          emptyTitle: _t('devolucao.mobile.noProductsTitle'),
          emptyMessage: _t('devolucao.mobile.noProductsMessage'),
          options: disponiveis
              .map(
                (ProdutoModel item) => SixMobileSelectionOption<ProdutoModel>(
                  value: item,
                  title: item.nomeProduto,
                  subtitle: _interpolate(
                    'devolucao.mobile.productPrice',
                    <String, String>{'value': _moeda(item.precoVenda)},
                  ),
                  icon: Icons.inventory_2_outlined,
                ),
              )
              .toList(growable: false),
        );
    if (produto == null || produto.id == null || !mounted) return;
    setState(() {
      _invalidarChave();
      _itensTroca[produto.id!] = _ItemTrocaMobileEdicao(produto);
    });
  }

  Future<void> _selecionarTipoAcerto() async {
    final TiposRecebimento? selecionado =
        await showSixMobileSelectionSheet<TiposRecebimento>(
          context: context,
          title: _t('devolucao.mobile.paymentMethod'),
          subtitle: _t('devolucao.mobile.paymentHelper'),
          searchHint: _t('devolucao.mobile.searchPayment'),
          selectedValue: _tipoAcertoSelecionado,
          emptyTitle: _t('devolucao.mobile.noPaymentMethods'),
          emptyMessage: _t('devolucao.mobile.noPaymentMethodsMessage'),
          options: _tiposAcerto
              .map(
                (TiposRecebimento item) =>
                    SixMobileSelectionOption<TiposRecebimento>(
                      value: item,
                      title: item.descricaoExibicao,
                      icon: Icons.payments_outlined,
                    ),
              )
              .toList(growable: false),
        );
    if (selecionado == null || !mounted) return;
    setState(() {
      _invalidarChave();
      _codigoTipoRecebimento = selecionado.codigoTipo;
    });
  }

  TiposRecebimento? get _tipoAcertoSelecionado {
    for (final TiposRecebimento item in _tiposAcerto) {
      if (item.codigoTipo == _codigoTipoRecebimento) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _t('devolucao.mobile.title'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
              tooltip: _t('common.back'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      bodyBuilder: _buildBody,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        edgeOffset: topInset,
        color: _colors.accent,
        backgroundColor: _colors.surface,
        onRefresh: _carregarApoio,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 30),
          children: <Widget>[
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 35),
              child: _buildBuscaCard(),
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 12),
              _buildErroCard(),
            ],
            if (_resultado != null) ...<Widget>[
              const SizedBox(height: 12),
              _buildResultadoCard(),
            ],
            if (_venda != null) ...<Widget>[
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 70),
                child: _buildResumoVenda(),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 95),
                child: _buildTipoOperacao(),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 120),
                child: _buildItensDevolucao(),
              ),
              if (_tipo == TipoDevolucaoProduto.troca) ...<Widget>[
                const SizedBox(height: 12),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 145),
                  child: _buildItensTroca(),
                ),
              ],
              const SizedBox(height: 12),
              _buildAcertoFinanceiro(),
              const SizedBox(height: 12),
              _buildConfirmacao(),
            ],
            const SizedBox(height: 18),
            _buildRecentes(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscaCard() {
    return _MobileSectionCard(
      icon: Icons.assignment_return_outlined,
      title: _t('devolucao.mobile.introTitle'),
      subtitle: _t('devolucao.mobile.introSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('devolucao-sale-search-field'),
            controller: _identificadorController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscarVenda(),
            decoration: InputDecoration(
              labelText: _t('devolucao.mobile.saleCodeLabel'),
              hintText: _t('devolucao.mobile.saleCodeHint'),
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              filled: true,
              fillColor: _colors.softSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey<String>('devolucao-search-sale'),
            onPressed: _buscandoVenda ? null : _buscarVenda,
            icon: _buscandoVenda
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _colors.onAccent,
                    ),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(
              _buscandoVenda
                  ? _t('devolucao.mobile.searching')
                  : _t('devolucao.mobile.searchSale'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErroCard() {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _erro,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: _colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _colors.errorBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: _colors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _erro!,
                style: TextStyle(
                  color: _colors.titleText,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: _t('common.close'),
              onPressed: () => setState(() => _erro = null),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard() {
    final DevolucaoProdutoResponse resultado = _resultado!;
    return Semantics(
      container: true,
      liveRegion: true,
      label: _t('devolucao.mobile.operationCompleted'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _colors.softAccentSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _colors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colors.accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.check_rounded, color: _colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _t('devolucao.mobile.operationCompleted'),
                    style: TextStyle(
                      color: _colors.titleText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${resultado.codigoDevolucao} • ${_tipoLabel(resultado.tipo)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _colors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoVenda() {
    final VendaElegivelDevolucao venda = _venda!;
    final String codigo = venda.codigoOperacao.isEmpty
        ? venda.idOperacao
        : venda.codigoOperacao;
    return _MobileSectionCard(
      icon: Icons.receipt_long_rounded,
      title: _t('devolucao.mobile.saleFound'),
      subtitle: codigo,
      trailing: IconButton(
        tooltip: _t('devolucao.mobile.changeSale'),
        onPressed: () {
          _descartarEditores();
          setState(() {
            _venda = null;
            _resultado = null;
            _identificadorController.clear();
          });
        },
        icon: const Icon(Icons.close_rounded),
      ),
      child: Column(
        children: <Widget>[
          _MobileInfoRow(
            icon: Icons.person_outline_rounded,
            label: _t('common.customer'),
            value: venda.nomeCliente.isEmpty
                ? _t('devolucao.mobile.unidentifiedCustomer')
                : venda.nomeCliente,
          ),
          const SizedBox(height: 10),
          _MobileInfoRow(
            icon: Icons.payments_outlined,
            label: _t('devolucao.mobile.productsValue'),
            value: _moeda(venda.valorTotalProdutos),
          ),
          const SizedBox(height: 10),
          _MobileInfoRow(
            icon: venda.possuiItensElegiveis
                ? Icons.check_circle_outline_rounded
                : Icons.block_rounded,
            label: _t('devolucao.mobile.returnBalance'),
            value: venda.possuiItensElegiveis
                ? _t('devolucao.mobile.hasEligibleItems')
                : _t('devolucao.mobile.noEligibleBalance'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoOperacao() {
    return _MobileSectionCard(
      icon: Icons.alt_route_rounded,
      title: _t('devolucao.mobile.operationTypeTitle'),
      subtitle: _t('devolucao.mobile.operationTypeSubtitle'),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _OperationTypeOption(
              key: const ValueKey<String>('devolucao-type-return'),
              icon: Icons.assignment_return_outlined,
              title: _t('devolucao.mobile.returnOnly'),
              selected: _tipo == TipoDevolucaoProduto.devolucao,
              onTap: () {
                setState(() {
                  _invalidarChave();
                  _tipo = TipoDevolucaoProduto.devolucao;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OperationTypeOption(
              key: const ValueKey<String>('devolucao-type-exchange'),
              icon: Icons.swap_horiz_rounded,
              title: _t('devolucao.mobile.exchange'),
              selected: _tipo == TipoDevolucaoProduto.troca,
              onTap: () {
                setState(() {
                  _invalidarChave();
                  _tipo = TipoDevolucaoProduto.troca;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItensDevolucao() {
    return _MobileSectionCard(
      icon: Icons.inventory_2_outlined,
      title: _t('devolucao.mobile.itemsTitle'),
      subtitle: _t('devolucao.mobile.itemsSubtitle'),
      child: _itens.isEmpty
          ? _MobileEmptyState(
              icon: Icons.inventory_2_outlined,
              title: _t('devolucao.mobile.noItems'),
            )
          : Column(
              children: <Widget>[
                for (
                  int index = 0;
                  index < _itens.values.length;
                  index++
                ) ...<Widget>[
                  _buildItemDevolucao(_itens.values.elementAt(index)),
                  if (index < _itens.values.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _buildItemDevolucao(_ItemDevolucaoMobileEdicao edicao) {
    final ItemVendaElegivelDevolucao item = edicao.item;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Duration motionDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 190);
    return AnimatedContainer(
      duration: motionDuration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: edicao.selecionado
            ? _colors.softAccentSurface
            : _colors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: edicao.selecionado
              ? _colors.accent.withValues(alpha: 0.42)
              : _colors.border,
        ),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            button: true,
            selected: edicao.selecionado,
            label: item.nomeProduto,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _invalidarChave();
                  edicao.selecionado = !edicao.selecionado;
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    value: edicao.selecionado,
                    onChanged: (bool? value) {
                      setState(() {
                        _invalidarChave();
                        edicao.selecionado = value == true;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.nomeProduto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _colors.titleText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            _MiniDataChip(
                              label: _interpolate(
                                'devolucao.mobile.soldValue',
                                <String, String>{
                                  'value': _quantidade(item.quantidadeVendida),
                                },
                              ),
                            ),
                            _MiniDataChip(
                              label: _interpolate(
                                'devolucao.mobile.availableValue',
                                <String, String>{
                                  'value': _quantidade(
                                    item.quantidadeDisponivel,
                                  ),
                                },
                              ),
                            ),
                            _MiniDataChip(label: _moeda(item.valorUnitario)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: motionDuration,
            child: !edicao.selecionado
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey<String>('return-item-${item.idItemVenda}'),
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: edicao.quantidadeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(_invalidarChave),
                          decoration: InputDecoration(
                            labelText: _t('devolucao.mobile.quantity'),
                            helperText: _interpolate(
                              'devolucao.mobile.maximumQuantity',
                              <String, String>{
                                'value': _quantidade(item.quantidadeDisponivel),
                              },
                            ),
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SixMobileSelectionField(
                          label: _t('devolucao.mobile.condition'),
                          value: _condicaoLabel(edicao.condicao),
                          icon: _condicaoIcon(edicao.condicao),
                          onTap: () => _selecionarCondicao(edicao),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: edicao.motivoController,
                          onChanged: (_) => _invalidarChave(),
                          maxLength: 500,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: _t('devolucao.mobile.reason'),
                            prefixIcon: const Icon(Icons.notes_rounded),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        _StockReturnToggle(
                          value: edicao.retornarAoEstoque,
                          title: _t('devolucao.mobile.stockReturn'),
                          subtitle: edicao.retornarAoEstoque
                              ? _t('devolucao.mobile.stockReturnOn')
                              : _t('devolucao.mobile.stockReturnOff'),
                          onChanged: (bool value) {
                            setState(() {
                              _invalidarChave();
                              edicao.retornarAoEstoque = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItensTroca() {
    return _MobileSectionCard(
      icon: Icons.add_shopping_cart_rounded,
      title: _t('devolucao.mobile.exchangeItemsTitle'),
      subtitle: _t('devolucao.mobile.exchangeItemsSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton.icon(
            key: const ValueKey<String>('devolucao-add-exchange-product'),
            onPressed: _carregandoApoio ? null : _selecionarProdutoTroca,
            icon: _carregandoApoio
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(_t('devolucao.mobile.addProduct')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          if (_itensTroca.isEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _MobileEmptyState(
              icon: Icons.swap_horiz_rounded,
              title: _t('devolucao.mobile.exchangeEmpty'),
            ),
          ],
          for (final _ItemTrocaMobileEdicao edicao
              in _itensTroca.values) ...<Widget>[
            const SizedBox(height: 10),
            _buildItemTroca(edicao),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTroca(_ItemTrocaMobileEdicao edicao) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _colors.border),
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
                  color: _colors.iconSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined, color: _colors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      edicao.produto.nomeProduto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colors.titleText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _interpolate('devolucao.mobile.perUnit', <String, String>{
                        'value': _moeda(edicao.produto.precoVenda),
                      }),
                      style: TextStyle(color: _colors.mutedText),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _t('devolucao.mobile.remove'),
                color: _colors.error,
                onPressed: () {
                  setState(() {
                    _invalidarChave();
                    _itensTroca.remove(edicao.produto.id)?.dispose();
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: edicao.quantidadeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_invalidarChave),
            decoration: InputDecoration(
              labelText: _t('devolucao.mobile.quantity'),
              prefixIcon: const Icon(Icons.numbers_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcertoFinanceiro() {
    final double saldo = _saldoFinanceiro;
    final bool diferenca = saldo.abs() > 0.009;
    final String orientacao = saldo > 0.009
        ? _t('devolucao.mobile.customerPays')
        : saldo < -0.009
        ? _t('devolucao.mobile.companyRefunds')
        : _t('devolucao.mobile.noFinancialMovement');
    return _MobileSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: _t('devolucao.mobile.financialTitle'),
      subtitle: orientacao,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _FinancialMetric(
                  label: _t('devolucao.mobile.returnedProducts'),
                  value: _moeda(_totalDevolvido),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FinancialMetric(
                  label: _t('devolucao.mobile.exchangeProducts'),
                  value: _moeda(_totalTroca),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FinancialMetric(
            label: saldo >= 0
                ? _t('devolucao.mobile.differenceReceive')
                : _t('devolucao.mobile.refundValue'),
            value: _moeda(saldo.abs()),
            emphasized: true,
          ),
          if (diferenca) ...<Widget>[
            const SizedBox(height: 12),
            SixMobileSelectionField(
              label: _t('devolucao.mobile.paymentMethod'),
              value: _tipoAcertoSelecionado?.descricaoExibicao,
              hint: _t('devolucao.mobile.selectPayment'),
              helperText: _t('devolucao.mobile.paymentHelper'),
              icon: Icons.payments_outlined,
              enabled: !_carregandoApoio,
              onTap: _selecionarTipoAcerto,
            ),
            if (_tiposAcerto.isEmpty && !_carregandoApoio) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _t('devolucao.mobile.noPaymentMethodsMessage'),
                style: TextStyle(
                  color: _colors.error,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmacao() {
    return _MobileSectionCard(
      icon: Icons.fact_check_outlined,
      title: _t('devolucao.mobile.reviewTitle'),
      subtitle: _t('devolucao.mobile.reviewSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _observacoesController,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => _invalidarChave(),
            decoration: InputDecoration(
              labelText: _t('devolucao.mobile.notes'),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey<String>('devolucao-submit'),
            onPressed: _salvando ? null : _registrar,
            icon: _salvando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _colors.onAccent,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _salvando
                  ? _t('devolucao.mobile.processing')
                  : _tipo == TipoDevolucaoProduto.troca
                  ? _t('devolucao.mobile.completeExchange')
                  : _t('devolucao.mobile.completeReturn'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _t('devolucao.mobile.confirmationHelper'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _colors.mutedText,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentes() {
    return _MobileSectionCard(
      icon: Icons.history_rounded,
      title: _t('devolucao.mobile.recentTitle'),
      subtitle: _t('devolucao.mobile.recentSubtitle'),
      trailing: IconButton(
        tooltip: _t('common.refresh'),
        onPressed: _carregandoApoio ? null : _carregarApoio,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: _carregandoApoio
          ? Semantics(
              liveRegion: true,
              label: _t('devolucao.mobile.loadingRecent'),
              child: Column(
                children: <Widget>[
                  LinearProgressIndicator(
                    minHeight: 3,
                    color: _colors.accent,
                    backgroundColor: _colors.softAccentSurface,
                  ),
                  const SizedBox(height: 12),
                  _RecentSkeleton(colors: _colors),
                ],
              ),
            )
          : _recentes.isEmpty
          ? _MobileEmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: _t('devolucao.mobile.emptyRecent'),
            )
          : Column(
              children: <Widget>[
                for (
                  int index = 0;
                  index < _recentes.length;
                  index++
                ) ...<Widget>[
                  _RecentOperationTile(
                    item: _recentes[index],
                    typeLabel: _tipoLabel(_recentes[index].tipo),
                    customerLabel: _recentes[index].nomeCliente.isEmpty
                        ? _t('devolucao.mobile.unidentifiedCustomer')
                        : _recentes[index].nomeCliente,
                    dateLabel: _data(_recentes[index].dataCriacao),
                    valueLabel: _moeda(_recentes[index].saldoFinanceiro.abs()),
                  ),
                  if (index < _recentes.length - 1)
                    Divider(height: 1, color: _colors.border),
                ],
              ],
            ),
    );
  }

  String _condicaoLabel(CondicaoProdutoDevolvido value) {
    return switch (value) {
      CondicaoProdutoDevolvido.novo => _t('devolucao.mobile.condition.sealed'),
      CondicaoProdutoDevolvido.aberto => _t(
        'devolucao.mobile.condition.opened',
      ),
      CondicaoProdutoDevolvido.usado => _t('devolucao.mobile.condition.used'),
      CondicaoProdutoDevolvido.comDefeito => _t(
        'devolucao.mobile.condition.defective',
      ),
      CondicaoProdutoDevolvido.avariado => _t(
        'devolucao.mobile.condition.damaged',
      ),
      CondicaoProdutoDevolvido.outro => _t('devolucao.mobile.condition.other'),
    };
  }

  IconData _condicaoIcon(CondicaoProdutoDevolvido value) {
    return switch (value) {
      CondicaoProdutoDevolvido.novo => Icons.inventory_2_outlined,
      CondicaoProdutoDevolvido.aberto => Icons.unarchive_outlined,
      CondicaoProdutoDevolvido.usado => Icons.history_rounded,
      CondicaoProdutoDevolvido.comDefeito => Icons.build_circle_outlined,
      CondicaoProdutoDevolvido.avariado => Icons.broken_image_outlined,
      CondicaoProdutoDevolvido.outro => Icons.more_horiz_rounded,
    };
  }

  String _tipoLabel(String value) {
    return value.trim().toUpperCase() == TipoDevolucaoProduto.troca.apiValue
        ? _t('devolucao.mobile.exchange')
        : _t('devolucao.mobile.returnOnly');
  }
}

class _ItemDevolucaoMobileEdicao {
  _ItemDevolucaoMobileEdicao(this.item)
    : quantidadeController = TextEditingController(
        text: item.quantidadeDisponivel >= 1
            ? '1'
            : item.quantidadeDisponivel.toString(),
      ),
      motivoController = TextEditingController();

  final ItemVendaElegivelDevolucao item;
  final TextEditingController quantidadeController;
  final TextEditingController motivoController;
  bool selecionado = false;
  bool retornarAoEstoque = true;
  CondicaoProdutoDevolvido condicao = CondicaoProdutoDevolvido.novo;

  void dispose() {
    quantidadeController.dispose();
    motivoController.dispose();
  }
}

class _ItemTrocaMobileEdicao {
  _ItemTrocaMobileEdicao(this.produto)
    : quantidadeController = TextEditingController(text: '1');

  final ProdutoModel produto;
  final TextEditingController quantidadeController;

  void dispose() => quantidadeController.dispose();
}

class _MobileSectionCard extends StatelessWidget {
  const _MobileSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.softAccentSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.titleText,
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((subtitle ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  const _MobileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: colors.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
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

class _OperationTypeOption extends StatelessWidget {
  const _OperationTypeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 94),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? colors.accent.withValues(alpha: 0.52)
                    : colors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: selected ? colors.accent : colors.mutedText),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.titleText : colors.mutedText,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniDataChip extends StatelessWidget {
  const _MiniDataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.iconSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.mutedText,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StockReturnToggle extends StatelessWidget {
  const _StockReturnToggle({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_outlined, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emphasized ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: emphasized
              ? colors.accent.withValues(alpha: 0.36)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized ? colors.accent : colors.titleText,
              fontSize: emphasized ? 19 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileEmptyState extends StatelessWidget {
  const _MobileEmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: <Widget>[
          Icon(icon, color: colors.mutedText, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _RecentOperationTile extends StatelessWidget {
  const _RecentOperationTile({
    required this.item,
    required this.typeLabel,
    required this.customerLabel,
    required this.dateLabel,
    required this.valueLabel,
  });

  final DevolucaoProdutoResponse item;
  final String typeLabel;
  final String customerLabel;
  final String dateLabel;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.iconSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item.tipo == TipoDevolucaoProduto.troca.apiValue
                  ? Icons.swap_horiz_rounded
                  : Icons.assignment_return_outlined,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.codigoDevolucao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$customerLabel • $typeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.mutedText, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(color: colors.mutedText, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valueLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton({required this.colors});

  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.iconSurface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.history_rounded, color: colors.mutedText),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SkeletonLine(widthFactor: 0.48, colors: colors),
              const SizedBox(height: 7),
              _SkeletonLine(widthFactor: 0.76, colors: colors),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.colors});

  final double widthFactor;
  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: colors.strongBorder.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
