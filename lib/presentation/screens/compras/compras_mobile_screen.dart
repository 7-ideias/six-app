import 'package:flutter/material.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:provider/provider.dart';

/// Tela mobile de compras persistentes. A fase 2 nao cria titulos nem entradas de estoque.
class ComprasMobileScreen extends StatefulWidget {
  const ComprasMobileScreen({super.key});
  @override
  State<ComprasMobileScreen> createState() => _ComprasMobileScreenState();
}

class _ComprasMobileScreenState extends State<ComprasMobileScreen> {
  final CompraApiClient _api = CompraApiClient();
  List<Map<String, dynamic>> _compras = [];
  String? _erro;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() { _loading = true; _erro = null; });
    try {
      final rows = await _api.listar();
      if (mounted) setState(() { _compras = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _erro = e.toString(); });
    }
  }

  Future<void> _abrir([Map<String, dynamic>? compra]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _CompraMobileEditor(api: _api, inicial: compra),
    ));
    if (saved == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: [
          IconButton(onPressed: _loading ? null : _reload,
            tooltip: 'Atualizar compras', icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: () => _abrir(), tooltip: 'Nova compra',
            icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  OutlinedButton(onPressed: _reload, child: const Text('Tentar novamente')),
                ]))
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Compras deste comércio', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      const Text('Sem movimentação de estoque ou financeiro nesta etapa.'),
                      const SizedBox(height: 14),
                      if (_compras.isEmpty)
                        const Padding(padding: EdgeInsets.all(36),
                          child: Text('Nenhuma compra cadastrada.')),
                      for (final compra in _compras)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _abrir(compra),
                            leading: const CircleAvatar(child: Icon(Icons.shopping_cart_outlined)),
                            title: Text(compra['fornecedorNome']?.toString().isNotEmpty == true
                                ? compra['fornecedorNome'].toString() : 'Rascunho sem fornecedor'),
                            subtitle: Text([
                              'Status: ${compra['status'] ?? '-'}',
                              if (compra['numeroDocumento'] != null)
                                'Documento: ${compra['numeroDocumento']}',
                            ].join(' · ')),
                            trailing: Column(mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${compra['moeda'] ?? 'BRL'} ${compra['totalCompra'] ?? 0}',
                                  style: theme.textTheme.labelLarge),
                                const Icon(Icons.chevron_right_rounded, size: 18),
                              ]),
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(), icon: const Icon(Icons.add_rounded),
        label: const Text('Nova compra'),
      ),
    );
  }
}

class _CompraMobileEditor extends StatefulWidget {
  const _CompraMobileEditor({required this.api, this.inicial});
  final CompraApiClient api;
  final Map<String, dynamic>? inicial;
  @override
  State<_CompraMobileEditor> createState() => _CompraMobileEditorState();
}

class _CompraMobileEditorState extends State<_CompraMobileEditor> {
  final fornecedoresApi = HttpFornecedorUsuarioApiClient();
  final produtosApi = ProdutoService();
  final form = GlobalKey<FormState>();
  late final TextEditingController documento, observacoes, frete, desconto,
      acrescimos, cotacao, parcelas, vencimento;
  final List<Map<String, dynamic>> itens = [];
  List<FornecedorUsuario> fornecedores = [];
  List<ProdutoModel> produtos = [];
  String? fornecedorId;
  String moeda = 'BRL';
  String moedaContabil = 'BRL';
  bool gerarContaPagar = true;
  bool busy = false, loading = true;
  String? error;

  bool get readOnly => widget.inicial != null &&
      widget.inicial!['status'] != 'RASCUNHO';

