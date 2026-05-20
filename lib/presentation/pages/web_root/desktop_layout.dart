import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/desktop_footer.dart';
import 'package:appplanilha/presentation/components/web_root/desktop_header.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/cta_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/features_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/hero_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/pricing_section.dart';
import 'package:flutter/material.dart';

// Layout para viewports >= 1024px (WebRootTokens.bpDesktopMin).
// Estrutura: header sticky + scroll vertical com hero / features / pricing /
// cta / footer. Cada section já cuida da sua tipografia e padding internos.
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
    super.key,
    this.onLogin,
    this.onSignup,
    this.onChoosePlan,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;
  final ValueChanged<String>? onChoosePlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebRootTokens.surface,
      body: Column(
        children: [
          DesktopHeader(
            onLogin: onLogin,
            onSignup: onSignup,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HeroSection(
                  isDesktop: true,
                  onStart: onSignup,
                  onWatch: () {},
                ),
                const RepaintBoundary(
                  child: FeaturesSection(isDesktop: true),
                ),
                RepaintBoundary(
                  child: PricingSection(
                    isDesktop: true,
                    onChoose: onChoosePlan,
                  ),
                ),
                CtaSection(isDesktop: true, onTalk: onSignup),
                const DesktopFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
