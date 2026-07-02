import 'package:flutter/material.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/sub_painel_cadastro_cliente.dart';

typedef ClienteUsuarioSavedCallback = Future<void> Function(ClienteUsuario cliente);

void showClienteUsuarioCadastroWebDialog(
  BuildContext context, {
  ClienteUsuario? cliente,
  ClienteUsuarioApiClient? apiClient,
  ClienteUsuarioSavedCallback? onSaved,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SubPainelCadastroCliente(
      textoDaAppBar: cliente == null ? 'Cadastro de Clientes' : 'Edição de Clientes',
      body: _ClienteUsuarioCadastroWebBody(
        cliente: cliente,
        apiClient: apiClient,
        onSaved: onSaved,
      ),
    ),
  );
}

class _ClienteUsuarioCadastroWebBody extends StatefulWidget {
  const _ClienteUsuarioCadastroWebBody({this.cliente, this.apiClient, this.onSaved});

  final ClienteUsuario? cliente;
  final ClienteUsuarioApiClient? apiClient;
  final ClienteUsuarioSavedCallback? onSaved;

  @override
  State<_ClienteUsuarioCadastroWebBody> createState() => _ClienteUsuarioCadastroWebBodyState();
}

class _ClienteUsuarioCadastroWebBodyState extends State<_ClienteUsuarioCadastroWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ClienteUsuarioApiClient _api;
  late final TextEditingController _nome;
  late final TextEditingController _documento;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _cep;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
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
    _bairro = TextEditingController(text: c?.bairro ?? '');
    _cidade = TextEditingController(text: c?.cidade ?? '');
    _uf = TextEditingController(text: c?.uf ?? '');
    _limite = TextEditingController(text: (c?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','));
    _prazo = TextEditingController(text: '${c?.prazoPagamentoDias == 0 ? 30 : c?.prazoPagamentoDias ?? 30}');
    _observacoes = TextEditingController(text: c?.observacoes ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[_nome, _documento, _telefone, _email, _cep, _logradouro, _numero, _bairro, _cidade, _uf, _limite, _prazo, _observacoes]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _money(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '.').trim()) ?? 0;
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

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
        complemento: '',
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
      final ClienteUsuario saved = widget.cliente == null ? await _api.cadastrarClienteUsuario(request) : await _api.atualizarClienteUsuario(widget.cliente!.id, request);
      await widget.onSaved?.call(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente salvo com sucesso.'), behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o cliente.'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  Widget _field(TextEditingController c, String label, IconData icon, {String? Function(String?)? validator, int maxLines = 1}) => TextFormField(controller: c, maxLines: maxLines, readOnly: _saving, decoration: _dec(label, icon), validator: validator);

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: children),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(28)),
                child: const Text('Cadastro de cliente', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 20),
              _card('Identidade do cadastro', Icons.badge_outlined, <Widget>[
                SizedBox(width: 360, child: _field(_nome, 'Nome completo / Razão social', Icons.person_outline, validator: _required)),
                SizedBox(width: 240, child: _field(_documento, 'CPF/CNPJ', Icons.badge_outlined, validator: _required)),
                SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _tipoPessoa, isExpanded: true, decoration: _dec('Tipo pessoa', Icons.apartment_outlined), items: const <DropdownMenuItem<String>>[DropdownMenuItem<String>(value: 'PF', child: Text('PF')), DropdownMenuItem<String>(value: 'PJ', child: Text('PJ'))], onChanged: (String? value) => setState(() => _tipoPessoa = value ?? 'PF'))),
              ]),
              const SizedBox(height: 20),
              _card('Contato e relacionamento', Icons.phone_in_talk_outlined, <Widget>[
                SizedBox(width: 260, child: _field(_telefone, 'Telefone principal', Icons.phone_outlined, validator: _required)),
                SizedBox(width: 360, child: _field(_email, 'E-mail', Icons.email_outlined)),
                SizedBox(width: 280, child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Cliente ativo'), value: _ativo, onChanged: (bool value) => setState(() => _ativo = value))),
              ]),
              const SizedBox(height: 20),
              _card('Endereço', Icons.location_on_outlined, <Widget>[
                SizedBox(width: 180, child: _field(_cep, 'CEP', Icons.pin_drop_outlined, validator: _required)),
                SizedBox(width: 360, child: _field(_logradouro, 'Logradouro', Icons.home_outlined, validator: _required)),
                SizedBox(width: 160, child: _field(_numero, 'Número', Icons.format_list_numbered, validator: _required)),
                SizedBox(width: 260, child: _field(_bairro, 'Bairro', Icons.location_city_outlined, validator: _required)),
                SizedBox(width: 260, child: _field(_cidade, 'Cidade', Icons.location_city, validator: _required)),
                SizedBox(width: 120, child: _field(_uf, 'UF', Icons.map_outlined, validator: _required)),
              ]),
              const SizedBox(height: 20),
              _card('Financeiro e limite de crédito', Icons.account_balance_wallet_outlined, <Widget>[
                SizedBox(width: 240, child: _field(_limite, 'Limite de crédito', Icons.credit_score_outlined)),
                SizedBox(width: 220, child: _field(_prazo, 'Prazo pagamento', Icons.timelapse_outlined)),
                SizedBox(width: 300, child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Permite compra a prazo'), value: _permiteFiado, onChanged: (bool value) => setState(() => _permiteFiado = value))),
                SizedBox(width: 300, child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Bloqueado por inadimplência'), value: _bloqueadoFiado, onChanged: (bool value) => setState(() => _bloqueadoFiado = value))),
              ]),
              const SizedBox(height: 20),
              _card('Observações comerciais', Icons.notes_outlined, <Widget>[SizedBox(width: 720, child: _field(_observacoes, 'Observações', Icons.note_alt_outlined, maxLines: 4))]),
              const SizedBox(height: 24),
              Row(children: <Widget>[Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Salvando...' : 'Salvar cliente')))]),
            ]),
          ),
        ),
      ),
    );
  }
}
