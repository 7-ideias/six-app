import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/navigation/mobile_navigation_controller.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/home_page_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimento_mobile_screen.dart';

class NavBarMobile extends StatelessWidget {
  const NavBarMobile({super.key, this.initialIndex = 1});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final MobileNavigationController? controller =
        MobileNavigationScope.maybeOf(context);
    final int selectedIndex = controller?.value ?? initialIndex;
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _NavItem(
              icon: Icons.manage_accounts_outlined,
              activeIcon: Icons.manage_accounts_rounded,
              label: context.t('mobile.nav.management', fallback: 'Gestão'),
              selected: selectedIndex == 0,
              onTap: () => _select(context, controller, 0),
            ),
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: context.t('mobile.nav.home', fallback: 'Início'),
              selected: selectedIndex == 1,
              onTap: () => _select(context, controller, 1),
            ),
            _NavItem(
              icon: Icons.support_agent_outlined,
              activeIcon: Icons.support_agent_rounded,
              label: context.t('mobile.nav.service', fallback: 'Atendimento'),
              selected: selectedIndex == 2,
              onTap: () => _select(context, controller, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _select(
    BuildContext context,
    MobileNavigationController? controller,
    int index,
  ) {
    if (controller != null) {
      controller.select(index);
      return;
    }

    if (index == initialIndex) return;

    final Widget page;
    switch (index) {
      case 0:
        page = const GestaoMobileScreen();
        break;
      case 1:
        page = const HomePageMobile(title: 'Início');
        break;
      case 2:
        page = const AtendimentoMobileScreen();
        break;
      default:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? colors.softAccentSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    selected ? activeIcon : icon,
                    size: 21,
                    color: selected ? colors.accent : colors.mutedText,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.titleText : colors.mutedText,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
