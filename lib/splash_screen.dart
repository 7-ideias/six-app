import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart'; // Garanta que este arquivo está no mesmo diretório

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Novo SIX App!', style: Theme.of(context).textTheme.headlineMedium),
            // Adicione aqui o seu logo ou outra imagem, se necessário
          ],
        ),
      ),
    );
  }
}
