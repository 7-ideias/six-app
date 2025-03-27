import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'login_mobile.dart';
import 'login_page_web.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == 4);
            },
            children: [
              buildPage("Bem-vindo!", "Gerencie suas ordens de serviço com facilidade.", "assets/images/placeholder.png"),
              buildPage("Cadastro Rápido", "Entre em segundos e comece a trabalhar.", "assets/images/placeholder.png"),
              buildPage("Gestão Técnica", "Acompanhe seus serviços e notificações.", "assets/images/placeholder.png"),
              buildPage("Controle Financeiro", "Gerencie suas contas a pagar e a receber.", "assets/images/placeholder.png"),
              buildPage("Vamos começar?", "Seu negócio mais organizado e eficiente!", "assets/images/placeholder.png"),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 16,
            child: SmoothPageIndicator(
              controller: _controller,
              count: 5,
              effect: ExpandingDotsEffect(activeDotColor: Colors.blue),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 16,
            child: isLastPage
                ? ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenOnboarding', true);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => kIsWeb ? LoginPageWeb() : LoginPageMobile()),
                );
              },
              child: Text("Começar"),
            )
                : TextButton(
              onPressed: () {
                _controller.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
              },
              child: Text("Avançar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage(String title, String subtitle, String imagePath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: 250),
        SizedBox(height: 30),
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}
