import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Future<String?> selecionarContaMobile(
  BuildContext context,
  String espaco, {
  String grupo = 'CONTAS',
  bool permitirLimpar = false,
}) async {
  final service = ConfiguracaoFinanceiraService(espaco);
  List<ConfiguracaoFinanceira> items;
  try {
    items = await service.listar(grupo);
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('space.retry'))));
    return null;
  } finally {
    service.dispose();
  }
  if (!context.mounted) return null;
  final options = Builder(
    builder:
        (context) => ListView(
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
                child: Text(context.t('space.emptyHint')),
              ),
            for (final item in items.where((e) => e.ativo))
              ListTile(
                title: Text(item.nome),
                subtitle:
                    item.instituicao.isEmpty ? null : Text(item.instituicao),
                onTap:
                    () => Navigator.of(
                      context,
                    ).pop(grupo != 'CATEGORIAS' ? item.id : item.nome),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t('space.cancel')),
            ),
          ],
        ),
  );
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.65,
            ),
            child: options,
          ),
        ),
  );
}

class ContaFinanceiraMobileField extends StatefulWidget {
  const ContaFinanceiraMobileField({
    super.key,
    required this.espaco,
    required this.onChanged,
    this.value,
    this.enabled = true,
  });
  final String espaco;
  final String? value;
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

  Future<void> _load() async {
    final s = ConfiguracaoFinanceiraService(widget.espaco);
    try {
      final items = await s.listar('CONTAS');
      if (mounted) setState(() => _items = items);
    } catch (_) {
    } finally {
      s.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = context.t('space.none');
    for (final item in _items) {
      if (item.id == widget.value) label = item.nome;
    }
    return OutlinedButton.icon(
      onPressed:
          !widget.enabled
              ? null
              : () async {
                final id = await selecionarContaMobile(
                  context,
                  widget.espaco,
                  permitirLimpar: true,
                );
                if (id != null && mounted) {
                  widget.onChanged(id.isEmpty ? null : id);
                  await _load();
                }
              },
      icon: const Icon(Icons.account_balance_outlined),
      label: Text('${context.t('space.account')}: $label'),
    );
  }
}
