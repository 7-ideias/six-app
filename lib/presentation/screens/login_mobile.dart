import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'home_page_mobile_screen.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  _LoginPageMobileState createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  TipoUsuario? _tipoSelecionado;

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
      MaterialPageRoute(builder: (context) =>
      const HomePageMobile(
          title: 'Flutter Demo Home Page')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: kIsWeb ? MediaQuery
                .of(context)
                .size
                .width * 0.25 : MediaQuery
                .of(context)
                .size
                .width * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlutterLogo(size: 80,
                    style: FlutterLogoStyle.markOnly,
                    textColor: theme.colorScheme.primary),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    hintText: 'login',
                    labelText: 'login',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
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
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Você é:", style: theme.textTheme.titleMedium),
                    RadioListTile<TipoUsuario>(
                      title: const Text('Administrador'),
                      value: TipoUsuario.administrador,
                      groupValue: _tipoSelecionado,
                      onChanged: (TipoUsuario? value) {
                        setState(() {
                          _tipoSelecionado = value;
                        });
                      },
                    ),
                    RadioListTile<TipoUsuario>(
                      title: const Text('Colaborador'),
                      value: TipoUsuario.colaborador,
                      groupValue: _tipoSelecionado,
                      onChanged: (TipoUsuario? value) {
                        setState(() {
                          _tipoSelecionado = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text("Esqueci minha senha",
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('entrar',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _createAccount,
                  child: Text("Criar nova conta",
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary)),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum TipoUsuario { administrador, colaborador }
