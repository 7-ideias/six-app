import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/usuario_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/usuario_provider.dart';

void showMeuPerfilWebDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      final Size size = MediaQuery.sizeOf(dialogContext);
      final bool compact = size.width < 760;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32,
          vertical: compact ? 16 : 24,
        ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 980,
            maxHeight: size.height - (compact ? 32 : 48),
          ),
          child: const MeuPerfilWebScreen(),
        ),
      );
    },
  );
}

class MeuPerfilWebScreen extends StatefulWidget {
  const MeuPerfilWebScreen({super.key});

  @override
  State<MeuPerfilWebScreen> createState() => _MeuPerfilWebScreenState();
}

class _MeuPerfilWebScreenState extends State<MeuPerfilWebScreen> {
  static const Duration _entryDuration = Duration(milliseconds: 420);
  static const Curve _entryCurve = Curves.easeOutCubic;

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar seus dados. Tente novamente.'),
          ),
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
    required IconData icon,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: colorScheme.surface,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.24)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error.withOpacity(0.70)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
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
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(context, label, icon: icon),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    required int order,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return _entry(
      order: order,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.86)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 23),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGrid({
    required List<_ProfileFormItem> items,
    int desktopColumns = 4,
  }) {
    const double spacing = 12;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 820
            ? desktopColumns
            : maxWidth >= 560
                ? math.min(2, desktopColumns)
                : 1;
        final double columnWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((ProfileFormItem item) {
            final int safeSpan = item.span < 1
                ? 1
                : item.span > columns
                    ? columns
                    : item.span;
            final double width = (columnWidth * safeSpan) + (spacing * (safeSpan - 1));
            return SizedBox(width: width, child: item.child);
          }).toList(),
        );
      },
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar seu perfil. Tente novamente.'),
          ),
        );
      }
    } finally {
      _usuarioProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: ListenableBuilder(
        listenable: _usuarioProvider,
        builder: (BuildContext context, _) {
          final Widget body = _usuarioProvider.isLoading
              ? const KeyedSubtree(
                  key: ValueKey<String>('meu-perfil-loading'),
                  child: _MeuPerfilLoading(),
                )
              : KeyedSubtree(
                  key: const ValueKey<String>('meu-perfil-form'),
                  child: _buildFormContent(context),
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(context),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: _entryCurve,
                  switchOutCurve: Curves.easeInCubic,
                  child: body,
                ),
              ),
              _buildFooter(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.account_circle_outlined, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Meu Perfil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dados de acesso, contato e localização do usuário.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: <Widget>[
          _buildSectionCard(
            context: context,
            title: 'Dados pessoais',
            subtitle: 'Atualize os dados principais usados em cadastros, vendas e atendimento.',
            icon: Icons.person_outline_rounded,
            order: 0,
            child: _buildFieldGrid(
              items: <_ProfileFormItem>[
                _ProfileFormItem(
                  span: 2,
                  child: _buildTextField(
                    context: context,
                    controller: _nomeController,
                    label: 'Primeiro nome',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  span: 2,
                  child: _buildTextField(
                    context: context,
                    controller: _sobrenomeController,
                    label: 'Sobrenome',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  span: 2,
                  child: _buildTextField(
                    context: context,
                    controller: _nomeDeGuerraController,
                    label: 'Nome de guerra',
                    icon: Icons.account_circle_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _cpfController,
                    label: 'CPF',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _rgController,
                    label: 'RG',
                    icon: Icons.perm_identity_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _dataNascimentoController,
                    label: 'Data de nascimento',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _celularController,
                    label: 'Celular',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                _ProfileFormItem(
                  span: 2,
                  child: _buildTextField(
                    context: context,
                    controller: _registroController,
                    label: 'Registro profissional',
                    icon: Icons.assignment_ind_outlined,
                  ),
                ),
                _ProfileFormItem(
                  span: 4,
                  child: _buildTextField(
                    context: context,
                    controller: _emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context: context,
            title: 'Endereço',
            subtitle: 'Dados de localização para contato, cadastro e documentos gerados pelo sistema.',
            icon: Icons.location_on_outlined,
            order: 1,
            child: _buildFieldGrid(
              items: <_ProfileFormItem>[
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _cepController,
                    label: 'CEP',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                _ProfileFormItem(
                  span: 3,
                  child: _buildTextField(
                    context: context,
                    controller: _logradouroController,
                    label: 'Logradouro',
                    icon: Icons.route_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  span: 2,
                  child: _buildTextField(
                    context: context,
                    controller: _complementoController,
                    label: 'Complemento',
                    icon: Icons.add_home_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _bairroController,
                    label: 'Bairro',
                    icon: Icons.location_city_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _localidadeController,
                    label: 'Localidade',
                    icon: Icons.map_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                _ProfileFormItem(
                  child: _buildTextField(
                    context: context,
                    controller: _ufController,
                    label: 'UF',
                    icon: Icons.flag_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Revise os dados antes de salvar.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _usuarioProvider.isLoading ? null : () => Navigator.of(context).pop(),
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
    );
  }

  Widget _entry({required int order, required Widget child}) {
    final int stagger = order > 4 ? 4 : order;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _entryDuration + Duration(milliseconds: stagger * 60),
      curve: _entryCurve,
      child: child,
      builder: (BuildContext context, double progress, Widget? child) {
        final double normalized = progress.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: normalized,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - normalized)),
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scale: 0.988 + (0.012 * normalized),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ProfileFormItem {
  const _ProfileFormItem({required this.child, this.span = 1});

  final Widget child;
  final int span;
}

class _MeuPerfilLoading extends StatelessWidget {
  const _MeuPerfilLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        children: const <Widget>[
          _MeuPerfilSkeletonSection(rows: 3),
          SizedBox(height: 16),
          _MeuPerfilSkeletonSection(rows: 2),
        ],
      ),
    );
  }
}

class _MeuPerfilSkeletonSection extends StatelessWidget {
  const _MeuPerfilSkeletonSection({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.86)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _skeletonBox(context, width: 44, height: 44, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonBox(context, width: 150, height: 14),
                    const SizedBox(height: 8),
                    _skeletonBox(context, width: 280, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List<Widget>.generate(rows, (int index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == rows - 1 ? 0 : 12),
              child: Row(
                children: <Widget>[
                  Expanded(child: _skeletonBox(context, height: 52, radius: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonBox(context, height: 52, radius: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _skeletonBox(
    BuildContext context, {
    double? width,
    required double height,
    double radius = 999,
  }) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
