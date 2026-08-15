import 'package:flutter/material.dart';
import 'package:sixpos/data/models/etiqueta_models.dart';
import 'package:sixpos/domain/services/etiqueta/etiqueta_service.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

import 'etiqueta_editor_web_page.dart';
import 'etiqueta_impressao_web_page.dart';
import 'etiqueta_web_i18n.dart';

class EtiquetasWebPage extends StatefulWidget {
  const EtiquetasWebPage({super.key, this.onBack, this.service});

  final VoidCallback? onBack;
  final EtiquetaService? service;

  @override
  State<EtiquetasWebPage> createState() => _EtiquetasWebPageState();
}

class _EtiquetasWebPageState extends State<EtiquetasWebPage> {
  late final EtiquetaService _service;
  final TextEditingController _searchController = TextEditingController();
  List<EtiquetaModelo> _models = const <EtiquetaModelo>[];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _busyModelId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? EtiquetaService();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EtiquetaModelo> get _filtered {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return _models;
    return _models
        .where((EtiquetaModelo model) =>
            model.nome.toLowerCase().contains(query) ||
            model.descricao.toLowerCase().contains(query) ||
            model.papel.preset.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          if (_error != null) _errorBanner(_error!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                children: <Widget>[
                  SixWebEntry(child: _topContext()),
                  const SizedBox(height: 18),
                  if (_loading) ...<Widget>[
                    const SixWebLoadingBlock(height: 118),
                    const SizedBox(height: 12),
                    const SixWebLoadingBlock(height: 118),
                    const SizedBox(height: 12),
                    const SixWebLoadingBlock(height: 118),
                  ] else if (_models.isEmpty)
                    SixWebEntry(order: 1, child: _emptyState())
                  else ...<Widget>[
                    SixWebEntry(order: 1, child: _searchBar()),
                    const SizedBox(height: 14),
                    SixWebEntry(order: 2, child: _modelsList()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topContext() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;
          final Widget description = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.local_offer_outlined, color: tokens.info),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _tr(
                        'labels.home.contextTitle',
                        'Modelos reutilizáveis para impressão',
                        'Reusable print templates',
                        'Plantillas reutilizables para impresión',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _tr(
                        'labels.home.contextSubtitle',
                        'Configure uma vez, salve no comércio atual e reutilize com diferentes produtos e quantidades.',
                        'Configure once, save it for the current business and reuse it with different products and quantities.',
                        'Configure una vez, guarde en el comercio actual y reutilice con diferentes productos y cantidades.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(color: tokens.secondaryText, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _models.isEmpty ? null : () => _openPrint(),
                icon: const Icon(Icons.print_outlined),
                label: Text(_tr('labels.home.print', 'Imprimir etiquetas', 'Print labels', 'Imprimir etiquetas')),
              ),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(_tr('labels.home.create', 'Criar modelo', 'Create template', 'Crear plantilla')),
              ),
            ],
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    description,
                    const SizedBox(height: 16),
                    actions,
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: description),
                    const SizedBox(width: 18),
                    actions,
                  ],
                );
        },
      ),
    );
  }

  Widget _searchBar() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextField(
      controller: _searchController,
      onChanged: (String value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: _tr(
          'labels.home.search',
          'Buscar por nome, descrição ou formato...',
          'Search by name, description or format...',
          'Buscar por nombre, descripción o formato...',
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: tokens.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
      ),
    );
  }

  Widget _modelsList() {
    final List<EtiquetaModelo> models = _filtered;
    if (models.isEmpty) {
      return SixWebNoData(
        text: _tr(
          'labels.home.noSearchResults',
          'Nenhum modelo corresponde à busca.',
          'No templates match your search.',
          'Ninguna plantilla coincide con la búsqueda.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 1040;
        final double itemWidth = wide
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            for (final EtiquetaModelo model in models)
              SizedBox(width: itemWidth, child: _modelCard(model)),
          ],
        );
      },
    );
  }

  Widget _modelCard(EtiquetaModelo model) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool busy = _busyModelId == model.id;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_offer_outlined, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (model.descricao.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        model.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !busy,
                tooltip: _tr('labels.home.moreActions', 'Mais ações', 'More actions', 'Más acciones'),
                onSelected: (String action) => _handleAction(action, model),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'duplicate',
                    child: _menuEntry(Icons.copy_outlined, _tr('labels.home.duplicate', 'Duplicar', 'Duplicate', 'Duplicar')),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: _menuEntry(Icons.delete_outline_rounded, _tr('labels.home.delete', 'Excluir', 'Delete', 'Eliminar')),
                  ),
                ],
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(Icons.straighten_rounded, '${_fmt(model.etiqueta.larguraMm)} × ${_fmt(model.etiqueta.alturaMm)} mm'),
              _chip(Icons.description_outlined, model.papel.preset),
              _chip(Icons.grid_view_outlined, '${model.grade.colunas} × ${model.grade.linhas}'),
              _chip(Icons.widgets_outlined, '${model.elementos.length} ${_tr('labels.home.elements', 'elementos', 'elements', 'elementos')}'),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _openEditor(model),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(_tr('labels.home.edit', 'Editar', 'Edit', 'Editar')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _openPrint(model.id),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(_tr('labels.home.printShort', 'Imprimir', 'Print', 'Imprimir')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.local_offer_outlined, color: tokens.info, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _tr('labels.home.emptyTitle', 'Crie seu primeiro modelo', 'Create your first template', 'Cree su primera plantilla'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              _tr(
                'labels.home.emptySubtitle',
                'Defina o papel, o tamanho de cada etiqueta, a grade e os campos que serão preenchidos automaticamente com os dados dos produtos.',
                'Define paper size, label dimensions, grid and fields that will be automatically filled with product data.',
                'Defina el papel, el tamaño de cada etiqueta, la cuadrícula y los campos que se completarán automáticamente con los datos de productos.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.secondaryText, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: Text(_tr('labels.home.create', 'Criar modelo', 'Create template', 'Crear plantilla')),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<EtiquetaModelo> models = await _service.listarModelos();
      if (!mounted) return;
      setState(() {
        _models = models;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _tr(
          'labels.home.loadError',
          'Não foi possível carregar os modelos de etiquetas.',
          'Could not load label templates.',
          'No se pudieron cargar las plantillas de etiquetas.',
        );
      });
    }
  }

  Future<void> _openEditor([EtiquetaModelo? model]) async {
    final Size size = MediaQuery.sizeOf(context);
    final EtiquetaModelo? saved = await showDialog<EtiquetaModelo>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: _min(size.width * 0.97, 1540),
          height: _min(size.height * 0.94, 980),
          child: EtiquetaEditorWebPage(
            initialModel: model,
            onSave: _service.salvarModelo,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
    if (saved == null || !mounted) return;
    await _load();
  }

  Future<void> _openPrint([String? templateId]) async {
    if (_models.isEmpty) return;
    final Size size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: _min(size.width * 0.96, 1420),
          height: _min(size.height * 0.92, 940),
          child: EtiquetaImpressaoWebPage(
            modelos: _models,
            service: _service,
            initialTemplateId: templateId,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action, EtiquetaModelo model) async {
    if (action == 'duplicate') {
      final String? id = model.id;
      if (id == null) return;
      setState(() => _busyModelId = id);
      try {
        await _service.duplicarModelo(id);
        if (!mounted) return;
        await _load();
      } catch (_) {
        if (!mounted) return;
        setState(() => _error = _tr(
              'labels.home.duplicateError',
              'Não foi possível duplicar o modelo.',
              'Could not duplicate the template.',
              'No se pudo duplicar la plantilla.',
            ));
      } finally {
        if (mounted) setState(() => _busyModelId = null);
      }
      return;
    }
    if (action == 'delete') await _delete(model);
  }

  Future<void> _delete(EtiquetaModelo model) async {
    final String? id = model.id;
    if (id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_tr('labels.home.deleteTitle', 'Excluir modelo?', 'Delete template?', '¿Eliminar plantilla?')),
        content: Text(
          _tr(
            'labels.home.deleteMessage',
            'O modelo “${model.nome}” deixará de estar disponível para novas impressões.',
            'The template “${model.nome}” will no longer be available for new print jobs.',
            'La plantilla “${model.nome}” dejará de estar disponible para nuevas impresiones.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_tr('labels.common.cancel', 'Cancelar', 'Cancel', 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_tr('labels.home.delete', 'Excluir', 'Delete', 'Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyModelId = id);
    try {
      await _service.excluirModelo(id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _tr(
            'labels.home.deleteError',
            'Não foi possível excluir o modelo.',
            'Could not delete the template.',
            'No se pudo eliminar la plantilla.',
          ));
    } finally {
      if (mounted) setState(() => _busyModelId = null);
    }
  }

  Widget _chip(IconData icon, String text) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _menuEntry(IconData icon, String text) => Row(
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 9),
          Text(text),
        ],
      );

  Widget _errorBanner(String message) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: tokens.danger.withValues(alpha: 0.10),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: _load,
            child: Text(_tr('labels.home.retry', 'Tentar novamente', 'Try again', 'Intentar de nuevo')),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  double _min(double a, double b) => a < b ? a : b;

  String _tr(String key, String pt, String en, String es) =>
      etiquetaTr(context, key, pt: pt, en: en, es: es);
}
