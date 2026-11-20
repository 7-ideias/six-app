import 'package:flutter/material.dart';
import '../../core/services/primeiro_acesso_convite.dart';
import '../../l10n/convite_texts.dart';

/// Form interaction shared by the two platform layouts.
mixin ConviteFormState<T extends StatefulWidget> on State<T> {
  String get codigo;
  late final fluxo = PrimeiroAcessoConvite(codigo);
  final otp = TextEditingController();
  final senha = TextEditingController();
  final repetir = TextEditingController();
  bool mostrar = false;
  Future<bool> autenticar();
  void irParaLogin(String? email);
  void abrirEmpresa();

  @override
  void initState() {
    super.initState();
    fluxo.addListener(_mudou);
    fluxo.carregar();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    fluxo.removeListener(_mudou);
    fluxo.dispose();
    otp.dispose();
    senha.dispose();
    repetir.dispose();
    super.dispose();
  }

  String texto(String key) => conviteText(context, key);
  String get acao => switch (fluxo.etapa) {
    EtapaConvite.carregar => 'retry',
    EtapaConvite.enviar => 'send',
    EtapaConvite.codigo => 'confirm',
    EtapaConvite.senha => 'save',
    EtapaConvite.entrar => 'signIn',
    EtapaConvite.existente => 'accept',
    _ => 'login',
  };

  Future<void> enviar() async {
    await fluxo.enviar(Localizations.localeOf(context).languageCode);
    if (mounted && fluxo.erro == null) otp.clear();
  }

  Future<void> continuar() async {
    switch (fluxo.etapa) {
      case EtapaConvite.carregar:
        await fluxo.carregar();
      case EtapaConvite.enviar:
        await enviar();
      case EtapaConvite.codigo:
        await fluxo.verificar(otp.text);
        if (mounted && fluxo.erro == null) otp.clear();
      case EtapaConvite.senha:
        await fluxo.salvar(senha.text, repetir.text);
        if (mounted && fluxo.etapa == EtapaConvite.criado) {
          senha.clear();
          repetir.clear();
          irParaLogin(fluxo.email);
        }
      case EtapaConvite.existente:
      case EtapaConvite.entrar:
        if (fluxo.etapa == EtapaConvite.existente) await fluxo.aceitar();
        if (mounted &&
            fluxo.etapa == EtapaConvite.entrar &&
            await autenticar() &&
            mounted) {
          await fluxo.aceitar();
        }
        if (mounted && fluxo.etapa == EtapaConvite.aceito) abrirEmpresa();
      case EtapaConvite.criado:
        irParaLogin(fluxo.email);
      case EtapaConvite.aceito:
        abrirEmpresa();
    }
  }

  Widget campoCodigo() => TextField(
    controller: otp,
    enabled: !fluxo.ocupado,
    maxLength: 6,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    decoration: InputDecoration(labelText: texto('code')),
    onSubmitted: (_) => continuar(),
  );

  Widget campoSenha(TextEditingController campo, String label) => TextField(
    controller: campo,
    enabled: !fluxo.ocupado,
    obscureText: !mostrar,
    maxLength: 64,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: const [AutofillHints.newPassword],
    decoration: InputDecoration(labelText: texto(label), counterText: ''),
  );

  Widget alternarSenha() => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: mostrar,
    title: Text(texto('show')),
    onChanged: (v) => setState(() => mostrar = v == true),
  );
}
