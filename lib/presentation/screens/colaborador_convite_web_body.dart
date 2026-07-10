import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/colaborador_convite_web_service.dart';
import '../../data/models/colaborador_convite_model.dart';

class ColaboradorConviteWebBody extends StatefulWidget {
  const ColaboradorConviteWebBody({super.key});

  @override
  State<ColaboradorConviteWebBody> createState() => _ColaboradorConviteWebBodyState();
}

class _ColaboradorConviteWebBodyState extends State<ColaboradorConviteWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController(text: '+55');

  bool _fazVenda = true;
  bool _lancaServico = true;
  bool _editaCliente = true;
  bool _acessaFinanceiro = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _isLoading = false;
  ColaboradorConviteResponse? _ultimoConvite;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  List<String> _permissoesSelecionadas() {
    return <String>[
      if (_fazVenda) 'VENDAS_CRIAR',
      if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
      if (_editaCliente) 'CLIENTES_EDITAR',
      if (_acessaFinanceiro) 'FINANCEIRO_ACESSAR',
      if (_geraRelatorio) 'RELATORIOS_GERAR',
      if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
    ];
  }

  String _linkConvite(ColaboradorConviteResponse convite) {
    final String base = Uri.base.origin;
    return '$base/colaborador/convites/${convite.codigo}';
  }

  Future<void> _criarConvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _ultimoConvite = null;
    });

    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        ColaboradorConviteRequest(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          celular: _celularController.text.trim(),
          permissoes: _permissoesSelecionadas(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ultimoConvite = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite de colaborador criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _ultimoConvite;
    if (convite == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _linkConvite(convite)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do convite copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
    );
  }

  Widget _switchCard(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.62), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ColaboradorConviteResponse? convite = _ultimoConvite;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Convidar colaborador',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'O colaborador recebe um vínculo com este comércio. A senha não é definida pelo ADMIN.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                SizedBox(
                  width: 360,
                  child: TextFormField(
                    controller: _nomeController,
                    decoration: _decoration('Nome do colaborador', Icons.person_outline),
                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: _decoration('E-mail de login', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? value) => value == null || value.trim().isEmpty ? 'Informe o e-mail.' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _celularController,
                    decoration: _decoration('Celular', Icons.phone_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Permissões iniciais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                SizedBox(width: 360, child: _switchCard('Vendas', 'Pode criar vendas.', _fazVenda, (bool v) => setState(() => _fazVenda = v))),
                SizedBox(width: 360, child: _switchCard('Assistência técnica', 'Pode lançar atendimentos técnicos.', _lancaServico, (bool v) => setState(() => _lancaServico = v))),
                SizedBox(width: 360, child: _switchCard('Clientes', 'Pode editar clientes.', _editaCliente, (bool v) => setState(() => _editaCliente = v))),
                SizedBox(width: 360, child: _switchCard('Financeiro', 'Pode acessar financeiro.', _acessaFinanceiro, (bool v) => setState(() => _acessaFinanceiro = v))),
                SizedBox(width: 360, child: _switchCard('Relatórios', 'Pode gerar relatórios.', _geraRelatorio, (bool v) => setState(() => _geraRelatorio = v))),
                SizedBox(width: 360, child: _switchCard('Permissões', 'Pode gerenciar permissões.', _gerenciaPermissoes, (bool v) => setState(() => _gerenciaPermissoes = v))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _isLoading ? null : _criarConvite,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(_isLoading ? 'Gerando convite...' : 'Gerar convite'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
            if (convite != null) ...<Widget>[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Convite criado', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 8),
                    SelectableText(_linkConvite(convite)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copiarLink,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar link'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
