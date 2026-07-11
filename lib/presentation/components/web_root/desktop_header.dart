import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/responsive_button.dart';
import 'package:sixpos/presentation/components/web_root/web_dark_toggle.dart';
import 'package:sixpos/presentation/components/web_root/web_language_switcher.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Nav desktop sticky premium:
//   [brand discreta] ─ [fluxo superior] ─ [Idioma | Dark | Entrar | CTA]
// Mantém os mesmos destinos atuais: home / features / pricing / about.
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
    _NavItem('home', l10n.navHome, Icons.dashboard_customize_rounded),
    _NavItem('features', l10n.navFeatures, Icons.storefront_rounded),
    _NavItem('pricing', l10n.navPricing, Icons.workspace_premium_rounded),
    _NavItem('about', l10n.navAbout, Icons.forum_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    final items = _navItems(l10n);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 112,
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.isDark
                    ? const Color(0xE60A1624)
                    : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.78),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0B1F3A).withOpacity(scheme.isDark ? 0.22 : 0.08),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool narrow = constraints.maxWidth < 980;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 18 : 22,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        _BrandMark(scheme: scheme),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: _FlowNav(
                              items: items,
                              active: _active,
                              scheme: scheme,
                              compact: narrow,
                              onTap: (id) {
                                setState(() => _active = id);
                                widget.onNavTap?.call(id);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const WebLanguageSwitcher(),
                        const SizedBox(width: 8),
                        const WebDarkToggle(),
                        const SizedBox(width: 12),
                        if (!narrow) ...[
                          ResponsiveButton(
                            label: l10n.navLogin,
                            onPressed: widget.onLogin,
                            variant: WebButtonVariant.ghost,
                            size: WebButtonSize.sm,
                          ),
                          const SizedBox(width: 10),
                        ],
                        ResponsiveButton(
                          label: l10n.navSignup,
                          onPressed: widget.onSignup,
                          variant: WebButtonVariant.primary,
                          size: WebButtonSize.sm,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.scheme});

  final WebRootScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bool isDark = scheme.isDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF0B1F3A), Color(0xFF2563EB)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/six-logo-flecha.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Six',
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
                color: scheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CRM para operação técnica',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF8EA6BA) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _FlowNav extends StatefulWidget {
  const _FlowNav({
    required this.items,
    required this.active,
    required this.scheme,
    required this.compact,
    required this.onTap,
  });

  final List<_NavItem> items;
  final String active;
  final WebRootScheme scheme;
  final bool compact;
  final ValueChanged<String> onTap;

  @override
  State<_FlowNav> createState() => _FlowNavState();
}

class _FlowNavState extends State<_FlowNav> {
  final Map<String, bool> _hovering = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: widget.scheme.isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFF1F5F9).withOpacity(0.86),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.scheme.isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final item in widget.items)
              _FlowNavButton(
                item: item,
                active: widget.active == item.id,
                hovering: _hovering[item.id] ?? false,
                compact: widget.compact,
                scheme: widget.scheme,
                onEnter: () => setState(() => _hovering[item.id] = true),
                onExit: () => setState(() => _hovering[item.id] = false),
                onTap: () => widget.onTap(item.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowNavButton extends StatelessWidget {
  const _FlowNavButton({
    required this.item,
    required this.active,
    required this.hovering,
    required this.compact,
    required this.scheme,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final bool hovering;
  final bool compact;
  final WebRootScheme scheme;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = active
        ? Colors.white
        : (hovering ? scheme.textPrimary : scheme.textMuted);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: active,
          label: item.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 15,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF0B1F3A)
                  : (hovering
                      ? (scheme.isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.86))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0B1F3A).withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.icon, size: 16, color: foreground),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: WebRootTokens.fontFamily,
                      fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                      color: foreground,
                    ),
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
