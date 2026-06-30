import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

import '../../data/models/cliente_usuario_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';

class ClientesUsuarioListPage extends StatefulWidget {
  const ClientesUsuarioListPage({super.key, this.embedded = false, this.onBack, this.apiClient});

  final bool embedded;
  final VoidCallback? onBack;
  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClientesUsuarioListPage> createState() => _ClientesUsuarioListPageState();
}

class _ClientesUsuarioListPageState extends State<ClientesUsuarioListPage> {
  static const _bg = Color(0xFFF4F7FB);
  static const _primary = Color(0xFF0B1F3A);
  static const _secondary = Color(0xFF123B69);
  static const _accent = Color(0xFF2563EB);
  static const _muted = Color(0xFF64748B);
  static const _title = Color(0xFF0F172A);

  late final ClienteUsuarioApiClient _api;
  final _search = TextEditingController();
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _loading = false;
  String? _erro;
  ClienteUsuarioListResponse? _response;
  String _filter = '';

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

  List<ClienteUsuario> get _all => _response?.clientes ?? const [];
  List<ClienteUsuario> get _items {
    final term = _norm(_filter);
    if (term.isEmpty) return _all;
    return _all.where((c) => _norm('${c.nome} ${c.documento} ${c.telefone} ${c.email} ${c.cidade}').contains(term)).toList();
  }

