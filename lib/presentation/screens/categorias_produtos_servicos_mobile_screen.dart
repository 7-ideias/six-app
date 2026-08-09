import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class CategoriasProdutosServicosMobileScreen extends StatefulWidget {
  const CategoriasProdutosServicosMobileScreen({super.key, this.apiClient});

  final CategoriaCatalogoApiClient? apiClient;

  @override
  State<CategoriasProdutosServicosMobileScreen> createState() =>
      _CategoriasProdutosServicosMobileScreenState();
}

class _CategoriasProdutosServicosMobileScreenState
    extends State<CategoriasProdutosServicosMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _errorColor => SixMobilePalette.error;
  static const Color _successColor = Color(0xFF15803D);
  static const Color _serviceColor = Color(0xFF0EA5E9);
  static const Color _mixedColor = Color(0xFF7C3AED);

  late final CategoriaCatalogoApiClient _api;
  final TextEditingController _buscaController = TextEditingController();

  List<CategoriaCatalogoModel> _categorias = <CategoriaCatalogoModel>[];
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
        return context.t(
          'catalogCategories.errors.invalidCompany',
          fallback: 'Dados inválidos ou empresa não informada.',
        );
      case 401:
        return context.t(
          'catalogCategories.errors.sessionExpired',
          fallback: 'Sessão expirada. Faça login novamente.',
        );
      case 403:
        return context.t(
          'catalogCategories.errors.companyAccessDenied',
          fallback: 'Usuário sem vínculo com a empresa.',
        );
      case 409:
        return context.t(
          'catalogCategories.errors.conflict',
          fallback: 'Categoria vinculada ou nome já existente.',
        );
      default:
        final String prefix = context.t(
          'catalogCategories.errors.httpPrefix',
          fallback: 'Erro ao processar categorias',
        );
        return '$prefix (HTTP $statusCode).';
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
        _erro = context.t(
          'catalogCategories.errors.load',
          fallback: 'Não foi possível carregar as categorias.',
        );
      });
    }
  }

  Future<void> _abrirFormulario({CategoriaCatalogoModel? categoria}) async {
    final CategoriaCatalogoRequest? request =
        await showModalBottomSheet<CategoriaCatalogoRequest>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          useSafeArea: true,
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
                ? context.t(
                  'catalogCategories.feedback.created',
                  fallback: 'Categoria cadastrada com sucesso.',
                )
                : context.t(
                  'catalogCategories.feedback.updated',
                  fallback: 'Categoria atualizada com sucesso.',
                ),
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
      _mostrarErro(
        context.t(
          'catalogCategories.errors.save',
          fallback: 'Não foi possível salvar a categoria.',
        ),
      );
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
                ? context.t(
                  'catalogCategories.feedback.disabled',
                  fallback: 'Categoria desativada com sucesso.',
                )
                : context.t(
                  'catalogCategories.feedback.enabled',
                  fallback: 'Categoria ativada com sucesso.',
                ),
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
      _mostrarErro(
        context.t(
          'catalogCategories.errors.toggleStatus',
          fallback: 'Não foi possível alterar o status da categoria.',
        ),
      );
    }
  }

  Future<void> _confirmarExclusao(CategoriaCatalogoModel categoria) async {
    final bool confirmou =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.44),
          useSafeArea: true,
          builder: (BuildContext dialogContext) {
            return _ConfirmDeleteCategorySheet(
              categoryName: categoria.nome,
              onCancel: () => Navigator.of(dialogContext).pop(false),
              onConfirm: () => Navigator.of(dialogContext).pop(true),
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
        SnackBar(
          content: Text(
            context.t(
              'catalogCategories.feedback.deleted',
              fallback: 'Categoria excluída com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (error.statusCode == 409) {
        _mostrarErro(
          context.t(
            'catalogCategories.errors.deleteLinked',
            fallback:
                'Não foi possível excluir: categoria vinculada a itens. '
                'Desative a categoria para manter os vínculos existentes.',
          ),
        );
        return;
      }
      _mostrarErro(_mensagemErro(error.statusCode));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarErro(
        context.t(
          'catalogCategories.errors.delete',
          fallback: 'Não foi possível excluir a categoria.',
        ),
      );
    }
  }

  Future<void> _abrirAcoes(CategoriaCatalogoModel categoria) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      useSafeArea: true,
      builder: (BuildContext context) {
        return _CategoryActionsSheet(
          active: categoria.ativo,
          onEdit: () => Navigator.of(context).pop('edit'),
          onToggle: () => Navigator.of(context).pop('toggle'),
          onDelete: () => Navigator.of(context).pop('delete'),
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
        return context.t(
          'catalogCategories.types.service',
          fallback: 'Serviço',
        );
      case 'AMBOS':
        return context.t('catalogCategories.types.both', fallback: 'Ambos');
      default:
        return context.t(
          'catalogCategories.types.product',
          fallback: 'Produto',
        );
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return _serviceColor;
      case 'AMBOS':
        return _mixedColor;
      default:
        return _accentColor;
    }
  }

  String _formatarInteiro(int value) {
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    final String separator = localeSettings.thousandSeparator;
    final bool negative = value < 0;
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index += 1) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[index]);
    }

    return '${negative ? '-' : ''}${buffer.toString()}';
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    Offset beginOffset = const Offset(0, 0.08),
  }) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) return child;

    return SixStaggeredEntry(
      delay: delay,
      beginOffset: beginOffset,
      child: child,
    );
  }

  Widget _buildChipTipo(String? tipo, String label) {
    final bool selected = _filtroTipo == tipo;

    return ChoiceChip(
      selected: selected,
      label: Text(label, overflow: TextOverflow.ellipsis),
      avatar:
          selected
              ? Icon(Icons.check_rounded, size: 16)
              : tipo == null
              ? Icon(Icons.tune_rounded, size: 16)
              : null,
      side: BorderSide(color: selected ? _accentColor : _borderColor),
      selectedColor: _softAccentColor,
      backgroundColor: _surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => setState(() => _filtroTipo = tipo),
      labelStyle: TextStyle(
        color: selected ? _accentColor : _mutedTextColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildCardCategoria(CategoriaCatalogoModel categoria, int index) {
    final String descricao =
        categoria.descricao.trim().isEmpty
            ? context.t(
              'catalogCategories.emptyDescription',
              fallback: 'Sem descrição',
            )
            : categoria.descricao;
    final String linkedCount = _formatarInteiro(categoria.itensVinculados);

    return _entry(
      Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 12,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _softAccentColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tipoColor(categoria.tipo).withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: _tipoColor(categoria.tipo),
                    size: 20,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        categoria.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mutedTextColor, height: 1.35),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  tooltip: context.t(
                    'catalogCategories.actions.open',
                    fallback: 'Ações',
                  ),
                  onPressed: _loading ? null : () => _abrirAcoes(categoria),
                  icon: Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            SizedBox(height: 10),
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
                  label:
                      categoria.ativo
                          ? context.t(
                            'catalogCategories.status.active',
                            fallback: 'Ativa',
                          )
                          : context.t(
                            'catalogCategories.status.inactive',
                            fallback: 'Inativa',
                          ),
                  textColor: categoria.ativo ? _successColor : _errorColor,
                  backgroundColor:
                      categoria.ativo
                          ? _successColor.withValues(alpha: 0.12)
                          : _errorColor.withValues(alpha: 0.12),
                ),
                if (categoria.itensVinculados >= 0)
                  _TagPill(
                    label:
                        '$linkedCount ${context.t('catalogCategories.linkedItemsSuffix', fallback: 'vinculados')}',
                    textColor: _secondaryColor,
                    backgroundColor: _softSurfaceColor,
                  ),
              ],
            ),
          ],
        ),
      ),
      delay: Duration(milliseconds: 70 + (index * 35)),
    );
  }

  Widget _buildHeaderCard() {
    final String total = _formatarInteiro(_categoriasFiltradas.length);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('catalogCategories.title', fallback: 'Categorias'),
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '$total ${context.t('catalogCategories.visibleCountSuffix', fallback: 'categoria(s) exibida(s)')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _mutedTextColor, fontSize: 12.5),
          ),
          SizedBox(height: 14),
          TextField(
            controller: _buscaController,
            onChanged: (String value) => setState(() => _busca = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.t(
                'catalogCategories.searchHint',
                fallback: 'Buscar por nome ou descrição',
              ),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon:
                  _busca.isEmpty
                      ? null
                      : IconButton(
                        tooltip: context.t('common.clear', fallback: 'Limpar'),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _busca = '');
                        },
                        icon: Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: _softSurfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accentColor, width: 1.3),
              ),
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildChipTipo(
                null,
                context.t('catalogCategories.filters.all', fallback: 'Todos'),
              ),
              _buildChipTipo('PRODUTO', _tipoLabel('PRODUTO')),
              _buildChipTipo('SERVICO', _tipoLabel('SERVICO')),
              _buildChipTipo('AMBOS', _tipoLabel('AMBOS')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController, double topInset) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 96),
        children: <Widget>[
          AnimatedSwitcher(
            duration:
                reduceMotion ? Duration.zero : Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildState(),
          ),
        ],
      ),
    );
  }

  Widget _buildState() {
    if (_loading && _categorias.isEmpty) {
      return _buildLoadingState();
    }

    if (_erro != null && _categorias.isEmpty) {
      return _buildErrorState();
    }

    return Column(
      key: ValueKey<String>('catalog-categories-success'),
      children: <Widget>[
        _entry(_buildHeaderCard()),
        SizedBox(height: 14),
        if (_categoriasFiltradas.isEmpty)
          _buildEmptyState()
        else
          ...List<Widget>.generate(_categoriasFiltradas.length, (int index) {
            return _buildCardCategoria(_categoriasFiltradas[index], index);
          }),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Semantics(
      key: ValueKey<String>('catalog-categories-loading'),
      container: true,
      liveRegion: true,
      label: context.t(
        'catalogCategories.loading',
        fallback: 'Carregando categorias...',
      ),
      child: Column(
        children: <Widget>[
          _entry(_buildLoadingHeaderCard()),
          SizedBox(height: 14),
          ...List<Widget>.generate(
            3,
            (int index) => _entry(
              _buildLoadingCategoryCard(),
              delay: Duration(milliseconds: 80 + (index * 35)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SkeletonLine(width: 112, height: 18),
          SizedBox(height: 8),
          _SkeletonLine(width: 176, height: 12),
          SizedBox(height: 16),
          _SkeletonLine(width: double.infinity, height: 48),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SkeletonLine(width: 74, height: 34, radius: 999),
              _SkeletonLine(width: 88, height: 34, radius: 999),
              _SkeletonLine(width: 84, height: 34, radius: 999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCategoryCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.category_outlined, color: _accentColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SkeletonLine(width: 160, height: 15),
                SizedBox(height: 8),
                _SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SkeletonLine(width: 82, height: 24, radius: 999),
                    _SkeletonLine(width: 74, height: 24, radius: 999),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      key: ValueKey<String>('catalog-categories-error'),
      padding: EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: _errorColor),
          SizedBox(height: 10),
          Text(
            _erro!,
            textAlign: TextAlign.center,
            style: TextStyle(color: _titleTextColor, height: 1.35),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _recarregar,
            icon: Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: ValueKey<String>('catalog-categories-empty'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.category_outlined, color: _mutedTextColor),
          SizedBox(height: 10),
          Text(
            context.t(
              'catalogCategories.empty.title',
              fallback: 'Nenhuma categoria encontrada.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _busca.isEmpty && _filtroTipo == null
                ? context.t(
                  'catalogCategories.empty.description',
                  fallback:
                      'Cadastre uma categoria para organizar produtos e serviços.',
                )
                : context.t(
                  'catalogCategories.empty.filteredDescription',
                  fallback: 'Ajuste a busca ou os filtros para ver resultados.',
                ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.35),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.thousandSeparator}|${provider.languageCode}|${provider.countryCode}',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_houveMudanca);
      },
      child: SixMobilePageShell(
        title: context.t('catalogCategories.title', fallback: 'Categorias'),
        backgroundColor: _backgroundColor,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
        toolbarHeight: 48,
        initialContentSpacing: 8,
        scrollEffectOffset: 28,
        scrolledSurfaceOpacity: 0.70,
        leading: IconButton(
          tooltip: context.t('common.back', fallback: 'Voltar'),
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(_houveMudanca),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: context.t('common.refresh', fallback: 'Atualizar'),
            onPressed: _loading ? null : _recarregar,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
        bodyBuilder: (
          BuildContext context,
          ScrollController scrollController,
          double topInset,
        ) {
          return SafeArea(
            top: false,
            child: Stack(
              children: <Widget>[
                _buildBody(scrollController, topInset),
                if (_loading && _categorias.isNotEmpty)
                  Positioned(
                    top: topInset,
                    left: 16,
                    right: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    minimum: EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton.extended(
                      onPressed: _loading ? null : () => _abrirFormulario(),
                      backgroundColor: _accentColor,
                      foregroundColor: SixMobilePalette.onPrimary,
                      elevation: 5,
                      icon: Icon(Icons.add_rounded),
                      label: Text(
                        context.t(
                          'catalogCategories.newCategory',
                          fallback: 'Nova categoria',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return context.t(
          'catalogCategories.types.service',
          fallback: 'Serviço',
        );
      case 'AMBOS':
        return context.t('catalogCategories.types.both', fallback: 'Ambos');
      default:
        return context.t(
          'catalogCategories.types.product',
          fallback: 'Produto',
        );
    }
  }

  String _tipoSubtitle(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return context.t(
          'catalogCategories.types.serviceDesc',
          fallback: 'Usar em serviços e assistências.',
        );
      case 'AMBOS':
        return context.t(
          'catalogCategories.types.bothDesc',
          fallback: 'Usar em produtos e serviços.',
        );
      default:
        return context.t(
          'catalogCategories.types.productDesc',
          fallback: 'Usar no cadastro de produtos.',
        );
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'SERVICO':
        return Icons.build_circle_outlined;
      case 'AMBOS':
        return Icons.all_inclusive_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  OutlineInputBorder _inputBorder([Color? color]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color ?? SixMobilePalette.border),
    );
  }

  Future<void> _abrirTipoSelector() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return _CategoryTypeSelectorSheet(
          selectedType: _tipo,
          options: <_CategoryTypeOption>[
            _CategoryTypeOption(
              value: 'PRODUTO',
              title: _tipoLabel('PRODUTO'),
              subtitle: _tipoSubtitle('PRODUTO'),
              icon: _tipoIcon('PRODUTO'),
            ),
            _CategoryTypeOption(
              value: 'SERVICO',
              title: _tipoLabel('SERVICO'),
              subtitle: _tipoSubtitle('SERVICO'),
              icon: _tipoIcon('SERVICO'),
            ),
            _CategoryTypeOption(
              value: 'AMBOS',
              title: _tipoLabel('AMBOS'),
              subtitle: _tipoSubtitle('AMBOS'),
              icon: _tipoIcon('AMBOS'),
            ),
          ],
        );
      },
    );

    if (selected == null || selected == _tipo) return;
    setState(() => _tipo = selected);
  }

  Widget _buildTipoField() {
    return Semantics(
      button: true,
      label: context.t(
        'catalogCategories.form.typeField',
        fallback: 'Uso da categoria',
      ),
      value: _tipoLabel(_tipo),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _abrirTipoSelector,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: context.t(
              'catalogCategories.form.typeField',
              fallback: 'Uso da categoria',
            ),
            prefixIcon: Icon(_tipoIcon(_tipo)),
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
            filled: true,
            fillColor: SixMobilePalette.softNeutralSurface,
            border: _inputBorder(),
            enabledBorder: _inputBorder(SixMobilePalette.activeBorder),
            focusedBorder: _inputBorder(SixMobilePalette.accent),
          ),
          child: Text(
            _tipoLabel(_tipo),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.categoria != null;
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      editando
                          ? context.t(
                            'catalogCategories.form.editTitle',
                            fallback: 'Editar categoria',
                          )
                          : context.t(
                            'catalogCategories.form.createTitle',
                            fallback: 'Nova categoria',
                          ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SixMobilePalette.titleText,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'catalogCategories.form.name',
                        fallback: 'Nome da categoria',
                      ),
                      prefixIcon: Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: SixMobilePalette.softNeutralSurface,
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(
                        SixMobilePalette.activeBorder,
                      ),
                      focusedBorder: _inputBorder(SixMobilePalette.accent),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.t(
                          'catalogCategories.form.nameRequired',
                          fallback: 'Informe o nome da categoria.',
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'catalogCategories.form.description',
                        fallback: 'Descrição',
                      ),
                      hintText: context.t(
                        'catalogCategories.form.optional',
                        fallback: 'Opcional',
                      ),
                      prefixIcon: Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: SixMobilePalette.softNeutralSurface,
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(
                        SixMobilePalette.activeBorder,
                      ),
                      focusedBorder: _inputBorder(SixMobilePalette.accent),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildTipoField(),
                  SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _ativo,
                    activeThumbColor: SixMobilePalette.accent,
                    onChanged: (bool value) => setState(() => _ativo = value),
                    title: Text(
                      context.t(
                        'catalogCategories.form.active',
                        fallback: 'Categoria ativa',
                      ),
                    ),
                    subtitle: Text(
                      context.t(
                        'catalogCategories.form.activeDescription',
                        fallback:
                            'Categorias inativas ficam indisponíveis no cadastro.',
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.t('common.cancel', fallback: 'Cancelar'),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _salvar,
                          child: Text(
                            editando
                                ? context.t('common.save', fallback: 'Salvar')
                                : context.t(
                                  'common.register',
                                  fallback: 'Cadastrar',
                                ),
                          ),
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

class _CategoryTypeOption {
  const _CategoryTypeOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _CategoryTypeSelectorSheet extends StatelessWidget {
  const _CategoryTypeSelectorSheet({
    required this.selectedType,
    required this.options,
  });

  final String selectedType;
  final List<_CategoryTypeOption> options;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _SheetHandle(),
          SizedBox(height: 14),
          _SheetTitle(
            title: context.t(
              'catalogCategories.form.typeField',
              fallback: 'Uso da categoria',
            ),
          ),
          SizedBox(height: 12),
          ...options.map((_CategoryTypeOption option) {
            final bool selected = option.value == selectedType;
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _SheetActionTile(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                selected: selected,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryActionsSheet extends StatelessWidget {
  const _CategoryActionsSheet({
    required this.active,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _SheetHandle(),
          SizedBox(height: 14),
          _SheetTitle(
            title: context.t(
              'catalogCategories.actions.title',
              fallback: 'Ações da categoria',
            ),
          ),
          SizedBox(height: 12),
          _SheetActionTile(
            icon: Icons.edit_outlined,
            title: context.t('common.edit', fallback: 'Editar'),
            onTap: onEdit,
          ),
          SizedBox(height: 8),
          _SheetActionTile(
            icon: active ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
            title:
                active
                    ? context.t(
                      'catalogCategories.actions.disable',
                      fallback: 'Desativar',
                    )
                    : context.t(
                      'catalogCategories.actions.enable',
                      fallback: 'Ativar',
                    ),
            onTap: onToggle,
          ),
          SizedBox(height: 8),
          _SheetActionTile(
            icon: Icons.delete_outline_rounded,
            title: context.t('common.delete', fallback: 'Excluir'),
            destructive: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ConfirmDeleteCategorySheet extends StatelessWidget {
  const _ConfirmDeleteCategorySheet({
    required this.categoryName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String categoryName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _SheetHandle(),
          SizedBox(height: 14),
          _SheetTitle(
            title: context.t(
              'catalogCategories.delete.title',
              fallback: 'Excluir categoria',
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SixMobilePalette.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SixMobilePalette.errorBorder),
            ),
            child: Text(
              '${context.t('catalogCategories.delete.question', fallback: 'Deseja excluir')} "$categoryName"? ${context.t('catalogCategories.delete.linkedWarning', fallback: 'Se houver vínculo com produtos ou serviços, o backend pode bloquear.')}',
              style: TextStyle(color: SixMobilePalette.titleText, height: 1.35),
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.error,
                    foregroundColor: SixMobilePalette.onPrimary,
                  ),
                  onPressed: onConfirm,
                  icon: Icon(Icons.delete_outline_rounded),
                  label: Text(context.t('common.delete', fallback: 'Excluir')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomSheetSurface extends StatelessWidget {
  const _BottomSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: SixMobilePalette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: SixMobilePalette.titleText,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        destructive ? SixMobilePalette.error : SixMobilePalette.accent;
    final Color foreground =
        destructive
            ? SixMobilePalette.error
            : selected
            ? SixMobilePalette.accent
            : SixMobilePalette.titleText;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color:
            selected
                ? SixMobilePalette.softAccentSurface
                : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 56),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.highlightedBorder
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: activeColor, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            height: 1.25,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected) ...<Widget>[
                  SizedBox(width: 10),
                  Icon(
                    Icons.check_circle_rounded,
                    color: SixMobilePalette.accent,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.border.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(radius),
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
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
