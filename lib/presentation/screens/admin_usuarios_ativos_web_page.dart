import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/admin_portal_service.dart';
import '../../core/services/auth_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../admin/admin_navigation_shell.dart';
import '../admin/admin_portal_components.dart';
import '../admin/admin_portal_texts.dart';

class AdminUsuariosAtivosWebPage extends StatefulWidget {
  const AdminUsuariosAtivosWebPage({super.key});

  @override
  State<AdminUsuariosAtivosWebPage> createState() =>
      _AdminUsuariosAtivosWebPageState();
}

class _AdminUsuariosAtivosWebPageState
    extends State<AdminUsuariosAtivosWebPage> {
  final AdminPortalService _service = AdminPortalService();
  final AuthService _authService = AuthService();
  final TextEditingController _filtroController = TextEditingController();

  bool _carregando = true;
  bool _saindo = false;
  String? _erro;
  String? _userName;
  String? _userEmail;
  List<AdminEmpresaAtiva> _empresas = const <AdminEmpresaAtiva>[];

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    final String? email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _userName = _nomeExibicaoPorEmail(email);
    });
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final List<AdminEmpresaAtiva> empresas =
          await _service.listarUsuariosAtivos();
      if (!mounted) return;
      setState(() {
        _empresas = empresas;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String mensagem = e.toString().replaceAll('Exception: ', '');
      if (_erroDeSessao(mensagem)) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
        return;
      }
      setState(() {
        _erro = mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    try {
      await _authService.logout();
    } finally {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
      }
    }
  }

  bool _erroDeSessao(String mensagem) {
    final String normalized = mensagem.toLowerCase();
    return normalized.contains('login') ||
        normalized.contains('sessão') ||
        normalized.contains('sessao');
  }

  String? _nomeExibicaoPorEmail(String? email) {
    final String normalized = email?.trim() ?? '';
    if (normalized.isEmpty || !normalized.contains('@')) return null;
    final String prefix =
        normalized
            .split('@')
            .first
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .trim();
    if (prefix.isEmpty) return null;
    return prefix
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part.characters.first.toUpperCase()}${part.characters.skip(1).join().toLowerCase()}',
        )
        .join(' ');
  }

  List<AdminEmpresaAtiva> get _filtradas {
    final String filtro = _filtroController.text.trim().toLowerCase();
    if (filtro.isEmpty) return _empresas;
    return _empresas
        .where((AdminEmpresaAtiva empresa) {
          return _contains(empresa.idUnicoDaEmpresa, filtro) ||
              _contains(empresa.nomeEmpresa, filtro) ||
              _contains(empresa.nomeFantasia, filtro) ||
              _contains(empresa.documentoNoBrasilCNPJ, filtro) ||
              empresa.usuarios.any(
                (AdminUsuarioEmpresaAtiva usuario) =>
                    _contains(usuario.nome, filtro) ||
                    _contains(usuario.email, filtro) ||
                    _contains(usuario.celular, filtro) ||
                    _contains(usuario.papel, filtro) ||
                    _contains(usuario.status, filtro),
              );
        })
        .toList(growable: false);
  }

  int get _totalUsuarios => _empresas.fold<int>(
    0,
    (int total, AdminEmpresaAtiva empresa) => total + empresa.usuarios.length,
  );

  int _usuariosVisiveis(List<AdminEmpresaAtiva> empresas) {
    return empresas.fold<int>(
      0,
      (int total, AdminEmpresaAtiva empresa) => total + empresa.usuarios.length,
    );
  }

  bool _contains(String value, String filtro) {
    return value.toLowerCase().contains(filtro);
  }

  @override
  Widget build(BuildContext context) {
    final String profileType = context
        .select<ColaboradorAutorizacoesProvider, String>(
          (ColaboradorAutorizacoesProvider provider) =>
              provider.tipoPerfilUnificado,
        );
    final AdminPortalTexts portalTexts = AdminPortalTexts.of(context);
    final _UsersTexts texts = _UsersTexts.of(context);

    return AdminNavigationShell(
      texts: portalTexts,
      userInfo: AdminPortalUserInfo(
        name: _userName,
        email: _userEmail,
        profileType: profileType,
      ),
      currentRoute: '/admin/usuarios',
      pageTitle: texts.title,
      onLogout: _logout,
      onRefresh: _carregar,
      refreshing: _carregando,
      loggingOut: _saindo,
      child: AnimatedSwitcher(
        duration: AdminMotion.medium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildContent(texts),
      ),
    );
  }

  Widget _buildContent(_UsersTexts texts) {
    if (_carregando) {
      return _UsersLoadingState(
        key: const ValueKey<String>('admin-users-loading'),
        texts: texts,
      );
    }

    final String? erro = _erro;
    if (erro != null) {
      return _UsersErrorState(
        key: const ValueKey<String>('admin-users-error'),
        texts: texts,
        message: erro,
        onRetry: _carregar,
      );
    }

    final List<AdminEmpresaAtiva> empresas = _filtradas;
    final LocaleSettingsProvider localeSettings =
        context.watch<LocaleSettingsProvider>();

    return Column(
      key: ValueKey<String>(
        'admin-users-${empresas.length}-${_empresas.length}-$_totalUsuarios',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _UsersHeader(
          texts: texts,
          totalCompanies: _empresas.length,
          visibleCompanies: empresas.length,
          totalUsers: _totalUsuarios,
          visibleUsers: _usuariosVisiveis(empresas),
        ),
        const SizedBox(height: AdminSpacing.lg),
        _UsersFilter(
          controller: _filtroController,
          hint: texts.search,
          onChanged: (_) => setState(() {}),
          onClear: () {
            _filtroController.clear();
            setState(() {});
          },
        ),
        const SizedBox(height: AdminSpacing.lg),
        if (empresas.isEmpty)
          _UsersEmptyState(
            texts: texts,
            hasFilter: _filtroController.text.trim().isNotEmpty,
          )
        else
          AdminStaggeredColumn(
            children: empresas
                .map(
                  (AdminEmpresaAtiva empresa) => Padding(
                    padding: const EdgeInsets.only(bottom: AdminSpacing.md),
                    child: _CompanyCard(
                      empresa: empresa,
                      texts: texts,
                      localeSettings: localeSettings,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({
    required this.texts,
    required this.totalCompanies,
    required this.visibleCompanies,
    required this.totalUsers,
    required this.visibleUsers,
  });

  final _UsersTexts texts;
  final int totalCompanies;
  final int visibleCompanies;
  final int totalUsers;
  final int visibleUsers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        final Widget title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              texts.eyebrow,
              style: const TextStyle(
                color: AdminPalette.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texts.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AdminPalette.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texts.subtitle,
              style: const TextStyle(
                color: AdminPalette.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        );
        final Widget counters = Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: <Widget>[
            _HeaderPill(
              icon: Icons.business_rounded,
              label: texts.activeCompanies,
              value:
                  visibleCompanies == totalCompanies
                      ? totalCompanies.toString()
                      : '$visibleCompanies ${texts.ofLabel} $totalCompanies',
            ),
            _HeaderPill(
              icon: Icons.groups_rounded,
              label: texts.linkedUsers,
              value:
                  visibleUsers == totalUsers
                      ? totalUsers.toString()
                      : '$visibleUsers ${texts.ofLabel} $totalUsers',
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[title, const SizedBox(height: 16), counters],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: title),
            const SizedBox(width: 20),
            Flexible(child: counters),
          ],
        );
      },
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminPalette.activeGreen,
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: AdminPalette.dark),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AdminPalette.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersFilter extends StatelessWidget {
  const _UsersFilter({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon:
              controller.text.isEmpty
                  ? null
                  : IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          filled: true,
          fillColor: AdminPalette.softSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            borderSide: const BorderSide(color: AdminPalette.border),
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.empresa,
    required this.texts,
    required this.localeSettings,
  });

  final AdminEmpresaAtiva empresa;
  final _UsersTexts texts;
  final LocaleSettingsProvider localeSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 760;
          final Widget title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminPalette.activeGreen,
                  borderRadius: BorderRadius.circular(AdminRadius.md),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AdminPalette.dark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      empresa.nomeExibicao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AdminPalette.dark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      empresa.idUnicoDaEmpresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminPalette.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget registration = _DateBlock(
            label: texts.registration,
            value: _formatDate(empresa.dataCadastro),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    title,
                    const SizedBox(height: 14),
                    registration,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: title),
                    const SizedBox(width: 18),
                    registration,
                  ],
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _InfoTag(
                    icon: Icons.verified_rounded,
                    label: texts.status,
                    value: texts.active,
                  ),
                  _InfoTag(
                    icon: Icons.storefront_rounded,
                    label: texts.companyName,
                    value: empresa.nomeEmpresa,
                  ),
                  _InfoTag(
                    icon: Icons.badge_outlined,
                    label: texts.document,
                    value: empresa.documentoNoBrasilCNPJ,
                  ),
                  _InfoTag(
                    icon: Icons.groups_rounded,
                    label: texts.usersInCompany,
                    value: empresa.usuarios.length.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: AdminPalette.border),
              const SizedBox(height: 16),
              Text(
                texts.userInfo,
                style: const TextStyle(
                  color: AdminPalette.dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (empresa.usuarios.isEmpty)
                _NoUsers(texts: texts)
              else
                Column(
                  children: empresa.usuarios
                      .map(
                        (AdminUsuarioEmpresaAtiva usuario) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _UserRow(
                            usuario: usuario,
                            texts: texts,
                            registeredAt: _formatDate(usuario.dataCadastro),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return texts.noDate;
    return '${localeSettings.formatDate(value)} ${localeSettings.formatTime(value)}';
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 188),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.event_available_rounded,
            size: 18,
            color: AdminPalette.mutedText,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminPalette.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminPalette.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.usuario,
    required this.texts,
    required this.registeredAt,
  });

  final AdminUsuarioEmpresaAtiva usuario;
  final _UsersTexts texts;
  final String registeredAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AdminPalette.dark,
            child: Text(
              _initials(usuario.nomeExibicao),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  usuario.nomeExibicao.isEmpty
                      ? texts.userFallback
                      : usuario.nomeExibicao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminPalette.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoTag(
                      icon: Icons.mail_outline_rounded,
                      label: texts.email,
                      value: usuario.email,
                    ),
                    _InfoTag(
                      icon: Icons.phone_outlined,
                      label: texts.phone,
                      value: usuario.celular,
                    ),
                    _InfoTag(
                      icon: Icons.admin_panel_settings_outlined,
                      label: texts.role,
                      value: texts.roleLabel(usuario.papel),
                    ),
                    _InfoTag(
                      icon: Icons.event_available_rounded,
                      label: texts.registration,
                      value: registeredAt,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String normalized = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AdminPalette.mutedText),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AdminPalette.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              normalized,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AdminPalette.dark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUsers extends StatelessWidget {
  const _NoUsers({required this.texts});

  final _UsersTexts texts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.person_off_outlined,
            size: 18,
            color: AdminPalette.mutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texts.noLinkedUsers,
              style: const TextStyle(
                color: AdminPalette.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersLoadingState extends StatelessWidget {
  const _UsersLoadingState({super.key, required this.texts});

  final _UsersTexts texts;

  @override
  Widget build(BuildContext context) {
    return AdminStaggeredColumn(
      children: <Widget>[
        _UsersHeader(
          texts: texts,
          totalCompanies: 0,
          visibleCompanies: 0,
          totalUsers: 0,
          visibleUsers: 0,
        ),
        const AdminSkeletonCard(height: 78),
        const AdminSkeletonCard(height: 230),
        const AdminSkeletonCard(height: 230),
      ],
    );
  }
}

class _UsersErrorState extends StatelessWidget {
  const _UsersErrorState({
    super.key,
    required this.texts,
    required this.message,
    required this.onRetry,
  });

  final _UsersTexts texts;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AdminPalette.danger,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            texts.error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AdminPalette.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminPalette.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(texts.tryAgain),
          ),
        ],
      ),
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState({required this.texts, required this.hasFilter});

  final _UsersTexts texts;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 58),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminPalette.activeGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              hasFilter ? Icons.search_off_rounded : Icons.groups_rounded,
              color: AdminPalette.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? texts.noResults : texts.empty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AdminPalette.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter ? texts.noResultsHint : texts.emptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminPalette.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTexts {
  const _UsersTexts({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.search,
    required this.activeCompanies,
    required this.linkedUsers,
    required this.ofLabel,
    required this.registration,
    required this.status,
    required this.active,
    required this.companyName,
    required this.document,
    required this.usersInCompany,
    required this.userInfo,
    required this.email,
    required this.phone,
    required this.role,
    required this.adminRole,
    required this.collaboratorRole,
    required this.userFallback,
    required this.noDate,
    required this.noLinkedUsers,
    required this.empty,
    required this.emptyHint,
    required this.noResults,
    required this.noResultsHint,
    required this.error,
    required this.tryAgain,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final String search;
  final String activeCompanies;
  final String linkedUsers;
  final String ofLabel;
  final String registration;
  final String status;
  final String active;
  final String companyName;
  final String document;
  final String usersInCompany;
  final String userInfo;
  final String email;
  final String phone;
  final String role;
  final String adminRole;
  final String collaboratorRole;
  final String userFallback;
  final String noDate;
  final String noLinkedUsers;
  final String empty;
  final String emptyHint;
  final String noResults;
  final String noResultsHint;
  final String error;
  final String tryAgain;

  String roleLabel(String value) {
    final String normalized = value.trim().toUpperCase();
    if (normalized == 'ADMINISTRADOR') return adminRole;
    if (normalized == 'COLABORADOR') return collaboratorRole;
    return normalized.replaceAll('_', ' ');
  }

  factory _UsersTexts.of(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'en') {
      return const _UsersTexts(
        title: 'Users',
        eyebrow: 'Administrative management',
        subtitle:
            'List active companies and the users linked to each registration.',
        search: 'Search by company, document, user, email, phone or role',
        activeCompanies: 'Active companies',
        linkedUsers: 'Linked users',
        ofLabel: 'of',
        registration: 'Registered',
        status: 'Status',
        active: 'Active',
        companyName: 'Company name',
        document: 'Document',
        usersInCompany: 'Users',
        userInfo: 'User information',
        email: 'Email',
        phone: 'Phone',
        role: 'Role',
        adminRole: 'Administrator',
        collaboratorRole: 'Collaborator',
        userFallback: 'Linked user',
        noDate: 'No date',
        noLinkedUsers: 'No linked users found for this active company.',
        empty: 'No active companies found',
        emptyHint: 'Active company registrations will appear here.',
        noResults: 'No users match this search',
        noResultsHint: 'Try changing or clearing the search term.',
        error: 'Unable to load active users.',
        tryAgain: 'Try again',
      );
    }
    if (languageCode == 'es') {
      return const _UsersTexts(
        title: 'Usuarios',
        eyebrow: 'Gestión administrativa',
        subtitle:
            'Lista las empresas activas y los usuarios vinculados a cada registro.',
        search: 'Buscar por empresa, documento, usuario, email, teléfono o rol',
        activeCompanies: 'Empresas activas',
        linkedUsers: 'Usuarios vinculados',
        ofLabel: 'de',
        registration: 'Registro',
        status: 'Estado',
        active: 'Activa',
        companyName: 'Razón social',
        document: 'Documento',
        usersInCompany: 'Usuarios',
        userInfo: 'Información de usuarios',
        email: 'Email',
        phone: 'Teléfono',
        role: 'Rol',
        adminRole: 'Administrador',
        collaboratorRole: 'Colaborador',
        userFallback: 'Usuario vinculado',
        noDate: 'Sin fecha',
        noLinkedUsers:
            'No se encontraron usuarios vinculados para esta empresa activa.',
        empty: 'No se encontraron empresas activas',
        emptyHint: 'Los registros de empresas activas aparecerán aquí.',
        noResults: 'Ningún usuario coincide con esta búsqueda',
        noResultsHint: 'Intenta cambiar o limpiar el término de búsqueda.',
        error: 'No fue posible cargar los usuarios activos.',
        tryAgain: 'Intentar de nuevo',
      );
    }
    return const _UsersTexts(
      title: 'Usuários',
      eyebrow: 'Gestão administrativa',
      subtitle:
          'Liste as empresas ativas e os usuários vinculados a cada cadastro.',
      search:
          'Busque por empresa, documento, usuário, e-mail, telefone ou papel',
      activeCompanies: 'Empresas ativas',
      linkedUsers: 'Usuários vinculados',
      ofLabel: 'de',
      registration: 'Cadastro',
      status: 'Status',
      active: 'Ativa',
      companyName: 'Razão social',
      document: 'Documento',
      usersInCompany: 'Usuários',
      userInfo: 'Informações dos usuários',
      email: 'E-mail',
      phone: 'Telefone',
      role: 'Papel',
      adminRole: 'Administrador',
      collaboratorRole: 'Colaborador',
      userFallback: 'Usuário vinculado',
      noDate: 'Sem data',
      noLinkedUsers:
          'Nenhum usuário vinculado foi encontrado para esta empresa ativa.',
      empty: 'Nenhuma empresa ativa encontrada',
      emptyHint: 'Os cadastros de empresas ativas aparecerão aqui.',
      noResults: 'Nenhum usuário corresponde à busca',
      noResultsHint: 'Tente alterar ou limpar o termo pesquisado.',
      error: 'Não foi possível carregar os usuários ativos.',
      tryAgain: 'Tentar novamente',
    );
  }
}

String _initials(String value) {
  final List<String> parts =
      value
          .trim()
          .split(RegExp(r'\s+'))
          .where((String item) => item.isNotEmpty)
          .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
