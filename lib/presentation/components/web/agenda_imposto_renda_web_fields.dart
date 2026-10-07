import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_comprovante_picker.dart';
import 'package:sixpos/data/models/agenda_imposto_renda.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class AgendaImpostoRendaWebFields extends StatefulWidget {
  const AgendaImpostoRendaWebFields({
    super.key,
    required this.draft,
    required this.onChanged,
    this.enabled = true,
    this.picker,
  });
  final AgendaImpostoRenda draft;
  final VoidCallback onChanged;
  final bool enabled;
  final AgendaComprovantePicker? picker;
  @override
  State<AgendaImpostoRendaWebFields> createState() =>
      _AgendaImpostoRendaWebFieldsState();
}

class _AgendaImpostoRendaWebFieldsState
    extends State<AgendaImpostoRendaWebFields> {
  Future<void> _anexar({bool camera = false}) async {
    final draft = widget.draft;
    if (!widget.enabled || draft.carregando || draft.comprovantes.length >= 3)
      return;
    draft.carregando = true;
    widget.onChanged();
    try {
      final arquivo = await (widget.picker ?? AgendaComprovantePicker())
          .selecionar(camera: camera);
      if (mounted && arquivo != null) draft.comprovantes.add(arquivo);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t('ir.fileError'))));
    } finally {
      draft.carregando = false;
      if (mounted) widget.onChanged();
    }
  }

  Future<void> _visualizar(AgendaComprovanteIr arquivo) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 900,
          height: 650,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.memory(
                    arquivo.bytes,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final ativo = widget.enabled && !draft.carregando;
    return Container(
      key: const ValueKey('ir-fields'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile.adaptive(
            key: const ValueKey('ir-mark'),
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('ir.title')),
            subtitle: Text(context.t('ir.hint')),
            value: draft.marcado,
            onChanged: ativo
                ? (value) {
                    draft.marcado = value;
                    widget.onChanged();
                  }
                : null,
          ),
          if (draft.marcado || draft.comprovantes.isNotEmpty) ...[
            Text(context.t('ir.limit')),
            for (final arquivo in draft.comprovantes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  arquivo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _visualizar(arquivo),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.t('ir.view'),
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => _visualizar(arquivo),
                    ),
                    IconButton(
                      tooltip: context.t('ir.remove'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: ativo
                          ? () {
                              draft.comprovantes.remove(arquivo);
                              widget.onChanged();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('ir-add'),
                  onPressed: ativo && draft.comprovantes.length < 3
                      ? () => _anexar()
                      : null,
                  icon: const Icon(Icons.attach_file),
                  label: Text(context.t('ir.add')),
                ),
              ],
            ),
            if (draft.carregando) const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
