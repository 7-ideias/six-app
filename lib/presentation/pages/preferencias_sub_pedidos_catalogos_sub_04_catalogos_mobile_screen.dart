import 'package:flutter/material.dart';

class CatalogosMobileScreen extends StatefulWidget {
  const CatalogosMobileScreen({Key? key}) : super(key: key);

  @override
  State<CatalogosMobileScreen> createState() => _CatalogosMobileScreenState();
}

class _CatalogosMobileScreenState extends State<CatalogosMobileScreen> {
  bool selecionarServicos = false;
  bool selecionarPecas = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogos"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Ao criar um pedido, você sempre selecionará do seu catálogo.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          SwitchListTile(
            title: const Text("Sempre selecionar serviços do catálogo"),
            value: selecionarServicos,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                selecionarServicos = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Sempre selecionar peças do catálogo"),
            value: selecionarPecas,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                selecionarPecas = value;
              });
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // salvar preferências de catálogo
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
