import 'package:flutter/material.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

class SixWebMultiSelectOption {
  const SixWebMultiSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final String value;
  final String label;
  final String? subtitle;
}

class SixWebMultiSelectField extends StatefulWidget {
  const SixWebMultiSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.selectedValues,
    required this.allLabel,
    required this.searchHint,
    required this.emptyLabel,
    required this.onChanged,
    this.icon,
    this.width,
    this.tooltip,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<SixWebMultiSelectOption> options;
  final Set<String> selectedValues;
  final String allLabel;
  final String searchHint;
  final String emptyLabel;
  final ValueChanged<Set<String>> onChanged;
  final IconData? icon;
  final double? width;
  final String? tooltip;
  final bool enabled;

  @override
  State<SixWebMultiSelectField> createState() => _SixWebMultiSelectFieldState();
}

class _SixWebMultiSelectFieldState extends State<SixWebMultiSelectField> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled) return;

    final BuildContext? fieldContext = _fieldKey.currentContext;
    final RenderBox? fieldBox = fieldContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final double menuWidth =
        fieldBox.size.width < 360 ? 360 : fieldBox.size.width;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    setState(() => _open = true);
    final Set<String>? selected = await showMenu<Set<String>>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldBox.size.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldBox.size.width,
        0,
      ),
      color: dark ? tokens.surfaceElevated : tokens.menuBackground,
      elevation: 12,
      constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: <PopupMenuEntry<Set<String>>>[
        _SixWebMultiSelectMenuEntry(
          title: widget.label,
          options: widget.options,
          selectedValues: widget.selectedValues,
          allLabel: widget.allLabel,
          searchHint: widget.searchHint,
          emptyLabel: widget.emptyLabel,
        ),
      ],
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && !_sameValues(selected, widget.selectedValues)) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final bool active = widget.enabled && (_hovered || _open);

    final Widget field = Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: widget.value,
      child: AnimatedOpacity(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        opacity: widget.enabled ? 1 : 0.55,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            key: _fieldKey,
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.enabled ? _openMenu : null,
              child: Tooltip(
                message: widget.tooltip ?? '${widget.label}: ${widget.value}',
                waitDuration: const Duration(milliseconds: 450),
                child: AnimatedContainer(
                  duration: WebThemeTokens.transitionDuration,
                  curve: WebThemeTokens.transitionCurve,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                  decoration: BoxDecoration(
                    color:
                        active
                            ? (dark
                                ? tokens.surfaceElevated
                                : tokens.surfaceMuted)
                            : (dark
                                ? tokens.surfaceElevated.withValues(alpha: 0.92)
                                : tokens.inputBackground),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? tokens.selectedBorder : tokens.cardBorder,
                      width: active ? 1.4 : 1,
                    ),
                    boxShadow:
                        active
                            ? <BoxShadow>[
                              BoxShadow(
                                color: tokens.info.withValues(
                                  alpha: dark ? 0.14 : 0.10,
                                ),
                                blurRadius: dark ? 20 : 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: active ? tokens.info : tokens.secondaryText,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: tokens.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: WebThemeTokens.transitionDuration,
                        curve: WebThemeTokens.transitionCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: active ? tokens.info : tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.width == null) return field;
    return SizedBox(width: widget.width, child: field);
  }
}

class _SixWebMultiSelectMenuEntry extends PopupMenuEntry<Set<String>> {
  const _SixWebMultiSelectMenuEntry({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.allLabel,
    required this.searchHint,
    required this.emptyLabel,
  });

  final String title;
  final List<SixWebMultiSelectOption> options;
  final Set<String> selectedValues;
  final String allLabel;
  final String searchHint;
  final String emptyLabel;

  @override
  double get height => 500;

  @override
  bool represents(Set<String>? value) => false;

  @override
  State<_SixWebMultiSelectMenuEntry> createState() =>
      _SixWebMultiSelectMenuEntryState();
}

class _SixWebMultiSelectMenuEntryState
    extends State<_SixWebMultiSelectMenuEntry> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SixWebMultiSelectOption> get _filteredOptions {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where(
          (SixWebMultiSelectOption option) =>
              option.label.toLowerCase().contains(query) ||
              (option.subtitle ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void _toggle(String value) {
    setState(() {
      if (!_selection.remove(value)) {
        _selection.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<SixWebMultiSelectOption> options = _filteredOptions;
    final String selectionText =
        _selection.isEmpty
            ? widget.allLabel
            : _webSelectedCountLabel(context, _selection.length);

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.person_search_rounded, color: tokens.info, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.info.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selectionText,
                    style: TextStyle(
                      color: tokens.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              autofocus: widget.options.length > 8,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          tooltip:
                              MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                filled: true,
                fillColor: tokens.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tokens.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tokens.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SixWebMultiSelectTile(
              label: widget.allLabel,
              icon: Icons.groups_rounded,
              selected: _selection.isEmpty,
              onTap: () => setState(_selection.clear),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: tokens.cardBorder),
            const SizedBox(height: 6),
            Expanded(
              child:
                  options.isEmpty
                      ? Center(
                        child: Text(
                          widget.emptyLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.mutedText),
                        ),
                      )
                      : ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (BuildContext context, int index) {
                          final SixWebMultiSelectOption option = options[index];
                          return _SixWebMultiSelectTile(
                            label: option.label,
                            subtitle: option.subtitle,
                            icon: Icons.person_outline_rounded,
                            selected: _selection.contains(option.value),
                            onTap: () => _toggle(option.value),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.t('common.cancel')),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: Text(context.t('common.clear')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(Set<String>.from(_selection)),
                  child: Text(context.t('common.apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _webSelectedCountLabel(BuildContext context, int count) {
  final String language = Localizations.localeOf(context).languageCode;
  final String fallback = switch (language) {
    'en' => '$count selected',
    'es' => count == 1 ? '1 seleccionado' : '$count seleccionados',
    _ => count == 1 ? '1 selecionado' : '$count selecionados',
  };
  return context
      .t(
        count == 1 ? 'common.oneSelected' : 'common.selectedCount',
        fallback: fallback,
      )
      .replaceAll('{count}', count.toString());
}

class _SixWebMultiSelectTile extends StatelessWidget {
  const _SixWebMultiSelectTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: selected ? tokens.selectedBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tokens.selectedBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                size: 18,
                color: selected ? tokens.info : tokens.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? tokens.info : tokens.primaryText,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.mutedText, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameValues(Set<String> first, Set<String> second) {
  return first.length == second.length && first.containsAll(second);
}
