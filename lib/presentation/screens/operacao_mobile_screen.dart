import 'dart:io';

import 'package:appplanilha/presentation/screens/pdv_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/produto_list_mobile_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';

class OperacaoMobileScreen extends StatefulWidget {
  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}


class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  bool showCadastrosStats = false;
  bool showOperacoesStats = false;

  Widget buildHeader(String title, IconData icon, VoidCallback onTap,
      {bool isExpandable = false, bool isExpanded = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: isExpandable
            ? Icon(isExpanded ? Icons.remove : Icons.add, color: Colors.black54)
            : const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }

  Widget buildOperacoesCard(String title, IconData icon, VoidCallback onTap,
      {bool isExpandable = false, bool isExpanded = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: isExpandable
            ? Icon(isExpanded ? Icons.remove : Icons.add, color: Colors.black54)
            : const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }

  Widget buildCadastrosCard(Color color, String label, int value,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 10,),
                  Text(
                    'mais info', style: const TextStyle(color: Colors.white),)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCadastrosSection() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: showCadastrosStats
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          buildCadastrosCard(Colors.teal, 'Produtos', 257, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProdutolistMobileScreen()),
            );
          }),
          buildCadastrosCard(Colors.amber, 'Colaboradores', 9, () {}),
          buildCadastrosCard(Colors.green, 'Clientes', 205, () {}),
          buildCadastrosCard(Colors.red, 'Fornecedores', 10, () {}),
          buildCadastrosCard(Colors.pink, 'Catálogo', 10, () {}),
        ],
      ),
    );
  }

  Widget buildOperacoesStatSection() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: showOperacoesStats
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          buildCadastrosCard(Colors.teal, 'Vendas', 257, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdvMobileScreen(),
              ),
            );
          }),
          buildCadastrosCard(Colors.amber, 'Os', 9, () {}),
        ],
      ),
    );
  }

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
      appBar: AppBar(title: Text('Operações')),
      drawer: AppDrawerDoMobile(
        image: _image,
        onPickImage: _pickImage,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // buildHeader('Perfil do Meu Negócio', Icons.newspaper, () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => SeguimentoSelecionarMobileScreen(),
            //     ),
            //   );
            // }),
            buildOperacoesCard(
              'Operações',
              Icons.bar_chart,
                  () {
                setState(() {
                  showOperacoesStats = !showOperacoesStats;
                  showOperacoesStats == true
                      ? showCadastrosStats = false
                      : null;
                });
              },
              isExpandable: true,
              isExpanded: showOperacoesStats,
            ),
            buildOperacoesStatSection(),
            buildHeader(
              'Cadastros',
              Icons.bar_chart,
                  () {
                setState(() {
                  showCadastrosStats = !showCadastrosStats;
                  showCadastrosStats == true
                      ? showOperacoesStats = false
                      : null;
                });
              },
              isExpandable: true,
              isExpanded: showCadastrosStats,
            ),
            buildCadastrosSection(),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 2),
    );
  }
}

