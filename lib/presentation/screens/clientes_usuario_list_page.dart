import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_link_section.dart';
import 'package:sixpos/presentation/screens/cliente_usuario_cadastro_mobile_screen.dart';
import 'package:sixpos/presentation/screens/cliente_usuario_cadastro_web_dialog.dart';

class ClientesUsuarioListPage extends StatefulWidget {
  const ClientesUsuarioListPage({super.key, this.embedded = false, this.onBack, this.apiClient});

  final bool embedded;
  final VoidCallback? onBack;
  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClientesUsuarioListPage> createState() => _ClientesUsuarioListPageState();
}

class _ClientesUsuarioListPageState extends State<ClientesUsuarioListPage> {
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
    return _clientes.where((ClienteUsuario c) {
      final String source = '${c.nome} ${c.documento} ${c.telefone} ${c.email} ${c.cidade} ${c.uf}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  bool _useMobileForm(BuildContext context) => !widget.embedded && MediaQuery.of(context).size.width < 720;

  void _openForm({ClienteUsuario? cliente}) {
    if (_useMobileForm(context)) {
      Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ClienteUsuarioCadastroMobileScreen(cliente: cliente, apiClient: _api),
        ),
      ).then((bool? saved) {
        if (saved == true && mounted) {
          _reload();
        }
      });
      return;
    }

    showClienteUsuarioCadastroWebDialog(
      context,
      cliente: cliente,
      apiClient: _api,
      onSaved: (_) async => _reload(),
    );
  }

