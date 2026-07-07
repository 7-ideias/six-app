import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../components/web_dashboard_widgets.dart';
import 'colaborador_convite_web_body.dart';

class ColaboradoresUsuarioListPage extends StatefulWidget {
  const ColaboradoresUsuarioListPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.apiClient,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final ColaboradorUsuarioApiClient? apiClient;

  @override
  State<ColaboradoresUsuarioListPage> createState() =>
      _ColaboradoresUsuarioListPageState();
}

class _ColaboradoresUsuarioListPageState
    extends State<ColaboradoresUsuarioListPage> {
  late final ColaboradorUsuarioApiClient _api;
  final TextEditingController _search = TextEditingController();
  final NumberFormat _number = NumberFormat.decimalPattern('pt_BR');

  bool _loading = false;
  String? _erro;
  List<ColaboradorUsuarioResumo> _colaboradores = <ColaboradorUsuarioResumo>[];
  String _filter = '';

  List<ColaboradorUsuarioResumo> get _items {
    final String term = _filter
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (term.isEmpty) return _colaboradores;
    return _colaboradores.where((ColaboradorUsuarioResumo c) {
      final String source = '${c.nome} ${c.nomeDeGuerra} ${c.email} ${c.celularDeAcesso}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return source.contains(term);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpColaboradorUsuarioApiClient();
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
      final List<ColaboradorUsuarioResumo> data =
          await _api.listarColaboradores();
      if (!mounted) return;
      setState(() {
        _colaboradores = data;
        _loading = false;
      });
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _message(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar a lista de colaboradores.';
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
      default:
        return 'Erro ao carregar colaboradores (HTTP $code).';
    }
  }

  Future<void> _openNovoColaborador() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;
        return _EscCloseScope(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: SizedBox(
              width: size.width * 0.78,
              height: size.height * 0.84,
              child: const ColaboradorConviteWebBody(),
            ),
          ),
        );
      },
    );

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openEditar(ColaboradorUsuarioResumo resumo) async {
    try {
      final ColaboradorUsuarioDetalhe detalhe =
          await _api.buscarColaborador(resumo.idUnicoPessoal);
      if (!mounted) return;

      final Map<String, dynamic>? payload = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return _EscCloseScope(
            child: _EditarColaboradorDialog(
              resumo: resumo,
              detalhe: detalhe,
            ),
          );
        },
      );

      if (payload == null) {
        return;
      }

      await _api.editarColaborador(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador atualizado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(error.statusCode)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      children: <Widget>[
        _header(),
        Expanded(child: _body()),
      ],
    );
    final Widget closeAwareContent = widget.onBack == null
        ? content
        : _EscCloseScope(onEscape: widget.onBack, child: content);

    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: closeAwareContent,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(child: closeAwareContent),
    );
  }

  Widget _header() {
    return SixWebDashboardHeader(
      icon: Icons.badge_outlined,
      title: 'Colaboradores',
      subtitle:
          'Gestão de colaboradores, convites, contatos e permissões de acesso por comércio.',
      onBack: widget.onBack,
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: _loading ? null : _reload,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _openNovoColaborador,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Novo colaborador'),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading && _colaboradores.isEmpty) {
      return const _LoadingColaboradores();
    }

    if (_erro != null && _colaboradores.isEmpty) {
      return _errorState();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 24 : 16,
              widget.embedded ? 24 : 14,
              widget.embedded ? 24 : 16,
              widget.embedded ? 28 : 96,
            ),
            children: <Widget>[
              SixWebEntry(order: 0, child: _kpis(compact)),
              const SizedBox(height: 18),
              SixWebEntry(order: 4, child: _searchSection()),
              if (_erro != null) ...<Widget>[
                const SizedBox(height: 14),
                _inlineError(_erro!),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Colaboradores encontrados',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Chip(label: Text('${_items.length}')),
                ],
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty) _empty() else ..._items.map(_card),
            ],
          );
        },
      ),
    );
  }

  Widget _kpis(bool compact) {
    final int comEmail = _colaboradores.where((ColaboradorUsuarioResumo c) => c.email.trim().isNotEmpty).length;
    final int comCelular = _colaboradores.where((ColaboradorUsuarioResumo c) => c.celularDeAcesso.trim().isNotEmpty).length;
    final int semNome = _colaboradores.where((ColaboradorUsuarioResumo c) => c.nome.trim().isEmpty).length;

    final List<_Metric> metrics = <_Metric>[
      _Metric(Icons.groups_2_outlined, 'Colaboradores cadastrados', _colaboradores.length.toDouble()),
      _Metric(Icons.alternate_email_rounded, 'Com e-mail', comEmail.toDouble()),
      _Metric(Icons.phone_iphone_rounded, 'Com celular', comCelular.toDouble()),
      _Metric(Icons.manage_accounts_outlined, 'Cadastro incompleto', semNome.toDouble(), semNome > 0),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 118,
      ),
      itemBuilder: (_, int index) {
        final _Metric metric = metrics[index];
        return SixWebKpiCard(
          icon: metric.icon,
          label: metric.label,
          value: metric.value,
          formatter: (double value) => _number.format(value.round()),
          highlight: metric.highlight,
        );
      },
    );
  }

  Widget _searchSection() {
    return SixWebSectionCard(
      title: 'Busca e filtros',
      subtitle: 'Encontre rapidamente por nome, e-mail, celular ou apelido.',
      icon: Icons.search_rounded,
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: 'Buscar nome, e-mail, celular ou apelido...',
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

  Widget _card(ColaboradorUsuarioResumo colaborador) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SixWebEntry(
        order: 6,
        child: _HoverableColaboradorCard(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;
              final Widget data = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.10),
                    child: Text(
                      _initials(colaborador.nome),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                colaborador.nome.isEmpty ? 'Colaborador sem nome' : colaborador.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            _status('Ativo', Colors.green.shade700),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          colaborador.nomeDeGuerra.isEmpty ? 'Sem nome de guerra' : colaborador.nomeDeGuerra,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _info(Icons.mail_outline, colaborador.email.isEmpty ? 'Sem e-mail' : colaborador.email),
                            _info(Icons.phone_outlined, colaborador.celularDeAcesso.isEmpty ? 'Sem celular' : colaborador.celularDeAcesso),
                            _info(Icons.badge_outlined, colaborador.idUnicoPessoal),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _accessHint(colaborador),
                      ],
                    ),
                  ),
                ],
              );

              final Widget buttons = compact
                  ? Row(
                      children: <Widget>[
                        Expanded(child: _detailButton(colaborador)),
                        const SizedBox(width: 10),
                        Expanded(child: _editButton(colaborador)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _detailButton(colaborador),
                        const SizedBox(height: 10),
                        _editButton(colaborador),
                      ],
                    );

              return compact
                  ? Column(children: <Widget>[data, const SizedBox(height: 14), buttons])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: data),
                        const SizedBox(width: 16),
                        SizedBox(width: 210, child: buttons),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailButton(ColaboradorUsuarioResumo colaborador) {
    return OutlinedButton.icon(
      onPressed: () => _showDetails(colaborador),
      icon: const Icon(Icons.info_outline_rounded, size: 18),
      label: const Text('Resumo'),
    );
  }

  Widget _editButton(ColaboradorUsuarioResumo colaborador) {
    return FilledButton.icon(
      onPressed: () => _openEditar(colaborador),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Editar'),
    );
  }

  Widget _accessHint(ColaboradorUsuarioResumo colaborador) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.admin_panel_settings_outlined, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              colaborador.email.isEmpty
                  ? 'Informe um e-mail para permitir vínculo de acesso ao sistema.'
                  : 'Acesso controlado por convite e permissões da empresa ativa.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _info(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _empty() {
    return SixWebSectionCard(
      title: 'Nenhum colaborador cadastrado',
      subtitle: 'Convide colaboradores para operar vendas, atendimento técnico e rotinas do comércio com permissões controladas.',
      icon: Icons.group_add_outlined,
      child: FilledButton.icon(
        onPressed: _openNovoColaborador,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Novo colaborador'),
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
            const Icon(Icons.cloud_off_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Não foi possível carregar os colaboradores.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.35),
      ),
      child: Text(message),
    );
  }

  void _showDetails(ColaboradorUsuarioResumo colaborador) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EscCloseScope(
        child: AlertDialog(
          title: Text(colaborador.nome.isEmpty ? 'Colaborador' : colaborador.nome),
          content: Text(
            'Nome de guerra: ${colaborador.nomeDeGuerra.isEmpty ? '-' : colaborador.nomeDeGuerra}\n'
            'Celular: ${colaborador.celularDeAcesso.isEmpty ? '-' : colaborador.celularDeAcesso}\n'
            'E-mail: ${colaborador.email.isEmpty ? '-' : colaborador.email}\n'
            'Identificador: ${colaborador.idUnicoPessoal}',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) return 'CO';
    return parts.length == 1 ? parts.first[0].toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _HoverableColaboradorCard extends StatefulWidget {
  const _HoverableColaboradorCard({required this.child});

  final Widget child;

  @override
  State<_HoverableColaboradorCard> createState() => _HoverableColaboradorCardState();
}

class _HoverableColaboradorCardState extends State<_HoverableColaboradorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovered
              ? theme.colorScheme.primary.withOpacity(0.025)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withOpacity(0.30)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: _hovered
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: widget.child,
      ),
    );
  }
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class _EscCloseScope extends StatelessWidget {
  const _EscCloseScope({required this.child, this.onEscape});

  final Widget child;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _CloseDialogIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
            onInvoke: (_) {
              final VoidCallback? handler = onEscape;
              if (handler != null) {
                handler();
              } else {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _EditarColaboradorDialog extends StatefulWidget {
  const _EditarColaboradorDialog({
    required this.resumo,
    required this.detalhe,
  });

  final ColaboradorUsuarioResumo resumo;
  final ColaboradorUsuarioDetalhe detalhe;

  @override
  State<_EditarColaboradorDialog> createState() => _EditarColaboradorDialogState();
}

class _EditarColaboradorDialogState extends State<_EditarColaboradorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _nomeDeGuerra;
  late final TextEditingController _email;
  late final TextEditingController _celular;

  bool _podeVender = false;
  bool _podeServico = false;
  bool _podeEditarCliente = false;
  bool _podeRelatorio = false;
  bool _podeFinanceiro = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.detalhe.nome.isNotEmpty ? widget.detalhe.nome : widget.resumo.nome);
    _nomeDeGuerra = TextEditingController(text: widget.detalhe.nomeDeGuerra.isNotEmpty ? widget.detalhe.nomeDeGuerra : widget.resumo.nomeDeGuerra);
    _email = TextEditingController(text: widget.detalhe.email.isNotEmpty ? widget.detalhe.email : widget.resumo.email);
    _celular = TextEditingController(text: widget.detalhe.celularDeAcesso.isNotEmpty ? widget.detalhe.celularDeAcesso : widget.resumo.celularDeAcesso);

    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> autorizacoes = _ensureMap(json['objAutorizacoes']);
    _podeVender = _ensureMap(autorizacoes['objVendasPode'])['fazVenda'] == true;
    _podeServico = _ensureMap(autorizacoes['objAssistenciaTecnicaPode'])['lancaServico'] == true;
    _podeEditarCliente = _ensureMap(autorizacoes['objClientesPode'])['podeEditarCliente'] == true;
    _podeRelatorio = _ensureMap(autorizacoes['objRelatoriosPode'])['geraRelatorioDeVendas'] == true;
    final Map<String, dynamic> financeiro = _ensureMap(autorizacoes['objLancamentosFinanceirosPode']);
    _podeFinanceiro = financeiro['podeReceberNoCaixa'] == true || financeiro['podeVerQuantoVendeu'] == true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _nomeDeGuerra.dispose();
    _email.dispose();
    _celular.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> info = _ensureMap(json['objInformacoesDoCadastro']);
    info['idUnicoDoUsuario'] = widget.resumo.idUnicoPessoal;
    json['objInformacoesDoCadastro'] = info;
    json['celularDeAcesso'] = _celular.text.trim();
    json['senhaParaPermitirOAcessoDoColaborador'] = null;

    final Map<String, dynamic> pessoa = _ensureMap(json['objPessoa']);
    pessoa['nome'] = _nome.text.trim();
    pessoa['nomeDeGuerra'] = _nomeDeGuerra.text.trim();
    pessoa['email'] = _email.text.trim();
    pessoa['celular'] = _celular.text.trim();
    pessoa['senha'] = null;
    json['objPessoa'] = pessoa;

    final Map<String, dynamic> autorizacoes = _ensureMap(json['objAutorizacoes']);
    autorizacoes['podeCadastrarProduto'] = autorizacoes['podeCadastrarProduto'] ?? false;
    autorizacoes['podeFazerDevolucao'] = autorizacoes['podeFazerDevolucao'] ?? false;
    autorizacoes['objVendasPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objVendasPode']),
      'fazVenda': _podeVender,
    };
    autorizacoes['objAssistenciaTecnicaPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objAssistenciaTecnicaPode']),
      'lancaServico': _podeServico,
    };
    autorizacoes['objClientesPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objClientesPode']),
      'podeEditarCliente': _podeEditarCliente,
    };
    autorizacoes['objRelatoriosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objRelatoriosPode']),
      'geraRelatorioDeVendas': _podeRelatorio,
    };
    autorizacoes['objLancamentosFinanceirosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objLancamentosFinanceirosPode']),
      'podeReceberNoCaixa': _podeFinanceiro,
      'podeVerQuantoVendeu': _podeFinanceiro,
    };
    json['objAutorizacoes'] = autorizacoes;
    return json;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Editar colaborador'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: 310,
                      child: TextFormField(
                        controller: _nome,
                        decoration: _input('Nome', Icons.person_outline),
                        validator: (String? value) => value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                      ),
                    ),
                    SizedBox(
                      width: 310,
                      child: TextFormField(
                        controller: _nomeDeGuerra,
                        decoration: _input('Nome de guerra', Icons.badge_outlined),
                      ),
                    ),
                    SizedBox(
                      width: 310,
                      child: TextFormField(
                        controller: _email,
                        decoration: _input('E-mail', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(
                      width: 310,
                      child: TextFormField(
                        controller: _celular,
                        decoration: _input('Celular', Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Permissões operacionais', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _switchTile('Vendas', 'Pode realizar vendas no comércio.', _podeVender, (bool value) => setState(() => _podeVender = value)),
                _switchTile('Assistência técnica', 'Pode lançar serviços técnicos.', _podeServico, (bool value) => setState(() => _podeServico = value)),
                _switchTile('Clientes', 'Pode editar dados de clientes.', _podeEditarCliente, (bool value) => setState(() => _podeEditarCliente = value)),
                _switchTile('Relatórios', 'Pode gerar relatórios de vendas.', _podeRelatorio, (bool value) => setState(() => _podeRelatorio = value)),
                _switchTile('Financeiro', 'Pode acessar recebimentos e valores vendidos.', _podeFinanceiro, (bool value) => setState(() => _podeFinanceiro = value)),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_payload());
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar alterações'),
        ),
      ],
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }

  static Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class _LoadingColaboradores extends StatelessWidget {
  const _LoadingColaboradores();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        SixWebLoadingBlock(height: 118),
        SizedBox(height: 18),
        SixWebLoadingBlock(height: 124),
        SizedBox(height: 18),
        SixWebLoadingBlock(height: 172),
        SizedBox(height: 12),
        SixWebLoadingBlock(height: 172),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, [this.highlight = false]);

  final IconData icon;
  final String label;
  final double value;
  final bool highlight;
}
