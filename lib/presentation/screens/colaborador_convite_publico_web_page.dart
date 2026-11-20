import 'package:flutter/material.dart';
import '../../core/services/primeiro_acesso_convite.dart';
import '../components/convite_form_state.dart';
import '../theme/web_theme_tokens.dart';
import 'login_page_web.dart';

class ColaboradorConvitePublicoWebPage extends StatefulWidget {
  const ColaboradorConvitePublicoWebPage({super.key, required this.codigo});
  final String codigo;
  @override
  State<ColaboradorConvitePublicoWebPage> createState() => _ConviteWebState();
}

class _ConviteWebState extends State<ColaboradorConvitePublicoWebPage>
    with ConviteFormState<ColaboradorConvitePublicoWebPage> {
  @override
  String get codigo => widget.codigo;
  @override
  Future<bool> autenticar() async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginPageWeb(voltarAoConvite: true),
        ),
      ) ==
      true;
  @override
  void irParaLogin(String? email) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/login/flutter'),
      builder: (_) => LoginPageWeb(emailConvite: email),
    ),
  );
  @override
  void abrirEmpresa() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/app', (_) => false);

  @override
  Widget build(BuildContext context) {
    final cores = WebThemeTokens.of(context);
    return Scaffold(
      backgroundColor: cores.workspaceBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: cores.surfaceElevated,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texto('title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (fluxo.convite case final c?) ...[
                      const SizedBox(height: 12),
                      Text(c.nomeFantasia),
                      Text(c.emailConvidado),
                    ],
                    const SizedBox(height: 20),
                    if (fluxo.etapa == EtapaConvite.codigo) ...[
                      campoCodigo(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: fluxo.ocupado ? null : enviar,
                          child: Text(texto('resend')),
                        ),
                      ),
                    ],
                    if (fluxo.etapa == EtapaConvite.senha) ...[
                      campoSenha(senha, 'password'),
                      const SizedBox(height: 12),
                      campoSenha(repetir, 'repeat'),
                      alternarSenha(),
                    ],
                    if (fluxo.erro case final e?)
                      Text(texto(e), style: TextStyle(color: cores.danger)),
                    if (fluxo.ocupado) const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: fluxo.ocupado ? null : continuar,
                      child: Text(texto(acao)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
