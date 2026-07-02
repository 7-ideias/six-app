import 'package:flutter/material.dart';
import 'package:sixpos/core/services/empresa_service.dart';
import 'package:sixpos/data/models/empresa_model.dart';
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
      body: const SafeArea(
        child: EmpresaConfiguracaoForm(embedded: false),
      ),
    );
  }
}

class EmpresaConfiguracaoForm extends StatefulWidget {
  const EmpresaConfiguracaoForm({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<EmpresaConfiguracaoForm> createState() => _EmpresaConfiguracaoFormState();
}

class _EmpresaConfiguracaoFormState extends State<EmpresaConfiguracaoForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeEmpresaController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final EmpresaService _empresaService = EmpresaService();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
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
        _erro = 'Não foi possível carregar os dados da empresa.';
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
    );

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final EmpresaModel atualizada = await _empresaService.atualizarDadosDaEmpresa(empresa);
      if (!mounted) return;
      setState(() {
        _empresaOriginal = atualizada;
        _salvando = false;
      });
      _mostrarMensagem('Dados da empresa atualizados com sucesso.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar os dados da empresa.';
      });
      _mostrarMensagem('Não foi possível salvar os dados da empresa.', erro: true);
    }
  }

  void _aplicarEmpresa(EmpresaModel empresa, {required bool atualizarEstado}) {
    final void Function() apply = () {
      _empresaOriginal = empresa;
      _nomeEmpresaController.text = _limparPlaceholder(empresa.nomeEmpresa);
      _nomeFantasiaController.text = _limparPlaceholder(empresa.nomeFantasia);
      _documentoController.text = _limparPlaceholder(empresa.documentoNoBrasilCNPJ);
    };

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

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = widget.embedded
        ? EdgeInsets.zero
        : const EdgeInsets.fromLTRB(16, 16, 16, 24);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: SixStaggeredEntry(
            delay: const Duration(milliseconds: 70),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.embedded ? 0 : constraints.maxHeight - 40),
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
        _buildFormCard(theme, availableWidth),
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

  Widget _buildFormCard(ThemeData theme, double availableWidth) {
    final bool compacto = availableWidth < 760;
    final double spacing = compacto ? 12 : 16;
    final double larguraCampo = compacto ? availableWidth : (availableWidth - spacing) / 2;

    return Container(
      padding: EdgeInsets.all(compacto ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(widget.embedded ? 0.03 : 0.05),
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
                    label: 'Razão social',
                    hint: 'Nome legal da empresa',
                    icon: Icons.apartment_rounded,
                    required: true,
                  ),
                ),
                SizedBox(
                  width: larguraCampo,
                  child: _buildTextField(
                    controller: _nomeFantasiaController,
                    label: 'Nome fantasia',
                    hint: 'Nome comercial usado no atendimento',
                    icon: Icons.storefront_rounded,
                  ),
                ),
                SizedBox(
                  width: larguraCampo,
                  child: _buildTextField(
                    controller: _documentoController,
                    label: 'Documento da empresa',
                    hint: 'CNPJ ou documento fiscal equivalente',
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
            color: theme.colorScheme.primary.withOpacity(0.10),
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
    bool required = false,
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
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Informe este campo.';
        }
        return null;
      },
    );
  }

  Widget _buildActions(bool compacto) {
    final Widget saveButton = FilledButton.icon(
      onPressed: _salvando ? null : _salvar,
      icon: _salvando
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
      children: <Widget>[
        reloadButton,
        const SizedBox(width: 12),
        saveButton,
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final String resumo = _empresaOriginal == null
        ? 'Aguardando dados da empresa.'
        : 'Dados carregados e prontos para edição.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
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
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
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
