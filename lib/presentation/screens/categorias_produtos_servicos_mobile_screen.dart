import 'package:flutter/material.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

class CategoriasProdutosServicosMobileScreen extends StatefulWidget {
  const CategoriasProdutosServicosMobileScreen({super.key, this.apiClient});

  final CategoriaCatalogoApiClient? apiClient;

  @override
  State<CategoriasProdutosServicosMobileScreen> createState() =>
      _CategoriasProdutosServicosMobileScreenState();
}

class _CategoriasProdutosServicosMobileScreenState
    extends State<CategoriasProdutosServicosMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  late final CategoriaCatalogoApiClient _api;
  final TextEditingController _buscaController = TextEditingController();

  List<CategoriaCatalogoModel> _categorias = const <CategoriaCatalogoModel>[];
  bool _loading = false;
  String? _erro;
  String _busca = '';
  String? _filtroTipo;
  bool _houveMudanca = false;

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

  List<CategoriaCatalogoModel> get _categoriasFiltradas {
    final String termo = _normalizarBusca(_busca);
    return _categorias
        .where((CategoriaCatalogoModel categoria) {
          final bool combinaTexto =
              termo.isEmpty ||
              _normalizarBusca(
                '${categoria.nome} ${categoria.descricao}',
              ).contains(termo);
          final bool combinaTipo =
              _filtroTipo == null || categoria.tipo == _filtroTipo;
          return combinaTexto && combinaTipo;
        })
        .toList(growable: false);
  }

  String _normalizarBusca(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
        return 'Categoria vinculada ou nome já existente.';
      default:
        return 'Erro ao processar categorias (HTTP $statusCode).';
    }
  }

  Future<void> _recarregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final CategoriaCatalogoListResponse response =
          await _api.listarCategorias();
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

  Future<void> _abrirFormulario({CategoriaCatalogoModel? categoria}) async {
    final CategoriaCatalogoRequest? request =
        await showModalBottomSheet<CategoriaCatalogoRequest>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _CategoriaCatalogoFormSheet(categoria: categoria);
          },
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
      setState(() => _houveMudanca = true);
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
      setState(() => _houveMudanca = true);
      await _recarregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoria.ativo
                ? 'Categoria desativada com sucesso.'
                : 'Categoria ativada com sucesso.',
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
      _mostrarErro('Não foi possível alterar o status da categoria.');
    }
  }

  Future<void> _confirmarExclusao(CategoriaCatalogoModel categoria) async {
    final bool confirmou =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Excluir categoria'),
              content: Text(
                'Deseja excluir "${categoria.nome}"? '
                'Se houver vínculo com produtos/serviços, o backend pode bloquear.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmou) return;

    setState(() => _loading = true);
    try {
      await _api.apagarCategoria(categoria.id);
      if (!mounted) return;
      setState(() => _houveMudanca = true);
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
      if (error.statusCode == 409) {
        _mostrarErro(
          'Não foi possível excluir: categoria vinculada a itens. '
          'Desative a categoria para manter os vínculos existentes.',
        );
        return;
      }
      _mostrarErro(_mensagemErro(error.statusCode));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro('Não foi possível excluir a categoria.');
    }
  }

  Future<void> _abrirAcoes(CategoriaCatalogoModel categoria) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar'),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
                ListTile(
                  leading: Icon(
                    categoria.ativo
                        ? Icons.toggle_off_outlined
                        : Icons.toggle_on_outlined,
                  ),
                  title: Text(categoria.ativo ? 'Desativar' : 'Ativar'),
                  onTap: () => Navigator.of(context).pop('toggle'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB91C1C),
                  ),
                  title: const Text(
                    'Excluir',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        await _abrirFormulario(categoria: categoria);
        break;
      case 'toggle':
        await _alternarStatus(categoria);
        break;
      case 'delete':
        await _confirmarExclusao(categoria);
        break;
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return 'Serviço';
      case 'AMBOS':
        return 'Ambos';
      default:
        return 'Produto';
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return const Color(0xFF0EA5E9);
      case 'AMBOS':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Widget _buildChipTipo(String? tipo, String label) {
    final bool selected = _filtroTipo == tipo;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      side: BorderSide(
        color: selected ? _accentColor : const Color(0xFFE2E8F0),
      ),
      selectedColor: const Color(0xFFDCEBFF),
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _filtroTipo = tipo),
      labelStyle: TextStyle(
        color: selected ? _accentColor : _mutedTextColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCardCategoria(CategoriaCatalogoModel categoria, int index) {
    return SixStaggeredEntry(
      delay: Duration(milliseconds: 70 + (index * 35)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: _tipoColor(categoria.tipo),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        categoria.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        categoria.descricao.trim().isEmpty
                            ? 'Sem descrição'
                            : categoria.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Ações',
                  onPressed: _loading ? null : () => _abrirAcoes(categoria),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _TagPill(
                  label: _tipoLabel(categoria.tipo),
                  textColor: _tipoColor(categoria.tipo),
                  backgroundColor: _tipoColor(
                    categoria.tipo,
                  ).withValues(alpha: 0.12),
                ),
                _TagPill(
                  label: categoria.ativo ? 'Ativa' : 'Inativa',
                  textColor:
                      categoria.ativo
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                  backgroundColor:
                      categoria.ativo
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                ),
                if (categoria.itensVinculados >= 0)
                  _TagPill(
                    label: '${categoria.itensVinculados} vinculados',
                    textColor: const Color(0xFF334155),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Categorias',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_categoriasFiltradas.length} categoria(s) exibida(s)',
            style: const TextStyle(color: _mutedTextColor, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _buscaController,
            onChanged: (String value) => setState(() => _busca = value),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou descrição',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  _busca.isEmpty
                      ? null
                      : IconButton(
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _busca = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accentColor, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildChipTipo(null, 'Todos'),
              _buildChipTipo('PRODUTO', 'Produto'),
              _buildChipTipo('SERVICO', 'Serviço'),
              _buildChipTipo('AMBOS', 'Ambos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _categorias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null && _categorias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C)),
              const SizedBox(height: 10),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _titleTextColor),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: <Widget>[
          SixStaggeredEntry(child: _buildHeaderCard()),
          const SizedBox(height: 14),
          if (_categoriasFiltradas.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(Icons.category_outlined, color: _mutedTextColor),
                  SizedBox(height: 10),
                  Text(
                    'Nenhuma categoria encontrada.',
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List<Widget>.generate(_categoriasFiltradas.length, (int index) {
              return _buildCardCategoria(_categoriasFiltradas[index], index);
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_houveMudanca);
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_houveMudanca),
          ),
          title: const Text(
            'Categorias',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              _buildBody(),
              if (_loading && _categorias.isNotEmpty)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _abrirFormulario(),
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova categoria'),
        ),
      ),
    );
  }
}

class _CategoriaCatalogoFormSheet extends StatefulWidget {
  const _CategoriaCatalogoFormSheet({this.categoria});

  final CategoriaCatalogoModel? categoria;

  @override
  State<_CategoriaCatalogoFormSheet> createState() =>
      _CategoriaCatalogoFormSheetState();
}

class _CategoriaCatalogoFormSheetState
    extends State<_CategoriaCatalogoFormSheet> {
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
    _descricaoController = TextEditingController(
      text: categoria?.descricao ?? '',
    );
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
    if (!_formKey.currentState!.validate()) return;

    final CategoriaCatalogoRequest request = CategoriaCatalogoRequest(
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      tipo: _tipo,
      ativo: _ativo,
    );
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.categoria != null;
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      editando ? 'Editar categoria' : 'Nova categoria',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da categoria.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Opcional',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Uso da categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'PRODUTO',
                        child: Text('Produto'),
                      ),
                      DropdownMenuItem(
                        value: 'SERVICO',
                        child: Text('Serviço'),
                      ),
                      DropdownMenuItem(value: 'AMBOS', child: Text('Ambos')),
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
                    onChanged: (bool value) => setState(() => _ativo = value),
                    title: const Text('Categoria ativa'),
                    subtitle: const Text(
                      'Categorias inativas ficam indisponíveis no cadastro.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _salvar,
                          child: Text(editando ? 'Salvar' : 'Cadastrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
