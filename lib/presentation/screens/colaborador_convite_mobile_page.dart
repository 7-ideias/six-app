import 'package:flutter/material.dart';
import '../../core/services/primeiro_acesso_convite.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../components/convite_form_state.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import 'login_mobile.dart';
import 'post_login_splash_mobile_page.dart';

class ColaboradorConviteMobilePage extends StatefulWidget {
  const ColaboradorConviteMobilePage({super.key, required this.codigo});
  final String codigo;
  @override
  State<ColaboradorConviteMobilePage> createState() => _ConviteMobileState();
}

class _ConviteMobileState extends State<ColaboradorConviteMobilePage>
    with ConviteFormState<ColaboradorConviteMobilePage> {
  @override
  String get codigo => widget.codigo;
  @override
  Future<bool> autenticar() async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginPageMobile(voltarAoConvite: true),
        ),
      ) ==
      true;
  @override
  void irParaLogin(String? email) => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => LoginPageMobile(emailInicial: email),
    ),
    (_) => false,
  );
  @override
  void abrirEmpresa() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const PostLoginSplashMobilePage()),
    (_) => false,
  );

  @override
  Widget build(BuildContext context) {
    final cores = context.sixMobileColors;
    return SixMobilePageShell(
      title: texto('title'),
      backgroundColor: cores.background,
      primaryColor: cores.primary,
      secondaryColor: cores.secondary,
      accentColor: cores.accent,
      bodyBuilder:
          (context, scroll, inset) => ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(20, inset + 12, 20, 36),
            children: [
              if (fluxo.convite case final c?)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(c.nomeFantasia),
                  subtitle: Text(c.emailConvidado),
                ),
              if (fluxo.ocupado) const LinearProgressIndicator(),
              const SizedBox(height: 20),
              if (fluxo.etapa == EtapaConvite.codigo) ...[
                campoCodigo(),
                TextButton(
                  onPressed: fluxo.ocupado ? null : enviar,
                  child: Text(texto('resend')),
                ),
              ],
              if (fluxo.etapa == EtapaConvite.senha) ...[
                campoSenha(senha, 'password'),
                const SizedBox(height: 14),
                campoSenha(repetir, 'repeat'),
                alternarSenha(),
              ],
              if (fluxo.erro case final erro?)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    texto(erro),
                    style: TextStyle(color: cores.error),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: fluxo.ocupado ? null : continuar,
                child: Text(texto(acao)),
              ),
            ],
          ),
    );
  }
}
