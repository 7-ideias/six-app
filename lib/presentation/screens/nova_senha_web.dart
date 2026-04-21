import 'package:flutter/material.dart';

import '../../core/exceptions/recuperacao_senha_exception.dart';
import '../../core/services/recuperacao_senha_service.dart';
import '../components/web_auth_shell.dart';
import 'login_page_web.dart';

class NovaSenhaWeb extends StatefulWidget {
  final String email;
  final String codigo;

  const NovaSenhaWeb({super.key, required this.email, required this.codigo});

  @override
  State<NovaSenhaWeb> createState() => _NovaSenhaWebState();
}

class _NovaSenhaWebState extends State<NovaSenhaWeb> {
  final TextEditingController _senhaCtrl = TextEditingController();
  final TextEditingController _confirmarCtrl = TextEditingController();
  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _redefinir() async {
    final senha = _senhaCtrl.text.trim();
    final confirmar = _confirmarCtrl.text.trim();

    if (senha.isEmpty || confirmar.isEmpty) {
      _showSnack('Preencha todos os campos');
      return;
    }

    if (senha != confirmar) {
      _showSnack('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.redefinirSenha(
        email: widget.email,
        codigo: widget.codigo,
        novaSenha: senha,
      );
      if (!mounted) return;
      _showSnack('Senha redefinida com sucesso!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPageWeb()),
        (route) => false,
      );
    } on RecuperacaoSenhaException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível redefinir a senha. Tente novamente.');
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
            title: 'Nova senha',
            subtitle: 'Defina uma nova senha para acessar sua conta.',
          ),
          const SizedBox(height: 32),
          WebAuthTextField(
            controller: _senhaCtrl,
            hint: 'Digite sua nova senha',
            label: 'Nova senha',
            prefixIcon: Icons.shield_outlined,
            obscure: _obscureSenha,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              icon: Icon(
                _obscureSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: WebAuthShell.labelGrey(),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
            ),
          ),
          const SizedBox(height: 14),
          WebAuthTextField(
            controller: _confirmarCtrl,
            hint: 'Confirme sua nova senha',
            label: 'Confirmar senha',
            prefixIcon: Icons.shield_outlined,
            obscure: _obscureConfirmar,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _redefinir(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmar
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: WebAuthShell.labelGrey(),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirmar = !_obscureConfirmar),
            ),
          ),
          const SizedBox(height: 28),
          WebAuthPrimaryButton(
            label: 'Redefinir senha',
            onPressed: _redefinir,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
