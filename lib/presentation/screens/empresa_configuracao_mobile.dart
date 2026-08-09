import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/empresa_service.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/providers/empresa_provider.dart';

class EmpresaConfiguracaoMobile extends StatefulWidget {
  const EmpresaConfiguracaoMobile({
    super.key,
    this.carregarEmpresa,
    this.salvarEmpresa,
  });

  final Future<EmpresaModel> Function()? carregarEmpresa;
  final Future<EmpresaModel> Function(EmpresaModel empresa)? salvarEmpresa;

  @override
  State<EmpresaConfiguracaoMobile> createState() =>
      _EmpresaConfiguracaoMobileState();
}

class _EmpresaConfiguracaoMobileState extends State<EmpresaConfiguracaoMobile> {
  static const int _maxLogoBytes = 1024 * 1024;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeEmpresaController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final EmpresaService _empresaService = EmpresaService();

  bool _carregando = true;
  bool _salvando = false;
  bool _selecionandoLogo = false;
  String? _erro;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _preencherComProvider();
    _carregarEmpresa();
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _nomeFantasiaController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  void _preencherComProvider() {
    final EmpresaModel? empresa = EmpresaProvider().empresa;
    if (empresa == null) return;
    _aplicarEmpresa(empresa, atualizarEstado: false);
  }

