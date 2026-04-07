import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

import 'mock_cadastros_store.dart';

class SubPainelCadastroColaborador extends SubPainelWebGeneral {
  const SubPainelCadastroColaborador({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroColaborador(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return SubPainelCadastroColaborador(
        textoDaAppBar: textoDaAppBar,
        body: const CadastroColaboradorWebBody(),
      );
    },
  );
}

class CadastroColaboradorWebBody extends StatefulWidget {
  const CadastroColaboradorWebBody({super.key});

  @override
  State<CadastroColaboradorWebBody> createState() => _CadastroColaboradorWebBodyState();
}

class _CadastroColaboradorWebBodyState extends State<CadastroColaboradorWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController(text: 'Técnico');
  String _perfilSelecionado = 'TÉCNICO';
  bool _ativo = true;

  static const List<String> _perfis = <String>['TÉCNICO', 'ATENDENTE', 'FINANCEIRO', 'ADMINISTRATIVO'];

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _card(BuildContext context, String title, String subtitle, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ColaboradorMock colaborador = ColaboradorMock(
      id: MockCadastrosStore.proximoColaboradorId(),
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      email: _emailController.text.trim(),
      documento: _documentoController.text.trim(),
      cargo: _cargoController.text.trim(),
      perfil: _perfilSelecionado,
      ativo: _ativo,
    );

    MockCadastrosStore.adicionarColaborador(colaborador);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Colaborador cadastrado'),
          content: Text('Cadastro mock salvo com sucesso para ${colaborador.nome}.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.86),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.group_add_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Cadastro de colaborador',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tela local para alimentar o técnico responsável e demais papéis operacionais do fluxo.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: <Widget>[
                          _card(
                            context,
                            'Dados do colaborador',
                            'Base para escolha de técnico, responsável comercial e equipe de apoio.',
                            Icons.person_pin_outlined,
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: <Widget>[
                                SizedBox(
                                  width: 320,
                                  child: TextFormField(
                                    controller: _nomeController,
                                    decoration: _dec(context, 'Nome completo', Icons.person_outline),
                                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 240,
                                  child: TextFormField(
                                    controller: _documentoController,
                                    decoration: _dec(context, 'CPF / Documento', Icons.badge_outlined),
                                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 250,
                                  child: TextFormField(
                                    controller: _telefoneController,
                                    decoration: _dec(context, 'Telefone', Icons.phone_outlined),
                                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 320,
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: _dec(context, 'E-mail', Icons.email_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            context,
                            'Papel operacional',
                            'Ajuda a diferenciar atendimento, técnico e apoio interno no mock do SixApp.',
                            Icons.engineering_outlined,
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: <Widget>[
                                SizedBox(
                                  width: 280,
                                  child: TextFormField(
                                    controller: _cargoController,
                                    decoration: _dec(context, 'Cargo', Icons.work_outline),
                                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 240,
                                  child: DropdownButtonFormField<String>(
                                    value: _perfilSelecionado,
                                    decoration: _dec(context, 'Perfil', Icons.security_outlined),
                                    items: _perfis
                                        .map((String item) => DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            ))
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() => _perfilSelecionado = value);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 320,
                                  child: SwitchListTile(
                                    value: _ativo,
                                    onChanged: (bool value) => setState(() => _ativo = value),
                                    title: const Text('Colaborador ativo'),
                                    subtitle: const Text('Disponível para ser escolhido nos fluxos da OS e do orçamento.'),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _card(
                        context,
                        'Resumo do cadastro',
                        'Conferência rápida antes de salvar.',
                        Icons.summarize_outlined,
                        Column(
                          children: <Widget>[
                            ListTile(title: const Text('Nome'), subtitle: Text(_nomeController.text.trim().isEmpty ? '-' : _nomeController.text.trim())),
                            ListTile(title: const Text('Cargo'), subtitle: Text(_cargoController.text.trim().isEmpty ? '-' : _cargoController.text.trim())),
                            ListTile(title: const Text('Perfil'), subtitle: Text(_perfilSelecionado)),
                            ListTile(title: const Text('Status'), subtitle: Text(_ativo ? 'Ativo' : 'Inativo')),
                            ListTile(title: const Text('Uso esperado'), subtitle: Text(_perfilSelecionado == 'TÉCNICO' ? 'Responsável por execução e reparo' : 'Apoio operacional / atendimento')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      const Text(
                        'Esse cadastro já alimenta o seletor de técnico responsável e o responsável comercial mockados.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Wrap(
                        spacing: 12,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Salvar colaborador'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
