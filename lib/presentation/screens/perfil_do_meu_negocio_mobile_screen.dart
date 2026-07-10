import 'package:flutter/material.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/empresa_service.dart';
import 'package:sixpos/data/models/empresa_model.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/assinatura_mobile_screen.dart';
import 'package:sixpos/presentation/screens/seguimento_mobile_screen.dart';
import 'package:sixpos/providers/empresa_provider.dart';

class PerfilDoMeuNegocioMobileScreen extends StatefulWidget {
  const PerfilDoMeuNegocioMobileScreen({super.key});

  @override
  State<PerfilDoMeuNegocioMobileScreen> createState() =>
      _PerfilDoMeuNegocioMobileScreenState();
}

class _PerfilDoMeuNegocioMobileScreenState
    extends State<PerfilDoMeuNegocioMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _surfaceColor = Colors.white;
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _softBlueColor = Color(0xFFEFF6FF);
  static const Color _inputBackgroundColor = Color(0xFFF8FAFC);

  final EmpresaProvider _empresaProvider = EmpresaProvider();
  final EmpresaService _empresaService = EmpresaService();

  final TextEditingController _nomeEmpresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _razaoSocialController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    final EmpresaModel? empresa = _empresaProvider.empresa;
    if (empresa != null) {
      _preencherCampos(empresa);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosDaEmpresa();
    });
  }

  Future<void> _carregarDadosDaEmpresa() async {
    if (mounted) {
      setState(() => _carregando = true);
    }

    try {
      final EmpresaModel empresa = await _empresaService.buscarDadosDaEmpresa();

      if (!mounted) {
        return;
      }

      setState(() {
        _preencherCampos(empresa);
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar dados da empresa na inicialização: $e');

      if (!mounted) {
        return;
      }

      setState(() => _carregando = false);
      _mostrarSnackBar(
        'Não foi possível carregar os dados do negócio.',
        isError: true,
      );
    }
  }

  void _preencherCampos(EmpresaModel empresa) {
    _nomeEmpresaController.text = empresa.nomeEmpresa;
    _cnpjController.text = empresa.documentoNoBrasilCNPJ;
    _razaoSocialController.text = empresa.nomeFantasia;
  }

  Future<void> _salvarPerfil() async {
    FocusScope.of(context).unfocus();

    setState(() => _salvando = true);

    final EmpresaModel novaEmpresa = EmpresaModel(
      nomeEmpresa: _nomeEmpresaController.text.trim(),
      nomeFantasia: _razaoSocialController.text.trim(),
      documentoNoBrasilCNPJ: _cnpjController.text.trim(),
    );

    try {
      final EmpresaModel empresaAtualizada = await _empresaService
          .atualizarDadosDaEmpresa(novaEmpresa);

      if (!mounted) {
        return;
      }

      setState(() {
        _preencherCampos(empresaAtualizada);
      });

      _mostrarSnackBar('Perfil do negócio atualizado com sucesso!');
    } catch (e) {
      debugPrint('Erro ao atualizar perfil do negócio: $e');

      if (!mounted) {
        return;
      }

      _mostrarSnackBar('Erro ao atualizar perfil do negócio.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _cnpjController.dispose();
    _razaoSocialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text(
          'Perfil do negócio',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildAppVersionPill(compact: true)),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _carregando
                ? _buildLoadingState()
                : RefreshIndicator(
                  onRefresh: _carregarDadosDaEmpresa,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: <Widget>[
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 60),
                        child: _buildHeaderCard(),
                      ),
                      const SizedBox(height: 16),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 120),
                        child: _buildSegmentSection(),
                      ),
                      const SizedBox(height: 16),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 180),
                        child: _buildProfileSection(),
                      ),
                      const SizedBox(height: 16),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 240),
                        child: _buildDetailsSection(),
                      ),
                      const SizedBox(height: 16),
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 300),
                        child: _buildSignatureSection(),
                      ),
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: _surfaceColor,
            border: Border(top: BorderSide(color: _borderColor)),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _salvando ? null : _salvarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon:
                  _salvando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.check_rounded),
              label: Text(
                _salvando ? 'Salvando...' : 'Salvar perfil do negócio',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: _primaryColor));
  }

  Widget _buildHeaderCard() {
    final String nomeEmpresa = _nomeEmpresaController.text.trim();
    final String titulo = nomeEmpresa.isEmpty ? 'Meu negócio' : nomeEmpresa;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAppVersionPill(),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Identidade, documentos e dados do comércio em um só lugar.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersionPill({bool compact = false}) {
    final String versao = AppConfig.appVersion.trim();
    final String label = versao.isEmpty ? 'v-' : 'v$versao';

    return Tooltip(
      message:
          versao.isEmpty ? 'Versão não informada' : 'Versão atual x: $versao',
      child: Container(
        height: compact ? 30 : 28,
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: compact ? 0.14 : 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 11 : 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentSection() {
    return _buildSectionCard(
      children: <Widget>[
        _buildSectionHeader(
          icon: Icons.category_outlined,
          title: 'Segmento',
          subtitle: 'Defina a principal atividade do seu comércio.',
        ),
        const SizedBox(height: 14),
        _buildActionTile(
          icon: Icons.tune_rounded,
          title: 'Escolha seu segmento',
          subtitle: 'Assistência técnica, vendas, serviços e outros perfis.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => SeguimentoMobileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return _buildSectionCard(
      children: <Widget>[
        _buildSectionHeader(
          icon: Icons.badge_outlined,
          title: 'Perfil do meu negócio',
          subtitle: 'Dados principais usados no app e nos documentos.',
        ),
        const SizedBox(height: 14),
        _buildLogoCard(),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _nomeEmpresaController,
          label: 'Nome da empresa',
          icon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _cnpjController,
          label: 'CNPJ',
          icon: Icons.receipt_long_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _razaoSocialController,
          label: 'Razão social',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 14),
        _buildActionTile(
          icon: Icons.place_outlined,
          title: 'Telefone e endereço',
          subtitle: 'Configure os dados de contato e localização.',
          onTap: _mostrarRecursoEmBreve,
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.alternate_email_rounded,
          title: 'Redes sociais',
          subtitle: 'Instagram, site e outros canais do comércio.',
          onTap: _mostrarRecursoEmBreve,
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _buildSectionCard(
      children: <Widget>[
        _buildSectionHeader(
          icon: Icons.auto_awesome_outlined,
          title: 'Detalhes do negócio',
          subtitle: 'Textos institucionais para melhorar a experiência.',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Qual é o slogan da sua empresa?',
          icon: Icons.campaign_outlined,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Qual é a história da sua empresa?',
          icon: Icons.history_edu_outlined,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Qual é a sua mensagem de agradecimento?',
          icon: Icons.volunteer_activism_outlined,
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return _buildSectionCard(
      children: <Widget>[
        _buildSectionHeader(
          icon: Icons.draw_outlined,
          title: 'Assinatura nos documentos',
          subtitle: 'Use sua assinatura em orçamentos e comprovantes.',
        ),
        const SizedBox(height: 14),
        _buildSignatureCard(),
      ],
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _softBlueColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _titleTextColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _inputBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _inputBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _borderColor),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _mostrarSnackBar('Logotipo disponível para usuários Pro e Top.');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _softBlueColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: _primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Logotipo da empresa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Personalização visual para documentos e comprovantes.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const AssinaturaMobileScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _inputBackgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: const Icon(
                  Icons.draw_rounded,
                  color: _primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Coloque sua assinatura aqui',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A assinatura salva será inserida nos documentos gerados pelo app.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarRecursoEmBreve() {
    _mostrarSnackBar('Recurso ainda não disponível nesta tela.');
  }

  void _mostrarSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }
}
