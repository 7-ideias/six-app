import 'package:sixpos/presentation/components/web/financeiro_configuracao_web_dialog.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'cartoes_credito_web.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/web/configuracao_financeira_web_editor.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/data/models/marca_financeira_catalogo.dart';
import 'package:sixpos/presentation/components/web/configuracao_financeira_marca_card.dart';

class ConfiguracoesEspacoWeb extends StatefulWidget {
  const ConfiguracoesEspacoWeb({super.key, required this.espaco, this.service});
  final String espaco;
  final ConfiguracaoFinanceiraService? service;
  @override
  State<ConfiguracoesEspacoWeb> createState() => _ConfiguracoesEspacoWebState();
}

class _ConfiguracoesEspacoWebState extends State<ConfiguracoesEspacoWeb> {
  late ConfiguracaoFinanceiraService _service =
      widget.service ?? ConfiguracaoFinanceiraService(widget.espaco);
  String _grupo = 'CONTAS';
  bool _loading = true;
  bool _error = false;
  List<ConfiguracaoFinanceira> _items = [];
  List<ConfiguracaoFinanceira> _contasDestino = [];
  CatalogoInstituicoesBrasil _catalogo = CatalogoInstituicoesBrasil.vazio;
  int _catalogoRequest = 0;
  @override
  void initState() {
    super.initState();
    _load();
    _loadCatalogo();
  }

  Future<void> _loadCatalogo() async {
    final request = ++_catalogoRequest;
    try {
      final resposta = await _service.catalogoBrasileiro();
      if (mounted && request == _catalogoRequest) {
        setState(() => _catalogo = resposta);
      }
    } catch (_) {
      if (mounted && request == _catalogoRequest) {
        setState(() => _catalogo = CatalogoInstituicoesBrasil.vazio);
      }
    }
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  int _request = 0;

  @override
  void didUpdateWidget(covariant ConfiguracoesEspacoWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.espaco != widget.espaco ||
        oldWidget.service != widget.service) {
      if (oldWidget.service == null) _service.dispose();
      _service = widget.service ?? ConfiguracaoFinanceiraService(widget.espaco);
      _items = [];
      _contasDestino = [];
      _catalogo = CatalogoInstituicoesBrasil.vazio;
      _grupo = 'CONTAS';
      _load();
      _loadCatalogo();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final grupo = _grupo;
      final consultas = await Future.wait([
        _service.listar(grupo),
        if (grupo == 'MAQUININHAS') _service.listar('CONTAS'),
      ]);
      if (mounted && request == _request) {
        setState(() {
          _items = consultas.first;
          _contasDestino = consultas.length > 1 ? consultas[1] : [];
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _error = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _edit([ConfiguracaoFinanceira? item]) async {
    final editor = ConfiguracaoFinanceiraWebEditor(
      service: _service,
      grupo: _grupo,
      item: item,
      catalogo: _catalogo,
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: editor,
            ),
          ),
    );
    if (mounted) await _load();
  }

  String _descricao(ConfiguracaoFinanceira item, BuildContext context) {
    if (_grupo == 'MAQUININHAS') {
      return item.instituicao.isEmpty
          ? context.t('financialBrand.terminal') : item.instituicao;
    }
    final tipo = switch (item.tipo) {
      'BANCO' => context.t('financialBrand.bank'),
      'CARTEIRA' => context.t('financialBrand.wallet'),
      'CAIXA' => context.t('financialBrand.cash'),
      _ => context.t('space.${item.tipo}'),
    };
    if (item.instituicao.isEmpty) return tipo;
    return '$tipo · ${item.instituicao}';
  }

  String? _detalhe(ConfiguracaoFinanceira item, BuildContext context) {
    if (_grupo != 'MAQUININHAS') return null;
    String destino = context.t('financialBrand.noDestination');
    for (final conta in _contasDestino) {
      if (conta.id == item.contaDestinoId) {
        destino = conta.nome;
        break;
      }
    }
    return '${context.t('financialBrand.paymentDestination')}: $destino';
  }

  Widget _vazio(BuildContext context) {
    final contas = _grupo == 'CONTAS';
    final maquininhas = _grupo == 'MAQUININHAS';
    if (!contas && !maquininhas) return Text(context.t('space.empty'));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(contas ? Icons.account_balance_outlined
                  : Icons.point_of_sale_outlined, size: 38,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(context.t(contas
                  ? 'financialBrand.emptyAccountsTitle'
                  : 'financialBrand.emptyMachinesTitle'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(context.t(contas
                  ? 'financialBrand.emptyAccountsText'
                  : 'financialBrand.emptyMachinesText'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('financial-brand-first-web'),
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(context.t(contas
                    ? 'financialBrand.firstAccount'
                    : 'financialBrand.firstMachine')),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.credit_card_outlined, size: 18),
            label: Text(context.t('cards.title')),
            onPressed: () => showFinanceiroConfiguracaoWebDialog<void>(
              context: context,
              title: context.t('cards.title'),
              child: CartoesCreditoWeb(espaco: widget.espaco),
            ),
          ),
          for (final grupo in [
            'CONTAS',
            'MAQUININHAS',
            'CATEGORIAS',
            'CENTROS',
          ])
            ChoiceChip(
              label: Text(context.t('space.' + grupo)),
              selected: _grupo == grupo,
              onSelected:
                  _loading
                      ? null
                      : (_) {
                        setState(() => _grupo = grupo);
                        _load();
                      },
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (_loading)
        SixBackendLoading(
          title: context.t('space.loading'),
          subtitle: context.t('space.settings'),
        )
      else if (_error)
        TextButton(onPressed: _load, child: Text(context.t('space.retry')))
      else if (_items.isEmpty)
        _vazio(context)
      else
        for (final item in _items)
          ConfiguracaoFinanceiraMarcaCard(
            key: ValueKey('financial-brand-web-${item.id}'),
            nome: item.nome,
            descricao: _descricao(item, context),
            detalhe: _detalhe(item, context),
            tipo: _grupo == 'MAQUININHAS' ? 'MAQUININHA' : item.tipo,
            ativo: item.ativo,
            textoStatus: context.t(item.ativo ? 'space.active' : 'space.inactive'),
            tooltipEditar: context.t('space.edit'),
            logotipoUrl: MarcaFinanceiraCatalogo.logoDaConfiguracao(
              item, _grupo, _catalogo,
            ),
            onEdit: () => _edit(item),
          ),
    ];
    return Scaffold(
      body: Column(
        children: [
          SixWebDashboardHeader(
            icon: Icons.account_balance_outlined,
            title: context.t('space.settings'),
            subtitle: context.t('space.' + widget.espaco),
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              if (!(!_loading && !_error && _items.isEmpty &&
                  (_grupo == 'CONTAS' || _grupo == 'MAQUININHAS')))
                FilledButton.icon(
                  onPressed: _loading ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(context.t('space.add')),
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: content,
            ),
          ),
        ],
      ),
    );
  }
}
