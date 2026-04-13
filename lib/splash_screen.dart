import 'dart:async';

import 'package:appplanilha/presentation/screens/login_mobile.dart';
import 'package:appplanilha/presentation/screens/login_page_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'design_system/themes/app_text_styles.dart';

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
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => kIsWeb ? LoginPageWeb() : LoginPageMobile()));
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
