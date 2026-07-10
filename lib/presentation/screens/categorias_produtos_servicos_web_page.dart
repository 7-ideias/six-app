import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';

class CategoriasProdutosServicosWebPage extends StatefulWidget {
  const CategoriasProdutosServicosWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.apiClient,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final CategoriaCatalogoApiClient? apiClient;

  @override
  State<CategoriasProdutosServicosWebPage> createState() =>
      _CategoriasProdutosServicosWebPageState();
}

class _CategoriasProdutosServicosWebPageState
    extends State<CategoriasProdutosServicosWebPage> {
  late final CategoriaCatalogoApiClient _api;
  final TextEditingController _buscaController = TextEditingController();

  List<CategoriaCatalogoModel> _categorias = const <CategoriaCatalogoModel>[];
  String _busca = '';
  String? _filtroTipo;
  bool _somenteAtivas = false;
  bool _loading = false;
  String? _erro;

  List<CategoriaCatalogoModel> get _categoriasFiltradas {
    final String termo = _normalizarBusca(_busca);
    return _categorias.where((CategoriaCatalogoModel categoria) {
      final bool combinaTexto = termo.isEmpty ||
          _normalizarBusca(
            '${categoria.nome} ${categoria.descricao} ${_tipoLabel(categoria.tipo)}',
          ).contains(termo);
      final bool combinaTipo = _filtroTipo == null || categoria.tipo == _filtroTipo;
      final bool combinaStatus = !_somenteAtivas || categoria.ativo;
      return combinaTexto && combinaTipo && combinaStatus;
    }).toList(growable: false);
  }

  int get _ativas =>
      _categorias.where((CategoriaCatalogoModel item) => item.ativo).length;

  int get _produtos => _categorias.where((CategoriaCatalogoModel item) {
        return item.tipo == 'PRODUTO' || item.tipo == 'AMBOS';
      }).length;

  int get _servicos => _categorias.where((CategoriaCatalogoModel item) {
        return item.tipo == 'SERVICO' || item.tipo == 'AMBOS';
      }).length;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpCategoriaCatalogoApiClient();
    _recarregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final CategoriaCatalogoListResponse response = await _api.listarCategorias();
      if (!mounted) return;
      setState(() {
        _categorias = response.categorias;
        _loading = false;
      });
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = _mensagemErro(error.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar as categorias.';
      });
    }
  }

  String _mensagemErro(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos ou empresa não informada.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Usuário sem vínculo com a empresa.';
      case 409:
        return 'Esta categoria possui vínculo ou nome duplicado.';
      default:
        return 'Erro ao carregar categorias (HTTP $statusCode).';
    }
  }

  String _normalizarBusca(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _limparFiltros() {
    setState(() {
      _busca = '';
      _filtroTipo = null;
      _somenteAtivas = false;
      _buscaController.clear();
    });
  }

  Future<void> _abrirFormulario({CategoriaCatalogoModel? categoria}) async {
    final CategoriaCatalogoRequest? request = await showDialog<CategoriaCatalogoRequest>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _EscCloseScope(
        child: _CategoriaCatalogoDialog(categoria: categoria),
      ),
    );

    if (request == null) return;

    setState(() => _loading = true);
    try {
      if (categoria == null) {
        await _api.cadastrarCategoria(request);
      } else {
        await _api.atualizarCategoria(categoria.id, request);
      }
      if (!mounted) return;
      await _recarregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoria == null
                ? 'Categoria cadastrada com sucesso.'
                : 'Categoria atualizada com sucesso.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro(_mensagemErro(error.statusCode));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro('Não foi possível salvar a categoria.');
    }
  }

  Future<void> _confirmarExclusao(CategoriaCatalogoModel categoria) async {
    final bool confirmou = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return _EscCloseScope(
              child: AlertDialog(
                icon: const Icon(Icons.delete_outline_rounded),
                title: const Text('Excluir categoria'),
                content: Text(
                  categoria.itensVinculados > 0
                      ? 'Esta categoria possui ${categoria.itensVinculados} item(ns) vinculado(s). O backend bloqueará a exclusão para preservar a referência dos produtos/serviços.'
                      : 'Deseja remover a categoria "${categoria.nome}"?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _loading = true);
    try {
      await _api.apagarCategoria(categoria.id);
      if (!mounted) return;
      await _recarregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoria excluída com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro(_mensagemErro(error.statusCode));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro('Não foi possível excluir a categoria.');
    }
  }

  Future<void> _alternarStatus(CategoriaCatalogoModel categoria) async {
    final CategoriaCatalogoRequest request = CategoriaCatalogoRequest(
      nome: categoria.nome,
      descricao: categoria.descricao,
      tipo: categoria.tipo,
      ativo: !categoria.ativo,
    );

    setState(() => _loading = true);
    try {
      await _api.atualizarCategoria(categoria.id, request);
      if (!mounted) return;
      await _recarregar();
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro(_mensagemErro(error.statusCode));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro('Não foi possível alterar o status da categoria.');
    }
  }

  void _mostrarErro(String mensagem) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _EscCloseScope(
          child: AlertDialog(
            icon: const Icon(Icons.error_outline_rounded),
            title: const Text('Atenção'),
            content: Text(mensagem),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      children: <Widget>[_header(), Expanded(child: _body())],
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
      appBar: AppBar(title: const Text('Categorias')),
      body: SafeArea(child: closeAwareContent),
    );
  }

  Widget _header() {
    return SixWebDashboardHeader(
      icon: Icons.category_outlined,
      title: 'Categorias',
      subtitle:
          'Organize produtos e serviços por grupos comerciais, operacionais e de atendimento.',
      onBack: widget.onBack,
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: _loading ? null : _recarregar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : () => _abrirFormulario(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova categoria'),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading && _categorias.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 24 : 16,
          widget.embedded ? 24 : 16,
          widget.embedded ? 24 : 16,
          28,
        ),
        children: const <Widget>[
          SixWebLoadingBlock(height: 118),
          SizedBox(height: 18),
          SixWebLoadingBlock(height: 118),
          SizedBox(height: 18),
          SixWebLoadingBlock(height: 220),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _recarregar,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 24 : 16,
              widget.embedded ? 24 : 16,
              widget.embedded ? 24 : 16,
              widget.embedded ? 28 : 96,
            ),
            children: <Widget>[
              if (_erro != null) ...<Widget>[
                _inlineError(_erro!),
                const SizedBox(height: 18),
              ],
              SixWebEntry(order: 0, child: _kpis(compact)),
              const SizedBox(height: 18),
              SixWebEntry(order: 2, child: _filtros(compact)),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Categorias encontradas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Chip(label: Text('${_categoriasFiltradas.length}')),
                ],
              ),
              const SizedBox(height: 12),
              if (_categoriasFiltradas.isEmpty)
                const SixWebNoData(text: 'Nenhuma categoria encontrada.')
              else
                ...List<Widget>.generate(_categoriasFiltradas.length, (int index) {
                  final CategoriaCatalogoModel categoria = _categoriasFiltradas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SixWebEntry(
                      order: 3 + index,
                      child: _categoriaCard(categoria, compact: compact),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _inlineError(String mensagem) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpis(bool compact) {
    final List<_CategoriaMetric> metrics = <_CategoriaMetric>[
      _CategoriaMetric(
        icon: Icons.category_outlined,
        label: 'Categorias',
        value: _categorias.length.toDouble(),
      ),
      _CategoriaMetric(
        icon: Icons.verified_outlined,
        label: 'Ativas',
        value: _ativas.toDouble(),
      ),
      _CategoriaMetric(
        icon: Icons.inventory_2_outlined,
        label: 'Para produtos',
        value: _produtos.toDouble(),
      ),
      _CategoriaMetric(
        icon: Icons.design_services_outlined,
        label: 'Para serviços',
        value: _servicos.toDouble(),
        highlight: true,
      ),
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
      itemBuilder: (BuildContext context, int index) {
        final _CategoriaMetric metric = metrics[index];
        return SixWebKpiCard(
          icon: metric.icon,
          label: metric.label,
          value: metric.value,
          formatter: (double value) => value.round().toString(),
          highlight: metric.highlight,
        );
      },
    );
  }

  Widget _filtros(bool compact) {
    return SixWebSectionCard(
      title: 'Busca e filtros',
      subtitle:
          'Encontre categorias por nome, descrição ou tipo de uso no catálogo.',
      icon: Icons.search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: compact ? double.infinity : 420,
                child: TextField(
                  controller: _buscaController,
                  onChanged: (String value) => setState(() => _busca = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    labelText: 'Buscar categoria',
                    hintText: 'Ex.: peças, assistência, acessórios...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              FilterChip(
                selected: _somenteAtivas,
                label: const Text('Somente ativas'),
                avatar: const Icon(Icons.check_circle_outline, size: 18),
                onSelected: (bool value) => setState(() => _somenteAtivas = value),
              ),
              OutlinedButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ChoiceChip(
                selected: _filtroTipo == null,
                label: const Text('Todas'),
                onSelected: (_) => setState(() => _filtroTipo = null),
              ),
              ...<String>['PRODUTO', 'SERVICO', 'AMBOS'].map(
                (String tipo) => ChoiceChip(
                  selected: _filtroTipo == tipo,
                  avatar: Icon(_tipoIcon(tipo), size: 18),
                  label: Text(_tipoLabel(tipo)),
                  onSelected: (_) => setState(() => _filtroTipo = tipo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoriaCard(
    CategoriaCatalogoModel categoria, {
    required bool compact,
  }) {
    final ThemeData theme = Theme.of(context);
    final Widget leading = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(_tipoIcon(categoria.tipo), color: theme.colorScheme.primary),
    );

    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                categoria.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (!compact) ...<Widget>[
              const SizedBox(width: 12),
              _statusChip(categoria.ativo),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          categoria.descricao.isEmpty ? 'Sem descrição cadastrada.' : categoria.descricao,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _tipoChip(categoria.tipo),
            _infoPill(
              icon: Icons.link_rounded,
              label: '${categoria.itensVinculados} item(ns)',
            ),
            if (categoria.atualizadoEm != null)
              _infoPill(
                icon: Icons.schedule_outlined,
                label: _formatarData(categoria.atualizadoEm!),
              ),
            if (compact) _statusChip(categoria.ativo),
          ],
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _alternarStatus(categoria),
          icon: Icon(
            categoria.ativo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          label: Text(categoria.ativo ? 'Desativar' : 'Ativar'),
        ),
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _abrirFormulario(categoria: categoria),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        IconButton.outlined(
          onPressed: _loading ? null : () => _confirmarExclusao(categoria),
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );

    return _HoverableCategoriaCard(
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    leading,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                leading,
                const SizedBox(width: 16),
                Expanded(child: details),
                const SizedBox(width: 18),
                actions,
              ],
            ),
    );
  }

  Widget _statusChip(bool ativo) {
    final ThemeData theme = Theme.of(context);
    final Color color = ativo ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant;
    return Chip(
      avatar: Icon(
        ativo ? Icons.check_circle_outline : Icons.pause_circle_outline,
        size: 18,
        color: color,
      ),
      label: Text(ativo ? 'Ativa' : 'Inativa'),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      side: BorderSide(color: color.withValues(alpha: 0.22)),
      backgroundColor: color.withValues(alpha: 0.07),
    );
  }

  Widget _tipoChip(String tipo) {
    final ThemeData theme = Theme.of(context);
    return Chip(
      avatar: Icon(_tipoIcon(tipo), size: 18, color: theme.colorScheme.primary),
      label: Text(_tipoLabel(tipo)),
      labelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return 'Serviços';
      case 'AMBOS':
        return 'Produtos e serviços';
      case 'PRODUTO':
      default:
        return 'Produtos';
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return Icons.design_services_outlined;
      case 'AMBOS':
        return Icons.category_outlined;
      case 'PRODUTO':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String _formatarData(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    final String ano = data.year.toString();
    return '$dia/$mes/$ano';
  }
}

class _HoverableCategoriaCard extends StatefulWidget {
  const _HoverableCategoriaCard({required this.child});

  final Widget child;

  @override
  State<_HoverableCategoriaCard> createState() => _HoverableCategoriaCardState();
}

class _HoverableCategoriaCardState extends State<_HoverableCategoriaCard> {
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
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered
              ? theme.colorScheme.primary.withValues(alpha: 0.025)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.30)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: _hovered ? 0.10 : 0.05),
              blurRadius: _hovered ? 18.0 : 14.0,
              offset: Offset(0, _hovered ? 8.0 : 6.0),
            ),
          ],
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

class _CategoriaCatalogoDialog extends StatefulWidget {
  const _CategoriaCatalogoDialog({this.categoria});

  final CategoriaCatalogoModel? categoria;

  @override
  State<_CategoriaCatalogoDialog> createState() => _CategoriaCatalogoDialogState();
}

class _CategoriaCatalogoDialogState extends State<_CategoriaCatalogoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late String _tipo;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    final CategoriaCatalogoModel? categoria = widget.categoria;
    _nomeController = TextEditingController(text: categoria?.nome ?? '');
    _descricaoController = TextEditingController(text: categoria?.descricao ?? '');
    _tipo = categoria?.tipo ?? 'PRODUTO';
    _ativo = categoria?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      CategoriaCatalogoRequest(
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        tipo: _tipo,
        ativo: _ativo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool editando = widget.categoria != null;
    return AlertDialog(
      icon: Icon(
        editando ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
        color: theme.colorScheme.primary,
      ),
      title: Text(editando ? 'Editar categoria' : 'Nova categoria'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da categoria',
                  hintText: 'Ex.: Peças de reposição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da categoria.';
                  }
                  if (value.trim().length < 3) {
                    return 'Use pelo menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva quando esta categoria deve ser usada.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: InputDecoration(
                  labelText: 'Uso da categoria',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'PRODUTO', child: Text('Produtos')),
                  DropdownMenuItem(value: 'SERVICO', child: Text('Serviços')),
                  DropdownMenuItem(value: 'AMBOS', child: Text('Produtos e serviços')),
                ],
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _tipo = value);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _ativo,
                title: const Text('Categoria ativa'),
                subtitle: const Text(
                  'Categorias inativas podem continuar visíveis para histórico.',
                ),
                onChanged: (bool value) => setState(() => _ativo = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CategoriaMetric {
  const _CategoriaMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final double value;
  final bool highlight;
}
