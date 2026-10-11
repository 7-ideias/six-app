import 'package:flutter/material.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';

/// Cadastro unico para Web e Mobile, reutilizando o mesmo contrato de API.
class FornecedoresWebPage extends StatefulWidget {
  const FornecedoresWebPage({super.key, this.embedded = false, this.onBack, this.apiClient});
  final bool embedded;
  final VoidCallback? onBack;
  final FornecedorUsuarioApiClient? apiClient;

  @override
  State<FornecedoresWebPage> createState() => _FornecedoresWebPageState();
}

class _FornecedoresWebPageState extends State<FornecedoresWebPage> {
  late final FornecedorUsuarioApiClient _api;
  final _busca = TextEditingController();
  List<FornecedorUsuario> _fornecedores = <FornecedorUsuario>[];
  String _filtro = 'Todos';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpFornecedorUsuarioApiClient();
    _busca.addListener(_atualizarBusca);
    _recarregar();
  }

  void _atualizarBusca() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _busca.removeListener(_atualizarBusca);
    _busca.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final itens = await _api.listar();
      if (mounted) setState(() { _fornecedores = itens; _carregando = false; });
    } catch (error) {
      if (mounted) setState(() { _erro = error.toString(); _carregando = false; });
    }
  }

  List<FornecedorUsuario> get _filtrados {
    final query = _busca.text.trim().toLowerCase();
    return _fornecedores.where((f) {
      if (_filtro == 'Ativos' && !f.ativo) return false;
      if (_filtro == 'Inativos' && f.ativo) return false;
      if (query.isEmpty) return true;
      return [f.nome, f.documento, f.telefone, f.email, f.contatoResponsavel]
          .any((campo) => campo.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _editar([FornecedorUsuario? atual]) async {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    Future<FornecedorUsuario> salvar(FornecedorUsuarioDraft draft) =>
        atual == null ? _api.cadastrar(draft) : _api.atualizar(atual.id, draft);
    final form = _FornecedorEditor(atual: atual, onSave: salvar);
    final FornecedorUsuario? salvo;
    if (mobile) {
      salvo = await showModalBottomSheet<FornecedorUsuario>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: .94,
          child: form,
        ),
      );
    } else {
      salvo = await showDialog<FornecedorUsuario>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 690, maxHeight: 760),
            child: form,
          ),
        ),
      );
    }
    if (salvo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(atual == null ? 'Fornecedor cadastrado.' : 'Fornecedor atualizado.'),
      ));
      await _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final theme = Theme.of(context);
    final filtrados = _filtrados;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 16 : 28, 16, mobile ? 16 : 28, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fornecedores', style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Parceiros e contatos comerciais do seu comércio',
                      style: theme.textTheme.bodySmall),
                ],
              ),
              Wrap(spacing: 8, children: [
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregando ? null : _recarregar,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                FilledButton.icon(
                  key: const Key('fornecedor-novo'),
                  onPressed: _carregando ? null : () => _editar(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(mobile ? 'Novo' : 'Novo fornecedor'),
                ),
              ]),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 28, vertical: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ResumoFornecedor(label: 'Cadastrados', valor: _fornecedores.length),
              _ResumoFornecedor(label: 'Ativos', valor: _fornecedores.where((f) => f.ativo).length),
              _ResumoFornecedor(label: 'Inativos', valor: _fornecedores.where((f) => !f.ativo).length),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 28),
          child: TextField(
            key: const Key('fornecedor-busca'),
            controller: _busca,
            decoration: InputDecoration(
              labelText: 'Buscar por nome, documento, telefone ou e-mail',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 16 : 28, 8, mobile ? 16 : 28, 10),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final status in ['Todos', 'Ativos', 'Inativos'])
                ChoiceChip(
                  label: Text(status),
                  selected: _filtro == status,
                  onSelected: (_) => setState(() => _filtro = status),
                ),
              Text('${filtrados.length} encontrado(s)', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded, size: 32),
                        const SizedBox(height: 8),
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
                      ]),
                    ))
                  : RefreshIndicator(
                      onRefresh: _recarregar,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(mobile ? 16 : 28, 0, mobile ? 16 : 28, 24),
                        itemCount: filtrados.isEmpty ? 1 : filtrados.length,
                        itemBuilder: (context, index) => filtrados.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('Nenhum fornecedor encontrado.')),
                              )
                            : _card(filtrados[index], mobile),
                      ),
                    ),
        ),
      ],
    );
    if (widget.embedded) {
      return Material(color: theme.scaffoldBackgroundColor, child: body);
    }
    return Scaffold(
      appBar: mobile ? AppBar(title: const Text('Fornecedores')) : null,
      body: SafeArea(child: body),
    );
  }

  Widget _card(FornecedorUsuario f, bool mobile) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _editar(f),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.storefront_outlined, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text([f.documento, f.contatoResponsavel].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                Text([f.telefone, f.email].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            )),
            if (!mobile) const SizedBox(width: 12),
            Chip(label: Text(f.ativo ? 'Ativo' : 'Inativo')),
            IconButton(
              tooltip: 'Consultar ou editar fornecedor',
              onPressed: () => _editar(f),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ResumoFornecedor extends StatelessWidget {
  const _ResumoFornecedor({required this.label, required this.valor});
  final String label;
  final int valor;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.business_outlined, size: 16),
    label: Text('$label: $valor'),
  );
}

