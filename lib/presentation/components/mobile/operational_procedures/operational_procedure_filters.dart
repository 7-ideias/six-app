import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class OperationalProcedureFilters extends StatelessWidget {
  const OperationalProcedureFilters({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  final OperationalProcedureFilter selectedFilter;
  final ValueChanged<OperationalProcedureFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.t(
        'procedimentos.filtersLabel',
        fallback: 'Filtros de procedimentos',
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _FilterButton(
            label: context.t('procedimentos.filterAll', fallback: 'Todos'),
            selected: selectedFilter == OperationalProcedureFilter.all,
            onTap: () => onChanged(OperationalProcedureFilter.all),
          ),
          _FilterButton(
            label: context.t('procedimentos.filterActive', fallback: 'Ativos'),
            selected: selectedFilter == OperationalProcedureFilter.active,
            onTap: () => onChanged(OperationalProcedureFilter.active),
          ),
          _FilterButton(
            label: context.t(
              'procedimentos.filterInactive',
              fallback: 'Inativos',
            ),
            selected: selectedFilter == OperationalProcedureFilter.inactive,
            onTap: () => onChanged(OperationalProcedureFilter.inactive),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        selected
            ? SixMobilePalette.accent
            : SixMobilePalette.softNeutralSurface;
    final Color foregroundColor =
        selected ? SixMobilePalette.onPrimary : SixMobilePalette.titleText;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 40, minWidth: 64),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.accent
                        : SixMobilePalette.border,
              ),
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
