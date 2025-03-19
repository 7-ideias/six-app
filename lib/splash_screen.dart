import 'package:flutter/material.dart';
import 'dart:async';
import 'design_system/themes/app_text_styles.dart';
import 'login_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
            Text(kIsWeb? 'versao WEB SIX App!' : 'versao mobile SIX App!', style: AppTextStyles.heading),
            // Adicione aqui o seu logo ou outra imagem, se necessário
          ],
        ),
      ),
    );
  }
}
