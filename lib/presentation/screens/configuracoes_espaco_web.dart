import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/web/conta_financeira_web_field.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

class ConfiguracoesEspacoWeb extends StatefulWidget {
  const ConfiguracoesEspacoWeb({super.key, required this.espaco});
  final String espaco;
  @override
  State<ConfiguracoesEspacoWeb> createState() => _ConfiguracoesEspacoWebState();
}

class _ConfiguracoesEspacoWebState extends State<ConfiguracoesEspacoWeb> {
  late final _service = ConfiguracaoFinanceiraService(widget.espaco);
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
    final editor = _WebConfigEditor(
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

class _WebConfigEditor extends StatefulWidget {
  const _WebConfigEditor({
    required this.service,
    required this.grupo,
    this.item,
  });
  final ConfiguracaoFinanceiraService service;
  final String grupo;
  final ConfiguracaoFinanceira? item;
  @override
  State<_WebConfigEditor> createState() => _WebConfigEditorState();
}

class _WebConfigEditorState extends State<_WebConfigEditor> {
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _instituicao = TextEditingController(
    text: widget.item?.instituicao ?? '',
  );
  late String _tipo =
      widget.item?.tipo ?? (widget.grupo == 'CONTAS' ? 'BANCO' : 'AMBOS');
  late bool _ativo = widget.item?.ativo ?? true;
  late String? _contaDestinoId = widget.item?.contaDestinoId;
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
        tipo: widget.grupo == 'MAQUININHAS' ? 'MAQUININHA' : _tipo,
        contaDestinoId: _contaDestinoId,
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
              if (widget.grupo == 'CONTAS' || widget.grupo == 'MAQUININHAS')
                TextField(
                  controller: _instituicao,
                  enabled: !_saving,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.t(
                      widget.grupo == 'MAQUININHAS'
                          ? 'machine.operator'
                          : 'space.institution',
                    ),
                  ),
                ),
              if (widget.grupo == 'MAQUININHAS')
                ContaFinanceiraWebField(
                  espaco: widget.service.espaco,
                  value: _contaDestinoId,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _contaDestinoId = v),
                ),
              if (widget.grupo != 'MAQUININHAS')
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
                            _saving
                                ? null
                                : (_) => setState(() => _tipo = tipo),
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
