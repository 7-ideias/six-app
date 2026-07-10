import 'package:flutter/material.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_link_section.dart';

class ClienteUsuarioCadastroMobileScreen extends StatefulWidget {
  const ClienteUsuarioCadastroMobileScreen({super.key, this.cliente, this.apiClient});

  final ClienteUsuario? cliente;
  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClienteUsuarioCadastroMobileScreen> createState() => _ClienteUsuarioCadastroMobileScreenState();
}

class _ClienteUsuarioCadastroMobileScreenState extends State<ClienteUsuarioCadastroMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ClienteUsuarioApiClient _api;
  late final TextEditingController _nome;
  late final TextEditingController _documento;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _cep;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  late final TextEditingController _uf;
  late final TextEditingController _limite;
  late final TextEditingController _prazo;
  late final TextEditingController _observacoes;

  String _tipoPessoa = 'PF';
  bool _ativo = true;
  bool _permiteFiado = true;
  bool _bloqueadoFiado = false;
  bool _saving = false;

  bool get _editing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final ClienteUsuario? c = widget.cliente;
    _api = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _tipoPessoa = c?.tipoPessoa == 'PJ' ? 'PJ' : 'PF';
    _ativo = c?.ativo ?? true;
    _permiteFiado = c?.permiteCompraFiado ?? true;
    _bloqueadoFiado = c?.bloqueadoFiado ?? false;
    _nome = TextEditingController(text: c?.nome ?? '');
    _documento = TextEditingController(text: c?.documento ?? '');
    _telefone = TextEditingController(text: c?.telefone ?? '+55');
    _email = TextEditingController(text: c?.email ?? '');
    _cep = TextEditingController(text: c?.cep ?? '');
    _logradouro = TextEditingController(text: c?.logradouro ?? '');
    _numero = TextEditingController(text: c?.numero ?? '');
    _complemento = TextEditingController(text: c?.complemento ?? '');
    _bairro = TextEditingController(text: c?.bairro ?? '');
    _cidade = TextEditingController(text: c?.cidade ?? '');
    _uf = TextEditingController(text: c?.uf ?? '');
    _limite = TextEditingController(text: (c?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','));
    _prazo = TextEditingController(text: '${c?.prazoPagamentoDias == 0 ? 30 : c?.prazoPagamentoDias ?? 30}');
    _observacoes = TextEditingController(text: c?.observacoes ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _nome,
      _documento,
      _telefone,
      _email,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _uf,
      _limite,
      _prazo,
      _observacoes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  double _money(String value) {
    String raw = value.trim().replaceAll(' ', '');
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (raw.contains(',')) {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw) ?? 0;
  }

  InputDecoration _dec(String label, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label, icon),
      validator: validator,
    );
  }

  Widget _section({required String title, required String subtitle, required IconData icon, required Widget child}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.25)),
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

  Widget _switchCard({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? colorScheme.primary.withValues(alpha: 0.05) : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: value ? colorScheme.primary.withValues(alpha: 0.18) : colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.25)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: value, onChanged: _saving ? null : (bool newValue) => setState(() => onChanged(newValue))),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final ClienteUsuarioRequest request = ClienteUsuarioRequest(
        ativo: _ativo,
        tipoPessoa: _tipoPessoa,
        documento: _documento.text.trim(),
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        email: _email.text.trim(),
        cep: _cep.text.trim(),
        logradouro: _logradouro.text.trim(),
        numero: _numero.text.trim(),
        complemento: _complemento.text.trim(),
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        uf: _uf.text.trim().toUpperCase(),
        observacoes: _observacoes.text.trim(),
        foto: widget.cliente?.foto ?? '',
        permiteCompraFiado: _permiteFiado,
        limiteFiado: _permiteFiado ? _money(_limite.text) : 0,
        prazoPagamentoDias: _permiteFiado ? int.tryParse(_prazo.text.trim()) ?? 0 : 0,
        bloqueadoFiado: _permiteFiado && _bloqueadoFiado,
      );
      if (_editing) {
        await _api.atualizarClienteUsuario(widget.cliente!.id, request);
      } else {
        await _api.cadastrarClienteUsuario(request);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente salvo com sucesso.'), behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o cliente.'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildHeader() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colorScheme.primary, colorScheme.primary.withValues(alpha: 0.86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            child: Icon(_editing ? Icons.edit_outlined : Icons.person_add_alt_1_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_editing ? 'Editar cliente' : 'Novo cliente', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Cadastro rápido para vendas, assistência e compras a prazo.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Salvando...' : 'Salvar cliente'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(_editing ? 'Editar Cliente' : 'Cadastro de Clientes'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 16),
              _section(
                title: 'Dados principais',
                subtitle: 'Identifique o cliente para atendimento e relacionamento.',
                icon: Icons.badge_outlined,
                child: Column(
                  children: <Widget>[
                    _field(_nome, 'Nome completo / Razão social', Icons.person_outline, validator: _required),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _tipoPessoa,
                            isExpanded: true,
                            decoration: _dec('Tipo pessoa', Icons.apartment_outlined),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(value: 'PF', child: Text('PF')),
                              DropdownMenuItem<String>(value: 'PJ', child: Text('PJ')),
                            ],
                            onChanged: _saving ? null : (String? value) => setState(() => _tipoPessoa = value ?? 'PF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_documento, 'CPF/CNPJ', Icons.badge_outlined, validator: _required)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _switchCard(
                      title: 'Cliente ativo',
                      subtitle: 'Permite usar o cadastro em vendas e assistências.',
                      value: _ativo,
                      onChanged: (bool value) => _ativo = value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Contato',
                subtitle: 'Canais usados em orçamentos, ordens de serviço e cobrança.',
                icon: Icons.phone_in_talk_outlined,
                child: Column(
                  children: <Widget>[
                    _field(_telefone, 'Telefone principal', Icons.phone_outlined, validator: _required, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _field(_email, 'E-mail', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Endereço',
                subtitle: 'Informações para entrega, cobrança e emissão de documentos.',
                icon: Icons.location_on_outlined,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: _field(_cep, 'CEP', Icons.pin_drop_outlined, validator: _required, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_uf, 'UF', Icons.map_outlined, validator: _required)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field(_cidade, 'Cidade', Icons.location_city, validator: _required),
                    const SizedBox(height: 14),
                    _field(_logradouro, 'Logradouro', Icons.home_outlined, validator: _required),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(child: _field(_numero, 'Número', Icons.format_list_numbered, validator: _required)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_bairro, 'Bairro', Icons.location_city_outlined, validator: _required)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field(_complemento, 'Complemento', Icons.apartment_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Crédito / Fiado',
                subtitle: 'Parâmetros para compra a prazo e inadimplência.',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: _field(_limite, 'Limite de crédito', Icons.credit_score_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_prazo, 'Prazo pagamento', Icons.timelapse_outlined, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _switchCard(
                      title: 'Permite compra a prazo',
                      subtitle: 'Libera uso do limite de crédito em vendas futuras.',
                      value: _permiteFiado,
                      onChanged: (bool value) => _permiteFiado = value,
                    ),
                    const SizedBox(height: 12),
                    _switchCard(
                      title: 'Bloqueado por inadimplência',
                      subtitle: 'Impede novas compras até regularização.',
                      value: _bloqueadoFiado,
                      onChanged: (bool value) => _bloqueadoFiado = value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ClienteAutoCadastroLinkSection(initialTipoPessoa: _tipoPessoa, initialDocumento: _documento.text.trim()),
              const SizedBox(height: 16),
              _section(
                title: 'Observações',
                subtitle: 'Notas internas para atendimento e pós-venda.',
                icon: Icons.notes_outlined,
                child: _field(_observacoes, 'Observações', Icons.note_alt_outlined, maxLines: 4),
              ),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }
}
