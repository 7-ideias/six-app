import 'configuracao_financeira_web_editor.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Future<String?> selecionarContaWeb(
  BuildContext context,
  String espaco, {
  String grupo = 'CONTAS',
  bool permitirLimpar = false,
  ConfiguracaoFinanceiraService? service,
}) async {
  final ownedService = service ?? ConfiguracaoFinanceiraService(espaco);
  List<ConfiguracaoFinanceira> items;
  try {
    items = await ownedService.listar(grupo);
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('space.retry'))));
    if (service == null) ownedService.dispose();
    return null;
  }
  if (!context.mounted) {
    if (service == null) ownedService.dispose();
    return null;
  }
  bool abrindoCadastro = false;
  String busca = '';
  Future<void> editarCategoria(
    BuildContext dialogContext,
    StateSetter update, [
    ConfiguracaoFinanceira? item,
  ]) async {
    if (abrindoCadastro) return;
    update(() => abrindoCadastro = true);
    String? nomeSalvo;
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ConfiguracaoFinanceiraWebEditor(
            service: ownedService,
            grupo: 'CATEGORIAS',
            item: item,
            onSaved: (nome) => nomeSalvo = nome,
          ),
        ),
      ),
    );
    if (!dialogContext.mounted) return;
    update(() => abrindoCadastro = false);
    if (nomeSalvo != null) Navigator.of(dialogContext).pop(nomeSalvo);
  }

  final options = StatefulBuilder(
    builder: (context, setState) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.t('space.' + grupo),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (grupo == 'CATEGORIAS') ...[
          const SizedBox(height: 8),
          Text(context.t('space.' + espaco)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: context.t('agenda.category.search'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => busca = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('agenda-category-create'),
            onPressed: abrindoCadastro
                ? null
                : () => editarCategoria(context, setState),
            icon: const Icon(Icons.add),
            label: Text(context.t('agenda.category.create')),
          ),
          const SizedBox(height: 12),
        ],
        if (permitirLimpar)
          ListTile(
            title: Text(context.t('space.none')),
            onTap: () => Navigator.of(context).pop(''),
          ),
        if (!items.any((e) => e.ativo))
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.t(
                grupo == 'CONTAS'
                    ? 'space.emptyAccountHint'
                    : grupo == 'CATEGORIAS'
                    ? 'agenda.category.empty'
                    : 'space.emptyHint',
              ),
            ),
          ),
        for (final item in items.where(
          (e) => e.ativo && e.nome.toLowerCase().contains(busca),
        ))
          ListTile(
            title: Text(item.nome),
            trailing: grupo != 'CATEGORIAS'
                ? null
                : IconButton(
                    tooltip: context.t('agenda.category.edit'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: abrindoCadastro
                        ? null
                        : () => editarCategoria(context, setState, item),
                  ),
            subtitle: item.instituicao.isEmpty ? null : Text(item.instituicao),
            onTap: () => Navigator.of(
              context,
            ).pop(grupo != 'CATEGORIAS' ? item.id : item.nome),
          ),
        if (grupo == 'CONTAS')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: FilledButton.icon(
              key: const ValueKey('cadastrar-conta-no-seletor'),
              icon: const Icon(Icons.add),
              label: Text(context.t('space.createAccount')),
              onPressed: abrindoCadastro
                  ? null
                  : () async {
                      setState(() => abrindoCadastro = true);
                      final conta = await showDialog<ConfiguracaoFinanceira>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: ConfiguracaoFinanceiraWebEditor(
                              service: ownedService,
                              grupo: 'CONTAS',
                              selecionarAoCriar: true,
                            ),
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() => abrindoCadastro = false);
                      if (conta != null) Navigator.of(context).pop(conta.id);
                    },
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('space.cancel')),
        ),
      ],
    ),
  );
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 500),
          child: options,
        ),
      ),
    );
  } finally {
    if (service == null) ownedService.dispose();
  }
}

class ContaFinanceiraWebField extends StatefulWidget {
  const ContaFinanceiraWebField({
    super.key,
    required this.espaco,
    required this.onChanged,
    this.value,
    this.label,
    this.enabled = true,
    this.service,
  });
  final String espaco;
  final ConfiguracaoFinanceiraService? service;
  final String? value;
  final String? label;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  @override
  State<ContaFinanceiraWebField> createState() =>
      _ContaFinanceiraWebFieldState();
}

class _ContaFinanceiraWebFieldState extends State<ContaFinanceiraWebField> {
  List<ConfiguracaoFinanceira> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  int _request = 0;

  @override
  void didUpdateWidget(covariant ContaFinanceiraWebField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.espaco != widget.espaco ||
        oldWidget.service != widget.service) {
      _items = [];
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    final espaco = widget.espaco;
    final ownsService = widget.service == null;
    final s = widget.service ?? ConfiguracaoFinanceiraService(espaco);
    try {
      final items = await s.listar('CONTAS');
      if (mounted && widget.espaco == espaco && request == _request)
        setState(() => _items = items);
    } catch (_) {
    } finally {
      if (ownsService) s.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = context.t('space.none');
    for (final item in _items) {
      if (item.id == widget.value) label = item.nome;
    }
    return TextFormField(
      key: ValueKey('conta-${widget.espaco}-${widget.value}-$label'),
      initialValue: label,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label ?? context.t('space.account'),
        prefixIcon: const Icon(Icons.account_balance_outlined),
        suffixIcon: const Icon(Icons.expand_more_rounded),
      ),
      onTap: !widget.enabled
          ? null
          : () async {
              final espaco = widget.espaco;
              final id = await selecionarContaWeb(
                context,
                widget.espaco,
                permitirLimpar: true,
                service: widget.service,
              );
              if (id != null && mounted && widget.espaco == espaco) {
                widget.onChanged(id.isEmpty ? null : id);
                await _load();
              }
            },
    );
  }
}
