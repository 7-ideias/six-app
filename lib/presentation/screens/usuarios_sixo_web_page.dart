import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

class UsuariosSixoWebPage extends StatefulWidget {
  const UsuariosSixoWebPage({super.key, this.service});

  final AdminPortalService? service;

  @override
  State<UsuariosSixoWebPage> createState() => _UsuariosSixoWebPageState();
}

class _UsuariosSixoWebPageState extends State<UsuariosSixoWebPage> {
  late final AdminPortalService _service =
      widget.service ?? AdminPortalService();
  final TextEditingController _searchController = TextEditingController();

  bool _requestStarted = false;
  bool _loading = false;
  bool _loadFailed = false;
  List<AdminUsuarioEmpresaAtiva> _users =
      const <AdminUsuarioEmpresaAtiva>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startRequestIfAllowed();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _startRequestIfAllowed() {
    final bool isSuper = context
        .read<ColaboradorAutorizacoesProvider>()
        .ehSuperUsuario;
    if (!isSuper || _requestStarted) return;
    _requestStarted = true;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!context
        .read<ColaboradorAutorizacoesProvider>()
        .ehSuperUsuario) {
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final List<AdminUsuarioEmpresaAtiva> users =
          await _service.listarUsuariosSixo();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  List<AdminUsuarioEmpresaAtiva> get _filteredUsers {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users
        .where((AdminUsuarioEmpresaAtiva user) {
          return <String>[
            user.nome,
            user.email,
            user.celular,
            user.papel,
            user.idUnicoDoUsuario,
            user.keycloakId,
          ].any((String value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuper = context
        .watch<ColaboradorAutorizacoesProvider>()
        .ehSuperUsuario;
    if (isSuper && !_requestStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startRequestIfAllowed();
      });
    }
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.hub_outlined,
            title: context.t(
              'usuariosSixo.title',
              fallback: 'Usuários do Sixo',
            ),
            subtitle: context.t(
              'usuariosSixo.subtitle',
              fallback:
                  'Consulte os usuários cadastrados com acesso exclusivo para o perfil SUPER.',
            ),
            actions: <Widget>[
              if (isSuper)
                OutlinedButton.icon(
                  onPressed: _loading ? null : _loadUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.t('common.refresh', fallback: 'Atualizar'),
                  ),
                ),
            ],
          ),
          Expanded(
            child: isSuper
                ? _buildAllowedContent(context)
                : _WebMessageState(
                    icon: Icons.lock_outline_rounded,
                    title: context.t(
                      'usuariosSixo.forbiddenTitle',
                      fallback: 'Acesso exclusivo para SUPER',
                    ),
                    message: context.t(
                      'usuariosSixo.forbiddenMessage',
                      fallback:
                          'Seu perfil não possui permissão para consultar os usuários do Sixo.',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowedContent(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  _buildToolbar(context, constraints.maxWidth < 720),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildContent(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, bool compact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget total = SixWebKpiCard(
      icon: Icons.groups_2_outlined,
      label: context.t(
        'usuariosSixo.totalRegistered',
        fallback: 'Usuários cadastrados',
      ),
      value: _users.length.toDouble(),
      formatter: (double value) => value.round().toString(),
      highlight: true,
    );
    final Widget search = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.t(
            'usuariosSixo.searchHint',
            fallback: 'Buscar por nome, e-mail, celular ou perfil',
          ),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  tooltip: context.t('common.clear', fallback: 'Limpar'),
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: tokens.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
        ),
      ),
    );

    if (compact) {
      return Column(
        children: <Widget>[
          SizedBox(height: 92, child: total),
          const SizedBox(height: 12),
          search,
        ],
      );
    }
    return Row(
      children: <Widget>[
        SizedBox(width: 280, height: 92, child: total),
        const SizedBox(width: 16),
        Expanded(child: search),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: context.t(
          'usuariosSixo.loading',
          fallback: 'Carregando usuários do Sixo',
        ),
        child: ListView.separated(
          key: const ValueKey<String>('sixo-users-web-loading'),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const SixWebLoadingBlock(height: 112),
        ),
      );
    }
    if (_loadFailed) {
      return _WebMessageState(
        key: const ValueKey<String>('sixo-users-web-error'),
        icon: Icons.cloud_off_outlined,
        title: context.t(
          'usuariosSixo.loadErrorTitle',
          fallback: 'Não foi possível carregar os usuários',
        ),
        message: context.t(
          'usuariosSixo.loadError',
          fallback: 'Verifique sua conexão e tente novamente.',
        ),
        actionLabel: context.t('common.tryAgain', fallback: 'Tentar novamente'),
        onAction: _loadUsers,
      );
    }

    final List<AdminUsuarioEmpresaAtiva> users = _filteredUsers;
    if (users.isEmpty) {
      return _WebMessageState(
        key: const ValueKey<String>('sixo-users-web-empty'),
        icon: Icons.person_search_outlined,
        title: context.t(
          'usuariosSixo.emptyTitle',
          fallback: 'Nenhum usuário encontrado',
        ),
        message: context.t(
          'usuariosSixo.emptyMessage',
          fallback: 'Ajuste a busca para consultar outros usuários.',
        ),
      );
    }

    return Column(
      key: const ValueKey<String>('sixo-users-web-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            '${users.length} ${context.t('usuariosSixo.resultsLabel', fallback: 'encontrados')}',
            style: TextStyle(
              color: WebThemeTokens.of(context).secondaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final AdminUsuarioEmpresaAtiva user = users[index];
              return SixWebEntry(
                order: index.clamp(0, 10),
                child: _WebSixoUserCard(
                  user: user,
                  roleLabel: _roleLabel(context, user.papel),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _roleLabel(BuildContext context, String role) {
    return switch (role.trim().toUpperCase()) {
      'SUPER' || 'SUPER_USER' => context.t(
        'usuariosSixo.role.super',
        fallback: 'SUPER',
      ),
      'ADMIN' || 'ADMINISTRADOR' => context.t(
        'usuariosSixo.role.admin',
        fallback: 'Administrador',
      ),
      'COLABORADOR' => context.t(
        'usuariosSixo.role.collaborator',
        fallback: 'Colaborador',
      ),
      'CLIENTE' => context.t(
        'usuariosSixo.role.customer',
        fallback: 'Cliente',
      ),
      _ => context.t('usuariosSixo.role.unknown', fallback: 'Não informado'),
    };
  }
}

class _WebSixoUserCard extends StatelessWidget {
  const _WebSixoUserCard({required this.user, required this.roleLabel});

  final AdminUsuarioEmpresaAtiva user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String name = user.nomeExibicao.trim().isEmpty
        ? context.t('usuariosSixo.userFallback', fallback: 'Usuário do Sixo')
        : user.nomeExibicao.trim();
    return Semantics(
      container: true,
      label: '$name, $roleLabel',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: tokens.selectedBackground,
              foregroundColor: tokens.info,
              child: Text(
                _initials(name),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _WebUserMetadata(
                    icon: Icons.fingerprint_rounded,
                    value: _userIdentifier(user),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  _WebMetadataChip(
                    icon: Icons.mail_outline_rounded,
                    value: user.email.trim().isEmpty
                        ? context.t(
                            'usuariosSixo.noEmail',
                            fallback: 'E-mail não informado',
                          )
                        : user.email.trim(),
                  ),
                  _WebMetadataChip(
                    icon: Icons.phone_outlined,
                    value: user.celular.trim().isEmpty
                        ? context.t(
                            'usuariosSixo.noPhone',
                            fallback: 'Celular não informado',
                          )
                        : user.celular.trim(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.selectedBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.selectedBorder),
              ),
              child: Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _userIdentifier(AdminUsuarioEmpresaAtiva user) {
    if (user.idUnicoDoUsuario.trim().isNotEmpty) {
      return user.idUnicoDoUsuario.trim();
    }
    if (user.keycloakId.trim().isNotEmpty) return user.keycloakId.trim();
    return '-';
  }

  String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'SX';
    if (parts.length == 1) {
      return parts.first.characters.take(2).join().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _WebUserMetadata extends StatelessWidget {
  const _WebUserMetadata({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: tokens.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.mutedText, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _WebMetadataChip extends StatelessWidget {
  const _WebMetadataChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: tokens.secondaryText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebMessageState extends StatelessWidget {
  const _WebMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: tokens.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 40, color: tokens.mutedText),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.secondaryText, height: 1.45),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