class _FornecedorEditor extends StatefulWidget {
  const _FornecedorEditor({this.atual, required this.onSave});
  final FornecedorUsuario? atual;
  final Future<FornecedorUsuario> Function(FornecedorUsuarioDraft draft) onSave;
  @override
  State<_FornecedorEditor> createState() => _FornecedorEditorState();
}

class _FornecedorEditorState extends State<_FornecedorEditor> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _campos = {};
  late bool _ativo;
  late String _tipoPessoa;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.atual;
    _ativo = a?.ativo ?? true;
    _tipoPessoa = a?.tipoPessoa == 'PF' ? 'PF' : 'PJ';
    final valores = <String, String>{
      'nome': a?.nome ?? '', 'documento': a?.documento ?? '',
      'telefone': a?.telefone ?? '', 'email': a?.email ?? '',
      'cep': a?.cep ?? '', 'logradouro': a?.logradouro ?? '',
      'numero': a?.numero ?? '', 'complemento': a?.complemento ?? '',
      'bairro': a?.bairro ?? '', 'cidade': a?.cidade ?? '',
      'uf': a?.uf ?? '', 'pais': a?.pais ?? '',
      'contatoResponsavel': a?.contatoResponsavel ?? '',
      'condicoesPagamento': a?.condicoesPagamento ?? '',
      'observacoes': a?.observacoes ?? '',
    };
    for (final item in valores.entries) {
      _campos[item.key] = TextEditingController(text: item.value);
    }
  }

  @override
  void dispose() {
    for (final c in _campos.values) { c.dispose(); }
    super.dispose();
  }

  String _valor(String chave) => _campos[chave]!.text;
  Widget _campo(String chave, String rotulo, {bool obrigatorio = false,
      TextInputType? teclado, int maxLines = 1}) => TextFormField(
    key: Key('fornecedor-campo-$chave'),
    controller: _campos[chave],
    keyboardType: teclado,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
    validator: (value) {
      final texto = value?.trim() ?? '';
      if (obrigatorio && texto.isEmpty) return 'Campo obrigatório';
      if (chave == 'email' && texto.isNotEmpty && !texto.contains('@')) return 'E-mail inválido';
      return null;
    },
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _salvando) return;
    setState(() => _salvando = true);
    try {
      final salvo = await widget.onSave(FornecedorUsuarioDraft(
        ativo: _ativo, tipoPessoa: _tipoPessoa, nome: _valor('nome'),
        documento: _valor('documento'), telefone: _valor('telefone'),
        email: _valor('email'), cep: _valor('cep'),
        logradouro: _valor('logradouro'), numero: _valor('numero'),
        complemento: _valor('complemento'), bairro: _valor('bairro'),
        cidade: _valor('cidade'), uf: _valor('uf'), pais: _valor('pais'),
        contatoResponsavel: _valor('contatoResponsavel'),
        condicoesPagamento: _valor('condicoesPagamento'),
        observacoes: _valor('observacoes'),
      ));
      if (mounted) Navigator.of(context).pop(salvo);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(widget.atual == null ? 'Cadastrar fornecedor' : 'Consultar / editar fornecedor',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          IconButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded)),
        ]),
        const Divider(),
        Expanded(child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'PJ', label: Text('Pessoa jurídica')),
                  ButtonSegment(value: 'PF', label: Text('Pessoa física')),
                ],
                selected: {_tipoPessoa},
                onSelectionChanged: (selecionado) =>
                    setState(() => _tipoPessoa = selecionado.first),
              ),
              const SizedBox(height: 12),
              _campo('nome', 'Nome / razão social *', obrigatorio: true),
              const SizedBox(height: 12),
              _campo('documento', 'Documento (CPF, CNPJ ou equivalente)'),
              const SizedBox(height: 12),
              _campo('contatoResponsavel', 'Contato responsável'),
              const SizedBox(height: 12),
              _campo('telefone', 'Telefone', teclado: TextInputType.phone),
              const SizedBox(height: 12),
              _campo('email', 'E-mail', teclado: TextInputType.emailAddress),
              const SizedBox(height: 18),
              Text('Endereço', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _campo('cep', 'CEP / Código postal'),
              const SizedBox(height: 12),
              _campo('logradouro', 'Endereço / Logradouro'),
              const SizedBox(height: 12),
              _campo('numero', 'Número'),
              const SizedBox(height: 12),
              _campo('complemento', 'Complemento'),
              const SizedBox(height: 12),
              _campo('bairro', 'Bairro'),
              const SizedBox(height: 12),
              _campo('cidade', 'Cidade'),
              const SizedBox(height: 12),
              _campo('uf', 'Estado / Província'),
              const SizedBox(height: 12),
              _campo('pais', 'País'),
              const SizedBox(height: 18),
              Text('Condições comerciais', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _campo('condicoesPagamento', 'Condições de pagamento', maxLines: 2),
              const SizedBox(height: 12),
              _campo('observacoes', 'Observações', maxLines: 3),
              SwitchListTile.adaptive(
                title: const Text('Fornecedor ativo'),
                subtitle: const Text('Desative sem perder o histórico do cadastro.'),
                value: _ativo, onChanged: (v) => setState(() => _ativo = v),
              ),
            ]),
          ),
        )),
        const Divider(),
        Row(children: [
          TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          const Spacer(),
          FilledButton.icon(
            key: const Key('fornecedor-salvar'),
            onPressed: _salvando ? null : _salvar,
            icon: _salvando ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
            label: Text(_salvando ? 'Salvando...' : 'Salvar fornecedor'),
          ),
        ]),
      ]),
    );
  }
}
