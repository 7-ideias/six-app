import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/empresa_service.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/providers/empresa_provider.dart';

class EmpresaConfiguracaoScreen extends StatelessWidget {
  const EmpresaConfiguracaoScreen({super.key});

  static const Color _mobileBackgroundColor = Color(0xFFF4F7FB);
  static const Color _mobilePrimaryColor = Color(0xFF0B1F3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mobileBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _mobilePrimaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text(
          'Empresa',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: const SafeArea(child: EmpresaConfiguracaoForm(embedded: false)),
    );
  }
}

class EmpresaConfiguracaoForm extends StatefulWidget {
  const EmpresaConfiguracaoForm({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmpresaConfiguracaoForm> createState() =>
      _EmpresaConfiguracaoFormState();
}

class _EmpresaConfiguracaoFormState extends State<EmpresaConfiguracaoForm> {
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
  EmpresaModel? _empresaOriginal;

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
      final EmpresaModel empresa = await _empresaService.buscarDadosDaEmpresa();
      if (!mounted) return;
      setState(() {
        _aplicarEmpresa(empresa, atualizarEstado: false);
        _carregando = false;
      });
    } catch (e) {
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
      final EmpresaModel atualizada = await _empresaService
          .atualizarDadosDaEmpresa(empresa);
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
    } catch (e) {
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
      _empresaOriginal = empresa;
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

  Future<void> _selecionarLogo() async {
    if (_carregando || _salvando || _selecionandoLogo) return;

    setState(() => _selecionandoLogo = true);

    try {
      final XFile? arquivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
            erro ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding =
        widget.embedded
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(16, 16, 16, 24);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: SixStaggeredEntry(
            delay: const Duration(milliseconds: 70),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.embedded ? 0 : constraints.maxHeight - 40,
              ),
              child: _buildContent(context, constraints.maxWidth),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, double availableWidth) {
    final ThemeData theme = Theme.of(context);

    if (_carregando) {
      return _EmpresaSkeleton(embedded: widget.embedded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.embedded) _buildMobileHero(theme),
        if (!widget.embedded) const SizedBox(height: 18),
        if (_erro != null) ...<Widget>[
          _buildErrorCard(theme),
          const SizedBox(height: 16),
        ],
        _buildFormCard(context, theme, availableWidth),
        const SizedBox(height: 16),
        _buildInfoCard(theme),
      ],
    );
  }

  Widget _buildMobileHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0B1F3A), Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dados do comércio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mantenha a identidade da empresa sincronizada com o backend.',
                  style: TextStyle(color: Color(0xCCE2E8F0), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _carregando ? null : _carregarEmpresa,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    ThemeData theme,
    double availableWidth,
  ) {
    final bool compacto = availableWidth < 760;
    final double horizontalPadding = compacto ? 32 : 44;
    final double contentWidth = (availableWidth - horizontalPadding).clamp(
      0.0,
      double.infinity,
    );
    final double spacing = compacto ? 12 : 16;
    final double larguraCampo =
        compacto ? contentWidth : (contentWidth - spacing) / 2;

    return Container(
      padding: EdgeInsets.all(compacto ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.embedded ? 0.03 : 0.05,
            ),
            blurRadius: widget.embedded ? 18 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionHeader(theme),
            const SizedBox(height: 20),
            Wrap(
              spacing: spacing,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: larguraCampo,
                  child: _buildTextField(
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
                ),
                SizedBox(
                  width: larguraCampo,
                  child: _EmpresaWebLogoPicker(
                    logoValue: _logoBase64,
                    isBusy: _selecionandoLogo,
                    onSelect: _selecionarLogo,
                    onRemove: _removerLogo,
                  ),
                ),
                SizedBox(
                  width: larguraCampo,
                  child: _buildTextField(
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
                ),
                SizedBox(
                  width: larguraCampo,
                  child: _buildTextField(
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
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildActions(compacto),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.domain_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Identidade institucional',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Esses dados vêm do backend e serão usados como base para documentos, comprovantes e identificação do comércio.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildActions(bool compacto) {
    final Widget saveButton = FilledButton.icon(
      onPressed: _salvando ? null : _salvar,
      icon:
          _salvando
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.save_rounded),
      label: Text(_salvando ? 'Salvando...' : 'Salvar alterações'),
    );

    final Widget reloadButton = OutlinedButton.icon(
      onPressed: _salvando ? null : _carregarEmpresa,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Recarregar'),
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          saveButton,
          const SizedBox(height: 10),
          reloadButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[reloadButton, const SizedBox(width: 12), saveButton],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final String resumo =
        _empresaOriginal == null
            ? 'Aguardando dados da empresa.'
            : 'Dados carregados e prontos para edição.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  resumo,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A mesma camada de service é usada na web, Android e iOS para consultar e salvar os dados.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpresaWebLogoPicker extends StatelessWidget {
  const _EmpresaWebLogoPicker({
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
    final ThemeData theme = Theme.of(context);

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.42,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EmpresaWebLogoPreview(logoValue: logoValue, isBusy: isBusy),
            const SizedBox(width: 14),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: isBusy ? null : onSelect,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
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

class _EmpresaWebLogoPreview extends StatelessWidget {
  const _EmpresaWebLogoPreview({required this.logoValue, required this.isBusy});

  final String? logoValue;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
        errorBuilder: (_, _, _) => _buildFallback(theme),
      );
    } else if (isUrl) {
      content = Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallback(theme),
      );
    } else {
      content = _buildFallback(theme);
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
        if (isBusy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
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

  Widget _buildFallback(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.primary,
          size: 30,
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

class _EmpresaSkeleton extends StatelessWidget {
  const _EmpresaSkeleton({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(embedded ? 22 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _skeletonBox(width: 48, height: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonBox(width: 220, height: 18),
                    const SizedBox(height: 8),
                    _skeletonBox(width: 360, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _skeletonBox(width: double.infinity, height: 58),
          const SizedBox(height: 12),
          _skeletonBox(width: double.infinity, height: 58),
          const SizedBox(height: 12),
          _skeletonBox(width: double.infinity, height: 58),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
