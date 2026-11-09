import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';

import '../../data/models/web_header_assets_model.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/web/six_managed_web_hero.dart';
import '../components/web_dashboard_widgets.dart';
import '../layouts/six_web_page_shell.dart';
import '../theme/six_web_action_styles.dart';
import '../theme/web_theme_tokens.dart';
import 'fornecedores_permissoes_page.dart';

/// Listagem Web; integração de fornecedores compartilhada com o Mobile.
class FornecedoresWebPage extends StatefulWidget {
  const FornecedoresWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.apiClient,
  });
  final bool embedded;
  final VoidCallback? onBack;
  final FornecedorUsuarioApiClient? apiClient;

  @override
  State<FornecedoresWebPage> createState() => _FornecedoresWebPageState();
}

class _FornecedoresWebPageState extends State<FornecedoresWebPage> {
  late final FornecedorUsuarioApiClient _api;
  late final EmpresaProvider _empresaProvider;
  EmpresaModel? _empresaAnterior;
  int _versaoConsulta = 0;
  final _busca = TextEditingController();
  List<FornecedorUsuario> _fornecedores = <FornecedorUsuario>[];
  FornecedorAcesso _acesso = FornecedorAcesso.negado;
  String _filtro = 'Todos';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpFornecedorUsuarioApiClient();
    _empresaProvider = EmpresaProvider();
    _empresaAnterior = _empresaProvider.empresa;
    _empresaProvider.addListener(_empresaMudou);
    _busca.addListener(_atualizarBusca);
    _recarregar();
  }

  void _atualizarBusca() {
    if (mounted) setState(() {});
  }

  void _empresaMudou() {
    final atual = _empresaProvider.empresa;
    if (identical(atual, _empresaAnterior)) return;
    _empresaAnterior = atual;
    _recarregar(limpar: true);
  }

  @override
  void dispose() {
    _empresaProvider.removeListener(_empresaMudou);
    _busca.removeListener(_atualizarBusca);
    _busca.dispose();
    super.dispose();
  }

  Future<void> _recarregar({bool limpar = false}) async {
    final versao = ++_versaoConsulta;
    setState(() {
      _carregando = true;
      _erro = null;
      if (limpar) {
        _fornecedores = <FornecedorUsuario>[];
        _acesso = FornecedorAcesso.negado;
      }
    });
    try {
      final acesso = await _api.consultarAcesso();
      if (!mounted || versao != _versaoConsulta) return;
      if (!acesso.consultar) {
        setState(() {
          _acesso = acesso;
          _fornecedores = <FornecedorUsuario>[];
          _carregando = false;
          _erro = 'Sem permissão para consultar fornecedores neste comércio.';
        });
        return;
      }
      final itens = await _api.listar();
      if (!mounted || versao != _versaoConsulta) return;
      setState(() {
        _acesso = acesso;
        _fornecedores = itens;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted || versao != _versaoConsulta) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
  }

  List<FornecedorUsuario> get _filtrados {
    final query = _busca.text.trim().toLowerCase();
    return _fornecedores.where((f) {
      if (_filtro == 'Ativos' && !f.ativo) return false;
      if (_filtro == 'Inativos' && f.ativo) return false;
      if (query.isEmpty) return true;
      return [
        f.nome,
        f.documento,
        f.telefone,
        f.email,
        f.contatoResponsavel,
      ].any((campo) => campo.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _editar([FornecedorUsuario? atual]) async {
    if (atual == null && !_acesso.cadastrar) return;
    final mobile = MediaQuery.sizeOf(context).width < 700;
    Future<FornecedorUsuario> salvar(FornecedorUsuarioDraft draft) =>
        atual == null ? _api.cadastrar(draft) : _api.atualizar(atual.id, draft);
    final form = _FornecedorEditor(
      atual: atual,
      onSave: salvar,
      podeEditar: atual == null || _acesso.editar,
      podeAlterarAtivo: atual == null || (_acesso.editar && _acesso.inativar),
    );
    final FornecedorUsuario? salvo;
    if (mobile) {
      salvo = await showModalBottomSheet<FornecedorUsuario>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) =>
            FractionallySizedBox(heightFactor: .94, child: form),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            atual == null ? 'Fornecedor cadastrado.' : 'Fornecedor atualizado.',
          ),
        ),
      );
      await _recarregar();
    }
  }

  Future<void> _gerenciarPermissoes() async {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final editor = FornecedoresPermissoesPage(api: _api);
    if (mobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => FractionallySizedBox(heightFactor: .90, child: editor),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
            child: editor,
          ),
        ),
      );
    }
  }

  String _t(String key) => context.t('suppliers.web.$key');

  String _count(num value) =>
      context.read<LocaleSettingsProvider?>()?.formatInteger(value) ??
      value.round().toString();

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider?>();
    final tokens = WebThemeTokens.of(context);
    final filtrados = _filtrados;
    final body = SixWebPageShell(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SixManagedWebHero(
                // Fornecedores compartilha a imagem comercial gerenciada de Compras.
                page: WebHeaderAssetPage.compras,
                icon: Icons.local_shipping_outlined,
                title: _t('title'),
                subtitle: _t('subtitle'),
                onBack: widget.onBack,
                actions: [
                  OutlinedButton.icon(
                    onPressed: _carregando ? null : _recarregar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_t('refresh')),
                    style: SixWebActionStyles.secondary(context),
                  ),
                  if (Provider.of<ColaboradorAutorizacoesProvider?>(context)
                          ?.ehAdministrador ==
                      true)
                    OutlinedButton.icon(
                      onPressed: _carregando ? null : _gerenciarPermissoes,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: Text(_t('permissions')),
                      style: SixWebActionStyles.secondary(context),
                    ),
                  if (_acesso.cadastrar)
                    FilledButton.icon(
                      key: const Key('fornecedor-novo'),
                      onPressed: _carregando ? null : () => _editar(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_t('new')),
                      style: SixWebActionStyles.primary(context),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: SixWebPageShell.bodyPadding,
                child: _carregando
                    ? const Column(
                        children: [
                          SixWebLoadingBlock(height: 118),
                          SixWebPageShell.sectionGap,
                          SixWebLoadingBlock(height: 160),
                          SixWebPageShell.sectionGap,
                          SixWebLoadingBlock(height: 120),
                        ],
                      )
                    : _erro != null
                    ? _errorState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SixWebEntry(
                            order: 0,
                            child: _metrics(constraints.maxWidth),
                          ),
                          SixWebPageShell.sectionGap,
                          SixWebEntry(order: 1, child: _searchSection()),
                          SixWebPageShell.sectionGap,
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _t('found'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: tokens.primaryText,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              Chip(label: Text(_count(filtrados.length))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (filtrados.isEmpty) _emptyState(),
                        ],
                      ),
              ),
            ),
            if (!_carregando && _erro == null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _card(filtrados[index]),
                  childCount: filtrados.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
    if (widget.embedded) {
      return Material(color: tokens.workspaceBackground, child: body);
    }
    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(child: body),
    );
  }

  Widget _metrics(double width) {
    final active = _fornecedores.where((f) => f.ativo).length;
    final metrics = [
      (Icons.local_shipping_outlined, _t('registered'), _fornecedores.length),
      (Icons.check_circle_outline_rounded, _t('activePlural'), active),
      (
        Icons.pause_circle_outline_rounded,
        _t('inactivePlural'),
        _fornecedores.length - active,
      ),
    ];
    final columns = width < 600 ? 1 : 3;
    return Wrap(
      spacing: SixWebPageShell.sectionSpacing,
      runSpacing: SixWebPageShell.sectionSpacing,
      children: [
        for (final metric in metrics)
          SizedBox(
            width:
                (width - (columns - 1) * SixWebPageShell.sectionSpacing) /
                columns,
            height: 118,
            child: SixWebKpiCard(
              icon: metric.$1,
              label: metric.$2,
              value: metric.$3.toDouble(),
              formatter: _count,
            ),
          ),
      ],
    );
  }

  Widget _searchSection() {
    final tokens = WebThemeTokens.of(context);
    return SixWebSectionCard(
      title: _t('searchTitle'),
      subtitle: _t('searchHint'),
      icon: Icons.search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('fornecedor-busca'),
            controller: _busca,
            decoration: InputDecoration(
              hintText: _t('searchHint'),
              prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
              suffixIcon: _busca.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _t('clear'),
                      onPressed: _busca.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: tokens.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in [
                ('Todos', 'all'),
                ('Ativos', 'activePlural'),
                ('Inativos', 'inactivePlural'),
              ])
                ChoiceChip(
                  label: Text(_t(status.$2)),
                  selected: _filtro == status.$1,
                  selectedColor: tokens.selectedBackground,
                  side: BorderSide(
                    color: _filtro == status.$1
                        ? tokens.selectedBorder
                        : tokens.cardBorder,
                  ),
                  onSelected: (_) => setState(() => _filtro = status.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final filtered = _busca.text.trim().isNotEmpty || _filtro != 'Todos';
    return SixWebSectionCard(
      title: _t(filtered ? 'emptySearch' : 'empty'),
      subtitle: _t(filtered ? 'emptySearchHint' : 'emptyHint'),
      icon: Icons.local_shipping_outlined,
      child: Align(
        alignment: Alignment.centerLeft,
        child: filtered
            ? OutlinedButton.icon(
                onPressed: () {
                  _busca.clear();
                  setState(() => _filtro = 'Todos');
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(_t('clearFilters')),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _errorState() => SixWebSectionCard(
    title: _t('loadError'),
    subtitle: _erro,
    icon: Icons.error_outline_rounded,
    child: Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _recarregar,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(_t('retry')),
      ),
    ),
  );

  Widget _metadata(IconData icon, String value) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tokens.secondaryText),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(FornecedorUsuario f) {
    final tokens = WebThemeTokens.of(context);
    final statusColor = f.ativo ? tokens.success : tokens.secondaryText;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tokens.info.withValues(alpha: .10),
                child: Icon(Icons.local_shipping_outlined, color: tokens.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (f.contatoResponsavel.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        f.contatoResponsavel,
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (f.documento.trim().isNotEmpty)
                          _metadata(Icons.badge_outlined, f.documento),
                        if (f.telefone.trim().isNotEmpty)
                          _metadata(Icons.phone_outlined, f.telefone),
                        if (f.email.trim().isNotEmpty)
                          _metadata(Icons.mail_outline_rounded, f.email),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: .25)),
                ),
                child: Text(
                  _t(f.ativo ? 'active' : 'inactive'),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_acesso.consultar)
                OutlinedButton.icon(
                  onPressed: () => _editar(f),
                  icon: Icon(
                    _acesso.editar
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(_t(_acesso.editar ? 'edit' : 'view')),
                  style: SixWebActionStyles.secondary(context),
                ),
            ],
          );
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 16), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _FornecedorEditor extends StatefulWidget {
  const _FornecedorEditor({
    this.atual,
    required this.onSave,
    required this.podeEditar,
    required this.podeAlterarAtivo,
  });
  final FornecedorUsuario? atual;
  final Future<FornecedorUsuario> Function(FornecedorUsuarioDraft draft) onSave;
  final bool podeEditar, podeAlterarAtivo;
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
      'nome': a?.nome ?? '',
      'documento': a?.documento ?? '',
      'telefone': a?.telefone ?? '',
      'email': a?.email ?? '',
      'cep': a?.cep ?? '',
      'logradouro': a?.logradouro ?? '',
      'numero': a?.numero ?? '',
      'complemento': a?.complemento ?? '',
      'bairro': a?.bairro ?? '',
      'cidade': a?.cidade ?? '',
      'uf': a?.uf ?? '',
      'pais': a?.pais ?? '',
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
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _valor(String chave) => _campos[chave]!.text;
  Widget _campo(
    String chave,
    String rotulo, {
    bool obrigatorio = false,
    TextInputType? teclado,
    int maxLines = 1,
  }) => TextFormField(
    key: Key('fornecedor-campo-$chave'),
    controller: _campos[chave],
    enabled: widget.podeEditar,
    keyboardType: teclado,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: rotulo,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final texto = value?.trim() ?? '';
      if (obrigatorio && texto.isEmpty) return 'Campo obrigatório';
      if (chave == 'email' && texto.isNotEmpty && !texto.contains('@'))
        return 'E-mail inválido';
      return null;
    },
  );

  Future<void> _salvar() async {
    if (!widget.podeEditar || !_formKey.currentState!.validate() || _salvando)
      return;
    setState(() => _salvando = true);
    try {
      final salvo = await widget.onSave(
        FornecedorUsuarioDraft(
          ativo: _ativo,
          tipoPessoa: _tipoPessoa,
          nome: _valor('nome'),
          documento: _valor('documento'),
          telefone: _valor('telefone'),
          email: _valor('email'),
          cep: _valor('cep'),
          logradouro: _valor('logradouro'),
          numero: _valor('numero'),
          complemento: _valor('complemento'),
          bairro: _valor('bairro'),
          cidade: _valor('cidade'),
          uf: _valor('uf'),
          pais: _valor('pais'),
          contatoResponsavel: _valor('contatoResponsavel'),
          condicoesPagamento: _valor('condicoesPagamento'),
          observacoes: _valor('observacoes'),
        ),
      );
      if (mounted) Navigator.of(context).pop(salvo);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.atual == null
                      ? 'Cadastrar fornecedor'
                      : 'Consultar / editar fornecedor',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'PJ',
                          label: Text('Pessoa jurídica'),
                        ),
                        ButtonSegment(
                          value: 'PF',
                          label: Text('Pessoa física'),
                        ),
                      ],
                      selected: {_tipoPessoa},
                      onSelectionChanged: widget.podeEditar
                          ? (selecionado) =>
                                setState(() => _tipoPessoa = selecionado.first)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _campo('nome', 'Nome / razão social *', obrigatorio: true),
                    const SizedBox(height: 12),
                    _campo('documento', 'Documento (CPF, CNPJ ou equivalente)'),
                    const SizedBox(height: 12),
                    _campo('contatoResponsavel', 'Contato responsável'),
                    const SizedBox(height: 12),
                    _campo(
                      'telefone',
                      'Telefone',
                      teclado: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      'email',
                      'E-mail',
                      teclado: TextInputType.emailAddress,
                    ),
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
                    Text(
                      'Condições comerciais',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _campo(
                      'condicoesPagamento',
                      'Condições de pagamento',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _campo('observacoes', 'Observações', maxLines: 3),
                    SwitchListTile.adaptive(
                      title: const Text('Fornecedor ativo'),
                      subtitle: const Text(
                        'Desative sem perder o histórico do cadastro.',
                      ),
                      value: _ativo,
                      onChanged: widget.podeAlterarAtivo
                          ? (v) => setState(() => _ativo = v)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Row(
            children: [
              TextButton(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const Spacer(),
              if (widget.podeEditar)
                FilledButton.icon(
                  key: const Key('fornecedor-salvar'),
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar fornecedor'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
