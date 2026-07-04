import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_link_section.dart';
import 'package:sixpos/presentation/screens/cliente_usuario_cadastro_mobile_screen.dart';

class ClientesUsuarioMobileScreen extends StatefulWidget {
  const ClientesUsuarioMobileScreen({super.key, this.apiClient});

  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClientesUsuarioMobileScreen> createState() => _ClientesUsuarioMobileScreenState();
}

class _ClientesUsuarioMobileScreenState extends State<ClientesUsuarioMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  late final ClienteUsuarioApiClient _api;
  final TextEditingController _search = TextEditingController();
  final NumberFormat _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final NumberFormat _number = NumberFormat.decimalPattern('pt_BR');

  bool _loading = false;
  String? _erro;
  ClienteUsuarioListResponse? _response;
  String _filter = '';

  List<ClienteUsuario> get _clientes => _response?.clientes ?? const <ClienteUsuario>[];

  List<ClienteUsuario> get _items {
    final String term = _filter.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (term.isEmpty) return _clientes;

    return _clientes.where((ClienteUsuario cliente) {
      final String source = '${cliente.nome} ${cliente.documento} ${cliente.telefone} ${cliente.email} ${cliente.cidade} ${cliente.uf}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return source.contains(term);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final ClienteUsuarioListResponse data = await _api.listarClientesUsuario();
      if (!mounted) return;
      setState(() {
        _response = data;
        _loading = false;
      });
    } on ClienteUsuarioApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _message(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar a lista de clientes.';
      });
    }
  }

  String _message(int code) {
    switch (code) {
      case 400:
        return 'Dados inválidos ou empresa não informada.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Usuário sem vínculo com a empresa.';
      case 409:
        return 'Já existe cliente com documento ou e-mail informado.';
      default:
        return 'Erro ao carregar clientes (HTTP $code).';
    }
  }

  Future<void> _openForm({ClienteUsuario? cliente}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteUsuarioCadastroMobileScreen(cliente: cliente, apiClient: _api),
      ),
    );

    if (saved == true && mounted) {
      _reload();
    }
  }

  void _openAutoCadastro() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.link_outlined, color: _primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Auto cadastro',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Gere, copie ou compartilhe o link.',
                              style: TextStyle(color: _mutedTextColor, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const ClienteAutoCadastroLinkSection(
                    showAsCard: true,
                    actionsOnly: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        title: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(tooltip: 'Auto cadastro', onPressed: _loading ? null : _openAutoCadastro, icon: const Icon(Icons.link_outlined)),
          IconButton(tooltip: 'Atualizar', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(child: _body()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo cliente'),
      ),
    );
  }

  Widget _body() {
    if (_loading && _response == null) return const _MobileClientesLoading();

    if (_erro != null && _response == null) {
      return _errorState();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          _headerCard(),
          const SizedBox(height: 14),
          _summaryRow(),
          const SizedBox(height: 14),
          _searchBox(),
          if (_erro != null) ...<Widget>[const SizedBox(height: 12), _inlineError(_erro!)],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Clientes encontrados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Text(_number.format(_items.length), style: const TextStyle(fontWeight: FontWeight.w900, color: _primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty) _emptyState() else ..._items.map(_clientCard),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: <Color>[_primaryColor, Color(0xFF123B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x220B1F3A), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.16))),
            child: const Icon(Icons.groups_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Base de clientes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('Cadastre, edite e acompanhe relacionamento e fiado.', style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final int ativos = _clientes.where((ClienteUsuario cliente) => cliente.ativo).length;
    final int fiado = _clientes.where((ClienteUsuario cliente) => cliente.permiteCompraFiado).length;
    final double saldo = _clientes.fold<double>(0, (double total, ClienteUsuario cliente) => total + cliente.saldoFiado);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _summaryCard(Icons.groups_outlined, 'Clientes', _number.format(_clientes.length))),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(Icons.verified_user_outlined, 'Ativos', _number.format(ativos))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _summaryCard(Icons.request_quote_outlined, 'Fiado', _number.format(fiado))),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(Icons.receipt_long_outlined, 'Aberto', _money.format(saldo))),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: _primaryColor, size: 19),
          ),
          const SizedBox(height: 10),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _search.clear();
                    setState(() => _filter = '');
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Widget _clientCard(ClienteUsuario cliente) {
    final bool fiadoOk = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(_initials(cliente.nome), style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? 'Documento não informado' : cliente.documento}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
                  ],
                ),
              ),
              _status(cliente.ativo),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(Icons.phone_outlined, cliente.telefone.isEmpty ? 'Sem telefone' : cliente.telefone),
              _chip(Icons.mail_outline, cliente.email.isEmpty ? 'Sem e-mail' : cliente.email),
              _chip(Icons.location_on_outlined, _location(cliente)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fiadoOk ? Colors.green.withOpacity(0.08) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fiadoOk ? Colors.green.withOpacity(0.24) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.request_quote_outlined, color: fiadoOk ? Colors.green.shade700 : _mutedTextColor, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente.permiteCompraFiado ? 'Fiado: ${_money.format(cliente.limiteFiado)} • ${cliente.prazoPagamentoDias} dias' : 'Fiado não liberado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _history(cliente),
                  icon: const Icon(Icons.timeline_outlined, size: 18),
                  label: const Text('Histórico'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openForm(cliente: cliente),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _primaryColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _status(bool ativo) {
    final Color color = ativo ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(ativo ? 'Ativo' : 'Inativo', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.person_add_alt_1_rounded, color: _primaryColor),
          ),
          const SizedBox(height: 12),
          const Text('Nenhum cliente encontrado', style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Cadastre clientes para vender, atender e controlar fiado.', textAlign: TextAlign.center, style: TextStyle(color: _mutedTextColor)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 44, color: _primaryColor),
            const SizedBox(height: 12),
            Text(_erro ?? 'Não foi possível carregar os clientes.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.35)),
      child: Text(message),
    );
  }

  void _history(ClienteUsuario cliente) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(cliente.nome.isEmpty ? 'Cliente' : cliente.nome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              _historyRow('Telefone', cliente.telefone.isEmpty ? '-' : cliente.telefone),
              _historyRow('E-mail', cliente.email.isEmpty ? '-' : cliente.email),
              _historyRow('Endereço', _address(cliente)),
              _historyRow('Fiado', cliente.permiteCompraFiado ? _money.format(cliente.limiteFiado) : 'não liberado'),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(bottomSheetContext).pop(), child: const Text('Fechar'))),
            ],
          ),
        );
      },
    );
  }

  Widget _historyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 86, child: Text(label, style: const TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  String _location(ClienteUsuario cliente) {
    if (cliente.cidade.isEmpty && cliente.uf.isEmpty) return 'Sem cidade';
    if (cliente.uf.isEmpty) return cliente.cidade;
    if (cliente.cidade.isEmpty) return cliente.uf;
    return '${cliente.cidade}/${cliente.uf}';
  }

  String _address(ClienteUsuario cliente) {
    final String value = <String>[cliente.logradouro, cliente.numero, cliente.bairro, cliente.cidade, cliente.uf, cliente.cep]
        .where((String item) => item.trim().isNotEmpty)
        .join(', ');
    return value.isEmpty ? 'Endereço não informado.' : value;
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) return 'CL';
    return parts.length == 1 ? parts.first[0].toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MobileClientesLoading extends StatelessWidget {
  const _MobileClientesLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List<Widget>.generate(
        5,
        (int index) => Container(
          height: index == 0 ? 118 : 132,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
        ),
      ),
    );
  }
}
