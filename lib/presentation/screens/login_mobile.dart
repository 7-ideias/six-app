import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/enums/tipo_usuario_enum.dart';
import '../../core/services/auth_service.dart';
import 'home_page_mobile_screen.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  _LoginPageMobileState createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  TipoUsuarioEnum? _tipoSelecionado;

  bool _isLoading = false;

  Future<void> _login() async {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "Por favor, selecione se você é Administrador ou Colaborador")),
      );
      return;
    }

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
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "Por favor, selecione se você é Administrador ou Colaborador")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const HomePageMobile(title: 'Home')),
    );
  }

  void _loginWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login com Google (mocked)")),
    );
    _navigateToHome();
  }

  void _loginWithApple() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login com Apple (mocked)")),
    );
    _navigateToHome();
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recuperar senha (mocked)")),
    );
  }

  void _createAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Criar nova conta (mocked)")),
    );
  }

  Widget _buildUserTypeCard(BuildContext context, TipoUsuarioEnum tipo, String label, IconData icon) {
    final theme = Theme.of(context);
    final bool selected = _tipoSelecionado == tipo;
    final Color activeColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _tipoSelecionado = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.1) : theme.colorScheme.surface.withOpacity(0.5),
          border: Border.all(
              color: selected ? activeColor : theme.dividerColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? activeColor : theme.hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? activeColor : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: activeColor)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Para testar a claridade da imagem de fundo (0.0 = transparente, 1.0 = opaco)
    const double backgroundOpacity = 0.3;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Stack(
        children: [
          // Imagem de fundo que ocupa toda a tela
          Positioned.fill(
            child: Opacity(
              opacity: backgroundOpacity,
              child: Image.asset(
                'assets/images/moca-tela-login.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Conteudo principal
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                width: kIsWeb
                    ? MediaQuery.of(context).size.width * 0.35
                    : MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Icon(Icons.lock_person_rounded, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      "Bem-vindo",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        hintText: 'Login',
                        labelText: 'Login',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Senha',
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Você é:", style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: 12),
                    _buildUserTypeCard(
                      context,
                      TipoUsuarioEnum.ADMINISTRADOR,
                      "Administrador",
                      Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildUserTypeCard(
                      context,
                      TipoUsuarioEnum.COLABORADOR,
                      "Colaborador",
                      Icons.groups_outlined,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          "Esqueci minha senha",
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _createAccount,
                      child: Text(
                        "Criar nova conta",
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loginWithGoogle,
                      icon: const Icon(Icons.account_circle, color: Colors.red),
                      label: const Text("Entrar com Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(45),
                        side: const BorderSide(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loginWithApple,
                      icon: const Icon(Icons.apple, color: Colors.white),
                      label: const Text("Entrar com Apple"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
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

