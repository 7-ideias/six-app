import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:sixpos/core/services/catalogo_publico_service.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/catalogo_virtual/catalogo_virtual_mobile_editors.dart';
import 'package:sixpos/presentation/components/mobile/catalogo_virtual/catalogo_virtual_mobile_preview.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';

class CatalogoVirtualMobileScreen extends StatefulWidget {
  const CatalogoVirtualMobileScreen({super.key, this.service});

  final CatalogoPublicoService? service;

  @override
  State<CatalogoVirtualMobileScreen> createState() =>
      _CatalogoVirtualMobileScreenState();
}

class _CatalogoVirtualMobileScreenState
    extends State<CatalogoVirtualMobileScreen> {
  late final CatalogoPublicoService _service;

  CatalogoPublicoConfiguracaoModel? _saved;
  CatalogoPublicoConfiguracaoModel? _draft;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CatalogoPublicoService();
    _load();
  }

  bool get _dirty {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (saved == null || draft == null) return false;
    return saved.ativo != draft.ativo ||
        !saved.personalizacao.sameValuesAs(draft.personalizacao);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final CatalogoPublicoConfiguracaoModel configuration =
          await _service.buscarConfiguracao();
      if (!mounted) return;
      setState(() {
        _saved = configuration;
        _draft = configuration;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPersonalization(
    CatalogoPublicoPersonalizacaoModel personalization,
  ) {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || _saving) return;
    setState(() {
      _draft = draft.copyWith(personalizacao: personalization);
    });
  }

  Future<void> _editPresentation() async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || _saving) return;
    final CatalogoPublicoPersonalizacaoModel? updated =
        await showCatalogoVirtualPresentationMobileEditor(
          context: context,
          current: draft.personalizacao,
        );
    if (!mounted || updated == null) return;
    _applyPersonalization(updated);
  }

  Future<void> _editAppearance() async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || _saving) return;
    final CatalogoPublicoPersonalizacaoModel? updated =
        await showCatalogoVirtualAppearanceMobileEditor(
          context: context,
          current: draft.personalizacao,
        );
    if (!mounted || updated == null) return;
    _applyPersonalization(updated);
  }

  Future<void> _editContent() async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || _saving) return;
    final CatalogoPublicoPersonalizacaoModel? updated =
        await showCatalogoVirtualContentMobileEditor(
          context: context,
          current: draft.personalizacao,
        );
    if (!mounted || updated == null) return;
    _applyPersonalization(updated);
  }

  Future<void> _changePublication(bool value) async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || draft.ativo == value || _saving) return;

    if (!value) {
      final bool confirmed =
          await showCatalogoVirtualUnpublishMobileConfirmation(
            context: context,
          );
      if (!mounted || !confirmed) return;
    }

    setState(() => _draft = draft.copyWith(ativo: value));
  }

  void _discard() {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || _saving) return;
    setState(() => _draft = saved);
  }

  Future<void> _save() async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || !_dirty || _saving) return;

    setState(() => _saving = true);
    try {
      final CatalogoPublicoConfiguracaoModel updated = await _service
          .atualizarConfiguracao(
            ativo: draft.ativo,
            personalizacao: draft.personalizacao,
          );
      if (!mounted) return;
      setState(() {
        _saved = updated;
        _draft = updated;
      });
      _showSnack(
        updated.ativo
            ? context.t(
              'catalog.publicPage.saveSuccessPublished',
              fallback: 'Catálogo salvo e publicado com sucesso.',
            )
            : context.t(
              'catalog.publicPage.saveSuccessDraft',
              fallback: 'Personalização salva. Publique quando estiver pronta.',
            ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        context.t(
          'catalog.publicPage.saveError',
          fallback: 'Não foi possível salvar o catálogo virtual.',
        ),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyLink() async {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || !saved.ativo) return;
    await Clipboard.setData(ClipboardData(text: saved.url));
    if (!mounted) return;
    _showSnack(
      context.t(
        'catalog.publicPage.linkCopied',
        fallback: 'Link público copiado.',
      ),
    );
  }

  Future<void> _shareLink() async {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || !saved.ativo) return;
    final String title =
        saved.personalizacao.titulo.trim().isNotEmpty
            ? saved.personalizacao.titulo.trim()
            : saved.empresa.nome;
    final String message = <String>[
      title,
      saved.personalizacao.descricao.trim(),
      saved.url,
    ].where((String value) => value.isNotEmpty).join('\n\n');
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Rect? shareOrigin =
        renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size;

    try {
      await sharing.Share.share(
        message,
        subject: context
            .t(
              'catalog.publicPage.shareSubject',
              fallback: 'Catálogo de {title}',
            )
            .replaceAll('{title}', title),
        sharePositionOrigin: shareOrigin,
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: saved.url));
      if (!mounted) return;
      _showSnack(
        context.t(
          'catalog.publicPage.shareFallback',
          fallback:
              'O compartilhamento não está disponível. O link foi copiado.',
        ),
      );
    }
  }

  Future<void> _showPreview() async {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null) return;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (BuildContext sheetContext) {
        final SixMobileColorScheme colors = sheetContext.sixMobileColors;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: FractionallySizedBox(
              heightFactor: 0.94,
              child: Material(
                key: const ValueKey<String>(
                  'catalog-virtual-mobile-preview-sheet',
                ),
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.strongBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  sheetContext.t(
                                    'catalog.publicPage.preview.title',
                                    fallback: 'Prévia ao vivo',
                                  ),
                                  style: Theme.of(
                                    sheetContext,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: colors.titleText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dirty
                                      ? sheetContext.t(
                                        'catalog.publicPage.preview.unsaved',
                                        fallback:
                                            'Visualizando alterações ainda não salvas',
                                      )
                                      : sheetContext.t(
                                        'catalog.publicPage.preview.saved',
                                        fallback: 'Aparência salva no catálogo',
                                      ),
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: sheetContext.t(
                              'common.close',
                              fallback: 'Fechar',
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: colors.border),
                            boxShadow:
                                reduceMotion
                                    ? const <BoxShadow>[]
                                    : <BoxShadow>[
                                      BoxShadow(
                                        color: colors.heroShadow,
                                        blurRadius: 22,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: CatalogoVirtualMobilePreview(
                              configuration: draft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message, {bool error = false}) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? colors.error : colors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    final CatalogoPublicoConfiguracaoModel? saved = _saved;

    return SixMobilePageShell(
      title: context.t(
        'catalog.publicPage.title',
        fallback: 'Catálogo virtual',
      ),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      actions: <Widget>[
        if (saved?.ativo == true)
          IconButton(
            tooltip: context.t(
              'catalog.publicPage.share',
              fallback: 'Compartilhar',
            ),
            onPressed: _saving ? null : _shareLink,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        IconButton(
          tooltip: context.t('common.refresh', fallback: 'Atualizar'),
          onPressed: _loading || _saving || _dirty ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottomNavigationBar:
          draft != null && _dirty
              ? _CatalogVirtualSaveBar(
                saving: _saving,
                onDiscard: _discard,
                onSave: _save,
              )
              : null,
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
            children: <Widget>[
              AnimatedSwitcher(
                duration:
                    MediaQuery.disableAnimationsOf(context) ||
                            MediaQuery.accessibleNavigationOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    _loading
                        ? const _CatalogVirtualLoadingState(
                          key: ValueKey<String>(
                            'catalog-virtual-mobile-loading',
                          ),
                        )
                        : _loadFailed || draft == null
                        ? _CatalogVirtualErrorState(
                          key: const ValueKey<String>(
                            'catalog-virtual-mobile-error',
                          ),
                          onRetry: _load,
                        )
                        : _CatalogVirtualSuccessState(
                          key: const ValueKey<String>(
                            'catalog-virtual-mobile-success',
                          ),
                          draft: draft,
                          dirty: _dirty,
                          saving: _saving,
                          onPublicationChanged: _changePublication,
                          onPreview: _showPreview,
                          onCopy: saved?.ativo == true ? _copyLink : null,
                          onShare: saved?.ativo == true ? _shareLink : null,
                          onEditPresentation: _editPresentation,
                          onEditAppearance: _editAppearance,
                          onEditContent: _editContent,
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogVirtualSuccessState extends StatelessWidget {
  const _CatalogVirtualSuccessState({
    super.key,
    required this.draft,
    required this.dirty,
    required this.saving,
    required this.onPublicationChanged,
    required this.onPreview,
    required this.onCopy,
    required this.onShare,
    required this.onEditPresentation,
    required this.onEditAppearance,
    required this.onEditContent,
  });

  final CatalogoPublicoConfiguracaoModel draft;
  final bool dirty;
  final bool saving;
  final ValueChanged<bool> onPublicationChanged;
  final VoidCallback onPreview;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback onEditPresentation;
  final VoidCallback onEditAppearance;
  final VoidCallback onEditContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 40),
          child: _CatalogPublicationHero(
            configuration: draft,
            dirty: dirty,
            saving: saving,
            onChanged: onPublicationChanged,
          ),
        ),
        const SizedBox(height: 12),
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 90),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _CatalogQuickAction(
                  icon: Icons.phone_iphone_rounded,
                  label: context.t(
                    'catalog.publicPage.preview.title',
                    fallback: 'Prévia ao vivo',
                  ),
                  onTap: onPreview,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CatalogQuickAction(
                  icon: Icons.copy_rounded,
                  label: context.t(
                    'catalog.publicPage.copy',
                    fallback: 'Copiar link',
                  ),
                  onTap: onCopy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CatalogQuickAction(
                  icon: Icons.ios_share_rounded,
                  label: context.t(
                    'catalog.publicPage.share',
                    fallback: 'Compartilhar',
                  ),
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 130),
          child: _CatalogEditorActionCard(
            key: const ValueKey<String>(
              'catalog-virtual-mobile-editor-presentation',
            ),
            icon: Icons.text_fields_rounded,
            title: context.t(
              'catalog.publicPage.editor.content',
              fallback: 'Apresentação',
            ),
            subtitle: context.t(
              'catalog.publicPage.editor.contentHelp',
              fallback: 'Defina a mensagem que abre sua vitrine.',
            ),
            value:
                draft.personalizacao.titulo.trim().isEmpty
                    ? context.t(
                      'catalog.publicPage.editor.titleHint',
                      fallback: 'Ex.: Encontre o que precisa',
                    )
                    : draft.personalizacao.titulo.trim(),
            onTap: onEditPresentation,
          ),
        ),
        const SizedBox(height: 10),
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 170),
          child: _CatalogEditorActionCard(
            key: const ValueKey<String>(
              'catalog-virtual-mobile-editor-appearance',
            ),
            icon: Icons.palette_outlined,
            title: context.t(
              'catalog.publicPage.editor.appearance',
              fallback: 'Aparência',
            ),
            subtitle: context.t(
              'catalog.publicPage.editor.appearanceHelp',
              fallback: 'Escolha o clima visual e a cor de destaque.',
            ),
            value:
                '${_styleLabel(context, draft.personalizacao.estilo)}  •  ${draft.personalizacao.corPrincipal}',
            swatchColor: _catalogColor(draft.personalizacao.corPrincipal),
            onTap: onEditAppearance,
          ),
        ),
        const SizedBox(height: 10),
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 210),
          child: _CatalogEditorActionCard(
            key: const ValueKey<String>(
              'catalog-virtual-mobile-editor-content',
            ),
            icon: Icons.view_quilt_outlined,
            title: context.t(
              'catalog.publicPage.editor.layout',
              fallback: 'Conteúdo e layout',
            ),
            subtitle: _visibilitySummary(context, draft.personalizacao),
            value: _densityLabel(context, draft.personalizacao.densidade),
            onTap: onEditContent,
          ),
        ),
        const SizedBox(height: 22),
        SixStaggeredEntry(
          delay: const Duration(milliseconds: 250),
          child: _CatalogInlinePreview(
            configuration: draft,
            dirty: dirty,
            onTap: onPreview,
          ),
        ),
      ],
    );
  }

  static String _styleLabel(BuildContext context, CatalogoPublicoEstilo style) {
    return switch (style) {
      CatalogoPublicoEstilo.classico => context.t(
        'catalog.publicPage.style.classic',
        fallback: 'Clássico',
      ),
      CatalogoPublicoEstilo.minimalista => context.t(
        'catalog.publicPage.style.minimal',
        fallback: 'Minimalista',
      ),
      CatalogoPublicoEstilo.expressivo => context.t(
        'catalog.publicPage.style.expressive',
        fallback: 'Expressivo',
      ),
    };
  }

  static String _densityLabel(
    BuildContext context,
    CatalogoPublicoDensidade density,
  ) {
    return density == CatalogoPublicoDensidade.confortavel
        ? context.t(
          'catalog.publicPage.editor.comfortable',
          fallback: 'Confortável',
        )
        : context.t('catalog.publicPage.editor.compact', fallback: 'Compacto');
  }

  static String _visibilitySummary(
    BuildContext context,
    CatalogoPublicoPersonalizacaoModel personalization,
  ) {
    return <String>[
      if (personalization.exibirPrecos)
        context.t(
          'catalog.publicPage.editor.showPrices',
          fallback: 'Exibir preços',
        ),
      if (personalization.exibirContato)
        context.t(
          'catalog.publicPage.editor.showContact',
          fallback: 'Exibir contatos',
        ),
      if (personalization.exibirEndereco)
        context.t(
          'catalog.publicPage.editor.showAddress',
          fallback: 'Exibir endereço',
        ),
    ].join(' • ');
  }
}

class _CatalogPublicationHero extends StatelessWidget {
  const _CatalogPublicationHero({
    required this.configuration,
    required this.dirty,
    required this.saving,
    required this.onChanged,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final bool dirty;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final String companyName =
        configuration.empresa.nome.isEmpty
            ? context.t(
              'catalog.publicPage.preview.storeFallback',
              fallback: 'Seu comércio',
            )
            : configuration.empresa.nome;
    final String title =
        configuration.personalizacao.titulo.trim().isEmpty
            ? companyName
            : configuration.personalizacao.titulo.trim();

    return Semantics(
      container: true,
      label:
          '${configuration.ativo ? context.t('catalog.publicPage.published', fallback: 'Publicado') : context.t('catalog.publicPage.offline', fallback: 'Fora do ar')}. $title',
      child: Container(
        key: const ValueKey<String>('catalog-virtual-mobile-publication-card'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              SixMobilePalette.brandNavyDeep,
              SixMobilePalette.brandNavyBright,
              SixMobilePalette.brandViolet,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.brandNavyDeep.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _PublicationStatusPill(active: configuration.ativo),
                      if (dirty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          context.t(
                            'catalog.publicPage.preview.unsaved',
                            fallback:
                                'Visualizando alterações ainda não salvas',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SixMobilePalette.brandSupportingText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: configuration.ativo,
                  onChanged: saving ? null : onChanged,
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? SixMobilePalette.brandNavyDeep
                        : Colors.white;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? SixMobilePalette.brandCyan
                        : Colors.white24;
                  }),
                  trackOutlineColor: const WidgetStatePropertyAll<Color>(
                    Colors.white30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              configuration.personalizacao.descricao.trim().isEmpty
                  ? context.t(
                    'catalog.publicPage.subtitle',
                    fallback:
                        'Personalize, visualize e compartilhe sua vitrine em um só lugar.',
                  )
                  : configuration.personalizacao.descricao.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.brandSupportingText,
                height: 1.34,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                _HeroMetric(
                  icon: Icons.inventory_2_outlined,
                  value: configuration.produtos.length.toString(),
                  label: context.t(
                    'catalog.publicPage.preview.products',
                    fallback: 'Produtos disponíveis',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.language_rounded,
                          color: SixMobilePalette.brandCyan,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PT · EN · ES',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationStatusPill extends StatelessWidget {
  const _PublicationStatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          active ? Icons.public_rounded : Icons.visibility_off_outlined,
          color:
              active
                  ? SixMobilePalette.brandCyan
                  : SixMobilePalette.brandSupportingText,
          size: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            active
                ? context.t(
                  'catalog.publicPage.published',
                  fallback: 'Publicado',
                )
                : context.t(
                  'catalog.publicPage.offline',
                  fallback: 'Fora do ar',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  active
                      ? SixMobilePalette.brandCyan
                      : SixMobilePalette.brandSupportingText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: SixMobilePalette.brandCyan, size: 19),
            const SizedBox(width: 8),
            SixAnimatedNumberText(
              value: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SixMobilePalette.brandSupportingText,
                  fontSize: 9,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogQuickAction extends StatelessWidget {
  const _CatalogQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(8, 11, 8, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  color: enabled ? colors.accent : colors.mutedText,
                  size: 21,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: enabled ? colors.titleText : colors.mutedText,
                    fontSize: 10.5,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogEditorActionCard extends StatelessWidget {
  const _CatalogEditorActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.swatchColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Semantics(
      button: true,
      label: '$title. $value. $subtitle',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: colors.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.navigationShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.softAccentSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.accent, size: 21),
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
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (swatchColor != null) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.softAccentSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: colors.accent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogInlinePreview extends StatelessWidget {
  const _CatalogInlinePreview({
    required this.configuration,
    required this.dirty,
    required this.onTap,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final bool dirty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Container(
      key: const ValueKey<String>('catalog-virtual-mobile-inline-preview'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 9, 11),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          'catalog.publicPage.preview.title',
                          fallback: 'Prévia ao vivo',
                        ),
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dirty
                            ? context.t(
                              'catalog.publicPage.preview.unsaved',
                              fallback:
                                  'Visualizando alterações ainda não salvas',
                            )
                            : context.t(
                              'catalog.publicPage.preview.saved',
                              fallback: 'Aparência salva no catálogo',
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.t(
                    'catalog.publicPage.preview.mobile',
                    fallback: 'Celular',
                  ),
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    foregroundColor: colors.accent,
                    backgroundColor: colors.softAccentSurface,
                    side: BorderSide(color: colors.border),
                  ),
                  icon: const Icon(Icons.open_in_full_rounded, size: 19),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(21),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 360,
                child: IgnorePointer(
                  child: CatalogoVirtualMobilePreview(
                    configuration: configuration,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogVirtualSaveBar extends StatelessWidget {
  const _CatalogVirtualSaveBar({
    required this.saving,
    required this.onDiscard,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Material(
      key: const ValueKey<String>('catalog-virtual-mobile-save-bar'),
      color: colors.surfaceElevated,
      elevation: 10,
      shadowColor: colors.navigationShadow,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onDiscard,
                  child: Text(
                    context.t(
                      'catalog.publicPage.discard',
                      fallback: 'Descartar',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey<String>('catalog-virtual-mobile-save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                  ),
                  onPressed: saving ? null : onSave,
                  icon:
                      saving
                          ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onAccent,
                            ),
                          )
                          : const Icon(Icons.cloud_done_outlined),
                  label: Text(
                    saving
                        ? context.t('common.saving', fallback: 'Salvando...')
                        : context.t(
                          'catalog.publicPage.save',
                          fallback: 'Salvar alterações',
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogVirtualLoadingState extends StatelessWidget {
  const _CatalogVirtualLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t(
        'catalog.virtualCatalog.loading',
        fallback: 'Preparando catálogo virtual...',
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 230,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  SixMobilePalette.brandNavyDeep,
                  SixMobilePalette.brandNavyBright,
                  SixMobilePalette.brandViolet,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                const Spacer(),
                _SkeletonLine(
                  width: 190,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
                const SizedBox(height: 10),
                _SkeletonLine(
                  width: 270,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 8),
                _SkeletonLine(
                  width: 220,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (int index = 0; index < 3; index += 1) ...<Widget>[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 76,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      <IconData>[
                        Icons.phone_iphone_rounded,
                        Icons.copy_rounded,
                        Icons.ios_share_rounded,
                      ][index],
                      color: colors.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          for (final IconData icon in <IconData>[
            Icons.text_fields_rounded,
            Icons.palette_outlined,
            Icons.view_quilt_outlined,
          ]) ...<Widget>[
            Container(
              height: 92,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.softAccentSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: colors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SkeletonLine(width: 140, color: colors.softSurface),
                        const SizedBox(height: 9),
                        _SkeletonLine(width: 220, color: colors.softSurface),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CatalogVirtualErrorState extends StatelessWidget {
  const _CatalogVirtualErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: colors.error,
                size: 27,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t(
                'catalog.publicPage.loadErrorTitle',
                fallback: 'Não foi possível carregar o catálogo virtual',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.t('common.tryAgain', fallback: 'Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

Color _catalogColor(String value) {
  final RegExpMatch? match = RegExp(
    r'^#([0-9A-Fa-f]{6})$',
  ).firstMatch(value.trim());
  if (match == null) return const Color(0xFF126BFF);
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}