  int get _ativos => _all.where((c) => c.ativo).length;
  int get _fiado => _all.where((c) => c.permiteCompraFiado).length;
  double get _saldo => _all.fold(0, (v, c) => v + c.saldoFiado);
  String _norm(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await _api.listarClientesUsuario();
      if (!mounted) return;
      setState(() {
        _response = data;
        _loading = false;
      });
    } on ClienteUsuarioApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _msg(e.statusCode);
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
    final content = SafeArea(child: _content());
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [IconButton(tooltip: 'Atualizar', icon: const Icon(Icons.refresh_rounded), onPressed: _reload)],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        onPressed: () => _form(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo cliente'),
      ),
    );
  }

  Widget _content() {
    if (_loading && _response == null) return const _LoadingList();
    if (_erro != null && _response == null) return _errorState();
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 14, 16, widget.embedded ? 24 : 96),
        children: [
          SixStaggeredEntry(child: _hero()),
          const SizedBox(height: 16),
          SixStaggeredEntry(delay: const Duration(milliseconds: 70), child: _searchBox()),
          if (_erro != null) ...[const SizedBox(height: 14), _inlineError(_erro!)],
          const SizedBox(height: 14),
          SixStaggeredEntry(delay: const Duration(milliseconds: 120), child: _kpis()),
          const SizedBox(height: 18),
          SixStaggeredEntry(delay: const Duration(milliseconds: 170), child: _listTitle()),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            SixStaggeredEntry(delay: const Duration(milliseconds: 210), child: _empty())
          else
            ..._items.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SixStaggeredEntry(delay: Duration(milliseconds: 210 + ((e.key * 35).clamp(0, 260)).toInt()), child: _card(e.value)),
                )),
        ],
      ),
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [_primary, _secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [BoxShadow(color: Color(0x260B1F3A), blurRadius: 22, offset: Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _icon(Icons.groups_2_outlined),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Base de clientes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Relacionamento, histórico, fiado e dados de contato em uma visão rápida.', style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35)),
            ])),
            if (widget.onBack != null) IconButton(onPressed: widget.onBack, icon: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
          const SizedBox(height: 18),
          Row(children: [Expanded(child: _pill('Clientes', '${_all.length}')), const SizedBox(width: 12), Expanded(child: _pill('Ativos', '$_ativos'))]),
        ]),
      );

  Widget _icon(IconData icon) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x33FFFFFF))),
        child: Icon(icon, color: Colors.white),
      );

  Widget _pill(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x33FFFFFF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFBFD0EA), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SixAnimatedNumberText(value: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
      );

  Widget _searchBox() => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))]),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _filter = v),
          decoration: InputDecoration(
            hintText: 'Buscar nome, documento, telefone ou e-mail...',
            hintStyle: const TextStyle(color: _muted),
            prefixIcon: const Icon(Icons.search_rounded, color: _accent),
            suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, color: _muted), onPressed: () { _search.clear(); setState(() => _filter = ''); }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      );

  Widget _kpis() {
    final data = [
      _Metric(Icons.groups_outlined, 'Cadastrados', '${_all.length}'),
      _Metric(Icons.verified_user_outlined, 'Ativos', '$_ativos'),
      _Metric(Icons.request_quote_outlined, 'Fiado liberado', '$_fiado'),
      _Metric(Icons.receipt_long_outlined, 'Saldo aberto', _money.format(_saldo), true),
    ];
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth >= 560 ? (c.maxWidth - 12) / 2 : c.maxWidth;
      return Wrap(spacing: 12, runSpacing: 12, children: data.map((m) => SizedBox(width: width, child: _kpi(m))).toList());
    });
  }

  Widget _kpi(_Metric m) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: m.featured ? _primary : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: m.featured ? _primary : const Color(0xFFE2E8F0)), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))]),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: m.featured ? const Color(0x1AFFFFFF) : const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)), child: Icon(m.icon, color: m.featured ? Colors.white : _accent, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: m.featured ? const Color(0xFFD7E3F5) : _muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(m.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: m.featured ? Colors.white : _title, fontSize: 18, fontWeight: FontWeight.w900)),
          ])),
        ]),
      );

  Widget _listTitle() => Row(children: [
        const Expanded(child: Text('Clientes encontrados', style: TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(999)), child: Text('${_items.length}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w900))),
      ]);

  Widget _card(ClienteUsuario c) {
    final ok = c.permiteCompraFiado && !c.bloqueadoFiado;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _history(c),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 24, backgroundColor: const Color(0xFFEFF6FF), child: Text(_initials(c.nome), style: const TextStyle(color: _accent, fontWeight: FontWeight.w900))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.nome.isEmpty ? 'Cliente sem nome' : c.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${c.tipoPessoa.isEmpty ? 'PF' : c.tipoPessoa} • ${c.documento.isEmpty ? 'Documento não informado' : c.documento}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
              ])),
              _status(c.ativo ? 'Ativo' : 'Inativo', c.ativo ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [_info(Icons.phone_outlined, c.telefone.isEmpty ? 'Sem telefone' : c.telefone), _info(Icons.mail_outline, c.email.isEmpty ? 'Sem e-mail' : c.email), _info(Icons.location_on_outlined, _location(c))]),
            const SizedBox(height: 14),
            _credit(c, ok),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _history(c), icon: const Icon(Icons.timeline_outlined, size: 18), label: const Text('Histórico'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: () => _form(cliente: c), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar')))]),
          ]),
        ),
      ),
    );
  }

  Widget _credit(ClienteUsuario c, bool ok) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ok ? const Color(0xFFEFFDF4) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: ok ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0))),
        child: Row(children: [Icon(Icons.request_quote_outlined, color: ok ? const Color(0xFF15803D) : _muted, size: 20), const SizedBox(width: 10), Expanded(child: Text(c.permiteCompraFiado ? 'Fiado: limite ${_money.format(c.limiteFiado)} • prazo ${c.prazoPagamentoDias} dias' : 'Fiado não liberado para este cliente', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontWeight: FontWeight.w800, fontSize: 12)))]),
      );

  Widget _status(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)));
  Widget _info(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: _muted), const SizedBox(width: 6), ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700)))]));

  Widget _empty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(children: [const Icon(Icons.person_add_alt_1_rounded, color: _accent, size: 42), const SizedBox(height: 12), const Text('Nenhum cliente encontrado.', style: TextStyle(color: _title, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 6), const Text('Cadastre clientes para registrar vendas, serviços e compras a prazo.', textAlign: TextAlign.center, style: TextStyle(color: _muted)), const SizedBox(height: 18), FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente'))]),
      );

  Widget _errorState() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: Color(0xFFB91C1C), size: 44), const SizedBox(height: 12), const Text('Não foi possível carregar os clientes.', textAlign: TextAlign.center, style: TextStyle(color: _title, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(_erro ?? '', textAlign: TextAlign.center, style: const TextStyle(color: _muted)), const SizedBox(height: 18), FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente'))])));
  Widget _inlineError(String msg) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECACA))), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)), const SizedBox(width: 10), Expanded(child: Text(msg, style: const TextStyle(color: _title)))]));

  Future<void> _form({ClienteUsuario? cliente}) async {
    final request = await showDialog<ClienteUsuarioRequest>(context: context, barrierDismissible: false, builder: (_) => _ClientForm(cliente: cliente));
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
    } on ClienteUsuarioApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _msg(e.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível salvar o cliente.';
      });
    }
  }

  void _history(ClienteUsuario c) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 18),
              Text(c.nome.isEmpty ? 'Cliente sem nome' : c.nome, style: const TextStyle(color: _title, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(c.documento.isEmpty ? 'Documento não informado' : c.documento, style: const TextStyle(color: _muted)),
              const SizedBox(height: 18),
              _historyBox(Icons.phone_outlined, 'Telefone', c.telefone.isEmpty ? '-' : c.telefone),
              _historyBox(Icons.mail_outline, 'E-mail', c.email.isEmpty ? '-' : c.email),
              _historyBox(Icons.location_on_outlined, 'Endereço', _address(c)),
              _historyBox(Icons.request_quote_outlined, 'Fiado', c.permiteCompraFiado ? 'Liberado • saldo ${_money.format(c.saldoFiado)}' : 'Não liberado'),
              _historyBox(Icons.notes_outlined, 'Observações', c.observacoes.isEmpty ? 'Sem observações cadastradas.' : c.observacoes),
            ]),
          ),
        ),
      );

  Widget _historyBox(IconData icon, String title, String text) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _accent), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _title, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: _muted, height: 1.35))]))]));
  String _location(ClienteUsuario c) => c.cidade.isEmpty && c.uf.isEmpty ? 'Sem cidade' : c.uf.isEmpty ? c.cidade : c.cidade.isEmpty ? c.uf : '${c.cidade}/${c.uf}';
  String _address(ClienteUsuario c) => [c.logradouro, c.numero, c.bairro, c.cidade, c.uf, c.cep].where((v) => v.trim().isNotEmpty).join(', ').isEmpty ? 'Endereço não informado.' : [c.logradouro, c.numero, c.bairro, c.cidade, c.uf, c.cep].where((v) => v.trim().isNotEmpty).join(', ');
  String _initials(String n) { final p = n.trim().split(' ').where((v) => v.isNotEmpty).toList(); if (p.isEmpty) return 'CL'; return p.length == 1 ? p.first[0].toUpperCase() : '${p.first[0]}${p.last[0]}'.toUpperCase(); }
}

