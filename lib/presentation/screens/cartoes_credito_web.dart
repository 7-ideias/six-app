import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/web/cartao_credito_web_editor.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class CartoesCreditoWeb extends StatefulWidget {
  const CartoesCreditoWeb({super.key, required this.espaco, this.client, this.contasService});
  final String espaco;
  final CartaoCreditoApiClient? client;
  final ConfiguracaoFinanceiraService? contasService;

  @override
  State<CartoesCreditoWeb> createState() => _CartoesCreditoWebState();
}

class _CartoesCreditoWebState extends State<CartoesCreditoWeb> {
  late CartaoCreditoApiClient _client = widget.client ?? CartaoCreditoApiClient(espaco: widget.espaco);
  List<CartaoCredito> _items = [];
  bool _loading = true, _canEdit = false, _editing = false;
  String? _error;
  int _request = 0;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant CartoesCreditoWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.espaco != widget.espaco || oldWidget.client != widget.client) {
      if (oldWidget.client == null) _client.dispose();
      _client = widget.client ?? CartaoCreditoApiClient(espaco: widget.espaco);
      _items = [];
      _canEdit = false;
      _load();
    }
  }

  @override
  void dispose() {
    if (widget.client == null) _client.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _client.listar();
      if (!mounted || request != _request) return;
      setState(() { _items = result.cartoes; _canEdit = result.podeEditar; });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error is CartaoCreditoApiException ? error.messageKey : 'cards.error.server';
        _canEdit = false;
        if (error is CartaoCreditoApiException &&
            (error.statusCode == 401 || error.statusCode == 403)) _items = [];
      });
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _edit([CartaoCredito? item]) async {
    if (!_canEdit || _editing || _loading || _error != null) return;
    setState(() => _editing = true);
    final result = await showDialog<CartaoCredito>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: CartaoCreditoWebEditor(
            espaco: widget.espaco, client: _client, item: item,
            contasService: widget.contasService,
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _editing = false);
    if (result != null) {
      // Reflect only the server-confirmed response, even if the refresh fails.
      setState(() {
        _items = [..._items.where((e) => e.id != result.id), result]
          ..sort((a, b) => a.nome.compareTo(b.nome));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('cards.saved'))));
      await _load();
    }
  }

  Widget _card(CartaoCredito item) {
    final tokens = WebThemeTokens.of(context);
    return Card(
      elevation: 0,
      color: tokens.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: tokens.cardBorder)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.credit_card_rounded, color: tokens.info, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nome, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item.instituicao, style: TextStyle(color: tokens.secondaryText)),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 8, children: [
              Text('${context.t('cards.closing')}: ${item.diaFechamento}'),
              Text('${context.t('cards.due')}: ${item.diaVencimento}'),
              Text(context.t(item.ativo ? 'space.active' : 'space.inactive'),
                style: TextStyle(color: item.ativo ? tokens.financialPositive : tokens.secondaryText, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('${context.t('cards.account')}: ${item.contaPrevistaId == null ? context.t('space.none') : (item.contaPrevistaNome?.isNotEmpty == true ? item.contaPrevistaNome! : context.t('cards.linkedAccount'))}',
              style: TextStyle(color: tokens.secondaryText)),
          ])),
          if (_canEdit && _error == null)
            IconButton(
              tooltip: context.t('space.edit'),
              onPressed: _loading || _editing ? null : () => _edit(item),
              icon: const Icon(Icons.edit_outlined),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        SixWebDashboardHeader(
          icon: Icons.credit_card_rounded,
          title: context.t('cards.title'),
          subtitle: '${context.t('space.${widget.espaco}')} · ${context.t('cards.subtitle')}',
          onBack: () => Navigator.of(context).pop(),
          actions: [
            OutlinedButton.icon(onPressed: _loading || _editing ? null : _load,
              icon: const Icon(Icons.refresh), label: Text(context.t('cards.refresh'))),
            if (_canEdit && _error == null)
              FilledButton.icon(key: const ValueKey('cards-create'),
                onPressed: _loading || _editing ? null : () => _edit(),
                icon: const Icon(Icons.add), label: Text(context.t('cards.new'))),
          ],
        ),
        const SizedBox(height: 20),
        Text(context.t('cards.stageHint')),
        const SizedBox(height: 20),
        if (_loading)
          SixBackendLoading(title: context.t('space.loading'), subtitle: context.t('cards.title'))
        else if (_error != null)
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t(_error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_items.isNotEmpty) ...[const SizedBox(height: 8), Text(context.t('cards.stale'))],
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(context.t('space.retry'))),
            ],
          )))
        else if (_items.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.t('cards.empty')))),
        if (!_loading && _error == null && !_canEdit)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(context.t('cards.readOnly'))),
        ..._items.map(_card),
      ]),
    ))),
  );
}
