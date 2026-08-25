import 'package:flutter/material.dart';

import '../../../design_system/themes/six_mobile_color_scheme.dart';

class SixMobileSelectionOption<T> {
  const SixMobileSelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData icon;
}

Future<T?> showSixMobileSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<SixMobileSelectionOption<T>> options,
  required T? selectedValue,
  required String emptyTitle,
  String? subtitle,
  String? searchHint,
  String? emptyMessage,
}) {
  final bool searchable = searchHint != null && options.length > 5;
  final double initialSize = searchable
      ? 0.82
      : options.length > 4
      ? 0.70
      : options.length > 2
      ? 0.62
      : 0.50;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.44),
    builder: (BuildContext context) {
      return _SixMobileSelectionSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
        selectedValue: selectedValue,
        searchHint: searchable ? searchHint : null,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
        initialSize: initialSize,
      );
    },
  );
}

class SixMobileSelectionField extends StatelessWidget {
  const SixMobileSelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint,
    this.helperText,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final String? hint;
  final String? helperText;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final String displayValue = (value ?? '').trim().isEmpty
        ? hint ?? ''
        : value!.trim();

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label. $displayValue',
      child: Material(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.iconSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: enabled ? colors.accent : colors.mutedText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? colors.titleText : colors.mutedText,
                          fontSize: 14,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((helperText ?? '').trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          helperText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 10.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SixMobileSelectionSheet<T> extends StatefulWidget {
  const _SixMobileSelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.emptyTitle,
    required this.initialSize,
    this.subtitle,
    this.searchHint,
    this.emptyMessage,
  });

  final String title;
  final String? subtitle;
  final List<SixMobileSelectionOption<T>> options;
  final T? selectedValue;
  final String? searchHint;
  final String emptyTitle;
  final String? emptyMessage;
  final double initialSize;

  @override
  State<_SixMobileSelectionSheet<T>> createState() =>
      _SixMobileSelectionSheetState<T>();
}

class _SixMobileSelectionSheetState<T>
    extends State<_SixMobileSelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SixMobileSelectionOption<T>> get _filteredOptions {
    final String normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return widget.options;
    return widget.options
        .where((SixMobileSelectionOption<T> option) {
          return option.title.toLowerCase().contains(normalized) ||
              (option.subtitle ?? '').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: DraggableScrollableSheet(
          initialChildSize: widget.initialSize,
          minChildSize: 0.44,
          maxChildSize: 0.92,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            final List<SixMobileSelectionOption<T>> options = _filteredOptions;
            return Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: colors.titleText,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if ((widget.subtitle ?? '')
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle!,
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  if (widget.searchHint != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (String value) {
                          setState(() => _query = value);
                        },
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).deleteButtonTooltip,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: colors.softSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                    ),
                  Divider(height: 1, color: colors.border),
                  Expanded(
                    child: options.isEmpty
                        ? _SelectionEmptyState(
                            title: widget.emptyTitle,
                            message: widget.emptyMessage,
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                            itemCount: options.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final SixMobileSelectionOption<T> option =
                                  options[index];
                              final bool selected =
                                  option.value == widget.selectedValue;
                              return _SelectionOptionTile(
                                title: option.title,
                                subtitle: option.subtitle,
                                icon: option.icon,
                                selected: selected,
                                onTap: () =>
                                    Navigator.of(context).pop(option.value),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectionOptionTile extends StatelessWidget {
  const _SelectionOptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? colors.accent.withValues(alpha: 0.52)
                    : colors.border,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.accent.withValues(alpha: 0.12)
                        : colors.iconSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? colors.accent : colors.mutedText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((subtitle ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? colors.accent : colors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionEmptyState extends StatelessWidget {
  const _SelectionEmptyState({required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 38, color: colors.mutedText),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
            if ((message ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
