import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/core/services/agenda_comprovante_picker.dart';
import 'package:sixpos/data/models/agenda_imposto_renda.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class AgendaImpostoRendaMobileFields extends StatefulWidget {
  const AgendaImpostoRendaMobileFields({
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
  State<AgendaImpostoRendaMobileFields> createState() =>
      _AgendaImpostoRendaMobileFieldsState();
}

class _AgendaImpostoRendaMobileFieldsState
    extends State<AgendaImpostoRendaMobileFields> {
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: Column(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      child: Image.memory(
                        arquivo.bytes,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sixMobileColors.surface,
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
            onChanged:
                ativo
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
                trailing: IconButton(
                  tooltip: context.t('ir.remove'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed:
                      ativo
                          ? () {
                            draft.comprovantes.remove(arquivo);
                            widget.onChanged();
                          }
                          : null,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('ir-add'),
                  onPressed:
                      ativo && draft.comprovantes.length < 3
                          ? () => _anexar()
                          : null,
                  icon: const Icon(Icons.attach_file),
                  label: Text(context.t('ir.add')),
                ),
                OutlinedButton.icon(
                  onPressed:
                      ativo && draft.comprovantes.length < 3
                          ? () => _anexar(camera: true)
                          : null,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.t('ir.camera')),
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
