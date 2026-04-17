import 'package:flutter/material.dart';

import '../../core/enums/tipo_usuario_enum.dart';
import '../../core/services/auth_service.dart';
import 'create_account_mobile.dart';
import 'esqueceu_senha_mobile.dart';
import 'home_page_mobile_screen.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Mantido padrão para preservar o fluxo de autenticação existente
  // sem expor o seletor no novo design.
  TipoUsuarioEnum? _tipoSelecionado = TipoUsuarioEnum.ADMINISTRADOR;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_tipoSelecionado == null) {
      _showSnack('Por favor, selecione se você é Administrador ou Colaborador');
      return;
    }

    final login = _loginController.text.trim();
    final senha = _passwordController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      _showSnack('Por favor, preencha o e-mail e a senha');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(login, senha);
      _navigateToHome();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePageMobile(title: 'Home')),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loginWithGoogle() {
    _showSnack('Login com Google (mocked)');
    _navigateToHome();
  }

  void _loginWithApple() {
    _showSnack('Login com Apple (mocked)');
    _navigateToHome();
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EsqueceuSenhaMobile()),
    );
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAccountMobile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const fieldFill = Color(0xFFF1F3F2);
    const labelGrey = Color(0xFF8A8F8D);
    const textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo ──────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Título ────────────────────────────────────────
                      const Text(
                        'Entrar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Para entrar em sua conta, informe\nseu e-mail e senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: labelGrey,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Campo E-mail ──────────────────────────────────
                      _InputField(
                        controller: _loginController,
                        hint: 'E-mail',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        fillColor: fieldFill,
                        iconColor: primary,
                      ),
                      const SizedBox(height: 12),

                      // ── Campo Senha ───────────────────────────────────
                      _InputField(
                        controller: _passwordController,
                        hint: 'Senha',
                        prefixIcon: Icons.shield_outlined,
                        obscure: _obscurePassword,
                        fillColor: fieldFill,
                        iconColor: primary,
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
                      const SizedBox(height: 16),

                      // ── Esqueceu a senha ──────────────────────────────
                      Center(
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Botão Continuar ───────────────────────────────
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withValues(alpha: 0.6),
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
                                  'Continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Divider com texto ─────────────────────────────
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE3E6E5), thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Ainda não tem uma conta?',
                              style: TextStyle(
                                color: labelGrey,
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

                      // ── Criar conta ───────────────────────────────────
                      _SecondaryButton(
                        label: 'Criar conta',
                        onPressed: _createAccount,
                        fillColor: fieldFill,
                      ),
                      const SizedBox(height: 12),

                      // ── Apple ─────────────────────────────────────────
                      _SecondaryButton(
                        label: 'Entrar com Apple',
                        onPressed: _loginWithApple,
                        fillColor: fieldFill,
                        leading: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Google ────────────────────────────────────────
                      _SecondaryButton(
                        label: 'Entrar com Google',
                        onPressed: _loginWithGoogle,
                        fillColor: fieldFill,
                        leading: const _GoogleGlyph(),
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // ── Disclaimer ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: labelGrey,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
                              ),
                              TextSpan(
                                text: 'Termos de Uso e Política de Privacidade',
                                style: const TextStyle(
                                  color: textDark,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
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
            );
          },
        ),
      ),
    );
  }
}

// ── Campo de texto estilizado ──────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final Color fillColor;
  final Color iconColor;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.fillColor,
    required this.iconColor,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A8F8D), fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
          borderSide: BorderSide(color: iconColor.withValues(alpha: 0.4), width: 1.2),
        ),
      ),
    );
  }
}

// ── Botão secundário (criar conta, apple, google) ──────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color fillColor;
  final Widget? leading;

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.fillColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fillColor,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
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
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
