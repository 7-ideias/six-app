import 'package:appplanilha/presentation/screens/produto_list_mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MeuCatalogoMobileScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MeuCatalogoMobileScreenState();
}

class _MeuCatalogoMobileScreenState extends State<MeuCatalogoMobileScreen> {
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
              buildPage(
                "Bem-vindo!",
                "Anuncie produtos e servicos.",
                "assets/images/placeholder.png",
              ),
              buildPage(
                "Cadastro Rápido",
                "Apenas marque os produtos.",
                "assets/images/placeholder.png",
              ),
              buildPage(
                "Compartilhe o link",
                "Mande para seus clientes e espere as vendas.",
                "assets/images/placeholder.png",
              ),
              buildPage(
                "Configure o contato",
                "Anuncie no instagram.",
                "assets/images/placeholder.png",
              ),
              buildPage(
                "Vamos começar?",
                "suas vendas decolando!",
                "assets/images/placeholder.png",
              ),
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
            child:
                isLastPage
                    ? ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasSeenOnboarding', true);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProdutolistMobileScreen(),
                          ),
                        );
                      },
                      child: Text("Começar"),
                    )
                    : TextButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
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
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
