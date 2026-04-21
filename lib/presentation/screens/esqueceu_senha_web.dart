import 'package:flutter/material.dart';

import '../../core/exceptions/recuperacao_senha_exception.dart';
import '../../core/services/recuperacao_senha_service.dart';
import '../components/web_auth_shell.dart';
import 'verificar_codigo_recuperacao_web.dart';

class EsqueceuSenhaWeb extends StatefulWidget {
  const EsqueceuSenhaWeb({super.key});

  @override
  State<EsqueceuSenhaWeb> createState() => _EsqueceuSenhaWebState();
}

class _EsqueceuSenhaWebState extends State<EsqueceuSenhaWeb> {
  final TextEditingController _emailCtrl = TextEditingController();
  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enviarCodigo() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Informe seu e-mail');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.enviarCodigo(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCodigoRecuperacaoWeb(email: email),
        ),
      );
    } on RecuperacaoSenhaException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível enviar o código. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebAuthShell(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebAuthTitle(
            title: 'Esqueceu a senha?',
            subtitle:
                'Informe seu e-mail e enviaremos um código para redefinir sua senha.',
          ),
          const SizedBox(height: 32),
          WebAuthTextField(
            controller: _emailCtrl,
            hint: 'seu@email.com',
            label: 'E-mail',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _enviarCodigo(),
          ),
          const SizedBox(height: 28),
          WebAuthPrimaryButton(
            label: 'Enviar código de verificação',
            onPressed: _enviarCodigo,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
