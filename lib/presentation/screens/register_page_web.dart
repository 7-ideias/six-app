import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/exceptions/registro_otp_exception.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/registro_otp_service.dart';
import '../components/web_auth_shell.dart';
import '../components/web_google_sign_in_button.dart';
import 'verificar_email_web.dart';

/// Tela de cadastro mapeada para a rota `/register`.
///
/// Fluxo simplificado: apenas e-mail, confirmar e-mail e senha.
/// Outros dados (nome, telefone, etc.) são preenchidos depois.
///
/// Validação cliente: os dois e-mails precisam ser idênticos antes de
/// enviar a requisição — evita typo no único dado de contato do usuário.
///
/// "Voltar" usa `Navigator.pushReplacementNamed('/login')` para garantir
/// que a URL mude de /register → /login (sem empilhar).
class RegisterPageWeb extends StatefulWidget {
  const RegisterPageWeb({super.key});

  @override
  State<RegisterPageWeb> createState() => _RegisterPageWebState();
}

class _RegisterPageWebState extends State<RegisterPageWeb> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final RegistroOtpService _otpService = RegistroOtpService();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  // Erro inline mostrado abaixo do campo "Confirmar senha".
  String? _passwordMismatchError;

  @override
  void initState() {
    super.initState();
    _listenGoogleSignIn();
    // Re-valida em tempo real conforme o usuário digita.
    _passwordCtrl.addListener(_validatePasswordsMatch);
    _confirmPasswordCtrl.addListener(_validatePasswordsMatch);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _authService.cancelPendingWebGoogleLogin();
    super.dispose();
  }

  void _listenGoogleSignIn() {
    _authService.awaitWebGoogleLogin().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/app', (route) => false);
    }).catchError((error) {
      if (!mounted) return;
      if (error is GoogleAuthException &&
          error.code == GoogleAuthErrorCode.cancelledByUser) {
        return;
      }
      final msg = error is GoogleAuthException
          ? error.message
          : 'Não foi possível concluir o cadastro com Google.';
      _showSnack(msg);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _validatePasswordsMatch() {
    // Só mostra o erro quando o usuário começou a digitar a confirmação.
    if (_confirmPasswordCtrl.text.isEmpty) {
      if (_passwordMismatchError != null) {
        setState(() => _passwordMismatchError = null);
      }
      return;
    }
    final equal = _passwordCtrl.text == _confirmPasswordCtrl.text;
    final next = equal ? null : 'As senhas não coincidem.';
    if (next != _passwordMismatchError) {
      setState(() => _passwordMismatchError = next);
    }
  }

  /// Volta para /login usando named route (URL correta no browser).
  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      _showSnack('Aceite os Termos e Condições para continuar');
      return;
    }

    final email = _emailCtrl.text.trim();
    final senha = _passwordCtrl.text;
    final confirmSenha = _confirmPasswordCtrl.text;

    if (email.isEmpty || senha.isEmpty || confirmSenha.isEmpty) {
      _showSnack('Preencha e-mail, senha e confirmação de senha');
      return;
    }

    if (senha.length < 8) {
      _showSnack('A senha precisa ter ao menos 8 caracteres');
      return;
    }

    // Validação obrigatória: não dispara request se as senhas divergem.
    if (senha != confirmSenha) {
      setState(() => _passwordMismatchError = 'As senhas não coincidem.');
      _showSnack('As senhas informadas não são iguais. Verifique e tente novamente.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _otpService.enviarCodigo(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarEmailWeb(
            email: email,
            senha: senha,
          ),
        ),
      );
    } on RegistroOtpException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível enviar o código. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return WebAuthShell(
      showBack: true,
      onBack: _goToLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebAuthTitle(
            title: 'Crie sua conta Six',
            subtitle: 'Você terá sete dias de avaliação gratuita.',
          ),
          const SizedBox(height: 28),

          // ── E-mail ──────────────────────────────────────────────────────
          WebAuthTextField(
            controller: _emailCtrl,
            hint: 'seu@email.com',
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // ── Senha ───────────────────────────────────────────────────────
          WebAuthTextField(
            controller: _passwordCtrl,
            hint: 'Mínimo 8 caracteres',
            label: 'Senha',
            obscure: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: WebAuthShell.labelGrey(),
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Confirmar senha ─────────────────────────────────────────────
          WebAuthTextField(
            controller: _confirmPasswordCtrl,
            hint: 'Repita sua senha',
            label: 'Confirme a senha',
            obscure: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: WebAuthShell.labelGrey(),
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
          if (_passwordMismatchError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _passwordMismatchError!,
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ── Termos ──────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                      activeColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          color: WebAuthShell.textDark(),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Concordo com os '),
                          TextSpan(
                            text: 'Termos e Condições',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          WebAuthPrimaryButton(
            label: 'Criar conta',
            onPressed: _signUp,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Divider(color: Color(0xFFE3E6E5), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou cadastre-se com',
                  style: TextStyle(
                    color: WebAuthShell.labelGrey(),
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: Color(0xFFE3E6E5), thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const WebGoogleSignInButton(),
          const SizedBox(height: 24),

          Center(
            child: GestureDetector(
              onTap: _goToLogin,
              behavior: HitTestBehavior.opaque,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: WebAuthShell.labelGrey(),
                  ),
                  children: [
                    const TextSpan(text: 'Já tem uma conta? '),
                    TextSpan(
                      text: 'Entrar',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
