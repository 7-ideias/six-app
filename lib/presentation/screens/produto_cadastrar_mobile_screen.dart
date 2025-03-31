import 'package:flutter/material.dart';

class CadastroProdutoMobileScreen extends StatefulWidget {
  const CadastroProdutoMobileScreen({super.key});

  @override
  State<CadastroProdutoMobileScreen> createState() =>
      _CadastroProdutoMobileScreenState();
}

class _CadastroProdutoMobileScreenState
    extends State<CadastroProdutoMobileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _modeloController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _estoqueMinController = TextEditingController();
  final _estoqueMaxController = TextEditingController();
  final _skuController = TextEditingController();
  final _tamanhoController = TextEditingController();
  final _corController = TextEditingController();
  final _precoAgrupadoController = TextEditingController();

  String? _tipoSelecionado;
  bool _ativo = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    _modeloController.dispose();
    _precoVendaController.dispose();
    _estoqueMinController.dispose();
    _estoqueMaxController.dispose();
    _skuController.dispose();
    _tamanhoController.dispose();
    _corController.dispose();
    _precoAgrupadoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso!')),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator:
          requiredField
              ? (value) =>
                  (value == null || value.isEmpty) ? 'Campo obrigatório' : null
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Produto ou Serviço'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nomeController,
                    label: 'Nome do Produto',
                    requiredField: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _codigoController,
                    label: 'Código de Barras',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo do Produto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PRODUTO',
                        child: Text('Produto'),
                      ),
                      DropdownMenuItem(
                        value: 'SERVICO',
                        child: Text('Serviço'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => _tipoSelecionado = value),
                    validator:
                        (value) => value == null ? 'Selecione o tipo' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _modeloController,
                    label: 'Modelo do Produto',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _precoVendaController,
                    label: 'Preço de Venda',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _estoqueMinController,
                          label: 'Estoque Mínimo',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _estoqueMaxController,
                          label: 'Estoque Máximo',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Agrupamento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _skuController, label: 'SKU'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _tamanhoController,
                    label: 'Tamanho',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _corController, label: 'Cor'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _precoAgrupadoController,
                    label: 'Preço Agrupado',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: _ativo,
                    onChanged: (value) => setState(() => _ativo = value),
                    title: const Text('Ativo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
