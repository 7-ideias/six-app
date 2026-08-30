import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';

class UsuarioSixoDetalheMobileScreen extends StatefulWidget {
  const UsuarioSixoDetalheMobileScreen({
    super.key,
    required this.usuario,
    this.service,
  });

  final AdminUsuarioEmpresaAtiva usuario;
  final AdminPortalService? service;

  @override
  State<UsuarioSixoDetalheMobileScreen> createState() =>
      _UsuarioSixoDetalheMobileScreenState();
}

class _UsuarioSixoDetalheMobileScreenState
    extends State<UsuarioSixoDetalheMobileScreen> {
  late final AdminPortalService _service =
      widget.service ?? AdminPortalService();

  AdminUsuarioDetalhe? _detail;
  bool _loading = true;
  bool _loadFailed = false;
  bool _updatingOnboarding = false;

  String get _idUsuario => widget.usuario.idUnicoDoUsuario.trim().isNotEmpty
      ? widget.usuario.idUnicoDoUsuario.trim()
      : widget.usuario.keycloakId.trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final AdminUsuarioDetalhe detail = await _service.buscarUsuarioSixo(
        _idUsuario,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _changeOnboarding() async {
    final AdminUsuarioDetalhe? detail = _detail;
    if (detail == null || _updatingOnboarding) return;
    final bool novoValor = !detail.fezOnboardingInicial;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            novoValor ? Icons.task_alt_rounded : Icons.restart_alt_rounded,
          ),
          title: Text(
            novoValor
                ? context.t(
                    'usuariosSixo.onboarding.completeTitle',
                    fallback: 'Marcar onboarding como concluído?',
                  )
                : context.t(
                    'usuariosSixo.onboarding.resetTitle',
                    fallback: 'Solicitar novo onboarding?',
                  ),
          ),
          content: Text(
            novoValor
                ? context.t(
                    'usuariosSixo.onboarding.completeMessage',
                    fallback:
                        'O usuário deixará de ver o onboarding inicial nos próximos acessos.',
                  )
                : context.t(
                    'usuariosSixo.onboarding.resetMessage',
                    fallback:
                        'No próximo acesso, o usuário deverá confirmar novamente seus dados iniciais antes de entrar no sistema.',
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                novoValor
                    ? context.t(
                        'usuariosSixo.onboarding.completeAction',
                        fallback: 'Marcar como concluído',
                      )
                    : context.t(
                        'usuariosSixo.onboarding.resetAction',
                        fallback: 'Refazer onboarding',
                      ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingOnboarding = true);
    try {
      final AdminUsuarioDetalhe updated =
          await _service.atualizarOnboardingInicial(
            idUsuario: detail.identificador,
            fezOnboardingInicial: novoValor,
          );
      if (!mounted) return;
      setState(() {
        _detail = updated;
        _updatingOnboarding = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'usuariosSixo.onboarding.successMessage',
              fallback: 'A nova regra já valerá no próximo acesso do usuário.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingOnboarding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'usuariosSixo.onboarding.errorMessage',
              fallback: 'Não foi possível atualizar. Tente novamente.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: context.t(
        'usuariosSixo.detail.title',
        fallback: 'Detalhes do usuário',
      ),
      backgroundColor: SixMobilePalette.backgroundLight,
      primaryColor: SixMobilePalette.primaryLight,
      secondaryColor: SixMobilePalette.secondaryLight,
      accentColor: SixMobilePalette.accentLight,
      actions: <Widget>[
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: context.t('common.refresh', fallback: 'Atualizar'),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return _buildBody(context, scrollController, topInset);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    if (_loading) {
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 32),
        children: const <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: 18),
          _MobileDetailSkeleton(height: 144),
          SizedBox(height: 12),
          _MobileDetailSkeleton(height: 260),
        ],
      );
    }
    if (_loadFailed || _detail == null) {
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 32),
        children: <Widget>[
          _MobileDetailMessage(
            message: context.t(
              'usuariosSixo.detail.loadError',
              fallback: 'Não foi possível carregar os detalhes.',
            ),
            onRetry: _load,
          ),
        ],
      );
    }

    final AdminUsuarioDetalhe detail = _detail!;
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 32),
      children: <Widget>[
        _MobileUserHero(detail: detail),
        const SizedBox(height: 12),
        _MobileOnboardingCard(
          complete: detail.fezOnboardingInicial,
          loading: _updatingOnboarding,
          onPressed: _changeOnboarding,
        ),
        const SizedBox(height: 12),
        _MobileDetailSection(
          icon: Icons.badge_outlined,
          title: context.t(
            'usuariosSixo.detail.personal',
            fallback: 'Dados pessoais',
          ),
          values: _mobileFlatten(detail.dadosPessoais),
          initiallyExpanded: true,
        ),
        const SizedBox(height: 10),
        _MobileDetailSection(
          icon: Icons.admin_panel_settings_outlined,
          title: context.t(
            'usuariosSixo.detail.account',
            fallback: 'Conta e permissões',
          ),
          values: <String, dynamic>{
            'idUnicoDoUsuario': detail.idUnicoDoUsuario,
            'keycloakId': detail.keycloakId,
            'tipoDoAssinante': detail.tipoDoAssinante,
            'fezOnboardingInicial': detail.fezOnboardingInicial,
            'smsFoiValidado': detail.smsFoiValidado,
            'dataCadastro': detail.dataCadastro,
            'testeExpiraEm': detail.testeExpiraEm,
            'idsUnicosDasEmpresas': detail.idsUnicosDasEmpresas,
            'permissoes': detail.permissoes,
            'quantidadeDeLogs': detail.quantidadeDeLogs,
          },
          initiallyExpanded: true,
        ),
        const SizedBox(height: 10),
        _MobileDetailSection(
          icon: Icons.tune_rounded,
          title: context.t(
            'usuariosSixo.detail.preferences',
            fallback: 'Preferências individuais',
          ),
          values: _mobileFlatten(detail.preferenciasIndividuais),
        ),
        const SizedBox(height: 10),
        _MobileDetailSection(
          icon: Icons.language_rounded,
          title: context.t(
            'usuariosSixo.detail.globalPreferences',
            fallback: 'Preferências globais',
          ),
          values: _mobileFlatten(detail.preferenciasGlobais),
        ),
        const SizedBox(height: 10),
        _MobileDetailSection(
          icon: Icons.storefront_outlined,
          title: context.t(
            'usuariosSixo.detail.companies',
            fallback: 'Empresas vinculadas',
          ),
          values: _mobileCollectionValues(
            detail.empresas,
            context.t(
              'usuariosSixo.detail.noCompanies',
              fallback: 'Nenhuma empresa vinculada.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        _MobileDetailSection(
          icon: Icons.link_rounded,
          title: context.t(
            'usuariosSixo.detail.links',
            fallback: 'Vínculos e dados contratuais',
          ),
          values: _mobileCollectionValues(
            detail.vinculos,
            context.t(
              'usuariosSixo.detail.noLinks',
              fallback: 'Nenhum vínculo cadastrado.',
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileUserHero extends StatelessWidget {
  const _MobileUserHero({required this.detail});

  final AdminUsuarioDetalhe detail;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: colors.onPrimary,
            child: const Icon(Icons.person_rounded, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  detail.nomeExibicao,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail.identificador,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.heroSupportingText,
                    fontSize: 11,
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

class _MobileOnboardingCard extends StatelessWidget {
  const _MobileOnboardingCard({
    required this.complete,
    required this.loading,
    required this.onPressed,
  });

  final bool complete;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                complete ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: complete ? colors.accent : const Color(0xFFD97706),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  complete
                      ? context.t(
                          'usuariosSixo.onboarding.completed',
                          fallback: 'Onboarding concluído',
                        )
                      : context.t(
                          'usuariosSixo.onboarding.pending',
                          fallback: 'Onboarding pendente',
                        ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      complete
                          ? Icons.restart_alt_rounded
                          : Icons.task_alt_rounded,
                    ),
              label: Text(
                complete
                    ? context.t(
                        'usuariosSixo.onboarding.resetAction',
                        fallback: 'Refazer onboarding',
                      )
                    : context.t(
                        'usuariosSixo.onboarding.completeAction',
                        fallback: 'Marcar como concluído',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDetailSection extends StatelessWidget {
  const _MobileDetailSection({
    required this.icon,
    required this.title,
    required this.values,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final Map<String, dynamic> values;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: colors.accent),
        title: Text(
          title,
          style: TextStyle(
            color: colors.titleText,
            fontWeight: FontWeight.w900,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          if (values.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.t('common.notInformed', fallback: 'Não informado'),
                style: TextStyle(color: colors.mutedText),
              ),
            )
          else
            for (final MapEntry<String, dynamic> entry in values.entries)
              _MobileDetailRow(entry: entry),
        ],
      ),
    );
  }
}

class _MobileDetailRow extends StatelessWidget {
  const _MobileDetailRow({required this.entry});

  final MapEntry<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _mobileHumanize(entry.key),
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            _mobileFormatValue(context, entry.key, entry.value),
            style: TextStyle(
              color: colors.titleText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDetailSkeleton extends StatelessWidget {
  const _MobileDetailSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.sixMobileColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.sixMobileColors.border),
      ),
    );
  }
}

class _MobileDetailMessage extends StatelessWidget {
  const _MobileDetailMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.sixMobileColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, size: 34),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _mobileCollectionValues(
  List<Map<String, dynamic>> items,
  String emptyLabel,
) {
  if (items.isEmpty) return <String, dynamic>{'situacao': emptyLabel};
  return <String, dynamic>{
    for (int i = 0; i < items.length; i++)
      ..._mobileFlatten(items[i], prefix: '${i + 1}'),
  };
}

Map<String, dynamic> _mobileFlatten(
  Map<String, dynamic> source, {
  String prefix = '',
}) {
  final Map<String, dynamic> result = <String, dynamic>{};
  source.forEach((String key, dynamic value) {
    final String path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<dynamic, dynamic>) {
      result.addAll(
        _mobileFlatten(
          value.map<String, dynamic>(
            (dynamic nestedKey, dynamic nestedValue) =>
                MapEntry<String, dynamic>(nestedKey.toString(), nestedValue),
          ),
          prefix: path,
        ),
      );
    } else {
      result[path] = value;
    }
  });
  return result;
}

String _mobileHumanize(String key) {
  final String leaf = key
      .replaceAll('.', ' · ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (Match match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ');
  return leaf.isEmpty ? '-' : '${leaf[0].toUpperCase()}${leaf.substring(1)}';
}

String _mobileFormatValue(BuildContext context, String key, dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return context.t('common.notInformed', fallback: 'Não informado');
  }
  if (value is bool) {
    return value
        ? context.t('common.yes', fallback: 'Sim')
        : context.t('common.no', fallback: 'Não');
  }
  if (value is DateTime) return value.toLocal().toIso8601String();
  if (value is List) {
    return value.isEmpty
        ? context.t('common.notInformed', fallback: 'Não informado')
        : value.join(', ');
  }
  final String text = value.toString();
  final String normalizedKey = key.toLowerCase();
  if ((normalizedKey.contains('foto') || normalizedKey.contains('logo')) &&
      text.length > 100) {
    return context.t(
      'usuariosSixo.detail.imageStored',
      fallback: 'Imagem armazenada',
    );
  }
  return text;
}