  @override
  void initState() {
    super.initState();
    final c = widget.inicial ?? {};
    fornecedorId = c['fornecedorId']?.toString();
    moeda = c['moeda']?.toString() ?? 'BRL';
    moedaContabil = c['moedaContabil']?.toString() ?? moeda;
    gerarContaPagar = c['gerarContaPagar'] != false;
    documento = TextEditingController(text: c['numeroDocumento']?.toString() ?? '');
    observacoes = TextEditingController(text: c['observacoes']?.toString() ?? '');
    frete = TextEditingController(text: c['frete']?.toString() ?? '0');
    desconto = TextEditingController(text: c['descontoGeral']?.toString() ?? '0');
    acrescimos = TextEditingController(text: c['outrosAcrescimos']?.toString() ?? '0');
    cotacao = TextEditingController(text: c['cotacao']?.toString() ?? '1');
    parcelas = TextEditingController(text: c['quantidadeParcelas']?.toString() ?? '1');
    vencimento = TextEditingController(text: c['primeiroVencimento']?.toString() ??
      DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10));
    for (final item in (c['itens'] as List? ?? [])) {
      if (item is Map) itens.add(Map<String, dynamic>.from(item));
    }
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    try {
      final vendors = await fornecedoresApi.listar();
      List<ProdutoModel> catalog = [];
      try {
        catalog = await produtosApi.buscarProdutosAtivosParaEstoque();
      } catch (_) {}
      if (mounted) setState(() {
        fornecedores = vendors.where((f) => f.ativo || f.id == fornecedorId).toList();
        produtos = catalog.where((p) => p.ativo).toList();
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.inicial == null) {
      final currency = context.read<LocaleSettingsProvider>().currencyCode;
      moedaContabil = currency;
      if (moeda == 'BRL') moeda = currency;
    }
  }

  @override
  void dispose() {
    for (final c in [documento, observacoes, frete, desconto, acrescimos,
      cotacao, parcelas, vencimento]) { c.dispose(); }
    super.dispose();
  }

  double number(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0;

  Map<String, dynamic> _payload() => {
    'versao': widget.inicial?['versao'],
    'fornecedorId': fornecedorId,
    'tipoDocumento': 'NF-e',
    'numeroDocumento': documento.text.trim(),
    'serieDocumento': '',
    'dataEmissao': DateTime.now().toIso8601String().substring(0, 10),
    'previsaoRecebimento': DateTime.now().toIso8601String().substring(0, 10),
    'moeda': moeda,
    'moedaContabil': moedaContabil,
    'cotacao': moeda == moedaContabil ? 1 :
        (cotacao.text.trim().isEmpty ? null : number(cotacao.text)),
    'observacoes': observacoes.text.trim(),
    'itens': itens,
    'frete': number(frete.text),
    'descontoGeral': number(desconto.text),
    'outrosAcrescimos': number(acrescimos.text),
    'gerarContaPagar': gerarContaPagar,
    'jaPago': false,
    'formaPagamento': '',
    'quantidadeParcelas': int.tryParse(parcelas.text) ?? 1,
    'primeiroVencimento': vencimento.text,
    'intervaloDias': 30,
    'contaFinanceira': '',
    'observacaoFinanceira': '',
  };

  Future<void> _salvar({bool confirmar = false}) async {
    if (!form.currentState!.validate() || busy) return;
    if (confirmar && (fornecedorId == null || itens.isEmpty ||
        documento.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Para confirmar, informe fornecedor, documento e itens.')));
      return;
    }
    setState(() => busy = true);
    try {
      final saved = widget.inicial == null
          ? await widget.api.criar(_payload())
          : await widget.api.atualizar(widget.inicial!['id'].toString(), _payload());
      if (confirmar) {
        await widget.api.confirmar(saved['id'].toString());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _cancelar() async {
    if (widget.inicial == null) return;
    final reason = TextEditingController();
    try {
      final motivo = await showDialog<String>(context: context, builder: (ctx) =>
        AlertDialog(
          title: const Text('Cancelar compra'),
          content: TextField(controller: reason,
            decoration: const InputDecoration(labelText: 'Motivo obrigatório')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, reason.text),
              child: const Text('Cancelar compra')),
          ],
        ),
      );
      if (motivo == null || motivo.trim().isEmpty) return;
      setState(() => busy = true);
      await widget.api.cancelar(widget.inicial!['id'].toString(), motivo);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      reason.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _adicionarItem() async {
    String? productId;
    final descricao = TextEditingController(), quantidade = TextEditingController(text: '1'),
        custo = TextEditingController(text: '0');
    try {
      final item = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, isScrollControlled: true, useSafeArea: true,
        builder: (ctx) => StatefulBuilder(builder: (ctx, update) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16,
                MediaQuery.viewInsetsOf(ctx).bottom + 16),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Adicionar item', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: productId,
                  decoration: const InputDecoration(labelText: 'Produto cadastrado (opcional)'),
                  items: [const DropdownMenuItem(value: '', child: Text('Item avulso')),
                    ...produtos.where((p) => p.id != null).map((p) =>
                      DropdownMenuItem(value: p.id!, child: Text(p.nomeProduto,
                          overflow: TextOverflow.ellipsis)))],
                  onChanged: (id) => update(() {
                    productId = id;
                    final match = produtos.where((p) => p.id == id);
                    if (match.isNotEmpty) descricao.text = match.first.nomeProduto;
                  }),
                ),
                TextField(controller: descricao,
                  decoration: const InputDecoration(labelText: 'Descrição')),
                TextField(controller: quantidade, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade')),
                TextField(controller: custo, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Custo unitário')),
                const SizedBox(height: 12),
                FilledButton(onPressed: () {
                  if (descricao.text.trim().isEmpty || number(quantidade.text) <= 0) return;
                  Navigator.pop(ctx, {
                    'id': 'item-${DateTime.now().microsecondsSinceEpoch}',
                    'produtoId': productId == '' ? null : productId,
                    'descricao': descricao.text.trim(),
                    'codigo': '', 'unidade': 'UN',
                    'quantidade': number(quantidade.text),
                    'valorUnitario': number(custo.text),
                    'desconto': 0, 'acrescimo': 0,
                    'movimentaEstoque': productId != null && productId!.isNotEmpty,
                  });
                }, child: const Text('Adicionar item')),
              ])),
          );
        }),
      );
      if (item != null && mounted) setState(() => itens.add(item));
    } finally {
      descricao.dispose(); quantidade.dispose(); custo.dispose();
    }
  }

