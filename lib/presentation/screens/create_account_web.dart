import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/exceptions/registro_otp_exception.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/registro_otp_service.dart';
import '../components/web_auth_shell.dart';
import '../components/web_google_sign_in_button.dart';
import 'home_page_mobile_screen.dart';
import 'verificar_email_web.dart';

class CreateAccountWeb extends StatefulWidget {
  const CreateAccountWeb({super.key});

  @override
  State<CreateAccountWeb> createState() => _CreateAccountWebState();
}

class _CreateAccountWebState extends State<CreateAccountWeb> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final RegistroOtpService _otpService = RegistroOtpService();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listenGoogleSignIn();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _authService.cancelPendingWebGoogleLogin();
    super.dispose();
  }

  void _listenGoogleSignIn() {
    _authService.awaitWebGoogleLogin().then((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePageMobile(title: 'Home')),
        (route) => false,
      );
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

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      _showSnack('Aceite os Termos e Condições para continuar');
      return;
    }

    final nome = _nameCtrl.text.trim();
    final sobrenome = _surnameCtrl.text.trim();
    final celular = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (nome.isEmpty ||
        sobrenome.isEmpty ||
        celular.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnack('Preencha todos os campos');
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
            nome: nome,
            sobrenome: sobrenome,
            celular: celular,
            email: email,
            senha: password,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebAuthTitle(
            title: 'Criar sua conta',
            subtitle:
                'Preencha seus dados abaixo ou cadastre-se com sua conta Google.',
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: WebAuthTextField(
                  controller: _nameCtrl,
                  hint: 'Primeiro nome',
                  label: 'Nome',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebAuthTextField(
                  controller: _surnameCtrl,
                  hint: 'Sobrenome',
                  label: 'Sobrenome',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WebAuthTextField(
            controller: _phoneCtrl,
            hint: '(00) 00000-0000',
            label: 'Celular',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          WebAuthTextField(
            controller: _emailCtrl,
            hint: 'seu@email.com',
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          WebAuthTextField(
            controller: _passwordCtrl,
            hint: 'Mínimo 8 caracteres',
            label: 'Senha',
            obscure: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
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
          const SizedBox(height: 18),
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
                      onChanged: (v) => setState(
                        () => _agreeTerms = v ?? false,
                      ),
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
            label: 'Cadastrar',
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
              onTap: () => Navigator.pop(context),
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
