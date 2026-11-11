import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'configuracao_financeira_mobile_editor.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Future<String?> selecionarContaMobile(
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
  String busca = '';
  bool abrindoCadastro = false;
  Future<void> editarCategoria(
    BuildContext sheetContext,
    StateSetter update, [
    ConfiguracaoFinanceira? item,
  ]) async {
    if (abrindoCadastro) return;
    update(() => abrindoCadastro = true);
    await showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: sheetContext.sixMobileColors.surface,
      builder: (_) => ConfiguracaoFinanceiraMobileEditor(
        service: ownedService,
        grupo: 'CATEGORIAS',
        item: item,
      ),
    );
    if (!sheetContext.mounted) return;
    try {
      final atualizados = await ownedService.listar(grupo);
      if (sheetContext.mounted) update(() => items = atualizados);
    } catch (_) {
      if (sheetContext.mounted)
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(SnackBar(content: Text(sheetContext.t('space.retry'))));
    } finally {
      if (sheetContext.mounted) update(() => abrindoCadastro = false);
    }
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
                    : 'agenda.category.empty',
              ),
            ),
          ),
        for (final item in items.where(
          (e) => e.ativo && e.nome.toLowerCase().contains(busca),
        ))
          ListTile(
            title: Text(item.nome),
            trailing: grupo == 'CATEGORIAS'
                ? IconButton(
                    tooltip: context.t('common.edit', fallback: 'Editar'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: abrindoCadastro
                        ? null
                        : () => editarCategoria(context, setState, item),
                  )
                : null,
            subtitle: item.instituicao.isEmpty ? null : Text(item.instituicao),
            onTap: () => Navigator.of(
              context,
            ).pop(grupo != 'CATEGORIAS' ? item.id : item.nome),
          ),
        if (grupo == 'CATEGORIAS')
          OutlinedButton.icon(
            onPressed: abrindoCadastro
                ? null
                : () => editarCategoria(context, setState),
            icon: const Icon(Icons.add),
            label: Text(context.t('agenda.category.create')),
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
                      final conta =
                          await showModalBottomSheet<ConfiguracaoFinanceira>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            isDismissible: false,
                            enableDrag: false,
                            backgroundColor: context.sixMobileColors.surface,
                            builder: (_) => ConfiguracaoFinanceiraMobileEditor(
                              service: ownedService,
                              grupo: 'CONTAS',
                              selecionarAoCriar: true,
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
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: options,
        ),
      ),
    );
  } finally {
    if (service == null) ownedService.dispose();
  }
}

class ContaFinanceiraMobileField extends StatefulWidget {
  const ContaFinanceiraMobileField({
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
  State<ContaFinanceiraMobileField> createState() =>
      _ContaFinanceiraMobileFieldState();
}

class _ContaFinanceiraMobileFieldState
    extends State<ContaFinanceiraMobileField> {
  List<ConfiguracaoFinanceira> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  int _request = 0;

  @override
  void didUpdateWidget(covariant ContaFinanceiraMobileField oldWidget) {
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
    return OutlinedButton.icon(
      onPressed: !widget.enabled
          ? null
          : () async {
              final espaco = widget.espaco;
              final id = await selecionarContaMobile(
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
      icon: const Icon(Icons.account_balance_outlined),
      label: Text('${widget.label ?? context.t('space.account')}: $label'),
    );
  }
}
