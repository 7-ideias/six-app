import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

import 'usuario_sixo_detalhe_mobile_screen.dart';

class UsuariosSixoMobileScreen extends StatefulWidget {
  const UsuariosSixoMobileScreen({super.key, this.service});

  final AdminPortalService? service;

  @override
  State<UsuariosSixoMobileScreen> createState() =>
      _UsuariosSixoMobileScreenState();
}

class _UsuariosSixoMobileScreenState extends State<UsuariosSixoMobileScreen> {
  late final AdminPortalService _service =
      widget.service ?? AdminPortalService();
  final TextEditingController _searchController = TextEditingController();

  bool _requestStarted = false;
  bool _loading = false;
  String? _error;
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
      _error = null;
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
        _error = 'usuariosSixo.loadError';
        _loading = false;
      });
    }
  }

  Future<void> _openUser(AdminUsuarioEmpresaAtiva user) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UsuarioSixoDetalheMobileScreen(
          usuario: user,
          service: _service,
        ),
      ),
    );
    if (mounted) await _loadUsers();
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

    return SixMobilePageShell(
      title: context.t('usuariosSixo.title', fallback: 'Usuários do Sixo'),
      backgroundColor: SixMobilePalette.backgroundLight,
      primaryColor: SixMobilePalette.primaryLight,
      secondaryColor: SixMobilePalette.secondaryLight,
      accentColor: SixMobilePalette.accentLight,
      actions: <Widget>[
        if (isSuper)
          IconButton(
            onPressed: _loading ? null : _loadUsers,
            tooltip: context.t('common.refresh', fallback: 'Atualizar'),
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 32),
          children: <Widget>[
            if (!isSuper)
              _MobileMessageCard(
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
              )
            else ...<Widget>[
              _buildSummary(context),
              const SizedBox(height: 14),
              _buildSearch(context),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildContent(context),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummary(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      container: true,
      label: context.t(
        'usuariosSixo.summarySemantics',
        fallback: 'Resumo dos usuários cadastrados no Sixo',
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.softAccentSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.hub_outlined, color: colors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(
                      'usuariosSixo.summaryTitle',
                      fallback: 'Base global de usuários',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t(
                      'usuariosSixo.summarySubtitle',
                      fallback:
                          'Consulta protegida pelo perfil SUPER do token.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                SixAnimatedNumberText(
                  value: _users.length.toString(),
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.t(
                    'usuariosSixo.totalLabel',
                    fallback: 'usuários',
                  ),
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.t(
          'usuariosSixo.searchHint',
          fallback: 'Buscar por nome, e-mail, celular ou perfil',
        ),
        prefixIcon: Icon(Icons.search_rounded, color: colors.mutedText),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _searchController.clear,
                tooltip: context.t('common.clear', fallback: 'Limpar'),
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const _MobileUsersLoading(
        key: ValueKey<String>('sixo-users-loading'),
      );
    }
    if (_error != null) {
      return _MobileMessageCard(
        key: const ValueKey<String>('sixo-users-error'),
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
      return _MobileMessageCard(
        key: const ValueKey<String>('sixo-users-empty'),
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
      key: const ValueKey<String>('sixo-users-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
          child: Text(
            '${users.length} ${context.t('usuariosSixo.resultsLabel', fallback: 'encontrados')}',
            style: TextStyle(
              color: context.sixMobileColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (int index = 0; index < users.length; index++)
          SixStaggeredEntry(
            delay: Duration(
              milliseconds: index.clamp(0, 8).toInt() * 28,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MobileSixoUserCard(
                user: users[index],
                roleLabel: _roleLabel(context, users[index].papel),
                onTap: () => _openUser(users[index]),
              ),
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

class _MobileSixoUserCard extends StatelessWidget {
  const _MobileSixoUserCard({
    required this.user,
    required this.roleLabel,
    required this.onTap,
  });

  final AdminUsuarioEmpresaAtiva user;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final String name = user.nomeExibicao.trim().isEmpty
        ? context.t('usuariosSixo.userFallback', fallback: 'Usuário do Sixo')
        : user.nomeExibicao.trim();
    return Semantics(
      container: true,
      button: true,
      label: '$name, $roleLabel',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 23,
              backgroundColor: colors.softAccentSurface,
              foregroundColor: colors.accent,
              child: Text(
                _initials(name),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.titleText,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.softAccentSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MobileUserMetadata(
                    icon: Icons.mail_outline_rounded,
                    value: user.email.trim().isEmpty
                        ? context.t(
                            'usuariosSixo.noEmail',
                            fallback: 'E-mail não informado',
                          )
                        : user.email.trim(),
                  ),
                  const SizedBox(height: 7),
                  _MobileUserMetadata(
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
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: colors.mutedText),
          ],
            ),
          ),
        ),
      ),
    );
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

class _MobileUserMetadata extends StatelessWidget {
  const _MobileUserMetadata({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: colors.mutedText),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.mutedText, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _MobileUsersLoading extends StatelessWidget {
  const _MobileUsersLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t(
        'usuariosSixo.loading',
        fallback: 'Carregando usuários do Sixo',
      ),
      child: Column(
        children: List<Widget>.generate(4, (int index) {
          return Container(
            height: 112,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: colors.iconSurface,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _MobileLoadingLine(widthFactor: 0.56),
                        const SizedBox(height: 12),
                        _MobileLoadingLine(widthFactor: 0.84),
                        const SizedBox(height: 8),
                        _MobileLoadingLine(widthFactor: 0.68),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MobileLoadingLine extends StatelessWidget {
  const _MobileLoadingLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: context.sixMobileColors.iconSurface,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _MobileMessageCard extends StatelessWidget {
  const _MobileMessageCard({
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 34, color: colors.mutedText),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