  void _openAutoCadastro() {
    showClienteAutoCadastroLinkDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(children: <Widget>[_header(), Expanded(child: _body())]);
    if (widget.embedded) return Material(color: Theme.of(context).colorScheme.surface, child: content);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: <Widget>[
          IconButton(onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: _loading ? null : _openAutoCadastro, icon: const Icon(Icons.link_outlined), tooltip: 'Auto cadastro'),
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

  Widget _header() {
    return SixWebDashboardHeader(
      icon: Icons.groups_2_outlined,
      title: 'Clientes',
      subtitle: 'Resumo da base de clientes, fiado, contatos e relacionamento comercial.',
      onBack: widget.onBack,
      actions: <Widget>[
        OutlinedButton.icon(onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
        OutlinedButton.icon(onPressed: _loading ? null : _openAutoCadastro, icon: const Icon(Icons.link_outlined), label: const Text('Auto cadastro')),
        FilledButton.icon(onPressed: _loading ? null : () => _openForm(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')),
      ],
    );
  }

  Widget _body() {
    if (_loading && _response == null) return const _LoadingClientes();
    if (_erro != null && _response == null) return _errorState();
    return RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(widget.embedded ? 24 : 16, widget.embedded ? 24 : 14, widget.embedded ? 24 : 16, widget.embedded ? 28 : 96),
          children: <Widget>[
            SixWebEntry(order: 0, child: _kpis(compact)),
            const SizedBox(height: 18),
            SixWebEntry(order: 4, child: _searchSection()),
            if (_erro != null) ...<Widget>[const SizedBox(height: 14), _inlineError(_erro!)],
            const SizedBox(height: 18),
            Row(children: <Widget>[
              Expanded(child: Text('Clientes encontrados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              Chip(label: Text('${_items.length}')),
            ]),
            const SizedBox(height: 12),
            if (_items.isEmpty) _empty() else ..._items.map(_card),
          ],
        );
      }),
    );
  }

  Widget _kpis(bool compact) {
    final int ativos = _clientes.where((ClienteUsuario c) => c.ativo).length;
    final int fiado = _clientes.where((ClienteUsuario c) => c.permiteCompraFiado).length;
    final double saldo = _clientes.fold<double>(0, (double total, ClienteUsuario c) => total + c.saldoFiado);
    final List<_Metric> metrics = <_Metric>[
      _Metric(Icons.groups_outlined, 'Clientes cadastrados', _clientes.length.toDouble(), (double v) => _number.format(v.round())),
      _Metric(Icons.verified_user_outlined, 'Clientes ativos', ativos.toDouble(), (double v) => _number.format(v.round())),
      _Metric(Icons.request_quote_outlined, 'Fiado liberado', fiado.toDouble(), (double v) => _number.format(v.round())),
      _Metric(Icons.receipt_long_outlined, 'Saldo aberto', saldo, _money.format, true),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 118),
      itemBuilder: (_, int index) {
        final _Metric m = metrics[index];
        return SixWebKpiCard(icon: m.icon, label: m.label, value: m.value, formatter: m.formatter, highlight: m.highlight);
      },
    );
  }

  Widget _searchSection() {
    return SixWebSectionCard(
      title: 'Busca e filtros',
      subtitle: 'Encontre rapidamente por nome, documento, telefone ou e-mail.',
      icon: Icons.search_rounded,
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: 'Buscar nome, documento, telefone ou e-mail...',
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _card(ClienteUsuario cliente) {
    final ThemeData theme = Theme.of(context);
    final bool fiadoOk = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SixWebEntry(
        order: 6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 760;
            final Widget data = Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.primary.withOpacity(0.10), child: Text(_initials(cliente.nome), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Text(cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  _status(cliente.ativo ? 'Ativo' : 'Inativo', cliente.ativo ? Colors.green.shade700 : theme.colorScheme.error),
                ]),
                const SizedBox(height: 4),
                Text('${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? 'Documento não informado' : cliente.documento}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  _info(Icons.phone_outlined, cliente.telefone.isEmpty ? 'Sem telefone' : cliente.telefone),
                  _info(Icons.mail_outline, cliente.email.isEmpty ? 'Sem e-mail' : cliente.email),
                  _info(Icons.location_on_outlined, _location(cliente)),
                ]),
                const SizedBox(height: 12),
                _credit(cliente, fiadoOk),
              ])),
            ]);
            final Widget buttons = compact
                ? Row(children: <Widget>[Expanded(child: _historyButton(cliente)), const SizedBox(width: 10), Expanded(child: _editButton(cliente))])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[_historyButton(cliente), const SizedBox(height: 10), _editButton(cliente)]);
            return compact
                ? Column(children: <Widget>[data, const SizedBox(height: 14), buttons])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: data), const SizedBox(width: 16), SizedBox(width: 210, child: buttons)]);
          }),
        ),
      ),
    );
  }

  Widget _historyButton(ClienteUsuario cliente) => OutlinedButton.icon(onPressed: () => _history(cliente), icon: const Icon(Icons.timeline_outlined, size: 18), label: const Text('Histórico'));
  Widget _editButton(ClienteUsuario cliente) => FilledButton.icon(onPressed: () => _openForm(cliente: cliente), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar'));

  Widget _credit(ClienteUsuario c, bool ok) {
    final ThemeData theme = Theme.of(context);
    final String text = c.permiteCompraFiado ? 'Fiado: limite ${_money.format(c.limiteFiado)} • prazo ${c.prazoPagamentoDias} dias' : 'Fiado não liberado para este cliente';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ok ? Colors.green.withOpacity(0.08) : theme.colorScheme.surfaceVariant.withOpacity(0.35), borderRadius: BorderRadius.circular(16), border: Border.all(color: ok ? Colors.green.withOpacity(0.25) : theme.colorScheme.outlineVariant)),
      child: Row(children: <Widget>[Icon(Icons.request_quote_outlined, color: ok ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)))]),
    );
  }

  Widget _status(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)));

  Widget _info(IconData icon, String label) => Chip(avatar: Icon(icon, size: 14), label: Text(label, overflow: TextOverflow.ellipsis), visualDensity: VisualDensity.compact);

  Widget _empty() => SixWebSectionCard(title: 'Nenhum cliente encontrado', subtitle: 'Cadastre clientes para registrar vendas, serviços e compras a prazo.', icon: Icons.person_add_alt_1_rounded, child: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')));

  Widget _errorState() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[const Icon(Icons.cloud_off_rounded, size: 44), const SizedBox(height: 12), Text(_erro ?? 'Não foi possível carregar os clientes.', textAlign: TextAlign.center), const SizedBox(height: 18), FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente'))])));

  Widget _inlineError(String message) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.35)), child: Text(message));

  void _history(ClienteUsuario cliente) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cliente.nome.isEmpty ? 'Cliente' : cliente.nome),
        content: Text('Telefone: ${cliente.telefone.isEmpty ? '-' : cliente.telefone}\nE-mail: ${cliente.email.isEmpty ? '-' : cliente.email}\nEndereço: ${_address(cliente)}\nFiado: ${cliente.permiteCompraFiado ? _money.format(cliente.limiteFiado) : 'não liberado'}'),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  String _location(ClienteUsuario c) => c.cidade.isEmpty && c.uf.isEmpty ? 'Sem cidade' : c.uf.isEmpty ? c.cidade : c.cidade.isEmpty ? c.uf : '${c.cidade}/${c.uf}';
  String _address(ClienteUsuario c) => <String>[c.logradouro, c.numero, c.bairro, c.cidade, c.uf, c.cep].where((String item) => item.trim().isNotEmpty).join(', ').isEmpty ? 'Endereço não informado.' : <String>[c.logradouro, c.numero, c.bairro, c.cidade, c.uf, c.cep].where((String item) => item.trim().isNotEmpty).join(', ');
  String _initials(String name) {
    final List<String> parts = name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) return 'CL';
    return parts.length == 1 ? parts.first[0].toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _LoadingClientes extends StatelessWidget {
  const _LoadingClientes();

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: const <Widget>[SixWebLoadingBlock(height: 118), SizedBox(height: 18), SixWebLoadingBlock(height: 124), SizedBox(height: 18), SixWebLoadingBlock(height: 172), SizedBox(height: 12), SixWebLoadingBlock(height: 172)]);
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, this.formatter, [this.highlight = false]);
  final IconData icon;
  final String label;
  final double value;
  final SixWebMetricFormatter formatter;
  final bool highlight;
}
