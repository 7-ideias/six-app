import 'dart:async';
import 'dart:io';

import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'design_system/components/circular progress bar/circular_progress_bar_web.dart';

class SubPainelCadastroProduto extends SubPainelWebGeneral {
  const SubPainelCadastroProduto({super.key, required super.body, required super.textoDaAppBar});
}

void showSubPainelCadastroProduto(BuildContext context, String textoDaAppBar) {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController precoController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController codigoBarrasController = TextEditingController();
  final TextEditingController fornecedorController = TextEditingController();
  final TextEditingController garantiaController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  String? categoriaSelecionada;
  File? imagemSelecionada;
  final List<String> categorias = ['Eletrônicos', 'Roupas', 'Acessórios', 'Alimentos', 'Outros'];

  Future<void> selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imagemSelecionada = File(pickedFile.path);
    }
  }

  void salvarProduto(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return circularProgressIndicator_web();
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sucesso!'),
            content: const Text('Produto salvo com sucesso!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  Widget widget = SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nomeController, decoration: customInputDecoration('Nome do Produto')),
          const SizedBox(height: 10),
          TextField(controller: descricaoController, decoration: customInputDecoration('Descrição')),
          const SizedBox(height: 10),
          TextField(controller: precoController, keyboardType: TextInputType.number, decoration: customInputDecoration('Preço')),
          const SizedBox(height: 10),
          TextField(controller: quantidadeController, keyboardType: TextInputType.number, decoration: customInputDecoration('Quantidade em Estoque')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: categoriaSelecionada,
            onChanged: (value) => categoriaSelecionada = value,
            items: categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            decoration: customInputDecoration('Categoria'),
          ),
          const SizedBox(height: 10),
          TextField(controller: codigoBarrasController, decoration: customInputDecoration('Código de Barras / SKU')),
          const SizedBox(height: 10),
          TextField(controller: fornecedorController, decoration: customInputDecoration('Fornecedor')),
          const SizedBox(height: 10),
          TextField(controller: garantiaController, decoration: customInputDecoration('Garantia')),
          const SizedBox(height: 10),
          TextField(controller: observacoesController, decoration: customInputDecoration('Observações')),
          const SizedBox(height: 10),
          imagemSelecionada != null
              ? Image.file(imagemSelecionada!, height: 100)
              : ElevatedButton.icon(onPressed: selecionarImagem, icon: const Icon(Icons.camera_alt), label: const Text('Selecionar Imagem')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => salvarProduto(context), child: const Text('Salvar Produto')),
        ],
      ),
    ),
  );

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SubPainelCadastroProduto(body: widget, textoDaAppBar: textoDaAppBar);
    },
  );
}