  Future<void> _carregarEmpresa() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final EmpresaModel empresa =
          await (widget.carregarEmpresa?.call() ??
              _empresaService.buscarDadosDaEmpresa());
      if (!mounted) return;
      setState(() {
        _aplicarEmpresa(empresa, atualizarEstado: false);
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = context.t(
          'empresa.configuracao.loadError',
          fallback: 'Não foi possível carregar os dados da empresa.',
        );
      });
    }
  }

  Future<void> _salvar() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();

    final EmpresaModel empresa = EmpresaModel(
      nomeEmpresa: _nomeEmpresaController.text.trim(),
      nomeFantasia: _nomeFantasiaController.text.trim(),
      documentoNoBrasilCNPJ: _documentoController.text.trim(),
      logoBase64: _logoBase64,
    );

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final EmpresaModel atualizada =
          await (widget.salvarEmpresa?.call(empresa) ??
              _empresaService.atualizarDadosDaEmpresa(empresa));
      if (!mounted) return;
      setState(() {
        _aplicarEmpresa(atualizada, atualizarEstado: false);
        _salvando = false;
      });
      _mostrarMensagem(
        context.t(
          'empresa.configuracao.saveSuccess',
          fallback: 'Dados da empresa atualizados com sucesso.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final String mensagem = context.t(
        'empresa.configuracao.saveError',
        fallback: 'Não foi possível salvar os dados da empresa.',
      );
      setState(() {
        _salvando = false;
        _erro = mensagem;
      });
      _mostrarMensagem(mensagem, erro: true);
    }
  }

  void _aplicarEmpresa(EmpresaModel empresa, {required bool atualizarEstado}) {
    void apply() {
      _nomeEmpresaController.text = _limparPlaceholder(empresa.nomeEmpresa);
      _nomeFantasiaController.text = _limparPlaceholder(empresa.nomeFantasia);
      _documentoController.text = _limparPlaceholder(
        empresa.documentoNoBrasilCNPJ,
      );
      _logoBase64 = _limparLogo(empresa.logoBase64);
    }

    if (atualizarEstado) {
      setState(apply);
    } else {
      apply();
    }
  }

  String _limparPlaceholder(String value) {
    final String normalizado = value.trim();
    return normalizado.toUpperCase() == 'NO DATA' ? '' : normalizado;
  }

  String _limparLogo(String? value) {
    final String normalizado = (value ?? '').trim();
    return normalizado.toUpperCase() == 'NO DATA' ? '' : normalizado;
  }

  Future<void> _abrirSelecionadorLogo() async {
    if (_carregando || _salvando || _selecionandoLogo) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      useSafeArea: true,
      builder: (BuildContext context) {
        return const _EmpresaLogoSourceSheet();
      },
    );

    if (source == null || !mounted) return;
    await _selecionarLogo(source);
  }

  Future<void> _selecionarLogo(ImageSource source) async {
    setState(() => _selecionandoLogo = true);

    try {
      final XFile? arquivo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 82,
      );

      if (!mounted) return;

      if (arquivo == null) {
        setState(() => _selecionandoLogo = false);
        return;
      }

      final Uint8List bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        throw const FormatException('Imagem vazia.');
      }

      if (bytes.length > _maxLogoBytes) {
        setState(() => _selecionandoLogo = false);
        _mostrarMensagem(
          context.t(
            'empresa.configuracao.logoTooLarge',
            fallback: 'Escolha uma imagem de até 1 MB.',
          ),
          erro: true,
        );
        return;
      }

      final String mimeType =
          arquivo.mimeType ?? _mimeTypeFromName(arquivo.name) ?? 'image/jpeg';

      setState(() {
        _logoBase64 = 'data:$mimeType;base64,${base64Encode(bytes)}';
        _selecionandoLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _selecionandoLogo = false);
      _mostrarMensagem(
        context.t(
          'empresa.configuracao.logoLoadError',
          fallback: 'Não foi possível carregar o logo.',
        ),
        erro: true,
      );
    }
  }

  void _removerLogo() {
    if (_carregando || _salvando || _selecionandoLogo) return;
    setState(() => _logoBase64 = '');
  }

  String? _mimeTypeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? SixMobilePalette.error : SixMobilePalette.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: context.t('empresa.configuracao.title', fallback: 'Empresa'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      leading: BackButton(
        color: SixMobilePalette.onPrimary,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bodyBuilder: _buildBody,
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _salvando ? () async {} : _carregarEmpresa,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 112),
          children: <Widget>[
            _MotionEntry(
              enabled: !reduceMotion,
              delay: Duration(milliseconds: 80),
              child: _buildSummaryCard(context),
            ),
            SizedBox(height: 14),
            AnimatedSwitcher(
              duration:
                  reduceMotion ? Duration.zero : Duration(milliseconds: 220),
              child:
                  _carregando
                      ? const _EmpresaMobileSkeleton(
                        key: ValueKey<String>('empresa-loading'),
                      )
                      : _buildLoadedContent(context, reduceMotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, bool reduceMotion) {
    return Column(
      key: ValueKey<String>('empresa-loaded'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_erro != null) ...<Widget>[
          _buildErrorCard(context),
          SizedBox(height: 14),
        ],
        _MotionEntry(
          enabled: !reduceMotion,
          delay: Duration(milliseconds: 130),
          child: _buildFormCard(context),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow.withValues(alpha: 0.78),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: SixMobilePalette.onPrimary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(
                      'empresa.configuracao.summaryTitle',
                      fallback: 'Dados do comércio',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.onPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.t(
                      'empresa.configuracao.summarySubtitle',
                      fallback:
                          'Atualize as informações usadas nos documentos e no atendimento.',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.heroSupportingText,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.errorBorder.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: SixMobilePalette.error,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _erro!,
              style: TextStyle(
                color: SixMobilePalette.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 8),
          TextButton(
            onPressed: _salvando ? null : _carregarEmpresa,
            child: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow.withValues(alpha: 0.50),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionHeader(context),
            SizedBox(height: 16),
            _EmpresaLogoPicker(
              logoValue: _logoBase64,
              isBusy: _selecionandoLogo,
              onSelect: _abrirSelecionadorLogo,
              onRemove: _removerLogo,
            ),
            SizedBox(height: 14),
            _EmpresaMobileTextField(
              controller: _nomeEmpresaController,
              label: context.t(
                'empresa.configuracao.legalName',
                fallback: 'Razão social',
              ),
              hint: context.t(
                'empresa.configuracao.legalNameHint',
                fallback: 'Nome legal da empresa',
              ),
              icon: Icons.apartment_rounded,
              isRequired: true,
            ),
            SizedBox(height: 12),
            _EmpresaMobileTextField(
              controller: _nomeFantasiaController,
              label: context.t(
                'empresa.configuracao.tradeName',
                fallback: 'Nome fantasia',
              ),
              hint: context.t(
                'empresa.configuracao.tradeNameHint',
                fallback: 'Nome comercial usado no atendimento',
              ),
              icon: Icons.storefront_rounded,
            ),
            SizedBox(height: 12),
            _EmpresaMobileTextField(
              controller: _documentoController,
              label: context.t(
                'empresa.configuracao.document',
                fallback: 'Documento da empresa',
              ),
              hint: context.t(
                'empresa.configuracao.documentHint',
                fallback: 'CNPJ ou documento fiscal equivalente',
              ),
              icon: Icons.badge_rounded,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: SixMobilePalette.softAccentSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SixMobilePalette.highlightedBorder.withValues(alpha: 0.48),
            ),
          ),
          child: Icon(
            Icons.domain_rounded,
            color: SixMobilePalette.accent,
            size: 22,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.t(
                  'empresa.configuracao.identityTitle',
                  fallback: 'Identidade da empresa',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.titleText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                context.t(
                  'empresa.configuracao.identitySubtitle',
                  fallback:
                      'Revise os dados principais antes de salvar as alterações.',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: SixMobilePalette.border, width: 0.6),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow.withValues(alpha: 0.75),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: _salvando || _carregando ? null : _salvar,
                icon:
                    _salvando
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(Icons.save_rounded),
                label: Text(
                  _salvando
                      ? context.t('common.saving', fallback: 'Salvando...')
                      : context.t(
                        'empresa.configuracao.saveChanges',
                        fallback: 'Salvar alterações',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmpresaLogoPicker extends StatelessWidget {
  const _EmpresaLogoPicker({
    required this.logoValue,
    required this.isBusy,
    required this.onSelect,
    required this.onRemove,
  });

  final String? logoValue;
  final bool isBusy;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  bool get _hasLogo => (logoValue ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          _hasLogo
              ? context.t(
                'empresa.configuracao.logoSemantics',
                fallback: 'Logo cadastrado da empresa.',
              )
              : context.t(
                'empresa.configuracao.logoEmptySemantics',
                fallback: 'Nenhum logo cadastrado.',
              ),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EmpresaLogoPreview(logoValue: logoValue, isBusy: isBusy),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(
                      'empresa.configuracao.logoTitle',
                      fallback: 'Logo da empresa',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _hasLogo
                        ? context.t(
                          'empresa.configuracao.logoRegistered',
                          fallback:
                              'Imagem pronta para salvar no cadastro do comércio.',
                        )
                        : context.t(
                          'empresa.configuracao.logoSubtitle',
                          fallback:
                              'Adicione uma imagem nítida, de preferência quadrada.',
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: isBusy ? null : onSelect,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(0, 38),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: Icon(
                          _hasLogo
                              ? Icons.change_circle_outlined
                              : Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _hasLogo
                              ? context.t(
                                'empresa.configuracao.logoChange',
                                fallback: 'Trocar logo',
                              )
                              : context.t(
                                'empresa.configuracao.logoSelect',
                                fallback: 'Selecionar logo',
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_hasLogo)
                        TextButton.icon(
                          onPressed: isBusy ? null : onRemove,
                          icon: Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(
                            context.t(
                              'empresa.configuracao.logoRemove',
                              fallback: 'Remover',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmpresaLogoPreview extends StatelessWidget {
  const _EmpresaLogoPreview({required this.logoValue, required this.isBusy});

  final String? logoValue;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _decodeLogoBytes(logoValue);
    final String value = (logoValue ?? '').trim();
    final bool isUrl =
        value.startsWith('http://') || value.startsWith('https://');
    final Widget content;

    if (bytes != null) {
      content = Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    } else if (isUrl) {
      content = Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 82,
          height: 82,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SixMobilePalette.activeBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
        if (isBusy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SixMobilePalette.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SixMobilePalette.iconSurface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: SixMobilePalette.accent,
          size: 28,
        ),
      ),
    );
  }
}

class _EmpresaLogoSourceSheet extends StatelessWidget {
  const _EmpresaLogoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SixMobilePalette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow.withValues(
                  alpha: 0.82,
                ),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.softAccentSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: SixMobilePalette.highlightedBorder.withValues(
                          alpha: 0.48,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: SixMobilePalette.accent,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(
                            'empresa.configuracao.logoSheetTitle',
                            fallback: 'Cadastrar logo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.titleText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          context.t(
                            'empresa.configuracao.logoSheetSubtitle',
                            fallback:
                                'Escolha uma imagem da galeria ou tire uma foto.',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _EmpresaLogoSourceOption(
                icon: Icons.photo_library_outlined,
                title: context.t(
                  'empresa.configuracao.logoFromGallery',
                  fallback: 'Escolher da galeria',
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              SizedBox(height: 8),
              _EmpresaLogoSourceOption(
                icon: Icons.photo_camera_outlined,
                title: context.t(
                  'empresa.configuracao.logoFromCamera',
                  fallback: 'Usar câmera',
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpresaLogoSourceOption extends StatelessWidget {
  const _EmpresaLogoSourceOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SixMobilePalette.softNeutralSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(icon, color: SixMobilePalette.accent, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SixMobilePalette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Uint8List? _decodeLogoBytes(String? value) {
  final String normalizado = (value ?? '').trim();
  if (normalizado.isEmpty ||
      normalizado.startsWith('http://') ||
      normalizado.startsWith('https://')) {
    return null;
  }

  String payload = normalizado;
  if (payload.toLowerCase().startsWith('data:') && payload.contains(',')) {
    payload = payload.substring(payload.indexOf(',') + 1);
  }

  try {
    return base64Decode(
      base64.normalize(
        payload
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('-', '+')
            .replaceAll('_', '/'),
      ),
    );
  } catch (_) {
    return null;
  }
}

class _EmpresaMobileTextField extends StatelessWidget {
  const _EmpresaMobileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 21),
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SixMobilePalette.highlightedBorder,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.errorBorder),
        ),
      ),
      validator: (String? value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return context.t(
            'empresa.configuracao.requiredField',
            fallback: 'Informe este campo.',
          );
        }
        return null;
      },
    );
  }
}

class _EmpresaMobileSkeleton extends StatelessWidget {
  const _EmpresaMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t('common.loading', fallback: 'Carregando...'),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                _SkeletonBox(width: 42, height: 42, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SkeletonBox(width: 180, height: 16),
                      SizedBox(height: 8),
                      _SkeletonBox(width: double.infinity, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            _SkeletonBox(width: double.infinity, height: 108, radius: 18),
            SizedBox(height: 12),
            _SkeletonBox(width: double.infinity, height: 58, radius: 16),
            SizedBox(height: 12),
            _SkeletonBox(width: double.infinity, height: 58, radius: 16),
            SizedBox(height: 12),
            _SkeletonBox(width: double.infinity, height: 58, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    final Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.activeBorder.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (reduceMotion) return box;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.42, end: 1),
      duration: Duration(milliseconds: 760),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: box,
    );
  }
}

class _MotionEntry extends StatelessWidget {
  const _MotionEntry({
    required this.child,
    required this.enabled,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool enabled;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return SixStaggeredEntry(delay: delay, child: child);
  }
}
