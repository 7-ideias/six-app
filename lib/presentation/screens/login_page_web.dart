import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../domain/services/telainicial_web/tela_inicial_web_service.dart';
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

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String login = _loginController.text.trim();
    final String senha = _passwordController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha o login e a senha")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(login, senha);
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      
      // Busca configurações de aparência do backend
      try {
        final aparenciaService = AparenciaService(apiClient: HttpAparenciaApiClient());
        final config = await aparenciaService.buscarAparencia();
        SixThemeResolver().atualizarConfiguracao(config);
      } catch (e) {
        debugPrint('Erro ao carregar aparência no login: $e');
        // O fallback já é tratado dentro do buscarAparencia() do service
      }

      await TelaInicialWebService().atualizaProviders();
      _navigateToHome();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const HomePageMobile(title: 'Flutter Demo Home Page'),
      ),
    );
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fluxo de recuperação de senha ainda não implementado.'),
      ),
    );
  }

  void _onCreateNewUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fluxo de cadastro de novo usuário ainda não implementado.'),
      ),
    );
  }

  Widget _buildStoreBadge({
    required String assetPath,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          height: 42,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double formWidth = kIsWeb
        ? (screenSize.width * 0.28).clamp(320.0, 460.0)
        : (screenSize.width * 0.9).clamp(280.0, 420.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/images/web/atendente_login_web.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Bem-vindo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para continuar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        hintText: 'login',
                        labelText: 'login',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'senha',
                        labelText: 'senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _onForgotPassword,
                        child: const Text('Esqueci a senha'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text(
                          'entrar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '[202604022158] Novo por aqui?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: _onCreateNewUser,
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Divider(
                      color: Colors.grey.withValues(alpha: 0.25),
                      thickness: 1,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Baixe também nosso app',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Disponível para Android e iPhone',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStoreBadge(
                          assetPath: 'assets/images/stores/google_play_badge.png',
                          label: 'Google Play',
                          onTap: () {
                            // abrir link da Play Store
                          },
                        ),
                        _buildStoreBadge(
                          assetPath: 'assets/images/stores/app_store_badge.png',
                          label: 'App Store',
                          onTap: () {
                            // abrir link da App Store
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD7E0F5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF24479D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Versões para Android e iOS disponíveis nas lojas.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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