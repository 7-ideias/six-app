import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/navigation/mobile_navigation_controller.dart';
import 'package:sixpos/presentation/screens/atendimento_mobile_screen.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/home_page_mobile_screen.dart';

class NavBarMobile extends StatelessWidget {
  const NavBarMobile({
    super.key,
    this.initialIndex = MobileNavigationController.dashIndex,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final MobileNavigationController? controller =
        MobileNavigationScope.maybeOf(context);
    final int selectedIndex = controller?.value ?? initialIndex;
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).scale(10) / 10;
    final double navigationHeight =
        66 + ((textScaleFactor.clamp(1.0, 1.4) - 1) * 18);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        height: navigationHeight,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border.withValues(alpha: 0.72)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow,
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _NavItem(
              assetPath: _NavBarAssets.inicio,
              label: context.t('mobile.nav.home'),
              selected: selectedIndex == MobileNavigationController.dashIndex,
              onTap: () => _select(
                context,
                controller,
                MobileNavigationController.dashIndex,
              ),
            ),
            _NavItem(
              assetPath: _NavBarAssets.atendimento,
              label: context.t('mobile.nav.service'),
              selected:
                  selectedIndex == MobileNavigationController.serviceIndex,
              onTap: () => _select(
                context,
                controller,
                MobileNavigationController.serviceIndex,
              ),
            ),
            _NavItem(
              assetPath: _NavBarAssets.gestao,
              label: context.t('mobile.nav.management'),
              selected:
                  selectedIndex == MobileNavigationController.managementIndex,
              onTap: () => _select(
                context,
                controller,
                MobileNavigationController.managementIndex,
              ),
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
      case MobileNavigationController.dashIndex:
        page = const HomePageMobile(title: 'dash');
        break;
      case MobileNavigationController.managementIndex:
        page = const GestaoMobileScreen();
        break;
      case MobileNavigationController.serviceIndex:
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
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    final Duration duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final Color foregroundColor = selected ? colors.accent : colors.mutedText;

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: selected ? 22 : 8,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedScale(
                    scale: selected ? 1.04 : 1,
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.softAccentSurface
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        assetPath,
                        width: 23,
                        height: 23,
                        colorFilter: ColorFilter.mode(
                          foregroundColor,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 10,
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

abstract final class _NavBarAssets {
  const _NavBarAssets._();

  static const String inicio = 'assets/images/navbar/nav-inicio.svg';
  static const String atendimento = 'assets/images/navbar/nav-atendimento.svg';
  static const String gestao = 'assets/images/navbar/nav-gestao.svg';
}
