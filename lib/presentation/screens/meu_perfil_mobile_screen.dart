import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';
import 'package:sixpos/presentation/utils/profile_image_payload.dart';

import '../../data/models/usuario_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/usuario_provider.dart';

class MeuPerfilMobileScreen extends StatefulWidget {
  const MeuPerfilMobileScreen({super.key});

  @override
  State<MeuPerfilMobileScreen> createState() => _MeuPerfilMobileScreenState();
}

class _MeuPerfilMobileScreenState extends State<MeuPerfilMobileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final UsuarioService _usuarioService = UsuarioService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _registroController = TextEditingController();
  final TextEditingController _nomeDeGuerraController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _localidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();

  bool _carregandoInicial = true;
  bool _salvando = false;
  bool _salvandoFoto = false;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscarDados();
    });
  }

  Future<void> _buscarDados() async {
    if (mounted) {
      setState(() => _carregandoInicial = true);
    }

    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }

      _preencherControllers(_usuarioProvider.usuario);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'perfil.mobile.loadError',
              'Não foi possível carregar seus dados. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregandoInicial = false);
      }
    }
  }

  void _preencherControllers(UsuarioModel? usuario) {
    if (usuario == null) {
      return;
    }

    _nomeController.text = usuario.nome;
    _sobrenomeController.text = usuario.sobrenome;
    _cpfController.text = usuario.cpf;
    _registroController.text = usuario.registroProfissional;
    _nomeDeGuerraController.text = usuario.nomeDeGuerra;
    _celularController.text = usuario.celular;
    _rgController.text = usuario.rg;
    _dataNascimentoController.text = usuario.dataNascimento;
    _emailController.text = usuario.email;

    final EnderecoModel? endereco = usuario.objEndereco;
    _cepController.text = endereco?.cep ?? '';
    _logradouroController.text = endereco?.logradouro ?? '';
    _complementoController.text = endereco?.complemento ?? '';
    _bairroController.text = endereco?.bairro ?? '';
    _localidadeController.text = endereco?.localidade ?? '';
    _ufController.text = endereco?.uf ?? '';
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _nomeController,
      _sobrenomeController,
      _cpfController,
      _registroController,
      _nomeDeGuerraController,
      _celularController,
      _rgController,
      _dataNascimentoController,
      _emailController,
      _cepController,
      _logradouroController,
      _complementoController,
      _bairroController,
      _localidadeController,
      _ufController,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (_salvando) {
      return;
    }

    final UsuarioModel? usuarioAtual = _usuarioProvider.usuario;

    if (usuarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'perfil.mobile.userNotFound',
              'Usuário não encontrado para atualização.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    final UsuarioModel atualizado = UsuarioModel(
      nome: _nomeController.text.trim(),
      sobrenome: _sobrenomeController.text.trim(),
      cpf: _cpfController.text.trim(),
      registroProfissional: _registroController.text.trim(),
      email: _emailController.text.trim(),
      foto: usuarioAtual.foto,
      nomeDeGuerra: _nomeDeGuerraController.text.trim(),
      celular: _celularController.text.trim(),
      senha: usuarioAtual.senha,
      salt: usuarioAtual.salt,
      rg: _rgController.text.trim(),
      dataNascimento: _dataNascimentoController.text.trim(),
      objEndereco: EnderecoModel(
        cep: _cepController.text.trim(),
        logradouro: _logradouroController.text.trim(),
        complemento: _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        localidade: _localidadeController.text.trim(),
        uf: _ufController.text.trim(),
      ),
      preferenciasIndividuaisDoUsuario:
          usuarioAtual.preferenciasIndividuaisDoUsuario,
    );

    try {
      await _usuarioService.atualizarDadosDoUsuario(atualizado);
      _preencherControllers(_usuarioProvider.usuario);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('perfil.mobile.saveSuccess', 'Perfil atualizado com sucesso!'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'perfil.mobile.saveError',
              'Não foi possível atualizar seu perfil. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _selecionarFotoPerfil(ImageSource source) async {
    if (_salvandoFoto || _salvando) {
      return;
    }

    final XFile? selected = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (selected == null) {
      return;
    }

    setState(() => _salvandoFoto = true);
    try {
      final String imageDataUrl = await buildProfileImageDataUrl(selected);
      await _usuarioService.atualizarFotoDoUsuario(imageDataUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'perfil.mobile.photoSaveSuccess',
              'Foto do perfil atualizada com sucesso.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'perfil.mobile.photoSaveError',
              'Não foi possível atualizar a foto do perfil. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoFoto = false);
      }
    }
  }

  void _mostrarOpcoesFotoPerfil() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: SixMobilePalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _t('perfil.mobile.photoTitle', 'Foto do perfil'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                _buildFotoOption(
                  bottomSheetContext,
                  icon: Icons.photo_camera_outlined,
                  title: _t('perfil.mobile.takePhoto', 'Tirar foto'),
                  source: ImageSource.camera,
                ),
                SizedBox(height: 8),
                _buildFotoOption(
                  bottomSheetContext,
                  icon: Icons.photo_library_outlined,
                  title: _t('perfil.mobile.choosePhoto', 'Escolher da galeria'),
                  source: ImageSource.gallery,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFotoOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ImageSource source,
  }) {
    return Material(
      color: SixMobilePalette.softNeutralSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          _selecionarFotoPerfil(source);
        },
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SixMobilePalette.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: SixMobilePalette.accent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: SixMobilePalette.accent),
      prefixIconConstraints: BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: SixMobilePalette.surface,
      contentPadding: EdgeInsets.fromLTRB(14, 15, 14, 15),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: SixMobilePalette.mutedText,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: SixMobilePalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: SixMobilePalette.highlightedBorder,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: SixMobilePalette.border.withValues(alpha: 0.64),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_salvando,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: SixMobilePalette.titleText,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(context, label, icon: icon),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    required int order,
  }) {
    final ThemeData theme = Theme.of(context);

    return SixStaggeredEntry(
      delay: Duration(milliseconds: 70 * order),
      beginOffset: Offset(0, 0.035),
      child: Semantics(
        container: true,
        label: title,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SixMobilePalette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow.withValues(alpha: 0.7),
                blurRadius: 18,
                offset: Offset(0, 8),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.softAccentSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: SixMobilePalette.accent, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: SixMobilePalette.titleText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SixMobilePalette.mutedText,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldSpacing(Widget child) {
    return Padding(padding: EdgeInsets.only(bottom: 12), child: child);
  }

  Widget _buildProfilePhotoButton() {
    final String imageValue = _usuarioProvider.usuario?.foto ?? '';

    return Semantics(
      button: true,
      label: _t('perfil.mobile.changePhoto', 'Alterar foto do perfil'),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _salvandoFoto ? null : _mostrarOpcoesFotoPerfil,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.22),
                ),
              ),
              child:
                  _salvandoFoto
                      ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: SixMobilePalette.onPrimary,
                          ),
                        ),
                      )
                      : UserProfileAvatarImage(
                        imageValue: imageValue,
                        fallbackIcon: Icons.account_circle_outlined,
                        fallbackColor: SixMobilePalette.onPrimary,
                        size: 56,
                        fallbackIconSize: 30,
                        circle: true,
                      ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: SixMobilePalette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SixMobilePalette.highlightedBorder,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 13,
                  color: SixMobilePalette.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name =
        '${_nomeController.text.trim()} ${_sobrenomeController.text.trim()}'
            .trim();
    final String displayName =
        name.isEmpty ? _t('perfil.mobile.title', 'Meu perfil') : name;
    final String email = _emailController.text.trim();

    return SixStaggeredEntry(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _buildProfilePhotoButton(),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: SixMobilePalette.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email.isEmpty
                        ? _t(
                          'perfil.mobile.summary',
                          'Dados de acesso, contato e localização.',
                        )
                        : email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SixMobilePalette.heroSupportingText,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFormContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
        children: <Widget>[
          _buildProfileSummary(context),
          SizedBox(height: 14),
          _buildSection(
            context: context,
            title: _t('perfil.personalData.title', 'Dados pessoais'),
            subtitle: _t(
              'perfil.personalData.subtitle',
              'Atualize os dados usados em cadastros, vendas e atendimento.',
            ),
            icon: Icons.person_outline_rounded,
            order: 1,
            children: <Widget>[
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _nomeController,
                  label: _t('perfil.firstName', 'Primeiro nome'),
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _sobrenomeController,
                  label: _t('perfil.lastName', 'Sobrenome'),
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _nomeDeGuerraController,
                  label: _t('perfil.nickname', 'Nome de guerra'),
                  icon: Icons.account_circle_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _cpfController,
                  label: _t('perfil.cpf', 'CPF'),
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _rgController,
                  label: _t('perfil.rg', 'RG'),
                  icon: Icons.perm_identity_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _dataNascimentoController,
                  label: _t('perfil.birthDate', 'Data de nascimento'),
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _celularController,
                  label: _t('perfil.mobilePhone', 'Celular'),
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _registroController,
                  label: _t(
                    'perfil.professionalRegistration',
                    'Registro profissional',
                  ),
                  icon: Icons.assignment_ind_outlined,
                ),
              ),
              _buildTextField(
                context: context,
                controller: _emailController,
                label: _t('perfil.email', 'E-mail'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          SizedBox(height: 14),
          _buildSection(
            context: context,
            title: _t('perfil.address.title', 'Endereço'),
            subtitle: _t(
              'perfil.address.subtitle',
              'Dados de localização para contato e documentos do sistema.',
            ),
            icon: Icons.location_on_outlined,
            order: 2,
            children: <Widget>[
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _cepController,
                  label: _t('perfil.zipCode', 'CEP'),
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _logradouroController,
                  label: _t('perfil.street', 'Logradouro'),
                  icon: Icons.route_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _complementoController,
                  label: _t('perfil.addressComplement', 'Complemento'),
                  icon: Icons.add_home_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _bairroController,
                  label: _t('perfil.neighborhood', 'Bairro'),
                  icon: Icons.location_city_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _localidadeController,
                  label: _t('perfil.city', 'Localidade'),
                  icon: Icons.map_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _buildTextField(
                context: context,
                controller: _ufController,
                label: _t('perfil.state', 'UF'),
                icon: Icons.flag_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _t('perfil.mobile.loadingSemantics', 'Carregando perfil'),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
        children: <Widget>[
          SixBackendLoading(
            title: _t('perfil.mobile.loadingTitle', 'Carregando perfil'),
            subtitle: _t(
              'perfil.mobile.loadingSubtitle',
              'Sincronizando seus dados de acesso, contato e localização.',
            ),
            leadingIcon: Icons.account_circle_outlined,
            animation: SixBackendLoadingAnimation.skeletonPulse,
            backgroundColor: SixMobilePalette.surface,
            borderColor: SixMobilePalette.border,
          ),
          SizedBox(height: 14),
          const _ProfileSkeletonSection(),
          SizedBox(height: 14),
          const _ProfileSkeletonSection(compact: true),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          border: Border(top: BorderSide(color: SixMobilePalette.border)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _salvando ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 48),
                    foregroundColor: SixMobilePalette.primary,
                    side: BorderSide(color: SixMobilePalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _t('common.cancel', 'Cancelar'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed:
                      (_salvando || _carregandoInicial) ? null : _salvarPerfil,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, 48),
                    backgroundColor: SixMobilePalette.accent,
                    foregroundColor: SixMobilePalette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon:
                      _salvando
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Icon(Icons.save_outlined),
                  label: Text(
                    _salvando
                        ? _t('common.saving', 'Salvando...')
                        : _t('perfil.mobile.saveButton', 'Salvar meu perfil'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _t('perfil.mobile.title', 'Meu perfil'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottomNavigationBar: _buildBottomBar(context),
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        if (_carregandoInicial) {
          return _buildLoadingContent(context, scrollController, topInset);
        }

        return _buildFormContent(context, scrollController, topInset);
      },
    );
  }
}

class _ProfileSkeletonSection extends StatelessWidget {
  const _ProfileSkeletonSection({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _skeletonBox(width: 42, height: 42, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonBox(width: 144, height: 14),
                    SizedBox(height: 8),
                    _skeletonBox(width: compact ? 190 : 250, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...List<Widget>.generate(compact ? 3 : 5, (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == (compact ? 2 : 4) ? 0 : 12,
              ),
              child: _skeletonBox(height: 54, radius: 16),
            );
          }),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    double width = double.infinity,
    required double height,
    double radius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.border.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
