import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/exceptions/registro_otp_exception.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/registro_otp_service.dart';
import 'home_page_mobile_screen.dart';
import 'verificar_email_mobile.dart';

class CreateAccountMobile extends StatefulWidget {
  const CreateAccountMobile({super.key});

  @override
  State<CreateAccountMobile> createState() => _CreateAccountMobileState();
}

class _CreateAccountMobileState extends State<CreateAccountMobile> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final RegistroOtpService _otpService = RegistroOtpService();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _passwordMismatchError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
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
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (nome.isEmpty ||
        sobrenome.isEmpty ||
        celular.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack('Preencha todos os campos');
      return;
    }

    if (password.length < 8) {
      _showSnack('A senha precisa ter ao menos 8 caracteres');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _passwordMismatchError = 'As senhas não coincidem.');
      _showSnack('As senhas informadas não são iguais. Verifique e tente novamente.');
      return;
    }

    setState(() => _passwordMismatchError = null);

    setState(() => _isLoading = true);
    try {
      await _otpService.enviarCodigo(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarEmailMobile(
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

  void _goToLogin() => Navigator.pop(context);

  void _signUpWithApple() => _showSnack('Cadastro com Apple (mocked)');

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.loginWithGoogle();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const HomePageMobile(title: 'Home')),
        (route) => false,
      );
    } on GoogleAuthException catch (e) {
      if (e.code == GoogleAuthErrorCode.cancelledByUser) return;
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Não foi possível concluir o cadastro com Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signUpWithFacebook() => _showSnack('Cadastro com Facebook (mocked)');

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: SixAuthTokens.colorShellBackground,
      appBar: AppBar(
        backgroundColor: SixAuthTokens.colorShellBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: SixAuthTokens.colorTextPrimary,
            size: 20,
          ),
          onPressed: _goToLogin,
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Título ──────────────────────────────────────────
                      const SixAuthTitle(
                        title: 'Criar conta',
                        subtitle:
                            'Preencha seus dados abaixo ou\ncadastre-se com sua conta social',
                      ),
                      const SizedBox(height: 28),

                      // ── Nome ────────────────────────────────────────────
                      SixAuthInput(
                        label: 'Nome',
                        hint: 'Seu primeiro nome',
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),

                      // ── Sobrenome ───────────────────────────────────────
                      SixAuthInput(
                        label: 'Sobrenome',
                        hint: 'Seu sobrenome',
                        controller: _surnameCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),

                      // ── Celular ─────────────────────────────────────────
                      SixAuthInput(
                        label: 'Celular',
                        hint: '(00) 00000-0000',
                        controller: _phoneCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      // ── E-mail ──────────────────────────────────────────
                      SixAuthInput(
                        label: 'E-mail',
                        hint: 'exemplo@email.com',
                        controller: _emailCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // ── Senha ───────────────────────────────────────────
                      SixAuthInput(
                        label: 'Senha',
                        hint: 'Mínimo 8 caracteres',
                        controller: _passwordCtrl,
                        obscure: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: SixAuthTokens.colorDividerText,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Confirmar senha ─────────────────────────────────
                      SixAuthInput(
                        label: 'Confirme a senha',
                        hint: 'Repita sua senha',
                        controller: _confirmPasswordCtrl,
                        obscure: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: SixAuthTokens.colorDividerText,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
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

                      // ── Termos ──────────────────────────────────────────
                      InkWell(
                        onTap: () =>
                            setState(() => _agreeTerms = !_agreeTerms),
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
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: SixAuthTokens.colorTextPrimary,
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'Concordo com os '),
                                      TextSpan(
                                        text: 'Termos e Condições',
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline,
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

                      // ── Botão Cadastrar ─────────────────────────────────
                      SixAuthPrimaryButton(
                        label: 'Cadastrar',
                        onPressed: _signUp,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ─────────────────────────────────────────
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: SixAuthTokens.colorDivider,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Ou cadastre-se com',
                              style: TextStyle(
                                color: SixAuthTokens.colorDividerText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: SixAuthTokens.colorDivider,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Ícones sociais ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIconButton(
                            onPressed: _signUpWithApple,
                            child: const Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _SocialIconButton(
                            onPressed: _signUpWithGoogle,
                            child: const _GoogleGlyph(),
                          ),
                          const SizedBox(width: 14),
                          _SocialIconButton(
                            onPressed: _signUpWithFacebook,
                            child: const Text(
                              'f',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1877F2),
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // ── Rodapé ──────────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _goToLogin,
                          behavior: HitTestBehavior.opaque,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: SixAuthTokens.colorDividerText,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Botão circular social ──────────────────────────────────────────────────

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SixAuthTokens.colorFieldFill,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: SixAuthTokens.colorFieldBorder),
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ── Google "G" glyph ────────────────────────────────────────────────────────

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
