import 'package:flutter/material.dart';

class CadastroClienteScreen extends StatefulWidget {
  @override
  _CadastroClienteScreenState createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfCnpjController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  void _salvarCadastro() {
    if (_formKey.currentState!.validate()) {
      // Salvar os dados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente cadastrado com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome Completo'),
                validator: (value) => value!.isEmpty ? 'Digite o nome' : null,
              ),
              TextFormField(
                controller: _cpfCnpjController,
                decoration: InputDecoration(labelText: 'CPF/CNPJ'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Digite o CPF/CNPJ' : null,
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Digite o telefone' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty || !value.contains('@') ? 'E-mail inválido' : null,
              ),
              TextFormField(
                controller: _enderecoController,
                decoration: InputDecoration(labelText: 'Endereço'),
                validator: (value) => value!.isEmpty ? 'Digite o endereço' : null,
              ),
              TextFormField(
                controller: _cidadeController,
                decoration: InputDecoration(labelText: 'Cidade'),
                validator: (value) => value!.isEmpty ? 'Digite a cidade' : null,
              ),
              TextFormField(
                controller: _estadoController,
                decoration: InputDecoration(labelText: 'Estado'),
                validator: (value) => value!.isEmpty ? 'Digite o estado' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarCadastro,
                child: Text('Salvar Cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
