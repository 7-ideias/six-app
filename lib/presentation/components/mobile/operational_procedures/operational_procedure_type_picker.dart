import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';

class OperationalProcedureTypePicker extends StatelessWidget {
  const OperationalProcedureTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ProcedureResponseType selected;
  final ValueChanged<ProcedureResponseType> onSelected;

  static Future<ProcedureResponseType?> show(
    BuildContext context, {
    required ProcedureResponseType selected,
  }) {
    return showModalBottomSheet<ProcedureResponseType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => OperationalProcedureTypePicker(
            selected: selected,
            onSelected: (ProcedureResponseType type) {
              Navigator.of(context).pop(type);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ProcedureResponseTypeCategory> categories =
        ProcedureResponseTypeCategory.values;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: SixMobilePalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('procedimentos.itemType', fallback: 'Tipo de item'),
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'procedimentos.itemTypePickerHelp',
              fallback:
                  'Escolha como o colaborador vai responder ou registrar esta ação.',
            ),
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children:
                  categories.map((ProcedureResponseTypeCategory category) {
                    final List<ProcedureResponseTypeMetadata> options =
                        procedureResponseTypeMetadata
                            .where(
                              (ProcedureResponseTypeMetadata metadata) =>
                                  metadata.category == category,
                            )
                            .toList(growable: false);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        container: true,
                        label: responseTypeCategoryLabel(context, category),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              responseTypeCategoryLabel(context, category),
                              style: const TextStyle(
                                color: SixMobilePalette.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...options.map(
                              (ProcedureResponseTypeMetadata metadata) =>
                                  _TypeOption(
                                    metadata: metadata,
                                    selected: selected == metadata.type,
                                    onTap: () => onSelected(metadata.type),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.metadata,
    required this.selected,
    required this.onTap,
  });

  final ProcedureResponseTypeMetadata metadata;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = responseTypeLabel(context, metadata.type);
    final String description = responseTypeDescription(context, metadata.type);
    return Semantics(
      button: true,
      selected: selected,
      label: OperationalProcedureI18n.responseTypeSemantics(
        context,
        label: label,
        description: description,
        simulated: metadata.simulated,
      ),
      child: Material(
        color:
            selected
                ? SixMobilePalette.softAccentSurface
                : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.highlightedBorder
                        : SixMobilePalette.border,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(metadata.icon, color: SixMobilePalette.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            label,
                            style: const TextStyle(
                              color: SixMobilePalette.titleText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (metadata.simulated)
                            Text(
                              OperationalProcedureI18n.demonstration(context),
                              style: const TextStyle(
                                color: SixMobilePalette.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: SixMobilePalette.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
