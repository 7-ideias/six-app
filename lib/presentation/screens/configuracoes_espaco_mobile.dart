import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/mobile/configuracao_financeira_mobile_editor.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import '../components/mobile/six_mobile_page_shell.dart';

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
  void didUpdateWidget(covariant ConfiguracoesEspacoMobile oldWidget) {
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
    final editor = ConfiguracaoFinanceiraMobileEditor(
      service: _service,
      grupo: _grupo,
      item: item,
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
                            color: colors.titleText,
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
