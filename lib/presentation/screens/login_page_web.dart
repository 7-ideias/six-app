import 'package:flutter/material.dart';

import '../../core/exceptions/google_auth_exception.dart';
import '../../core/services/auth_service.dart';
import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../domain/services/telainicial_web/tela_inicial_web_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../components/web_auth_shell.dart';
import '../components/web_google_sign_in_button.dart';
import 'create_account_web.dart';
import 'esqueceu_senha_web.dart';
import 'home_page_mobile_screen.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  State<LoginPageWeb> createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _listenGoogleSignIn();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _authService.cancelPendingWebGoogleLogin();
    super.dispose();
  }

  void _listenGoogleSignIn() {
    _authService.awaitWebGoogleLogin().then((_) async {
      if (!mounted) return;
      await _afterLoginBootstrap();
      if (!mounted) return;
      _navigateToHome();
    }).catchError((error) {
      if (!mounted) return;
      if (error is GoogleAuthException &&
          error.code == GoogleAuthErrorCode.cancelledByUser) {
        return;
      }
      final msg = error is GoogleAuthException
          ? error.message
          : 'Não foi possível concluir o login com Google.';
      _showSnack(msg);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _afterLoginBootstrap() async {
    await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

    try {
      final aparenciaService = AparenciaService(
        apiClient: HttpAparenciaApiClient(),
      );
      final config = await aparenciaService.buscarAparencia();
      SixThemeResolver().atualizarConfiguracao(config);
    } catch (e) {
      debugPrint('Erro ao carregar aparência no login: $e');
    }

    await TelaInicialWebService().atualizaProviders();
  }

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final senha = _passwordController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      _showSnack('Preencha o e-mail e a senha');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(login, senha);
      await _afterLoginBootstrap();
      if (!mounted) return;
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

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EsqueceuSenhaWeb()),
    );
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAccountWeb()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return WebAuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebAuthTitle(
            title: 'Entrar na sua conta',
            subtitle: 'Informe seu e-mail e senha para acessar o painel.',
          ),
          const SizedBox(height: 32),
          WebAuthTextField(
            controller: _loginController,
            hint: 'seu@email.com',
            label: 'E-mail',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          WebAuthTextField(
            controller: _passwordController,
            hint: 'Sua senha',
            label: 'Senha',
            prefixIcon: Icons.shield_outlined,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
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
          const SizedBox(height: 12),
          WebAuthPrimaryButton(
            label: 'Entrar',
            onPressed: _login,
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
                  'ou continue com',
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
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: _createAccount,
              behavior: HitTestBehavior.opaque,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: WebAuthShell.labelGrey(),
                  ),
                  children: [
                    const TextSpan(text: 'Ainda não tem uma conta? '),
                    TextSpan(
                      text: 'Criar conta',
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
