import 'package:flutter/material.dart';

import '../../data/models/usuario_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/usuario_provider.dart';

void showMeuPerfilWebDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: SizedBox(
        width: 980,
        child: MeuPerfilWebScreen(),
      ),
    ),
  );
}

class MeuPerfilWebScreen extends StatefulWidget {
  const MeuPerfilWebScreen({super.key});

  @override
  State<MeuPerfilWebScreen> createState() => _MeuPerfilWebScreenState();
}

class _MeuPerfilWebScreenState extends State<MeuPerfilWebScreen> {
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _registroController = TextEditingController();
  final TextEditingController _nomeDeGuerraController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _dataNascimentoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _localidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscarDados();
    });
  }

  Future<void> _buscarDados() async {
    _usuarioProvider.setLoading(true);
    try {
      if (_usuarioProvider.usuario == null) {
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      }
      _preencherControllers(_usuarioProvider.usuario);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar dados: $e')),
        );
      }
    } finally {
      _usuarioProvider.setLoading(false);
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

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(context, label, icon: icon),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Future<void> _salvarPerfil() async {
    final UsuarioModel? usuarioAtual = _usuarioProvider.usuario;
    if (usuarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não encontrado para atualização.')),
      );
      return;
    }

    final UsuarioModel atualizado = UsuarioModel(
      nome: _nomeController.text,
      sobrenome: _sobrenomeController.text,
      cpf: _cpfController.text,
      registroProfissional: _registroController.text,
      email: _emailController.text,
      nomeDeGuerra: _nomeDeGuerraController.text,
      celular: _celularController.text,
      senha: usuarioAtual.senha,
      salt: usuarioAtual.salt,
      rg: _rgController.text,
      dataNascimento: _dataNascimentoController.text,
      objEndereco: EnderecoModel(
        cep: _cepController.text,
        logradouro: _logradouroController.text,
        complemento: _complementoController.text,
        bairro: _bairroController.text,
        localidade: _localidadeController.text,
        uf: _ufController.text,
      ),
    );

    _usuarioProvider.setLoading(true);
    try {
      await UsuarioService().atualizarDadosDoUsuario(atualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
        );
      }
    } finally {
      _usuarioProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _usuarioProvider,
      builder: (BuildContext context, _) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Meu Perfil',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _usuarioProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: <Widget>[
                          _buildSectionCard(
                            context: context,
                            title: 'Dados pessoais',
                            subtitle: 'Atualize os dados principais do usuário.',
                            icon: Icons.person_outline_rounded,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _buildTextField(
                                        context: context,
                                        controller: _nomeController,
                                        label: 'Primeiro nome',
                                        icon: Icons.badge_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        context: context,
                                        controller: _sobrenomeController,
                                        label: 'Sobrenome',
                                        icon: Icons.badge_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  runSpacing: 12,
                                  spacing: 12,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 280,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _nomeDeGuerraController,
                                        label: 'Nome de guerra',
                                        icon: Icons.account_circle_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 220,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _cpfController,
                                        label: 'CPF',
                                        icon: Icons.credit_card_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 220,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _rgController,
                                        label: 'RG',
                                        icon: Icons.perm_identity_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 220,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _dataNascimentoController,
                                        label: 'Data de nascimento',
                                        icon: Icons.cake_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 220,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _celularController,
                                        label: 'Celular',
                                        icon: Icons.phone_android_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 240,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _registroController,
                                        label: 'Registro profissional',
                                        icon: Icons.assignment_ind_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  context: context,
                                  controller: _emailController,
                                  label: 'E-mail',
                                  icon: Icons.email_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            context: context,
                            title: 'Endereço',
                            subtitle: 'Dados de localização para contato e cadastro.',
                            icon: Icons.location_on_outlined,
                            child: Column(
                              children: <Widget>[
                                Wrap(
                                  runSpacing: 12,
                                  spacing: 12,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 180,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _cepController,
                                        label: 'CEP',
                                        icon: Icons.pin_drop_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 420,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _logradouroController,
                                        label: 'Logradouro',
                                        icon: Icons.route_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 260,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _complementoController,
                                        label: 'Complemento',
                                        icon: Icons.add_home_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 240,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _bairroController,
                                        label: 'Bairro',
                                        icon: Icons.location_city_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 280,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _localidadeController,
                                        label: 'Localidade',
                                        icon: Icons.map_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: _buildTextField(
                                        context: context,
                                        controller: _ufController,
                                        label: 'UF',
                                        icon: Icons.flag_outlined,
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
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _usuarioProvider.isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _usuarioProvider.isLoading ? null : _salvarPerfil,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar meu perfil'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
