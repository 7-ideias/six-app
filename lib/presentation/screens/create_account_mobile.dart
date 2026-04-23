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
  final RegistroOtpService _otpService = RegistroOtpService();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
        MaterialPageRoute(builder: (_) => const HomePageMobile(title: 'Home')),
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
    const fieldFill = Color(0xFFF1F3F2);
    const labelGrey = Color(0xFF8A8F8D);
    const textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
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
                      // ── Título ────────────────────────────────────────
                      const Text(
                        'Criar conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Preencha seus dados abaixo ou\ncadastre-se com sua conta social',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: labelGrey,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Nome ──────────────────────────────────────────
                      _LabeledField(
                        label: 'Nome',
                        hint: 'Seu primeiro nome',
                        controller: _nameCtrl,
                        fillColor: fieldFill,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),

                      // ── Sobrenome ─────────────────────────────────────
                      _LabeledField(
                        label: 'Sobrenome',
                        hint: 'Seu sobrenome',
                        controller: _surnameCtrl,
                        fillColor: fieldFill,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),

                      // ── Celular ───────────────────────────────────────
                      _LabeledField(
                        label: 'Celular',
                        hint: '(00) 00000-0000',
                        controller: _phoneCtrl,
                        fillColor: fieldFill,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      // ── E-mail ────────────────────────────────────────
                      _LabeledField(
                        label: 'E-mail',
                        hint: 'exemplo@email.com',
                        controller: _emailCtrl,
                        fillColor: fieldFill,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // ── Senha ─────────────────────────────────────────
                      _LabeledField(
                        label: 'Senha',
                        hint: 'Mínimo 8 caracteres',
                        controller: _passwordCtrl,
                        fillColor: fieldFill,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: labelGrey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Termos ────────────────────────────────────────
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
                                      color: textDark,
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

                      // ── Botão Cadastrar ───────────────────────────────
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  'Cadastrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Divider "Ou cadastre-se com" ──────────────────
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                                color: Color(0xFFE3E6E5), thickness: 1),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Ou cadastre-se com',
                              style: TextStyle(
                                color: labelGrey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                                color: Color(0xFFE3E6E5), thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Ícones sociais ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIconButton(
                            fillColor: fieldFill,
                            onPressed: _signUpWithApple,
                            child: const Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _SocialIconButton(
                            fillColor: fieldFill,
                            onPressed: _signUpWithGoogle,
                            child: const _GoogleGlyph(),
                          ),
                          const SizedBox(width: 14),
                          _SocialIconButton(
                            fillColor: fieldFill,
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

                      // ── Rodapé ────────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _goToLogin,
                          behavior: HitTestBehavior.opaque,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: labelGrey,
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

// ── Campo com rótulo acima ─────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Color fillColor;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.fillColor,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF8A8F8D), fontSize: 15),
            suffixIcon: suffix,
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: primary.withValues(alpha: 0.4), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botão circular social ──────────────────────────────────────────────────
class _SocialIconButton extends StatelessWidget {
  final Color fillColor;
  final VoidCallback onPressed;
  final Widget child;

  const _SocialIconButton({
    required this.fillColor,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ── Glyph simples representando o G do Google ──────────────────────────────
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
