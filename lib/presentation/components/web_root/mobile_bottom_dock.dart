import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/store_badge.dart';
import 'package:flutter/material.dart';

// .dock do CSS — aparece quando o usuário scrolla além da seção #baixar.
// O MobileLayout escuta o scroll e seta `visible=true` quando a área de
// stores do hero sai do viewport.
class MobileBottomDock extends StatelessWidget {
  const MobileBottomDock({
    super.key,
    required this.visible,
    this.onTap,
  });

  final bool visible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xF5FFFFFF), // 0.96
            border: Border(
              top: BorderSide(color: WebRootTokens.line),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            WebRootTokens.gutterMobile,
            10,
            WebRootTokens.gutterMobile,
            10 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: StoreBadge(store: AppStore.apple, onTap: onTap),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StoreBadge(store: AppStore.google, onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
