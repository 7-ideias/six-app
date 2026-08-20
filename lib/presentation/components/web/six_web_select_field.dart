import 'package:flutter/material.dart';

import '../../theme/web_theme_tokens.dart';

class SixWebSelectField extends StatefulWidget {
  const SixWebSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.icon,
    this.width,
    this.tooltip,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final IconData? icon;
  final double? width;
  final String? tooltip;
  final bool enabled;

  @override
  State<SixWebSelectField> createState() => _SixWebSelectFieldState();
}

class _SixWebSelectFieldState extends State<SixWebSelectField> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.items.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final RelativeRect position = RelativeRect.fromLTRB(
      fieldOffset.dx,
      fieldOffset.dy + fieldSize.height + 6,
      overlayBox.size.width - fieldOffset.dx - fieldSize.width,
      0,
    );

    setState(() => _open = true);
    final String? selected = await showMenu<String>(
      context: context,
      position: position,
      color: WebThemeTokens.of(context).menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: WebThemeTokens.of(context).cardBorder),
      ),
      items:
          widget.items.map((String item) {
            final bool selected = item == widget.value;
            final WebThemeTokens tokens = WebThemeTokens.of(context);
            final ThemeData theme = Theme.of(context);

            return PopupMenuItem<String>(
              value: item,
              height: 50,
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected ? tokens.info : tokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
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
                        active ? tokens.surfaceMuted : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? tokens.selectedBorder : tokens.cardBorder,
                      width: active ? 1.4 : 1,
                    ),
                    boxShadow:
                        active
                            ? <BoxShadow>[
                              BoxShadow(
                                color: tokens.info.withValues(alpha: 0.10),
                                blurRadius: 16,
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

    if (widget.width == null) {
      return field;
    }
    return SizedBox(width: widget.width, child: field);
  }
}
