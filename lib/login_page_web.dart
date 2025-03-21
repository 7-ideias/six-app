import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_page_mobile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  _LoginPageWebState createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _navigateToHome() {
    // if (_loginController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageMobile(title: 'Flutter Demo Home Page')));
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Login and Password must not be empty!")),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: kIsWeb ? MediaQuery.of(context).size.width * 0.25 : MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.login.toUpperCase(),
                    labelText: AppLocalizations.of(context)!.login.toUpperCase(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.senha.toUpperCase(),
                    labelText: AppLocalizations.of(context)!.senha.toUpperCase(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50), // makes the button taller
                  ),
                  child: Text(AppLocalizations.of(context)!.entrar.toUpperCase(), style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
