import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/web/configuracao_financeira_web_editor.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

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
  @override
  void initState() {
    super.initState();
    _load();
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
      _grupo = 'CONTAS';
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final items = await _service.listar(_grupo);
      if (mounted && request == _request) setState(() => _items = items);
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
        Text(context.t('space.empty'))
      else
        for (final item in _items)
          Card(
            color: colors.surface,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [
                            item.instituicao,
                            context.t(
                              item.ativo ? 'space.active' : 'space.inactive',
                            ),
                          ].where((s) => s.isNotEmpty).join(' · '),
                        ),
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
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.t('space.settings'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(padding: const EdgeInsets.all(24), children: content),
        ),
      ),
    );
  }
}