class _ClientForm extends StatefulWidget {
  const _ClientForm({this.cliente});
  final ClienteUsuario? cliente;
  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController nome, doc, tel, email, cidade, uf, obs, limite, prazo;
  String tipo = 'PF';
  bool ativo = true, permiteFiado = false, bloqueadoFiado = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    tipo = c?.tipoPessoa.isNotEmpty == true ? c!.tipoPessoa : 'PF';
    ativo = c?.ativo ?? true;
    permiteFiado = c?.permiteCompraFiado ?? false;
    bloqueadoFiado = c?.bloqueadoFiado ?? false;
    nome = TextEditingController(text: c?.nome ?? '');
    doc = TextEditingController(text: c?.documento ?? '');
    tel = TextEditingController(text: c?.telefone ?? '');
    email = TextEditingController(text: c?.email ?? '');
    cidade = TextEditingController(text: c?.cidade ?? '');
    uf = TextEditingController(text: c?.uf ?? '');
    obs = TextEditingController(text: c?.observacoes ?? '');
    limite = TextEditingController(text: (c?.limiteFiado ?? 0).toStringAsFixed(2).replaceAll('.', ','));
    prazo = TextEditingController(text: '${c?.prazoPagamentoDias ?? 30}');
  }

  @override
  void dispose() { for (final c in [nome, doc, tel, email, cidade, uf, obs, limite, prazo]) { c.dispose(); } super.dispose(); }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  Widget _field(TextEditingController c, String label, IconData icon, {bool req = false, TextInputType type = TextInputType.text, int lines = 1}) => TextFormField(controller: c, keyboardType: type, maxLines: lines, decoration: _dec(label, icon), validator: req ? (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null : null);
  double _parseMoney(String v) => double.tryParse(v.replaceAll('.', '').replaceAll(',', '.').trim()) ?? 0;

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final old = widget.cliente;
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
    final edit = widget.cliente != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(children: [
          Container(padding: const EdgeInsets.fromLTRB(20, 18, 12, 16), decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))), child: Row(children: [const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB)), const SizedBox(width: 12), Expanded(child: Text(edit ? 'Editar cliente' : 'Novo cliente', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded))])),
          Expanded(child: Form(key: _key, child: ListView(padding: const EdgeInsets.all(20), children: [
            DropdownButtonFormField<String>(value: tipo, isExpanded: true, decoration: _dec('Tipo', Icons.badge_outlined), items: const [DropdownMenuItem(value: 'PF', child: Text('Pessoa física')), DropdownMenuItem(value: 'PJ', child: Text('Pessoa jurídica'))], onChanged: (v) => setState(() => tipo = v ?? 'PF')),
            const SizedBox(height: 12),
            _field(nome, 'Nome / Razão social', Icons.person_outline, req: true),
            const SizedBox(height: 12),
            _field(doc, 'CPF / CNPJ', Icons.credit_card_outlined, req: true),
            const SizedBox(height: 12),
            _field(tel, 'Telefone / WhatsApp', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(email, 'E-mail', Icons.mail_outline, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _field(cidade, 'Cidade', Icons.location_on_outlined)), const SizedBox(width: 12), SizedBox(width: 92, child: _field(uf, 'UF', Icons.map_outlined))]),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: permiteFiado, title: const Text('Permitir compra fiado / a prazo'), onChanged: (v) => setState(() => permiteFiado = v)),
            if (permiteFiado) ...[const SizedBox(height: 12), _field(limite, 'Limite de fiado', Icons.account_balance_wallet_outlined, type: TextInputType.number), const SizedBox(height: 12), _field(prazo, 'Prazo padrão em dias', Icons.event_available_outlined, type: TextInputType.number)],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: bloqueadoFiado, title: const Text('Bloquear fiado'), onChanged: (v) => setState(() => bloqueadoFiado = v)),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: ativo, title: const Text('Cliente ativo'), onChanged: (v) => setState(() => ativo = v)),
            const SizedBox(height: 12),
            _field(obs, 'Observações', Icons.notes_outlined, lines: 3),
          ]))),
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))), child: Row(children: [Expanded(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(edit ? 'Salvar' : 'Cadastrar')))])),
        ]),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: const [_SkeletonBlock(height: 150), SizedBox(height: 16), _SkeletonBlock(height: 56), SizedBox(height: 14), _SkeletonBlock(height: 110), SizedBox(height: 12), _SkeletonBlock(height: 210), SizedBox(height: 12), _SkeletonBlock(height: 210)]);
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Center(child: CircularProgressIndicator()));
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, [this.featured = false]);
  final IconData icon;
  final String label;
  final String value;
  final bool featured;
}
