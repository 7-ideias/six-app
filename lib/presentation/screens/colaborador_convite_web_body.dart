import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/colaborador_convite_web_service.dart';
import '../../data/models/colaborador_convite_model.dart';
import '../components/web_dashboard_widgets.dart';

class ColaboradorConviteWebBody extends StatefulWidget {
  const ColaboradorConviteWebBody({super.key});

  @override
  State<ColaboradorConviteWebBody> createState() =>
      _ColaboradorConviteWebBodyState();
}

class _ColaboradorConviteWebBodyState extends State<ColaboradorConviteWebBody> {
  static const double _compactBreakpoint = 760;
  static const double _wideBreakpoint = 1180;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController(
    text: '+55',
  );

  bool _fazVenda = true;
  bool _lancaServico = true;
  bool _editaCliente = true;
  bool _acessaFinanceiro = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _isLoading = false;
  ColaboradorConviteResponse? _ultimoConvite;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  List<String> _permissoesSelecionadas() {
    return <String>[
      if (_fazVenda) 'VENDAS_CRIAR',
      if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
      if (_editaCliente) 'CLIENTES_EDITAR',
      if (_acessaFinanceiro) 'FINANCEIRO_ACESSAR',
      if (_geraRelatorio) 'RELATORIOS_GERAR',
      if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
    ];
  }

  String _linkConvite(ColaboradorConviteResponse convite) {
    final String base = Uri.base.origin;
    return '$base/colaborador/convites/${convite.codigo}';
  }

