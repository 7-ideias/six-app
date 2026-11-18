import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/mobile/configuracao_financeira_mobile_editor.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/data/models/marca_financeira_catalogo.dart';
import 'package:sixpos/presentation/components/marca_financeira_avatar.dart';

class ConfiguracoesEspacoMobile extends StatefulWidget {
  const ConfiguracoesEspacoMobile({
    super.key,
    required this.espaco,
    this.service,
  });
  final String espaco;
  final ConfiguracaoFinanceiraService? service;
  @override
  State<ConfiguracoesEspacoMobile> createState() =>
      _ConfiguracoesEspacoMobileState();
}

class _ConfiguracoesEspacoMobileState extends State<ConfiguracoesEspacoMobile> {
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
  void didUpdateWidget(covariant ConfiguracoesEspacoMobile oldWidget) {
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

  Future<List<ConfiguracaoFinanceira>> _contasDestinoSeguras() async {
    try {
      return await _service.listar('CONTAS');
    } catch (_) {
      // Uma falha secundária não pode esconder as maquininhas cadastradas.
      return const [];
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
        if (grupo == 'MAQUININHAS') _contasDestinoSeguras(),
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
    final editor = ConfiguracaoFinanceiraMobileEditor(
      service: _service,
      grupo: _grupo,
      item: item,
      catalogo: _catalogo,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.sixMobileColors.surface,
      builder: (_) => editor,
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
    return item.instituicao.isEmpty ? tipo : '$tipo · ${item.instituicao}';
  }

  String? _destino(ConfiguracaoFinanceira item, BuildContext context) {
    if (_grupo != 'MAQUININHAS') return null;
    final nome = _contasDestino
        .where((conta) => conta.id == item.contaDestinoId)
        .map((conta) => conta.nome).firstOrNull;
    final destino = nome ?? (item.contaDestinoId == null
        ? context.t('financialBrand.noDestination')
        : context.t('cards.linkedAccount'));
    return '${context.t('financialBrand.paymentDestination')}: $destino';
  }

  Widget _emptyState(BuildContext context) {
    final colors = context.sixMobileColors;
    final conta = _grupo == 'CONTAS';
    final maquininha = _grupo == 'MAQUININHAS';
    if (!conta && !maquininha) return Text(context.t('space.empty'));
    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(conta ? Icons.account_balance_outlined
              : Icons.point_of_sale_outlined,
              size: 38, color: colors.accent),
          const SizedBox(height: 12),
          Text(context.t(conta
              ? 'financialBrand.emptyAccountsTitle'
              : 'financialBrand.emptyMachinesTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.titleText,
              )),
          const SizedBox(height: 8),
          Text(context.t(conta
              ? 'financialBrand.emptyAccountsText'
              : 'financialBrand.emptyMachinesText'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
              )),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('financial-brand-first-mobile'),
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: Text(context.t(conta
                ? 'financialBrand.firstAccount'
                : 'financialBrand.firstMachine')),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    final content = <Widget>[
      Text(
        context.t('space.' + widget.espaco),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
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
      if (!(!_loading && !_error && _items.isEmpty &&
          (_grupo == 'CONTAS' || _grupo == 'MAQUININHAS')))
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _loading ? null : () => _edit(),
            icon: const Icon(Icons.add),
            label: Text(context.t('space.add')),
          ),
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
        _emptyState(context)
      else
        for (final item in _items)
          Card(
            key: ValueKey('financial-brand-mobile-${item.id}'),
            color: colors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _edit(item),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    MarcaFinanceiraAvatar(
                      nome: _descricao(item, context),
                      tipo: _grupo == 'MAQUININHAS'
                          ? 'MAQUININHA' : item.tipo,
                      logotipoUrl: MarcaFinanceiraCatalogo.logoDaConfiguracao(
                        item, _grupo, _catalogo,
                      ),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nome,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: colors.titleText,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_descricao(item, context),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.mutedText)),
                          if (_grupo == 'MAQUININHAS') ...[
                            const SizedBox(height: 4),
                            Text(_destino(item, context) ?? '', maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.mutedText)),
                          ],
                          const SizedBox(height: 4),
                          Text(context.t(item.ativo
                              ? 'space.active' : 'space.inactive'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: item.ativo
                                      ? colors.accent : colors.mutedText)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('space.edit'),
                      onPressed: () => _edit(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ];
    return SixMobilePageShell(
      title: context.t('space.settings'),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      enableAnimatedBackground: false,
      bodyBuilder:
          (context, controller, inset) => ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(16, inset + 16, 16, 24),
            children: content,
          ),
    );
  }
}
