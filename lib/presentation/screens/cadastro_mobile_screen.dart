import 'dart:io';

import 'package:appplanilha/presentation/screens/produto_list_mobile_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_nav_bar.dart';
import '../components/escolha_card_grid.dart';

class CadastroMobileScreen extends StatefulWidget {
  @override
  State<CadastroMobileScreen> createState() => _CadastroMobileScreenState();
}

class _CadastroMobileScreenState extends State<CadastroMobileScreen> {
  List<OperacaoItem> _buildOperacoes(BuildContext context) => [
    OperacaoItem(Icons.point_of_sale, 'Colaboradores', Colors.green, () {
      // TODO: ação venda
    }, description: "vendas, os"),
    OperacaoItem(Icons.person_add, 'Fornecedores', Colors.green, () {
      // TODO: ação cadastro
    }),
    OperacaoItem(Icons.person_add, 'Produtos', Colors.green, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProdutolistMobileScreen()),
      );
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
      // drawer: AppDrawerDoMobile(
      //   image: _image,
      //   onPickImage: _pickImage,
      // ),
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
