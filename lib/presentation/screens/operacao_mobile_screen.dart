import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';
import '../components/escolha_card_grid.dart';
import 'cadastro_mobile_screen.dart';

class OperacaoMobileScreen extends StatefulWidget {
  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}

class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  List<OperacaoItem> _buildOperacoes(BuildContext context) =>
      [
        OperacaoItem(Icons.point_of_sale, 'Operações', Colors.green, () {
      // TODO: ação venda
        }, description: "vendas, os"),
        OperacaoItem(Icons.person_add, 'Cadastros', Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CadastroMobileScreen()),
          );
    }),
        OperacaoItem(
      Icons.request_page,
      'Financeiro',
      Colors.deepPurple,
      () {
        // TODO: ação contas a receber
      },
    ),
        OperacaoItem(Icons.person_add, 'outros', Colors.blueGrey, () {
      // TODO: ação cadastro
    }),
  ];

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O que deseja fazer?')),
      drawer: AppDrawerDoMobile(
        image: _image,
        onPickImage: _pickImage,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            OperacaoCardGrid(
              operationList: _buildOperacoes(context),
              cardHeight: 200,
            ),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 2),
    );
  }
}

