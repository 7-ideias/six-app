import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Seletor de idioma para os headers web (desktop e mobile).
// Exibe ícone de globo + código do idioma atual + dropdown com 3 opções.
// Ao selecionar, chama LocaleSettingsProvider.setUserLocale() que propaga
// para MaterialApp.locale — o widget tree inteiro rebuilda no novo idioma.
class WebLanguageSwitcher extends StatefulWidget {
  const WebLanguageSwitcher({super.key});

  @override
  State<WebLanguageSwitcher> createState() => _WebLanguageSwitcherState();
}

class _WebLanguageSwitcherState extends State<WebLanguageSwitcher> {
  bool _open = false;
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;

  static const _options = <_LangOption>[
    _LangOption(locale: Locale('pt', 'BR'), label: 'PT'),
    _LangOption(locale: Locale('en', 'US'), label: 'EN'),
    _LangOption(locale: Locale('es', 'ES'), label: 'ES'),
  ];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  void _toggle() {
    if (_open) {
      _removeOverlay();
      return;
    }
    setState(() => _open = true);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
  }

  OverlayEntry _buildOverlay() {
    final localeProvider = context.read<LocaleSettingsProvider>();
    final isDark = SixThemeResolver().isDark;
    return OverlayEntry(
      builder: (_) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeOverlay,
          child: Stack(
            children: [
              Positioned(
                width: 100,
                child: CompositedTransformFollower(
                  link: _link,
                  offset: const Offset(0, 40),
                  showWhenUnlinked: false,
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? const Color(0xFF132538) : Colors.white,
                    shadowColor: const Color(0x290F2D3A),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _options.map((opt) {
                          final isSelected =
                              localeProvider.currentLocale.languageCode ==
                              opt.locale.languageCode;
                          return _DropdownItem(
                            option: opt,
                            selected: isSelected,
                            isDark: isDark,
                            onTap: () async {
                              await localeProvider.setUserLocale(opt.locale);
                              _removeOverlay();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    final localeProvider = context.watch<LocaleSettingsProvider>();
    final current = _options.firstWhere(
      (o) => o.locale.languageCode == localeProvider.currentLocale.languageCode,
      orElse: () => _options.first,
    );

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _open ? scheme.hoverBg : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de globo (sem bandeira)
                Icon(
                  Icons.language_rounded,
                  size: 16,
                  color: scheme.textPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  current.label,
                  style: TextStyle(
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: scheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangOption {
  const _LangOption({required this.locale, required this.label});
  final Locale locale;
  final String label;
}

class _DropdownItem extends StatefulWidget {
  const _DropdownItem({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final _LangOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? WebRootTokens.accent.withValues(alpha: 0.12)
        : (_hover
            ? (widget.isDark ? const Color(0xFF1E3040) : const Color(0xFFF5F5F5))
            : Colors.transparent);
    final textColor = widget.selected
        ? WebRootTokens.accent
        : (widget.isDark ? const Color(0xFFE8EEF3) : WebRootTokens.ink);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Globo pequeno por item
              Icon(
                Icons.language_rounded,
                size: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                widget.option.label,
                style: TextStyle(
                  fontFamily: WebRootTokens.fontFamily,
                  fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                  fontSize: 13,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (widget.selected)
                Icon(Icons.check_rounded, size: 14, color: WebRootTokens.accent),
            ],
          ),
        ),
      ),
    );
  }
}
