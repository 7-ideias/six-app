import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_auth_mobile_kit.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import 'create_account_mobile.dart';
import 'login_mobile.dart';

class AuthEntryMobile extends StatelessWidget {
  const AuthEntryMobile({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()));
  }

  void _goToCreateAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateAccountMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SixoAppAuthMobileScaffold(
      title: context.t(
        'auth.mobileEntry.title',
        fallback: 'Seu negócio, conectado.',
      ),
      subtitle: context.t(
        'auth.mobileEntry.subtitle',
        fallback:
            'Vendas, estoque e gestão no mesmo ritmo — onde você estiver.',
      ),
      featureLabels: <String>[
        context.t('auth.mobileEntry.sales', fallback: 'Vendas'),
        context.t('auth.mobileEntry.stock', fallback: 'Estoque'),
        context.t('auth.mobileEntry.management', fallback: 'Gestão'),
      ],
      minimumSurfaceHeight: 250,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SixStaggeredEntry(
            child: Text(
              context.t(
                'auth.mobileEntry.continueTitle',
                fallback: 'Como deseja continuar?',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 70),
            child: SixoAppAuthPrimaryButton(
              label: context.t(
                'auth.mobileEntry.loginAction',
                fallback: 'Entrar na minha conta',
              ),
              icon: Icons.login_rounded,
              onPressed: () => _goToLogin(context),
            ),
          ),
          const SizedBox(height: 12),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 120),
            child: SixoAppAuthSecondaryButton(
              label: context.t(
                'auth.mobileEntry.createAction',
                fallback: 'Criar minha conta',
              ),
              leading: const Icon(
                Icons.add_business_rounded,
                color: SixMobilePalette.brandBlue,
                size: 20,
              ),
              onPressed: () => _goToCreateAccount(context),
            ),
          ),
          const SizedBox(height: 20),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 170),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.shield_outlined,
                  color: SixMobilePalette.brandBlue,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.t(
                      'auth.mobileEntry.securityNote',
                      fallback: 'Acesso seguro e dados sempre protegidos.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