  Widget _field(TextEditingController c, String title,
      {bool mandatory = false, TextInputType? keyboard}) => TextFormField(
    controller: c, enabled: !readOnly,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: title, border: const OutlineInputBorder()),
    validator: (v) => mandatory && (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.inicial == null ? 'Nova compra' :
        'Compra ${widget.inicial!['numero'] ?? ''}')),
      body: loading ? const Center(child: CircularProgressIndicator()) :
        error != null ? Center(child: Text(error!)) :
        Form(key: form, child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('A confirmação nesta fase ainda não movimenta estoque ou financeiro.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: fornecedorId,
            decoration: const InputDecoration(labelText: 'Fornecedor', border: OutlineInputBorder()),
            items: fornecedores.map((f) => DropdownMenuItem(
              value: f.id, child: Text(f.nome, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: readOnly ? null : (v) => setState(() => fornecedorId = v),
          ),
          const SizedBox(height: 12),
          _field(documento, 'Número do documento fiscal'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: moeda,
            decoration: const InputDecoration(labelText: 'Moeda da compra'),
            items: [moeda, moedaContabil, 'BRL', 'USD', 'EUR']
                .toSet().map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: readOnly ? null : (v) => setState(() {
              moeda = v ?? moeda;
              if (widget.inicial == null || moeda != moedaContabil) {
                cotacao.clear();
              }
            }),
          ),
          if (moeda != moedaContabil) ...[
            const SizedBox(height: 12),
            _field(cotacao, 'Cotação para $moedaContabil', mandatory: true,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Itens (${itens.length})', style: theme.textTheme.titleMedium)),
            if (!readOnly) IconButton(onPressed: _adicionarItem,
              icon: const Icon(Icons.add_circle_outline_rounded)),
          ]),
          for (int i = 0; i < itens.length; i++)
            Card(child: ListTile(
              title: Text(itens[i]['descricao']?.toString() ?? ''),
              subtitle: Text('Quantidade ${itens[i]['quantidade']} · ${itens[i]['valorUnitario']}'),
              trailing: readOnly ? null : IconButton(icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => itens.removeAt(i))),
            )),
          const SizedBox(height: 16),
          _field(frete, 'Frete', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          _field(desconto, 'Desconto geral', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          _field(acrescimos, 'Outros acréscimos', keyboard: TextInputType.number),
          SwitchListTile.adaptive(
            title: const Text('Previsão de contas a pagar'),
            subtitle: const Text('Somente previsão nesta etapa; os títulos serão integrados na Fase 3.'),
            value: gerarContaPagar, onChanged: readOnly ? null :
              (v) => setState(() => gerarContaPagar = v),
          ),
          if (gerarContaPagar) ...[
            _field(parcelas, 'Quantidade de parcelas', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _field(vencimento, 'Primeiro vencimento (AAAA-MM-DD)'),
          ],
          const SizedBox(height: 12),
          _field(observacoes, 'Observações'),
          const SizedBox(height: 24),
          if (!readOnly) ...[
            OutlinedButton(onPressed: busy ? null : _salvar, child: const Text('Salvar rascunho')),
            const SizedBox(height: 10),
            FilledButton(onPressed: busy ? null : () => _salvar(confirmar: true),
              child: Text(busy ? 'Salvando...' : 'Confirmar compra')),
          ],
          if (widget.inicial != null && widget.inicial!['status'] != 'CANCELADA') ...[
            const SizedBox(height: 12),
            TextButton(onPressed: busy ? null : _cancelar,
              child: const Text('Cancelar compra')),
          ],
        ])),
    );
  }
}
