import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

import 'mock_cadastros_store.dart';

class SubPainelCadastroCliente extends SubPainelWebGeneral {
  const SubPainelCadastroCliente({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroCliente(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return SubPainelCadastroCliente(
        textoDaAppBar: textoDaAppBar,
        body: const CadastroClienteWebBody(),
      );
    },
  );
}

class CadastroClienteWebBody extends StatefulWidget {
  const CadastroClienteWebBody({super.key});

  @override
  State<CadastroClienteWebBody> createState() => _CadastroClienteWebBodyState();
}

class _CadastroClienteWebBodyState extends State<CadastroClienteWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  bool _autorizaContato = true;
  bool _aceitaWhatsapp = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _observacoesController.dispose();
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
                    Text(
                      subtitle,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
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

    final ClienteMock cliente = ClienteMock(
      id: MockCadastrosStore.proximoClienteId(),
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      email: _emailController.text.trim(),
      documento: _documentoController.text.trim(),
      observacoes: _observacoesController.text.trim(),
    );

    MockCadastrosStore.adicionarCliente(cliente);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cliente cadastrado'),
          content: Text('Cadastro mock salvo com sucesso para ${cliente.nome}.'),
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
                        child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Cadastro de cliente',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tela local para alimentar o fluxo de orçamento e ordem de serviço sem depender do backend.',
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
                            'Dados principais',
                            'Informações básicas para identificar e acionar o cliente.',
                            Icons.badge_outlined,
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: <Widget>[
                                SizedBox(
                                  width: 320,
                                  child: TextFormField(
                                    controller: _nomeController,
                                    decoration: _dec(context, 'Nome do cliente', Icons.person_outline),
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
                                    decoration: _dec(context, 'Telefone / WhatsApp', Icons.phone_outlined),
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
                            'Relacionamento e observações',
                            'Preferências de contato e notas relevantes para atendimento.',
                            Icons.chat_bubble_outline,
                            Column(
                              children: <Widget>[
                                TextFormField(
                                  controller: _observacoesController,
                                  maxLines: 4,
                                  decoration: _dec(context, 'Observações', Icons.note_alt_outlined),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 320,
                                      child: SwitchListTile(
                                        value: _autorizaContato,
                                        onChanged: (bool value) => setState(() => _autorizaContato = value),
                                        title: const Text('Autoriza contato automático'),
                                        subtitle: const Text('Preparar mensagens futuras de orçamento e OS.'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 320,
                                      child: SwitchListTile(
                                        value: _aceitaWhatsapp,
                                        onChanged: (bool value) => setState(() => _aceitaWhatsapp = value),
                                        title: const Text('Canal preferido: WhatsApp'),
                                        subtitle: const Text('Mantém o mock mais aderente ao seu fluxo principal.'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                        ),
                                      ),
                                    ),
                                  ],
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
                            ListTile(title: const Text('Documento'), subtitle: Text(_documentoController.text.trim().isEmpty ? '-' : _documentoController.text.trim())),
                            ListTile(title: const Text('Telefone'), subtitle: Text(_telefoneController.text.trim().isEmpty ? '-' : _telefoneController.text.trim())),
                            ListTile(title: const Text('Contato automático'), subtitle: Text(_autorizaContato ? 'Autorizado' : 'Não autorizado')),
                            ListTile(title: const Text('Canal preferido'), subtitle: Text(_aceitaWhatsapp ? 'WhatsApp' : 'Outro canal')),
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
                        'Esse cadastro já alimenta os seletores mockados do orçamento e da ordem de serviço.',
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
                            label: const Text('Salvar cliente'),
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