  Future<void> _criarConvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _ultimoConvite = null;
    });

    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        ColaboradorConviteRequest(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          celular: _celularController.text.trim(),
          permissoes: _permissoesSelecionadas(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ultimoConvite = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite de colaborador criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFromError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _ultimoConvite;
    if (convite == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _linkConvite(convite)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do convite copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _messageFromError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  InputDecoration _decoration(String label, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double width,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: _isLoading,
        keyboardType: keyboardType,
        decoration: _decoration(label, icon),
        validator: validator,
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            value
                ? colorScheme.primary.withValues(alpha: 0.05)
                : colorScheme.surface,
        border: Border.all(
          color:
              value
                  ? colorScheme.primary.withValues(alpha: 0.20)
                  : colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  value
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.50,
                      ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: _isLoading ? null : onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.group_add_outlined,
            title: 'Novo colaborador',
            subtitle:
                'Gere um convite com permissões iniciais para a empresa ativa.',
            onBack: () => Navigator.of(context).pop(),
            actions: const <Widget>[],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact =
                        constraints.maxWidth < _compactBreakpoint;
                    final bool wide = constraints.maxWidth >= _wideBreakpoint;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SixWebEntry(
                          order: 0,
                          child: _dadosSection(compact: compact, wide: wide),
                        ),
                        const SizedBox(height: 18),
                        SixWebEntry(
                          order: 1,
                          child: _permissoesSection(
                            compact: compact,
                            wide: wide,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SixWebEntry(order: 2, child: _actionsBar(compact)),
                        _conviteResult(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dadosSection({required bool compact, required bool wide}) {
    final double fieldWidth = compact ? double.infinity : 320;
    final List<Widget> fields = <Widget>[
      _field(
        controller: _nomeController,
        label: 'Nome do colaborador',
        icon: Icons.person_outline,
        width: wide ? 360 : fieldWidth,
        validator:
            (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Informe o nome.'
                    : null,
      ),
      _field(
        controller: _emailController,
        label: 'E-mail de login',
        icon: Icons.email_outlined,
        width: wide ? 360 : fieldWidth,
        keyboardType: TextInputType.emailAddress,
        validator:
            (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Informe o e-mail.'
                    : null,
      ),
      _field(
        controller: _celularController,
        label: 'Celular',
        icon: Icons.phone_outlined,
        width: compact ? double.infinity : 240,
        keyboardType: TextInputType.phone,
      ),
    ];

    return SixWebSectionCard(
      title: 'Dados do convite',
      subtitle:
          'Informe o nome e os contatos que identificam o acesso do colaborador.',
      icon: Icons.contact_mail_outlined,
      child:
          compact
              ? Column(
                children: <Widget>[
                  fields[0],
                  const SizedBox(height: 14),
                  fields[1],
                  const SizedBox(height: 14),
                  fields[2],
                ],
              )
              : Wrap(spacing: 14, runSpacing: 14, children: fields),
    );
  }

  Widget _permissoesSection({required bool compact, required bool wide}) {
    final List<Widget> cards = <Widget>[
      _switchCard(
        title: 'Vendas',
        subtitle: 'Pode criar vendas.',
        icon: Icons.point_of_sale_outlined,
        value: _fazVenda,
        onChanged: (bool v) => setState(() => _fazVenda = v),
      ),
      _switchCard(
        title: 'Assistência técnica',
        subtitle: 'Pode lançar atendimentos técnicos.',
        icon: Icons.handyman_outlined,
        value: _lancaServico,
        onChanged: (bool v) => setState(() => _lancaServico = v),
      ),
      _switchCard(
        title: 'Clientes',
        subtitle: 'Pode editar clientes.',
        icon: Icons.people_alt_outlined,
        value: _editaCliente,
        onChanged: (bool v) => setState(() => _editaCliente = v),
      ),
      _switchCard(
        title: 'Financeiro',
        subtitle: 'Pode acessar financeiro.',
        icon: Icons.account_balance_wallet_outlined,
        value: _acessaFinanceiro,
        onChanged: (bool v) => setState(() => _acessaFinanceiro = v),
      ),
      _switchCard(
        title: 'Relatórios',
        subtitle: 'Pode gerar relatórios.',
        icon: Icons.analytics_outlined,
        value: _geraRelatorio,
        onChanged: (bool v) => setState(() => _geraRelatorio = v),
      ),
      _switchCard(
        title: 'Permissões',
        subtitle: 'Pode gerenciar permissões.',
        icon: Icons.verified_user_outlined,
        value: _gerenciaPermissoes,
        onChanged: (bool v) => setState(() => _gerenciaPermissoes = v),
      ),
    ];
    final List<Widget> responsiveCards = cards
        .map(
          (Widget card) =>
              _permissionSlot(compact: compact, wide: wide, child: card),
        )
        .toList(growable: false);

    return SixWebSectionCard(
      title: 'Permissões iniciais',
      subtitle:
          'Ative apenas os acessos necessários para a rotina inicial do colaborador.',
      icon: Icons.security_outlined,
      child:
          compact
              ? Column(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < cards.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const SizedBox(height: 12),
                    cards[index],
                  ],
                ],
              )
              : Wrap(spacing: 14, runSpacing: 14, children: responsiveCards),
    );
  }

  Widget _permissionSlot({
    required bool compact,
    required bool wide,
    required Widget child,
  }) {
    final double width =
        compact
            ? double.infinity
            : wide
            ? 330
            : 300;
    return SizedBox(width: width, child: child);
  }

  Widget _actionsBar(bool compact) {
    final ColaboradorConviteResponse? convite = _ultimoConvite;
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _submitButton(),
                  if (convite != null) ...<Widget>[
                    const SizedBox(height: 10),
                    _copyButton(stretched: true),
                  ],
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      convite == null
                          ? 'Revise os dados e gere o link para o colaborador.'
                          : 'Convite disponível para compartilhamento.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (convite != null) ...<Widget>[
                    _copyButton(),
                    const SizedBox(width: 10),
                  ],
                  _submitButton(),
                ],
              ),
    );
  }

  Widget _submitButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _criarConvite,
      icon:
          _isLoading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.send_outlined),
      label: Text(_isLoading ? 'Gerando convite...' : 'Gerar convite'),
    );
  }

  Widget _copyButton({bool stretched = false}) {
    final Widget button = OutlinedButton.icon(
      onPressed: _copiarLink,
      icon: const Icon(Icons.copy_outlined),
      label: const Text('Copiar link'),
    );
    return stretched ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _conviteResult() {
    final ColaboradorConviteResponse? convite = _ultimoConvite;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          convite == null
              ? const SizedBox.shrink(key: ValueKey<String>('sem-convite'))
              : Padding(
                key: ValueKey<String>('convite-${convite.codigo}'),
                padding: const EdgeInsets.only(top: 18),
                child: SixWebEntry(order: 4, child: _conviteCard(convite)),
              ),
    );
  }

  Widget _conviteCard(ColaboradorConviteResponse convite) {
    final ThemeData theme = Theme.of(context);
    final String link = _linkConvite(convite);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < _compactBreakpoint;
          final Widget content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Convite criado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      convite.emailConvidado.isEmpty
                          ? 'Compartilhe o link com o colaborador convidado.'
                          : convite.emailConvidado,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: SelectableText(
                        link,
                        maxLines: 2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                content,
                const SizedBox(height: 14),
                _copyButton(stretched: true),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: content),
              const SizedBox(width: 14),
              _copyButton(),
            ],
          );
        },
      ),
    );
  }
}
