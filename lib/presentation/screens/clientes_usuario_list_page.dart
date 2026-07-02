import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';

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

  List<ClienteUsuario> get _all => _response?.clientes ?? const <ClienteUsuario>[];
  List<ClienteUsuario> get _items {
    final String term = _norm(_filter);
    if (term.isEmpty) return _all;
    return _all.where((ClienteUsuario cliente) => _norm('${cliente.nome} ${cliente.documento} ${cliente.telefone} ${cliente.email} ${cliente.cidade}').contains(term)).toList();
  }

  int get _ativos => _all.where((ClienteUsuario cliente) => cliente.ativo).length;
  int get _fiado => _all.where((ClienteUsuario cliente) => cliente.permiteCompraFiado).length;
  double get _saldo => _all.fold<double>(0, (double value, ClienteUsuario cliente) => value + cliente.saldoFiado);
  String _norm(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

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
        _erro = _msg(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar a lista de clientes.';
      });
    }
  }

  String _msg(int code) {
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

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(children: <Widget>[_header(), Expanded(child: _body())]),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: <Widget>[IconButton(tooltip: 'Atualizar', icon: const Icon(Icons.refresh_rounded), onPressed: _reload)],
      ),
      body: SafeArea(child: _body()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo cliente'),
      ),
    );
  }

  Widget _header() => SixWebDashboardHeader(
        icon: Icons.groups_2_outlined,
        title: 'Clientes',
        subtitle: 'Resumo da base de clientes, fiado, contatos e relacionamento comercial.',
        onBack: widget.onBack,
        actions: <Widget>[
          OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
          FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')),
        ],
      );

  Widget _body() {
    if (_loading && _response == null) return const _LoadingList();
    if (_erro != null && _response == null) return _errorState();

    return RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
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
              SixWebEntry(order: 5, child: _listTitle()),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                SixWebEntry(order: 6, child: _empty())
              else
                ..._items.asMap().entries.map((MapEntry<int, ClienteUsuario> entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SixWebEntry(order: 6 + entry.key.clamp(0, 8), child: _card(entry.value)),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _kpis(bool compact) {
    final List<_Metric> data = <_Metric>[
      _Metric(Icons.groups_outlined, 'Clientes cadastrados', _all.length.toDouble(), _whole),
      _Metric(Icons.verified_user_outlined, 'Clientes ativos', _ativos.toDouble(), _whole),
      _Metric(Icons.request_quote_outlined, 'Fiado liberado', _fiado.toDouble(), _whole),
      _Metric(Icons.receipt_long_outlined, 'Saldo aberto', _saldo, _currency, true),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 118),
      itemBuilder: (BuildContext context, int index) {
        final _Metric metric = data[index];
        return SixWebKpiCard(icon: metric.icon, label: metric.label, value: metric.value, formatter: metric.formatter, highlight: metric.highlight);
      },
    );
  }

  String _whole(double value) => _number.format(value.round());
  String _currency(double value) => _money.format(value);

  Widget _searchSection() => SixWebSectionCard(
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
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
        ),
      );

  Widget _listTitle() {
    final ThemeData theme = Theme.of(context);
    return Row(children: <Widget>[
      Expanded(child: Text('Clientes encontrados', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
        child: Text('${_items.length}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
      ),
    ]);
  }

  Widget _card(ClienteUsuario cliente) {
    final ThemeData theme = Theme.of(context);
    final bool ok = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _history(cliente),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;
              final Widget main = Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.primary.withOpacity(0.10), child: Text(_initials(cliente.nome), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(child: Text(cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                    const SizedBox(width: 8),
                    _status(cliente.ativo ? 'Ativo' : 'Inativo', cliente.ativo ? Colors.green.shade700 : theme.colorScheme.error),
                  ]),
                  const SizedBox(height: 4),
                  Text('${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? 'Documento não informado' : cliente.documento}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: <Widget>[_info(Icons.phone_outlined, cliente.telefone.isEmpty ? 'Sem telefone' : cliente.telefone), _info(Icons.mail_outline, cliente.email.isEmpty ? 'Sem e-mail' : cliente.email), _info(Icons.location_on_outlined, _location(cliente))]),
                  const SizedBox(height: 12),
                  _credit(cliente, ok),
                ])),
              ]);
              final Widget actions = _cardActions(cliente, compact);
              if (compact) {
                return Column(children: <Widget>[main, const SizedBox(height: 14), actions]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: main), const SizedBox(width: 16), SizedBox(width: 210, child: actions)]);
            },
          ),
        ),
      ),
    );
  }

  Widget _cardActions(ClienteUsuario cliente, bool compact) {
    final List<Widget> buttons = <Widget>[
      OutlinedButton.icon(onPressed: () => _history(cliente), icon: const Icon(Icons.timeline_outlined, size: 18), label: const Text('Histórico')),
      FilledButton.icon(onPressed: () => _form(cliente: cliente), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')),
    ];
    if (compact) {
      return Row(children: <Widget>[Expanded(child: buttons.first), const SizedBox(width: 10), Expanded(child: buttons.last)]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[buttons.first, const SizedBox(height: 10), buttons.last]);
  }

  Widget _credit(ClienteUsuario cliente, bool ok) {
    final ThemeData theme = Theme.of(context);
    final Color color = ok ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ok ? Colors.green.withOpacity(0.08) : theme.colorScheme.surfaceVariant.withOpacity(0.35), borderRadius: BorderRadius.circular(16), border: Border.all(color: ok ? Colors.green.withOpacity(0.25) : theme.colorScheme.outlineVariant)),
      child: Row(children: <Widget>[
        Icon(Icons.request_quote_outlined, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(cliente.permiteCompraFiado ? 'Fiado: limite ${_money.format(cliente.limiteFiado)} • prazo ${cliente.prazoPagamentoDias} dias' : 'Fiado não liberado para este cliente', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _status(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      );

  Widget _info(IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.45), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _empty() => SixWebSectionCard(
        title: 'Nenhum cliente encontrado',
        subtitle: 'Cadastre clientes para registrar vendas, serviços e compras a prazo.',
        icon: Icons.person_add_alt_1_rounded,
        child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente'))),
      );

  Widget _errorState() {
    final ThemeData theme = Theme.of(context);
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error, size: 44),
      const SizedBox(height: 12),
      Text('Não foi possível carregar os clientes.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(_erro ?? '', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
    ])));
  }

  Widget _inlineError(String message) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withOpacity(0.35), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.error.withOpacity(0.25))),
      child: Row(children: <Widget>[Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error), const SizedBox(width: 10), Expanded(child: Text(message))]),
    );
  }

  Future<void> _form({ClienteUsuario? cliente}) async {
    final ClienteUsuarioRequest? request = await showDialog<ClienteUsuarioRequest>(context: context, barrierDismissible: false, builder: (_) => _ClientForm(cliente: cliente));
    if (request == null) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      cliente == null ? await _api.cadastrarClienteUsuario(request) : await _api.atualizarClienteUsuario(cliente.id, request);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cliente == null ? 'Cliente cadastrado com sucesso.' : 'Cliente atualizado com sucesso.'), behavior: SnackBarBehavior.floating));
    } on ClienteUsuarioApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _msg(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível salvar o cliente.';
      });
    }
  }

  void _history(ClienteUsuario cliente) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (BuildContext context, ScrollController controller) => Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: <Widget>[
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 18),
              Text(cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(cliente.documento.isEmpty ? 'Documento não informado' : cliente.documento, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              _historyBox(Icons.phone_outlined, 'Telefone', cliente.telefone.isEmpty ? '-' : cliente.telefone),
              _historyBox(Icons.mail_outline, 'E-mail', cliente.email.isEmpty ? '-' : cliente.email),
              _historyBox(Icons.location_on_outlined, 'Endereço', _address(cliente)),
              _historyBox(Icons.request_quote_outlined, 'Fiado', cliente.permiteCompraFiado ? 'Liberado • saldo ${_money.format(cliente.saldoFiado)}' : 'Não liberado'),
              _historyBox(Icons.notes_outlined, 'Observações', cliente.observacoes.isEmpty ? 'Sem observações cadastradas.' : cliente.observacoes),
            ]),
          ),
        ),
      );

  Widget _historyBox(IconData icon, String title, String text) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35))]))]),
    );
  }

  String _location(ClienteUsuario cliente) => cliente.cidade.isEmpty && cliente.uf.isEmpty ? 'Sem cidade' : cliente.uf.isEmpty ? cliente.cidade : cliente.cidade.isEmpty ? cliente.uf : '${cliente.cidade}/${cliente.uf}';
  String _address(ClienteUsuario cliente) {
    final String value = <String>[cliente.logradouro, cliente.numero, cliente.bairro, cliente.cidade, cliente.uf, cliente.cep].where((String item) => item.trim().isNotEmpty).join(', ');
    return value.isEmpty ? 'Endereço não informado.' : value;
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(' ').where((String value) => value.isNotEmpty).toList();
    if (parts.isEmpty) return 'CL';
    return parts.length == 1 ? parts.first[0].toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ClientForm extends StatefulWidget {
  const _ClientForm({this.cliente});
  final ClienteUsuario? cliente;
  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  late final TextEditingController nome, doc, tel, email, cidade, uf, obs, limite, prazo;
  String tipo = 'PF';
  bool ativo = true, permiteFiado = false, bloqueadoFiado = false;

  @override
  void initState() {
    super.initState();
    final ClienteUsuario? cliente = widget.cliente;
    tipo = cliente?.tipoPessoa.isNotEmpty == true ? cliente!.tipoPessoa : 'PF';
    ativo = cliente?.ativo ?? true;
    permiteFiado = cliente?.permiteCompraFiado ?? false;
    bloqueadoFiado = cliente?.bloqueadoFiado ?? false;
    nome = TextEditingController(text: cliente?.nome ?? '');
    doc = TextEditingController(text: cliente?.documento ?? '');
    tel = TextEditingController(text: cliente?.telefone ?? '');
    email = TextEditingController(text: cliente?.email ?? '');
    cidade = TextEditingController(text: cliente?.cidade ?? '');
    uf = TextEditingController(text: cliente?.uf ?? '');
    obs = TextEditingController(text: cliente?.observacoes ?? '');
    limite = TextEditingController(text: (cliente?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','));
    prazo = TextEditingController(text: '${cliente?.prazoPagamentoDias ?? 30}');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[nome, doc, tel, email, cidade, uf, obs, limite, prazo]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  Widget _field(TextEditingController controller, String label, IconData icon, {bool req = false, TextInputType type = TextInputType.text, int lines = 1}) => TextFormField(controller: controller, keyboardType: type, maxLines: lines, decoration: _dec(label, icon), validator: req ? (String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null : null);
  double _parseMoney(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '.').trim()) ?? 0;

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final ClienteUsuario? old = widget.cliente;
    Navigator.of(context).pop(ClienteUsuarioRequest(
      ativo: ativo,
      tipoPessoa: tipo,
      documento: doc.text.trim(),
      nome: nome.text.trim(),
      telefone: tel.text.trim(),
      email: email.text.trim(),
      cep: old?.cep ?? '',
      logradouro: old?.logradouro ?? '',
      numero: old?.numero ?? '',
      complemento: old?.complemento ?? '',
      bairro: old?.bairro ?? '',
      cidade: cidade.text.trim(),
      uf: uf.text.trim().toUpperCase(),
      observacoes: obs.text.trim(),
      foto: old?.foto ?? '',
      permiteCompraFiado: permiteFiado,
      limiteFiado: permiteFiado ? _parseMoney(limite.text) : 0,
      prazoPagamentoDias: permiteFiado ? int.tryParse(prazo.text.trim()) ?? 0 : 0,
      bloqueadoFiado: bloqueadoFiado,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool edit = widget.cliente != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
            child: Row(children: <Widget>[Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(edit ? 'Editar cliente' : 'Novo cliente', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded))]),
          ),
          Expanded(child: Form(key: _key, child: ListView(padding: const EdgeInsets.all(20), children: <Widget>[
            DropdownButtonFormField<String>(value: tipo, isExpanded: true, decoration: _dec('Tipo', Icons.badge_outlined), items: const <DropdownMenuItem<String>>[DropdownMenuItem<String>(value: 'PF', child: Text('Pessoa física')), DropdownMenuItem<String>(value: 'PJ', child: Text('Pessoa jurídica'))], onChanged: (String? value) => setState(() => tipo = value ?? 'PF')),
            const SizedBox(height: 12),
            _field(nome, 'Nome / Razão social', Icons.person_outline, req: true),
            const SizedBox(height: 12),
            _field(doc, 'CPF / CNPJ', Icons.credit_card_outlined, req: true),
            const SizedBox(height: 12),
            _field(tel, 'Telefone / WhatsApp', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(email, 'E-mail', Icons.mail_outline, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Row(children: <Widget>[Expanded(child: _field(cidade, 'Cidade', Icons.location_on_outlined)), const SizedBox(width: 12), SizedBox(width: 92, child: _field(uf, 'UF', Icons.map_outlined))]),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: permiteFiado, title: const Text('Permitir compra fiado / a prazo'), onChanged: (bool value) => setState(() => permiteFiado = value)),
            if (permiteFiado) ...<Widget>[const SizedBox(height: 12), _field(limite, 'Limite de fiado', Icons.account_balance_wallet_outlined, type: TextInputType.number), const SizedBox(height: 12), _field(prazo, 'Prazo padrão em dias', Icons.event_available_outlined, type: TextInputType.number)],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: bloqueadoFiado, title: const Text('Bloquear fiado'), onChanged: (bool value) => setState(() => bloqueadoFiado = value)),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: ativo, title: const Text('Cliente ativo'), onChanged: (bool value) => setState(() => ativo = value)),
            const SizedBox(height: 12),
            _field(obs, 'Observações', Icons.notes_outlined, lines: 3),
          ]))),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))), child: Row(children: <Widget>[Expanded(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(edit ? 'Salvar' : 'Cadastrar')))])),
        ]),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;
          return ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: <Widget>[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 118),
              itemBuilder: (BuildContext context, int index) => SixWebLoadingBlock(height: 118, highlight: index == 3),
            ),
            const SizedBox(height: 18),
            const SixWebLoadingBlock(height: 124),
            const SizedBox(height: 18),
            const SixWebLoadingBlock(height: 172),
            const SizedBox(height: 12),
            const SixWebLoadingBlock(height: 172),
          ]);
        },
      );
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, this.formatter, [this.highlight = false]);
  final IconData icon;
  final String label;
  final double value;
  final SixWebMetricFormatter formatter;
  final bool highlight;
}
