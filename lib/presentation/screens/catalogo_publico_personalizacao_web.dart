import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:sixpos/core/services/catalogo_publico_service.dart';
import 'package:sixpos/core/utils/external_link_launcher.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/web/six_web_catalog_unpublish_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:provider/provider.dart';

enum _CatalogPreviewDevice { desktop, mobile }

Future<void> showCatalogoVirtualWebDialog(
  BuildContext context, {
  CatalogoPublicoService? service,
}) {
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  final bool reduceMotion =
      mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: context.t('common.close', fallback: 'Fechar'),
    barrierColor: Colors.transparent,
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          final Size size = MediaQuery.sizeOf(dialogContext);
          final WebThemeTokens tokens = WebThemeTokens.of(dialogContext);
          final bool compact = size.width < 760;
          final double horizontalInset = compact ? 12 : 32;
          final double verticalInset = size.height < 720 ? 12 : 28;
          final double dialogWidth = math.min(
            1560.0,
            size.width - (horizontalInset * 2),
          );
          final double dialogHeight = math.min(
            980.0,
            size.height - (verticalInset * 2),
          );
          final BorderRadius borderRadius = BorderRadius.circular(
            compact ? 18 : 24,
          );

          return Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(
                    color: const Color(0xFF020817).withValues(alpha: 0.72),
                  ),
                ),
                SafeArea(
                  minimum: EdgeInsets.symmetric(
                    horizontal: horizontalInset,
                    vertical: verticalInset,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: dialogWidth,
                      height: dialogHeight,
                      child: Material(
                        elevation: 32,
                        shadowColor: Colors.black.withValues(alpha: 0.55),
                        color: tokens.workspaceBackground,
                        borderRadius: borderRadius,
                        clipBehavior: Clip.antiAlias,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            border: Border.all(
                              color: tokens.cardBorder.withValues(alpha: 0.82),
                            ),
                          ),
                          child: CatalogoPublicoPersonalizacaoWebPage(
                            service: service,
                            onClose: () => Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (reduceMotion) return child;
          final Animation<double> curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
  );
}

class CatalogoPublicoPersonalizacaoWebPage extends StatefulWidget {
  const CatalogoPublicoPersonalizacaoWebPage({
    super.key,
    this.service,
    this.onClose,
  });

  final CatalogoPublicoService? service;
  final VoidCallback? onClose;

  @override
  State<CatalogoPublicoPersonalizacaoWebPage> createState() =>
      _CatalogoPublicoPersonalizacaoWebPageState();
}

class _CatalogoPublicoPersonalizacaoWebPageState
    extends State<CatalogoPublicoPersonalizacaoWebPage> {
  static const List<String> _accentColors = <String>[
    '#126BFF',
    '#0F766E',
    '#7C3AED',
    '#C2410C',
    '#BE185D',
    '#334155',
  ];

  late final CatalogoPublicoService _service;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  CatalogoPublicoConfiguracaoModel? _saved;
  CatalogoPublicoConfiguracaoModel? _draft;
  _CatalogPreviewDevice _previewDevice = _CatalogPreviewDevice.desktop;
  bool _loading = true;
  bool _saving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CatalogoPublicoService();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String? get _publicBaseUrl {
    final Uri currentUri = Uri.base;
    if (!<String>{'http', 'https'}.contains(currentUri.scheme) ||
        currentUri.host.isEmpty) {
      return null;
    }
    final bool loopback = <String>{
      'localhost',
      '127.0.0.1',
      '::1',
    }.contains(currentUri.host.toLowerCase());
    return currentUri
        .resolve(loopback ? '/catalogo.html' : '/catalogo')
        .toString();
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
        _errorMessage = '';
      });
    }
    try {
      final CatalogoPublicoConfiguracaoModel configuration = await _service
          .buscarConfiguracao(baseUrl: _publicBaseUrl);
      if (!mounted) return;
      _applyConfiguration(configuration);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyConfiguration(CatalogoPublicoConfiguracaoModel configuration) {
    _saved = configuration;
    _draft = configuration;
    _titleController.text = configuration.personalizacao.titulo;
    _descriptionController.text = configuration.personalizacao.descricao;
    _colorController.text = configuration.personalizacao.corPrincipal;
    setState(() {});
  }

  void _updatePersonalization(
    CatalogoPublicoPersonalizacaoModel Function(
      CatalogoPublicoPersonalizacaoModel current,
    )
    update,
  ) {
    final CatalogoPublicoConfiguracaoModel? draft = _draft;
    if (draft == null || _saving) return;
    setState(() {
      _draft = draft.copyWith(personalizacao: update(draft.personalizacao));
    });
  }

  void _resetDraft() {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || _saving) return;
    _applyConfiguration(saved);
  }

  Future<CatalogoPublicoConfiguracaoModel> _persistDraft() async {
    final CatalogoPublicoConfiguracaoModel draft = _draft!;
    final CatalogoPublicoConfiguracaoModel updated = await _service
        .atualizarConfiguracao(
          ativo: draft.ativo,
          personalizacao: draft.personalizacao,
          baseUrl: _publicBaseUrl,
        );
    if (mounted) _applyConfiguration(updated);
    return updated;
  }

  Future<void> _save() async {
    if (_saving || !_dirty || _draft == null || _saved == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool unpublishing = _saved!.ativo && !_draft!.ativo;
    if (unpublishing) {
      await showSixWebCatalogUnpublishDialog(
        context: context,
        commerceName: _draft!.empresa.nome.isEmpty
            ? context.t(
                'catalog.publicPage.preview.storeFallback',
                fallback: 'Seu comércio',
              )
            : _draft!.empresa.nome,
        publicUrl: _draft!.url,
        onConfirm: () async {
          await _persistDraft();
        },
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final CatalogoPublicoConfiguracaoModel updated = await _persistDraft();
      if (!mounted) return;
      _showSnack(
        updated.ativo
            ? context.t(
                'catalog.publicPage.saveSuccessPublished',
                fallback: 'Catálogo salvo e publicado com sucesso.',
              )
            : context.t(
                'catalog.publicPage.saveSuccessDraft',
                fallback:
                    'Personalização salva. Publique quando estiver pronta.',
              ),
      );
    } catch (error) {
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

  Future<void> _openPublicPage() async {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || !saved.ativo) return;
    final Uri? uri = Uri.tryParse(saved.url);
    if (uri == null || !await launchExternalUri(uri)) {
      if (mounted) {
        _showSnack(
          context.t(
            'catalog.publicPage.openError',
            fallback: 'Não foi possível abrir o catálogo em uma nova aba.',
          ),
          error: true,
        );
      }
    }
  }

  Future<void> _copyLink() async {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || !saved.ativo) return;
    await Clipboard.setData(ClipboardData(text: saved.url));
    if (mounted) {
      _showSnack(
        context.t(
          'catalog.publicPage.linkCopied',
          fallback: 'Link público copiado.',
        ),
      );
    }
  }

  Future<void> _shareLink() async {
    final CatalogoPublicoConfiguracaoModel? saved = _saved;
    if (saved == null || !saved.ativo) return;
    final String title = saved.personalizacao.titulo.trim().isNotEmpty
        ? saved.personalizacao.titulo.trim()
        : saved.empresa.nome;
    final String message = <String>[
      title,
      saved.personalizacao.descricao.trim(),
      saved.url,
    ].where((String value) => value.isNotEmpty).join('\n\n');
    try {
      await sharing.Share.share(
        message,
        subject: context
            .t(
              'catalog.publicPage.shareSubject',
              fallback: 'Catálogo de {title}',
            )
            .replaceAll('{title}', title),
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

  void _showSnack(String message, {bool error = false}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? tokens.danger : tokens.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    if (_loading) {
      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: ColoredBox(
              color: tokens.workspaceBackground,
              child: Center(
                child: SixBackendLoading.messages(
                  animation: SixBackendLoadingAnimation.skeletonPulse,
                ),
              ),
            ),
          ),
          if (widget.onClose != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildCloseButton(tokens),
            ),
        ],
      );
    }
    if (_errorMessage.isNotEmpty || _draft == null) {
      return Stack(
        children: <Widget>[
          Positioned.fill(child: _buildError(tokens)),
          if (widget.onClose != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildCloseButton(tokens),
            ),
        ],
      );
    }

    return ColoredBox(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          _buildHeader(tokens),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool sideBySide = constraints.maxWidth >= 1180;
                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: 440,
                        child: _buildEditor(
                          tokens,
                          independentlyScrollable: true,
                        ),
                      ),
                      VerticalDivider(width: 1, color: tokens.divider),
                      Expanded(child: _buildPreviewArea(tokens)),
                    ],
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: Column(
                    children: <Widget>[
                      _buildEditor(tokens, independentlyScrollable: false),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: constraints.maxWidth < 720 ? 760 : 660,
                        child: _buildPreviewArea(tokens),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(WebThemeTokens tokens) {
    return ColoredBox(
      color: tokens.workspaceBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.cloud_off_outlined, size: 42, color: tokens.danger),
                const SizedBox(height: 14),
                Text(
                  context.t(
                    'catalog.publicPage.loadErrorTitle',
                    fallback: 'Não foi possível carregar o catálogo virtual',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.secondaryText),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.t('common.tryAgain', fallback: 'Tentar novamente'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WebThemeTokens tokens) {
    final CatalogoPublicoConfiguracaoModel saved = _saved!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;
          final Widget title = Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.storefront_outlined, color: tokens.info),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(
                        'catalog.publicPage.title',
                        fallback: 'Catálogo virtual',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.t(
                        'catalog.publicPage.subtitle',
                        fallback:
                            'Personalize, visualize e compartilhe sua vitrine em um só lugar.',
                      ),
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          );
          final List<Widget> actions = <Widget>[
            _statusPill(tokens, saved.ativo),
            OutlinedButton.icon(
              onPressed: saved.ativo ? _openPublicPage : null,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                context.t('catalog.publicPage.open', fallback: 'Abrir'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: saved.ativo ? _copyLink : null,
              icon: const Icon(Icons.copy_rounded),
              label: Text(
                context.t('catalog.publicPage.copy', fallback: 'Copiar link'),
              ),
            ),
            FilledButton.icon(
              onPressed: saved.ativo ? _shareLink : null,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(
                context.t('catalog.publicPage.share', fallback: 'Compartilhar'),
              ),
            ),
            if (widget.onClose != null)
              _buildCloseButton(tokens),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                title,
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: 18),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloseButton(WebThemeTokens tokens) {
    return IconButton(
      onPressed: _saving ? null : widget.onClose,
      tooltip: context.t('common.close', fallback: 'Fechar'),
      style: IconButton.styleFrom(
        foregroundColor: tokens.primaryText,
        backgroundColor: tokens.surfaceMuted,
        side: BorderSide(color: tokens.cardBorder),
        minimumSize: const Size(42, 42),
      ),
      icon: const Icon(Icons.close_rounded),
    );
  }

  Widget _statusPill(WebThemeTokens tokens, bool active) {
    final Color color = active ? tokens.success : tokens.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            active ? Icons.public_rounded : Icons.visibility_off_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            active
                ? context.t(
                    'catalog.publicPage.published',
                    fallback: 'Publicado',
                  )
                : context.t(
                    'catalog.publicPage.offline',
                    fallback: 'Fora do ar',
                  ),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(
    WebThemeTokens tokens, {
    required bool independentlyScrollable,
  }) {
    final Widget content = Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildPublicationCard(tokens),
            const SizedBox(height: 14),
            _editorSection(
              tokens: tokens,
              icon: Icons.text_fields_rounded,
              title: context.t(
                'catalog.publicPage.editor.content',
                fallback: 'Apresentação',
              ),
              subtitle: context.t(
                'catalog.publicPage.editor.contentHelp',
                fallback: 'Defina a mensagem que abre sua vitrine.',
              ),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    maxLength: 80,
                    decoration: _inputDecoration(
                      tokens,
                      context.t(
                        'catalog.publicPage.editor.titleLabel',
                        fallback: 'Título da vitrine',
                      ),
                      context.t(
                        'catalog.publicPage.editor.titleHint',
                        fallback: 'Ex.: Encontre o que precisa',
                      ),
                    ),
                    onChanged: (String value) => _updatePersonalization(
                      (CatalogoPublicoPersonalizacaoModel current) =>
                          current.copyWith(titulo: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    maxLength: 240,
                    decoration: _inputDecoration(
                      tokens,
                      context.t(
                        'catalog.publicPage.editor.descriptionLabel',
                        fallback: 'Descrição curta',
                      ),
                      context.t(
                        'catalog.publicPage.editor.descriptionHint',
                        fallback:
                            'Explique em uma frase o que o cliente encontrará.',
                      ),
                    ),
                    onChanged: (String value) => _updatePersonalization(
                      (CatalogoPublicoPersonalizacaoModel current) =>
                          current.copyWith(descricao: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _editorSection(
              tokens: tokens,
              icon: Icons.palette_outlined,
              title: context.t(
                'catalog.publicPage.editor.appearance',
                fallback: 'Aparência',
              ),
              subtitle: context.t(
                'catalog.publicPage.editor.appearanceHelp',
                fallback: 'Escolha o clima visual e a cor de destaque.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final CatalogoPublicoEstilo style
                      in CatalogoPublicoEstilo.values) ...<Widget>[
                    _styleOption(tokens, style),
                    if (style != CatalogoPublicoEstilo.values.last)
                      const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    context.t(
                      'catalog.publicPage.editor.accentColor',
                      fallback: 'Cor de destaque',
                    ),
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: <Widget>[
                      for (final String color in _accentColors)
                        _colorSwatch(tokens, color),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorController,
                    maxLength: 7,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9A-Fa-f#]'),
                      ),
                    ],
                    decoration: _inputDecoration(
                      tokens,
                      context.t(
                        'catalog.publicPage.editor.customColor',
                        fallback: 'Cor personalizada',
                      ),
                      '#126BFF',
                    ),
                    validator: (String? value) {
                      if (!_hasMinimumWhiteContrast(value ?? '')) {
                        return context.t(
                          'catalog.publicPage.editor.invalidColor',
                          fallback:
                              'Use uma cor hexadecimal com bom contraste, como #126BFF.',
                        );
                      }
                      return null;
                    },
                    onChanged: (String value) {
                      if (_hasMinimumWhiteContrast(value)) {
                        _updatePersonalization(
                          (CatalogoPublicoPersonalizacaoModel current) =>
                              current.copyWith(
                                corPrincipal: value.toUpperCase(),
                              ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _editorSection(
              tokens: tokens,
              icon: Icons.view_quilt_outlined,
              title: context.t(
                'catalog.publicPage.editor.layout',
                fallback: 'Conteúdo e layout',
              ),
              subtitle: context.t(
                'catalog.publicPage.editor.layoutHelp',
                fallback: 'Controle a densidade e as informações visíveis.',
              ),
              child: Column(
                children: <Widget>[
                  SegmentedButton<CatalogoPublicoDensidade>(
                    segments: <ButtonSegment<CatalogoPublicoDensidade>>[
                      ButtonSegment<CatalogoPublicoDensidade>(
                        value: CatalogoPublicoDensidade.confortavel,
                        icon: const Icon(Icons.grid_view_rounded),
                        label: Text(
                          context.t(
                            'catalog.publicPage.editor.comfortable',
                            fallback: 'Confortável',
                          ),
                        ),
                      ),
                      ButtonSegment<CatalogoPublicoDensidade>(
                        value: CatalogoPublicoDensidade.compacta,
                        icon: const Icon(Icons.apps_rounded),
                        label: Text(
                          context.t(
                            'catalog.publicPage.editor.compact',
                            fallback: 'Compacto',
                          ),
                        ),
                      ),
                    ],
                    selected: <CatalogoPublicoDensidade>{
                      _draft!.personalizacao.densidade,
                    },
                    onSelectionChanged: _saving
                        ? null
                        : (Set<CatalogoPublicoDensidade> value) {
                            _updatePersonalization(
                              (CatalogoPublicoPersonalizacaoModel current) =>
                                  current.copyWith(densidade: value.first),
                            );
                          },
                  ),
                  const SizedBox(height: 10),
                  _visibilitySwitch(
                    tokens,
                    icon: Icons.sell_outlined,
                    title: context.t(
                      'catalog.publicPage.editor.showPrices',
                      fallback: 'Exibir preços',
                    ),
                    value: _draft!.personalizacao.exibirPrecos,
                    onChanged: (bool value) => _updatePersonalization(
                      (CatalogoPublicoPersonalizacaoModel current) =>
                          current.copyWith(exibirPrecos: value),
                    ),
                  ),
                  _visibilitySwitch(
                    tokens,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: context.t(
                      'catalog.publicPage.editor.showContact',
                      fallback: 'Exibir contatos',
                    ),
                    value: _draft!.personalizacao.exibirContato,
                    onChanged: (bool value) => _updatePersonalization(
                      (CatalogoPublicoPersonalizacaoModel current) =>
                          current.copyWith(exibirContato: value),
                    ),
                  ),
                  _visibilitySwitch(
                    tokens,
                    icon: Icons.location_on_outlined,
                    title: context.t(
                      'catalog.publicPage.editor.showAddress',
                      fallback: 'Exibir endereço',
                    ),
                    value: _draft!.personalizacao.exibirEndereco,
                    onChanged: (bool value) => _updatePersonalization(
                      (CatalogoPublicoPersonalizacaoModel current) =>
                          current.copyWith(exibirEndereco: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _dirty && !_saving ? _resetDraft : null,
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
                    key: const Key('catalog-public-save'),
                    onPressed: _dirty && !_saving ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_done_outlined),
                    label: Text(
                      _saving
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
          ],
        ),
      ),
    );

    if (!independentlyScrollable) return content;
    return SingleChildScrollView(child: content);
  }

  Widget _buildPublicationCard(WebThemeTokens tokens) {
    final bool active = _draft!.ativo;
    final Color color = active ? tokens.success : tokens.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              active ? Icons.public_rounded : Icons.visibility_off_outlined,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'catalog.publicPage.editor.publication',
                    fallback: 'Catálogo publicado',
                  ),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? context.t(
                          'catalog.publicPage.editor.publicationOn',
                          fallback: 'Clientes podem acessar pelo link público.',
                        )
                      : context.t(
                          'catalog.publicPage.editor.publicationOff',
                          fallback: 'O link fica preservado, mas indisponível.',
                        ),
                  style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: active,
            onChanged: _saving
                ? null
                : (bool value) {
                    setState(() => _draft = _draft!.copyWith(ativo: value));
                  },
          ),
        ],
      ),
    );
  }

  Widget _editorSection({
    required WebThemeTokens tokens,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tokens.info, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    WebThemeTokens tokens,
    String label,
    String hint,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: tokens.inputBackground,
      alignLabelWithHint: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.info, width: 1.4),
      ),
    );
  }

  Widget _styleOption(WebThemeTokens tokens, CatalogoPublicoEstilo style) {
    final bool selected = _draft!.personalizacao.estilo == style;
    final (String, String, IconData) data = switch (style) {
      CatalogoPublicoEstilo.classico => (
        context.t('catalog.publicPage.style.classic', fallback: 'Clássico'),
        context.t(
          'catalog.publicPage.style.classicHelp',
          fallback: 'Profissional, equilibrado e familiar.',
        ),
        Icons.business_center_outlined,
      ),
      CatalogoPublicoEstilo.minimalista => (
        context.t('catalog.publicPage.style.minimal', fallback: 'Minimalista'),
        context.t(
          'catalog.publicPage.style.minimalHelp',
          fallback: 'Mais espaço, menos elementos visuais.',
        ),
        Icons.crop_free_rounded,
      ),
      CatalogoPublicoEstilo.expressivo => (
        context.t(
          'catalog.publicPage.style.expressive',
          fallback: 'Expressivo',
        ),
        context.t(
          'catalog.publicPage.style.expressiveHelp',
          fallback: 'Cor e contraste para destacar a marca.',
        ),
        Icons.auto_awesome_outlined,
      ),
    };
    return InkWell(
      onTap: _saving
          ? null
          : () => _updatePersonalization(
              (CatalogoPublicoPersonalizacaoModel current) =>
                  current.copyWith(estilo: style),
            ),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: WebThemeTokens.transitionDuration,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tokens.selectedBorder : tokens.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(data.$3, color: selected ? tokens.info : tokens.mutedText),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data.$1,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    data.$2,
                    style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? tokens.info : tokens.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorSwatch(WebThemeTokens tokens, String value) {
    final bool selected =
        _draft!.personalizacao.corPrincipal.toUpperCase() == value;
    final Color color = _parseColor(value);
    return Tooltip(
      message: value,
      child: InkWell(
        onTap: _saving
            ? null
            : () {
                _colorController.text = value;
                _updatePersonalization(
                  (CatalogoPublicoPersonalizacaoModel current) =>
                      current.copyWith(corPrincipal: value),
                );
              },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: WebThemeTokens.transitionDuration,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? tokens.primaryText : tokens.cardBorder,
              width: selected ? 3 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: selected ? 10 : 0,
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _visibilitySwitch(
    WebThemeTokens tokens, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: tokens.mutedText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: _saving ? null : onChanged),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(WebThemeTokens tokens) {
    return Container(
      color: tokens.surfaceMuted,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Row(
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
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _dirty
                          ? context.t(
                              'catalog.publicPage.preview.unsaved',
                              fallback:
                                  'Visualizando alterações ainda não salvas',
                            )
                          : context.t(
                              'catalog.publicPage.preview.saved',
                              fallback: 'Aparência salva no catálogo',
                            ),
                      style: TextStyle(
                        color: _dirty ? tokens.warning : tokens.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<_CatalogPreviewDevice>(
                showSelectedIcon: false,
                segments: <ButtonSegment<_CatalogPreviewDevice>>[
                  ButtonSegment<_CatalogPreviewDevice>(
                    value: _CatalogPreviewDevice.desktop,
                    icon: const Icon(Icons.desktop_windows_outlined),
                    tooltip: context.t(
                      'catalog.publicPage.preview.desktop',
                      fallback: 'Desktop',
                    ),
                  ),
                  ButtonSegment<_CatalogPreviewDevice>(
                    value: _CatalogPreviewDevice.mobile,
                    icon: const Icon(Icons.phone_iphone_rounded),
                    tooltip: context.t(
                      'catalog.publicPage.preview.mobile',
                      fallback: 'Celular',
                    ),
                  ),
                ],
                selected: <_CatalogPreviewDevice>{_previewDevice},
                onSelectionChanged: (Set<_CatalogPreviewDevice> value) {
                  setState(() => _previewDevice = value.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: _previewDevice == _CatalogPreviewDevice.mobile
                    ? 390
                    : double.infinity,
                constraints: BoxConstraints(
                  maxWidth: _previewDevice == _CatalogPreviewDevice.mobile
                      ? 390
                      : 1100,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _previewDevice == _CatalogPreviewDevice.mobile ? 28 : 18,
                  ),
                  border: Border.all(color: tokens.cardBorder),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x22020A18),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: _CatalogLivePreview(
                  configuration: _draft!,
                  mobile: _previewDevice == _CatalogPreviewDevice.mobile,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String value) {
    final String normalized = value.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  bool _hasMinimumWhiteContrast(String value) {
    final RegExpMatch? match = RegExp(
      r'^#([0-9A-Fa-f]{6})$',
    ).firstMatch(value.trim());
    if (match == null) return false;
    final int raw = int.parse(match.group(1)!, radix: 16);
    double channel(int value) {
      final double normalized = value / 255;
      return normalized <= 0.04045
          ? normalized / 12.92
          : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
    }

    final double luminance =
        (0.2126 * channel(raw >> 16)) +
        (0.7152 * channel((raw >> 8) & 0xFF)) +
        (0.0722 * channel(raw & 0xFF));
    return 1.05 / (luminance + 0.05) >= 3;
  }
}

class _CatalogLivePreview extends StatelessWidget {
  const _CatalogLivePreview({
    required this.configuration,
    required this.mobile,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final CatalogoPublicoPersonalizacaoModel customization =
        configuration.personalizacao;
    final Color accent = _parseColor(customization.corPrincipal);
    final Color background = switch (customization.estilo) {
      CatalogoPublicoEstilo.classico => const Color(0xFFF4F7FA),
      CatalogoPublicoEstilo.minimalista => const Color(0xFFFFFFFF),
      CatalogoPublicoEstilo.expressivo => _mix(accent, Colors.white, 0.93),
    };
    final Color ink = switch (customization.estilo) {
      CatalogoPublicoEstilo.expressivo => _mix(
        accent,
        const Color(0xFF06152E),
        0.22,
      ),
      _ => const Color(0xFF10253E),
    };
    final String companyName = configuration.empresa.nome.isEmpty
        ? context.t(
            'catalog.publicPage.preview.storeFallback',
            fallback: 'Seu comércio',
          )
        : configuration.empresa.nome;
    final String heroTitle = customization.titulo.trim().isEmpty
        ? companyName
        : customization.titulo.trim();
    final double padding = mobile ? 14 : 20;

    return ColoredBox(
      color: background,
      child: Column(
        children: <Widget>[
          Container(
            height: mobile ? 52 : 58,
            padding: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              color: customization.estilo == CatalogoPublicoEstilo.expressivo
                  ? _mix(accent, const Color(0xFF00163A), 0.28)
                  : Colors.white.withValues(alpha: 0.96),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: <Widget>[
                _logo(
                  configuration.empresa.logoBase64,
                  accent,
                  mobile ? 30 : 34,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          customization.estilo ==
                              CatalogoPublicoEstilo.expressivo
                          ? Colors.white
                          : ink,
                      fontWeight: FontWeight.w900,
                      fontSize: mobile ? 12 : 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          customization.estilo ==
                              CatalogoPublicoEstilo.expressivo
                          ? Colors.white24
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    'PT · EN · ES',
                    style: TextStyle(
                      color:
                          customization.estilo ==
                              CatalogoPublicoEstilo.expressivo
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontSize: mobile ? 8 : 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(mobile ? 14 : 20),
                    decoration: BoxDecoration(
                      gradient: switch (customization.estilo) {
                        CatalogoPublicoEstilo.classico => LinearGradient(
                          colors: <Color>[
                            Colors.white,
                            _mix(accent, Colors.white, 0.91),
                          ],
                        ),
                        CatalogoPublicoEstilo.minimalista => null,
                        CatalogoPublicoEstilo.expressivo => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            _mix(accent, const Color(0xFF00163A), 0.20),
                            accent,
                          ],
                        ),
                      },
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(mobile ? 16 : 20),
                      border: Border.all(
                        color:
                            customization.estilo ==
                                CatalogoPublicoEstilo.expressivo
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: mobile
                        ? _heroContent(
                            context,
                            customization,
                            accent,
                            ink,
                            heroTitle,
                            companyName,
                            true,
                          )
                        : Row(
                            children: <Widget>[
                              _logo(
                                configuration.empresa.logoBase64,
                                accent,
                                58,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _heroContent(
                                  context,
                                  customization,
                                  accent,
                                  ink,
                                  heroTitle,
                                  companyName,
                                  false,
                                ),
                              ),
                              if (customization.exibirContato)
                                _contactPill(customization, accent),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.t(
                                'catalog.publicPage.preview.products',
                                fallback: 'Produtos disponíveis',
                              ),
                              style: TextStyle(
                                color: accent,
                                fontSize: mobile ? 9 : 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            Text(
                              context.t(
                                'catalog.publicPage.preview.chooseItems',
                                fallback: 'Escolha seus itens',
                              ),
                              style: TextStyle(
                                color: ink,
                                fontSize: mobile ? 15 : 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!mobile)
                        Container(
                          width: 190,
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Buscar...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _products(context, customization, accent, ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroContent(
    BuildContext context,
    CatalogoPublicoPersonalizacaoModel customization,
    Color accent,
    Color ink,
    String title,
    String companyName,
    bool mobileLayout,
  ) {
    final bool expressive =
        customization.estilo == CatalogoPublicoEstilo.expressivo;
    final Color foreground = expressive ? Colors.white : ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (mobileLayout) ...<Widget>[
          Row(
            children: <Widget>[
              _logo(configuration.empresa.logoBase64, accent, 44),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: mobileLayout ? 20 : 25,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (customization.descricao.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            customization.descricao.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.72),
              fontSize: mobileLayout ? 10 : 11,
              height: 1.35,
            ),
          ),
        ],
        if (customization.exibirEndereco &&
            configuration.empresa.endereco.isNotEmpty) ...<Widget>[
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Icon(
                Icons.location_on_outlined,
                color: foreground.withValues(alpha: 0.75),
                size: 13,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  configuration.empresa.endereco,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.72),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (mobileLayout && customization.exibirContato) ...<Widget>[
          const SizedBox(height: 10),
          _contactPill(customization, accent),
        ],
      ],
    );
  }

  Widget _contactPill(
    CatalogoPublicoPersonalizacaoModel customization,
    Color accent,
  ) {
    final bool expressive =
        customization.estilo == CatalogoPublicoEstilo.expressivo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: expressive ? Colors.white.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: expressive ? Colors.white24 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 12,
            color: expressive ? Colors.white : accent,
          ),
          const SizedBox(width: 5),
          Text(
            configuration.empresa.whatsapp.isNotEmpty ? 'WhatsApp' : 'Contato',
            style: TextStyle(
              color: expressive ? Colors.white : accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _products(
    BuildContext context,
    CatalogoPublicoPersonalizacaoModel customization,
    Color accent,
    Color ink,
  ) {
    final List<CatalogoPublicoProdutoPreviewModel> products = configuration
        .produtos
        .take(mobile ? 3 : 6)
        .toList(growable: false);
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, color: accent, size: 28),
            const SizedBox(height: 8),
            Text(
              context.t(
                'catalog.publicPage.preview.empty',
                fallback: 'Marque produtos como disponíveis para o catálogo.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final int columns = mobile
        ? 1
        : customization.densidade == CatalogoPublicoDensidade.compacta
        ? 3
        : 2;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing =
            customization.densidade == CatalogoPublicoDensidade.compacta
            ? 8
            : 12;
        final double width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final CatalogoPublicoProdutoPreviewModel product in products)
              SizedBox(
                width: width,
                child: _productCard(
                  context,
                  product,
                  customization,
                  accent,
                  ink,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _productCard(
    BuildContext context,
    CatalogoPublicoProdutoPreviewModel product,
    CatalogoPublicoPersonalizacaoModel customization,
    Color accent,
    Color ink,
  ) {
    final bool compact =
        customization.densidade == CatalogoPublicoDensidade.compacta;
    final String formattedPrice = context
        .read<LocaleSettingsProvider>()
        .formatCurrency(product.preco);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: mobile
          ? Row(
              children: <Widget>[
                SizedBox(
                  width: 86,
                  height: 92,
                  child: _productImage(product, accent),
                ),
                Expanded(
                  child: _productCopy(
                    product,
                    formattedPrice,
                    customization,
                    accent,
                    ink,
                    compact,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: compact ? 1.7 : 1.45,
                  child: _productImage(product, accent),
                ),
                _productCopy(
                  product,
                  formattedPrice,
                  customization,
                  accent,
                  ink,
                  compact,
                ),
              ],
            ),
    );
  }

  Widget _productCopy(
    CatalogoPublicoProdutoPreviewModel product,
    String formattedPrice,
    CatalogoPublicoPersonalizacaoModel customization,
    Color accent,
    Color ink,
    bool compact,
  ) {
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            product.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (product.modelo.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              product.modelo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
            ),
          ],
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              if (customization.exibirPrecos)
                Expanded(
                  child: Text(
                    formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                const Spacer(),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productImage(
    CatalogoPublicoProdutoPreviewModel product,
    Color accent,
  ) {
    final String source = product.imagemBase64;
    if (source.isNotEmpty) {
      try {
        final String payload = source.contains(',')
            ? source.split(',').last
            : source;
        return Image.memory(
          base64Decode(payload),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(accent),
        );
      } catch (_) {
        return _placeholder(accent);
      }
    }
    if (product.imagemUrl.isNotEmpty) {
      return Image.network(
        product.imagemUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(accent),
      );
    }
    return _placeholder(accent);
  }

  Widget _placeholder(Color accent) {
    return ColoredBox(
      color: _mix(accent, Colors.white, 0.91),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: accent.withValues(alpha: 0.58),
        ),
      ),
    );
  }

  Widget _logo(String raw, Color accent, double size) {
    final Widget fallback = Icon(
      Icons.storefront_rounded,
      color: accent,
      size: size * 0.5,
    );
    Widget child = fallback;
    if (raw.isNotEmpty) {
      try {
        final String payload = raw.contains(',') ? raw.split(',').last : raw;
        final Uint8List bytes = base64Decode(payload);
        child = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        // Mantém o fallback visual quando a imagem cadastrada estiver inválida.
      }
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _mix(accent, Colors.white, 0.90),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: child,
    );
  }

  Color _parseColor(String value) {
    final String normalized = value.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color _mix(
    Color foreground,
    Color background,
    double backgroundWeight,
  ) {
    return Color.lerp(foreground, background, backgroundWeight)!;
  }
}
