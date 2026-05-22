import 'package:appplanilha/design_system/helpers/six_theme_resolver.dart';
import 'package:appplanilha/design_system/tokens/web_root_scheme.dart';
import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/l10n/web_root_l10n.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_button.dart';
import 'package:appplanilha/presentation/components/web_root/web_dark_toggle.dart';
import 'package:appplanilha/presentation/components/web_root/web_language_switcher.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Nav desktop sticky 96px:
//   [LOGO maior, esquerda]  ─ flex spacer ─  [NAV CENTRALIZADA com indicator]
//                                            ─ flex spacer ─  [Idioma | Dark | Entrar | CTA]
class DesktopHeader extends StatefulWidget {
  const DesktopHeader({
    super.key,
    this.onLogin,
    this.onSignup,
    this.onNavTap,
    this.activeId = 'home',
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;
  final ValueChanged<String>? onNavTap;
  final String activeId;

  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  late String _active = widget.activeId;

  @override
  void didUpdateWidget(covariant DesktopHeader old) {
    super.didUpdateWidget(old);
    if (widget.activeId != old.activeId) {
      setState(() => _active = widget.activeId);
    }
  }

  List<_NavItem> _navItems(WebRootL10n l10n) => [
    _NavItem('home', l10n.navHome),
    _NavItem('features', l10n.navFeatures),
    _NavItem('pricing', l10n.navPricing),
    _NavItem('about', l10n.navAbout),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    final items = _navItems(l10n);

    return Container(
      height: 96,
      color: scheme.headerBgDesktop,
      child: Row(
        children: [
          // Logo à esquerda — fora do flex/centering.
          _logo(),
          // Conteúdo centralizado (nav + buttons) com borda inferior.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.border),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  _CenteredNav(
                    items: items,
                    active: _active,
                    scheme: scheme,
                    onTap: (id) {
                      setState(() => _active = id);
                      widget.onNavTap?.call(id);
                    },
                  ),
                  const Expanded(child: SizedBox()),
                  const WebLanguageSwitcher(),
                  const SizedBox(width: 8),
                  const WebDarkToggle(),
                  const SizedBox(width: 16),
                  ResponsiveButton(
                    label: l10n.navLogin,
                    onPressed: widget.onLogin,
                    variant: WebButtonVariant.ghost,
                    size: WebButtonSize.sm,
                  ),
                  const SizedBox(width: 10),
                  ResponsiveButton(
                    label: l10n.navSignup,
                    onPressed: widget.onSignup,
                    variant: WebButtonVariant.primary,
                    size: WebButtonSize.sm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: SizedBox(
        width: 220,
        height: 96,
        child: OverflowBox(
          maxWidth: 280,
          maxHeight: 180,
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/six-logo-flecha.png',
            height: 150,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.id, this.label);
  final String id;
  final String label;
}

// Nav centralizada com indicador animado (pill + underline).
class _CenteredNav extends StatefulWidget {
  const _CenteredNav({
    required this.items,
    required this.active,
    required this.scheme,
    required this.onTap,
  });

  final List<_NavItem> items;
  final String active;
  final WebRootScheme scheme;
  final ValueChanged<String> onTap;

  @override
  State<_CenteredNav> createState() => _CenteredNavState();
}

class _CenteredNavState extends State<_CenteredNav> {
  final Map<String, GlobalKey> _keys = {};
  final Map<String, Rect> _rects = {};
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    for (final it in widget.items) {
      _keys[it.id] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _CenteredNav old) {
    super.didUpdateWidget(old);
    // Re-cria keys quando os itens mudam (ex: troca de idioma muda labels
    // mas não IDs, então a estrutura é a mesma — apenas re-mede).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    for (final entry in _keys.entries) {
      final itemBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;
      final offset = itemBox.localToGlobal(Offset.zero, ancestor: box);
      _rects[entry.key] = offset & itemBox.size;
    }
    if (mounted) setState(() => _measured = true);
  }

  @override
  Widget build(BuildContext context) {
    final activeRect = _rects[widget.active];

    return LayoutBuilder(
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

        return SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_measured && activeRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: activeRect.left,
                  top: activeRect.top,
                  width: activeRect.width,
                  height: activeRect.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.scheme.borderSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              if (_measured && activeRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: activeRect.left + 16,
                  top: activeRect.bottom + 2,
                  width: (activeRect.width - 32).clamp(0, double.infinity),
                  height: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: WebRootTokens.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final it in widget.items)
                    _NavButton(
                      key: _keys[it.id],
                      item: it,
                      active: widget.active == it.id,
                      scheme: widget.scheme,
                      onTap: () => widget.onTap(it.id),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    super.key,
    required this.item,
    required this.active,
    required this.scheme,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final WebRootScheme scheme;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? widget.scheme.textPrimary
        : (_hover ? widget.scheme.textPrimary : widget.scheme.textMuted);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          selected: widget.active,
          label: widget.item.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: WebRootTokens.fontFamily,
                  fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                  fontSize: 14,
                  fontWeight:
                      widget.active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                child: Text(widget.item.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
