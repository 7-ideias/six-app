import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_button.dart';
import 'package:flutter/material.dart';

// Nav desktop: sticky 80px, items horizontais com pill ativo, login + CTA.
// Espelha o <WebNav> de Primitives.jsx.
class DesktopHeader extends StatefulWidget {
  const DesktopHeader({
    super.key,
    this.onLogin,
    this.onSignup,
    this.onNavTap,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;
  final ValueChanged<String>? onNavTap;

  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  String _active = 'home';

  static const _items = <_NavItem>[
    _NavItem('home', 'Início'),
    _NavItem('features', 'Recursos'),
    _NavItem('pricing', 'Planos'),
    _NavItem('about', 'Sobre'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: WebRootTokens.surface,
        border: Border(bottom: BorderSide(color: WebRootTokens.line)),
      ),
      // CSS spec: padding 0 56. O usuário aumentou pra 150 manualmente;
      // mantemos como tá pra respeitar o ajuste local.
      padding: const EdgeInsets.symmetric(horizontal: 150),
      child: Row(
        children: [
          _logo(),
          const SizedBox(width: 36),
          Expanded(
            child: Row(
              children: _items.map(_navButton).toList(),
            ),
          ),
          ResponsiveButton(
            label: 'Entrar',
            onPressed: widget.onLogin,
            variant: WebButtonVariant.ghost,
            size: WebButtonSize.sm,
          ),
          const SizedBox(width: 10),
          ResponsiveButton(
            label: 'Começar agora',
            onPressed: widget.onSignup,
            variant: WebButtonVariant.primary,
            size: WebButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    // Keep the header height at 80 but allow the image to paint larger
    // without creating unbounded constraints by giving a finite box
    return SizedBox(
      width: 160,
      height: 80,
      child: OverflowBox(
        maxWidth: 200,
        maxHeight: 140,
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'assets/images/six-logo-flecha.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _navButton(_NavItem item) {
    final isActive = _active == item.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _active = item.id);
          widget.onNavTap?.call(item.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0x140F2D3A)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.label,
            style: TextStyle(
              fontFamily: WebRootTokens.fontFamily,
              fontFamilyFallback: WebRootTokens.fontFamilyFallback,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? WebRootTokens.ink : WebRootTokens.fgMuted,
            ),
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
