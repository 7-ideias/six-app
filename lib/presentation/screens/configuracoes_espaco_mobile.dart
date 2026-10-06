import 'package:flutter/material.dart';
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
  late final _service =
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
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final items = await _service.listar(_grupo);
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([ConfiguracaoFinanceira? item]) async {
    final editor = _MobileConfigEditor(
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
          for (final grupo in ['CONTAS', 'CATEGORIAS', 'CENTROS'])
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

class _MobileConfigEditor extends StatefulWidget {
  const _MobileConfigEditor({
    required this.service,
    required this.grupo,
    this.item,
  });
  final ConfiguracaoFinanceiraService service;
  final String grupo;
  final ConfiguracaoFinanceira? item;
  @override
  State<_MobileConfigEditor> createState() => _MobileConfigEditorState();
}

class _MobileConfigEditorState extends State<_MobileConfigEditor> {
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _instituicao = TextEditingController(
    text: widget.item?.instituicao ?? '',
  );
  late String _tipo =
      widget.item?.tipo ?? (widget.grupo == 'CONTAS' ? 'BANCO' : 'AMBOS');
  late bool _ativo = widget.item?.ativo ?? true;
  bool _saving = false;
  bool _error = false;
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _nome.dispose();
    _instituicao.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      await widget.service.salvar(
        widget.grupo,
        original: widget.item,
        nome: _nome.text,
        tipo: _tipo,
        instituicao: _instituicao.text,
        ativo: _ativo,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t('space.' + widget.grupo),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                enabled: !_saving,
                maxLength: 120,
                decoration: InputDecoration(labelText: context.t('space.name')),
                validator:
                    (s) =>
                        s == null || s.trim().isEmpty
                            ? context.t('space.required')
                            : null,
              ),
              if (widget.grupo == 'CONTAS')
                TextField(
                  controller: _instituicao,
                  enabled: !_saving,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.t('space.institution'),
                  ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  for (final tipo
                      in (widget.grupo == 'CONTAS'
                          ? ['BANCO', 'CARTEIRA', 'CAIXA']
                          : widget.grupo == 'CENTROS'
                          ? ['CUSTO', 'RESULTADO', 'AMBOS']
                          : ['RECEITA', 'DESPESA', 'AMBOS']))
                    ChoiceChip(
                      label: Text(context.t('space.' + tipo)),
                      selected: tipo == _tipo,
                      onSelected:
                          _saving ? null : (_) => setState(() => _tipo = tipo),
                    ),
                ],
              ),
              SwitchListTile.adaptive(
                title: Text(context.t('space.active')),
                value: _ativo,
                onChanged: _saving ? null : (v) => setState(() => _ativo = v),
              ),
              Text(context.t('space.history')),
              if (_error)
                Text(
                  context.t('space.saveError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  context.t(_saving ? 'space.loading' : 'space.save'),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(context.t('space.cancel')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
