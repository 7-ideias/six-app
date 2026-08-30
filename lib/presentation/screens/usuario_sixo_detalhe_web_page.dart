import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../l10n/six_i18n.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';
import 'usuario_sixo_onboarding_web_dialog.dart';

class UsuarioSixoDetalheWebPage extends StatefulWidget {
  const UsuarioSixoDetalheWebPage({
    super.key,
    required this.usuario,
    required this.onBack,
    required this.onChanged,
    this.service,
  });

  final AdminUsuarioEmpresaAtiva usuario;
  final VoidCallback onBack;
  final ValueChanged<AdminUsuarioDetalhe> onChanged;
  final AdminPortalService? service;

  @override
  State<UsuarioSixoDetalheWebPage> createState() =>
      _UsuarioSixoDetalheWebPageState();
}

class _UsuarioSixoDetalheWebPageState extends State<UsuarioSixoDetalheWebPage> {
  late final AdminPortalService _service =
      widget.service ?? AdminPortalService();

  AdminUsuarioDetalhe? _detail;
  bool _loading = true;
  bool _loadFailed = false;
  bool _resettingPassword = false;

  String get _idUsuario =>
      widget.usuario.idUnicoDoUsuario.trim().isNotEmpty
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
    if (detail == null) return;
    final bool changed = await showUsuarioSixoOnboardingWebDialog(
      context: context,
      nomeUsuario: detail.nomeExibicao,
      valorAtual: detail.fezOnboardingInicial,
      onConfirm: (bool novoValor) async {
        final AdminUsuarioDetalhe updated = await _service
            .atualizarOnboardingInicial(
              idUsuario: detail.identificador,
              fezOnboardingInicial: novoValor,
            );
        if (!mounted) return;
        setState(() => _detail = updated);
        widget.onChanged(updated);
      },
    );
    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _resetPassword() async {
    final AdminUsuarioDetalhe? detail = _detail;
    if (detail == null || _resettingPassword) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.lock_reset_rounded),
          title: Text(
            context.t(
              'usuariosSixo.passwordReset.dialogTitle',
              fallback: 'Resetar a senha deste usuário?',
            ),
          ),
          content: Text(
            context.t(
              'usuariosSixo.passwordReset.dialogMessage',
              fallback:
                  'A ação será aplicada imediatamente ao usuário selecionado.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.lock_reset_rounded),
              label: Text(
                context.t(
                  'usuariosSixo.passwordReset.action',
                  fallback: 'Resetar senha',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resettingPassword = true);
    try {
      await _service.resetarSenhaUsuarioSixo(idUsuario: detail.identificador);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'usuariosSixo.passwordReset.successMessage',
              fallback: 'O reset de senha foi concluído com sucesso.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'usuariosSixo.passwordReset.errorMessage',
              fallback:
                  'Não foi possível resetar a senha agora. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.manage_accounts_outlined,
            title: context.t(
              'usuariosSixo.detail.title',
              fallback: 'Detalhes do usuário',
            ),
            subtitle: context.t(
              'usuariosSixo.detail.subtitle',
              fallback:
                  'Cadastro, preferências, empresas e vínculos salvos no Sixo.',
            ),
            actions: <Widget>[
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(context.t('common.back', fallback: 'Voltar')),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                tooltip: context.t('common.refresh', fallback: 'Atualizar'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const <Widget>[
          SixWebLoadingBlock(height: 150),
          SizedBox(height: 14),
          SixWebLoadingBlock(height: 260),
        ],
      );
    }
    if (_loadFailed || _detail == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            context.t(
              'usuariosSixo.detail.loadError',
              fallback: 'Não foi possível carregar. Tentar novamente',
            ),
          ),
        ),
      );
    }

    final AdminUsuarioDetalhe detail = _detail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _WebUserHero(
                detail: detail,
                onChangeOnboarding: _changeOnboarding,
                onResetPassword: _resetPassword,
                resettingPassword: _resettingPassword,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width =
                      constraints.maxWidth >= 900
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(
                        width: width,
                        child: _WebDetailSection(
                          icon: Icons.badge_outlined,
                          title: context.t(
                            'usuariosSixo.detail.personal',
                            fallback: 'Dados pessoais',
                          ),
                          values: _flatten(detail.dadosPessoais),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _WebDetailSection(
                          icon: Icons.admin_panel_settings_outlined,
                          title: context.t(
                            'usuariosSixo.detail.account',
                            fallback: 'Conta e permissões',
                          ),
                          values: _accountValues(detail),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _WebDetailSection(
                          icon: Icons.tune_rounded,
                          title: context.t(
                            'usuariosSixo.detail.preferences',
                            fallback: 'Preferências individuais',
                          ),
                          values: _flatten(detail.preferenciasIndividuais),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _WebDetailSection(
                          icon: Icons.language_rounded,
                          title: context.t(
                            'usuariosSixo.detail.globalPreferences',
                            fallback: 'Preferências globais',
                          ),
                          values: _flatten(detail.preferenciasGlobais),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _WebCollectionSection(
                icon: Icons.storefront_outlined,
                title: context.t(
                  'usuariosSixo.detail.companies',
                  fallback: 'Empresas vinculadas',
                ),
                items: detail.empresas,
                emptyLabel: context.t(
                  'usuariosSixo.detail.noCompanies',
                  fallback: 'Nenhuma empresa vinculada.',
                ),
              ),
              const SizedBox(height: 16),
              _WebCollectionSection(
                icon: Icons.link_rounded,
                title: context.t(
                  'usuariosSixo.detail.links',
                  fallback: 'Vínculos e dados contratuais',
                ),
                items: detail.vinculos,
                emptyLabel: context.t(
                  'usuariosSixo.detail.noLinks',
                  fallback: 'Nenhum vínculo cadastrado.',
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _accountValues(AdminUsuarioDetalhe detail) {
    return <String, dynamic>{
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
    };
  }
}

class _WebUserHero extends StatelessWidget {
  const _WebUserHero({
    required this.detail,
    required this.onChangeOnboarding,
    required this.onResetPassword,
    required this.resettingPassword,
  });

  final AdminUsuarioDetalhe detail;
  final VoidCallback onChangeOnboarding;
  final VoidCallback onResetPassword;
  final bool resettingPassword;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool complete = detail.fezOnboardingInicial;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: tokens.selectedBackground,
                foregroundColor: tokens.info,
                child: const Icon(Icons.person_rounded, size: 31),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      detail.nomeExibicao,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail.identificador,
                      style: TextStyle(color: tokens.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (complete ? tokens.success : tokens.warning)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      complete
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 17,
                      color: complete ? tokens.success : tokens.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
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
                        color: complete ? tokens.success : tokens.warning,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onChangeOnboarding,
                icon: Icon(
                  complete ? Icons.restart_alt_rounded : Icons.task_alt_rounded,
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
              OutlinedButton.icon(
                onPressed: resettingPassword ? null : onResetPassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.danger,
                  side: BorderSide(
                    color: tokens.danger.withValues(alpha: 0.32),
                  ),
                  backgroundColor: tokens.surfaceMuted,
                ),
                icon:
                    resettingPassword
                        ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.danger,
                          ),
                        )
                        : Icon(Icons.lock_reset_rounded, color: tokens.danger),
                label: Text(
                  context.t(
                    'usuariosSixo.passwordReset.action',
                    fallback: 'Resetar senha',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebDetailSection extends StatelessWidget {
  const _WebDetailSection({
    required this.icon,
    required this.title,
    required this.values,
  });

  final IconData icon;
  final String title;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: tokens.info, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (values.isEmpty)
            Text(
              context.t('common.notInformed', fallback: 'Não informado'),
              style: TextStyle(color: tokens.mutedText),
            )
          else
            for (final MapEntry<String, dynamic> entry in values.entries)
              _WebDetailRow(entry: entry),
        ],
      ),
    );
  }
}

class _WebCollectionSection extends StatelessWidget {
  const _WebCollectionSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final IconData icon;
  final String title;
  final List<Map<String, dynamic>> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return _WebDetailSection(
      icon: icon,
      title: title,
      values:
          items.isEmpty
              ? <String, dynamic>{'situacao': emptyLabel}
              : <String, dynamic>{
                for (int i = 0; i < items.length; i++)
                  ..._flatten(items[i], prefix: '${i + 1}'),
              },
    );
  }
}

class _WebDetailRow extends StatelessWidget {
  const _WebDetailRow({required this.entry});

  final MapEntry<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              _humanize(entry.key),
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SelectableText(
              _formatDetailValue(context, entry.key, entry.value),
              style: TextStyle(
                color: tokens.primaryText,
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

Map<String, dynamic> _flatten(
  Map<String, dynamic> source, {
  String prefix = '',
}) {
  final Map<String, dynamic> result = <String, dynamic>{};
  source.forEach((String key, dynamic value) {
    final String path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<dynamic, dynamic>) {
      result.addAll(
        _flatten(
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

String _humanize(String key) {
  final String leaf = key
      .replaceAll('.', ' · ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (Match match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ');
  return leaf.isEmpty ? '-' : '${leaf[0].toUpperCase()}${leaf.substring(1)}';
}

String _formatDetailValue(BuildContext context, String key, dynamic value) {
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
