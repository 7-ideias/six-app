import 'package:flutter/material.dart';

import '../../design_system/themes/six_mobile_palette.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/nav_bar_mobile.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'devolucoes_produtos_jornada.dart';

class DevolucoesProdutosMobileScreen extends StatelessWidget {
  const DevolucoesProdutosMobileScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: 'Devoluções',
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      bottomNavigationBar: const NavBarMobile(
        initialIndex: MobileNavigationController.returnsIndex,
      ),
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return DevolucoesProdutosJornada(
          web: false,
          scrollController: scrollController,
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 30),
        );
      },
    );
  }
}
