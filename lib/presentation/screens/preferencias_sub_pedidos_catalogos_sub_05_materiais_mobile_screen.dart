import 'package:flutter/material.dart';

class MateriaisMobileScreen extends StatefulWidget {
  const MateriaisMobileScreen({Key? key}) : super(key: key);

  @override
  State<MateriaisMobileScreen> createState() => _MateriaisMobileScreenState();
}

class _MateriaisMobileScreenState extends State<MateriaisMobileScreen> {
  String? _selecionado = 'Peças';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materiais, produtos ou peças"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Qual palavra descreve melhor o que você vende ou usa no seu negócio?',
              style: TextStyle(fontSize: 14),
            ),
          ),
          RadioListTile<String>(
            title: const Text('Materiais'),
            value: 'Materiais',
            groupValue: _selecionado,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                _selecionado = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Produtos'),
            value: 'Produtos',
            groupValue: _selecionado,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                _selecionado = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Peças'),
            value: 'Peças',
            groupValue: _selecionado,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                _selecionado = value;
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
              // salvar opção selecionada
            },
            child: const Text("salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
