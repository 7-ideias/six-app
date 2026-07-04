import 'package:flutter/material.dart';

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
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      }

      _preencherControllers(_usuarioProvider.usuario);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar seus dados. Tente novamente.',
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
        const SnackBar(
          content: Text('Usuário não encontrado para atualização.'),
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
      await UsuarioService().atualizarDadosDoUsuario(atualizado);
      _preencherControllers(_usuarioProvider.usuario);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar seu perfil. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    required IconData icon,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
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
      decoration: _inputDecoration(context, label, icon: icon),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: colorScheme.primary, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldSpacing(Widget child) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _buildSection(
            context: context,
            title: 'Dados pessoais',
            icon: Icons.person_outline_rounded,
            children: <Widget>[
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _nomeController,
                  label: 'Primeiro nome',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _sobrenomeController,
                  label: 'Sobrenome',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _nomeDeGuerraController,
                  label: 'Nome de guerra',
                  icon: Icons.account_circle_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _cpfController,
                  label: 'CPF',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _rgController,
                  label: 'RG',
                  icon: Icons.perm_identity_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _dataNascimentoController,
                  label: 'Data de nascimento',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _celularController,
                  label: 'Celular',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _registroController,
                  label: 'Registro profissional',
                  icon: Icons.assignment_ind_outlined,
                ),
              ),
              _buildTextField(
                context: context,
                controller: _emailController,
                label: 'E-mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Endereço',
            icon: Icons.location_on_outlined,
            children: <Widget>[
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _cepController,
                  label: 'CEP',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _logradouroController,
                  label: 'Logradouro',
                  icon: Icons.route_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _complementoController,
                  label: 'Complemento',
                  icon: Icons.add_home_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _bairroController,
                  label: 'Bairro',
                  icon: Icons.location_city_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _fieldSpacing(
                _buildTextField(
                  context: context,
                  controller: _localidadeController,
                  label: 'Localidade',
                  icon: Icons.map_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              _buildTextField(
                context: context,
                controller: _ufController,
                label: 'UF',
                icon: Icons.flag_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _salvando ? null : _salvarPerfil,
              icon:
                  _salvando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: Text(_salvando ? 'Salvando...' : 'Salvar meu perfil'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text(
          'Meu perfil',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child:
            _carregandoInicial
                ? const Center(child: CircularProgressIndicator())
                : _buildFormContent(context),
      ),
    );
  }
}
