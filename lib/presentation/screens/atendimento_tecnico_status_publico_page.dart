import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';

class AtendimentoTecnicoStatusPublicoPage extends StatefulWidget {
  const AtendimentoTecnicoStatusPublicoPage({
    super.key,
    required this.initialUri,
  });

  final Uri initialUri;

  @override
  State<AtendimentoTecnicoStatusPublicoPage> createState() =>
      _AtendimentoTecnicoStatusPublicoPageState();
}

class _AtendimentoTecnicoStatusPublicoPageState
    extends State<AtendimentoTecnicoStatusPublicoPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();

  late final String _token;
  late final String _idUnicoDaEmpresa;
  late Future<AtendimentoTecnicoStatusPublicoModel> _future;
  bool _gerandoLinkAssinatura = false;

  @override
  void initState() {
    super.initState();
    _token = widget.initialUri.queryParameters['token'] ?? '';
    _idUnicoDaEmpresa =
        widget.initialUri.queryParameters['idUnicoDaEmpresa'] ?? '';
    _future = _carregar();
  }

  Future<AtendimentoTecnicoStatusPublicoModel> _carregar() async {
    if (_token.isEmpty || _idUnicoDaEmpresa.isEmpty) {
      throw const _StatusPublicoLinkInvalidoException();
    }
    return _service.consultarStatusPublico(
      idUnicoDaEmpresa: _idUnicoDaEmpresa,
      token: _token,
    );
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  Future<void> _abrirAssinatura() async {
    if (_gerandoLinkAssinatura) return;
    final linkMissingMessage = context.t(
      'atendimentoTecnico.publicStatus.signatureLinkMissing',
      fallback: 'Link de assinatura não retornado pelo backend.',
    );
    final linkErrorMessage = context.t(
      'atendimentoTecnico.publicStatus.signatureLinkError',
      fallback: 'Não foi possível abrir a assinatura.',
    );
    setState(() => _gerandoLinkAssinatura = true);
    try {
      final response = await _service.gerarLinkAssinaturaPeloStatusPublico(
        idUnicoDaEmpresa: _idUnicoDaEmpresa,
        token: _token,
        baseUrl: '${Uri.base.origin}/atendimento/assinatura',
      );
      final String link = response.link.trim();
      if (link.isEmpty) {
        throw Exception(linkMissingMessage);
      }
      final assinaturaUri = Uri.parse(link);
      final routeName =
          assinaturaUri.hasQuery
              ? '${assinaturaUri.path}?${assinaturaUri.query}'
              : assinaturaUri.path;
      if (!mounted) return;
      await Navigator.of(context).pushNamed(routeName);
      if (mounted) _recarregar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(linkErrorMessage),
        ),
      );
    } finally {
      if (mounted) setState(() => _gerandoLinkAssinatura = false);
    }
  }

  String _formatarData(DateTime? value) {
    if (value == null) {
      return context.t('common.notInformed', fallback: 'Não informada');
    }
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarDataHora(DateTime? value) {
    if (value == null) {
      return context.t('common.notInformed', fallback: 'Não informada');
    }
    final locale = context.read<LocaleSettingsProvider>();
    return '${locale.formatDate(value)} ${locale.formatTime(value)}';
  }

  String _statusLabel(AtendimentoTecnicoStatusPublicoModel status) {
    return _localizedLabel(
      pt: status.statusNomePtBr,
      en: status.statusNomeEnUs,
      es: status.statusNomeEsEs,
      fallback: status.statusCodigo,
    );
  }

  String _etapaLabel(AtendimentoTecnicoStatusPublicoEtapaModel etapa) {
    return _localizedLabel(
      pt: etapa.nomePtBr,
      en: etapa.nomeEnUs,
      es: etapa.nomeEsEs,
      fallback: etapa.codigo,
    );
  }

  String _historicoLabel(AtendimentoTecnicoStatusPublicoHistoricoModel item) {
    return _localizedLabel(
      pt: item.statusNomePtBr,
      en: item.statusNomeEnUs,
      es: item.statusNomeEsEs,
      fallback: item.statusCodigo,
    );
  }

  String _localizedLabel({
    required String? pt,
    required String? en,
    required String? es,
    required String fallback,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final selected = switch (languageCode) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
    final String label = selected?.trim() ?? '';
    if (label.isNotEmpty) return label;
    final String fallbackTrimmed = fallback.trim();
    return fallbackTrimmed.isEmpty ? '-' : fallbackTrimmed;
  }

  List<AtendimentoTecnicoStatusPublicoEtapaModel> _etapasVisiveis(
    AtendimentoTecnicoStatusPublicoModel status,
  ) {
    final String codigoAtual = status.statusCodigo.trim().toUpperCase();
    final etapas = status.etapas
        .where(
          (etapa) =>
              !etapa.finalizador ||
              etapa.codigo.trim().toUpperCase() == codigoAtual,
        )
        .toList(growable: false);
    return etapas.isEmpty ? status.etapas : etapas;
  }

  double _progresso(AtendimentoTecnicoStatusPublicoModel status) {
    final etapas = _etapasVisiveis(status);
    if (etapas.isEmpty) return 0;
    final String codigoAtual = status.statusCodigo.trim().toUpperCase();
    final int index = etapas.indexWhere(
      (etapa) =>
          etapa.atual || etapa.codigo.trim().toUpperCase() == codigoAtual,
    );
    if (index < 0) return 0;
    return ((index + 1) / etapas.length).clamp(0, 1).toDouble();
  }

  Color _statusColor(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
  ) {
    AtendimentoTecnicoStatusPublicoEtapaModel? current;
    for (final etapa in status.etapas) {
      if (etapa.atual) {
        current = etapa;
        break;
      }
    }
    return _colorFromHex(current?.cor, theme.colorScheme.primary);
  }

  Color _colorFromHex(String? value, Color fallback) {
    final String hex = (value ?? '').replaceAll('#', '').trim();
    if (hex.length != 6 && hex.length != 8) return fallback;
    try {
      final String normalized = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _statusIcon(String icon) {
    return switch (icon.trim()) {
      'assignment_add' => Icons.assignment_add,
      'troubleshoot' => Icons.troubleshoot,
      'request_quote' => Icons.request_quote_outlined,
      'hourglass_top' => Icons.hourglass_top_rounded,
      'inventory' => Icons.inventory_2_outlined,
      'engineering' => Icons.engineering_outlined,
      'task_alt' => Icons.task_alt_rounded,
      'verified' => Icons.verified_rounded,
      'cancel' => Icons.cancel_outlined,
      'block' => Icons.block,
      _ => Icons.flag_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (provider) => '${provider.dateFormat}|${provider.timeFormat}',
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: FutureBuilder<AtendimentoTecnicoStatusPublicoModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingStatusPublico(
              message: context.t(
                'atendimentoTecnico.publicStatus.loading',
                fallback: 'Carregando status do serviço...',
              ),
            );
          }
          if (snapshot.hasError) {
            return _ErroStatusPublico(
              mensagem:
                  snapshot.error is _StatusPublicoLinkInvalidoException
                      ? context.t(
                        'atendimentoTecnico.publicStatus.invalidLink',
                        fallback:
                            'Link inválido. Token ou comércio não informado.',
                      )
                      : snapshot.error.toString(),
              onRetry: _recarregar,
            );
          }

          final status = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final horizontalPadding = compact ? 16.0 : 28.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      22,
                      horizontalPadding,
                      28,
                    ),
                    children: <Widget>[
                      _buildHeader(theme, status, compact),
                      const SizedBox(height: 14),
                      if (!status.assinaturaAprovada ||
                          status.requerNovaAssinatura) ...[
                        _buildAssinaturaAviso(theme, status, compact),
                        const SizedBox(height: 14),
                      ],
                      _buildProgress(theme, status),
                      const SizedBox(height: 14),
                      compact
                          ? Column(
                            children: <Widget>[
                              _buildResumo(theme, status),
                              const SizedBox(height: 14),
                              _buildHistorico(theme, status),
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: _buildResumo(theme, status)),
                              const SizedBox(width: 14),
                              Expanded(child: _buildHistorico(theme, status)),
                            ],
                          ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAssinaturaAviso(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
    bool compact,
  ) {
    final colorScheme = theme.colorScheme;
    final bool novaAssinatura = status.requerNovaAssinatura;
    final titleKey =
        novaAssinatura
            ? 'atendimentoTecnico.publicStatus.signatureRenewTitle'
            : 'atendimentoTecnico.publicStatus.signaturePendingTitle';
    final descriptionKey =
        novaAssinatura
            ? 'atendimentoTecnico.publicStatus.signatureRenewDescription'
            : 'atendimentoTecnico.publicStatus.signaturePendingDescription';
    final titleFallback =
        novaAssinatura
            ? 'Nova assinatura necessária'
            : 'Assinatura de aprovação pendente';
    final descriptionFallback =
        novaAssinatura
            ? 'O atendimento foi alterado depois da última aprovação. Você pode acompanhar o status normalmente e assinar a versão atual quando quiser aprovar.'
            : 'Você pode acompanhar o status normalmente. Para aprovar o serviço, clique no botão e assine na próxima página.';

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.edit_note_rounded,
            color: colorScheme.onErrorContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.t(titleKey, fallback: titleFallback),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t(descriptionKey, fallback: descriptionFallback),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: _gerandoLinkAssinatura ? null : _abrirAssinatura,
      icon:
          _gerandoLinkAssinatura
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.draw_rounded, size: 18),
      label: Text(
        _gerandoLinkAssinatura
            ? context.t('common.generating', fallback: 'Gerando...')
            : context.t(
              'atendimentoTecnico.publicStatus.signatureAction',
              fallback: 'Assinar aprovação',
            ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return _card(
      theme,
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[content, const SizedBox(height: 14), button],
              )
              : Row(
                children: <Widget>[
                  Expanded(child: content),
                  const SizedBox(width: 16),
                  button,
                ],
              ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
    bool compact,
  ) {
    final color = _statusColor(theme, status);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'atendimentoTecnico.publicStatus.title',
            fallback: 'Status do serviço',
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          context.t(
            'atendimentoTecnico.publicStatus.subtitle',
            fallback:
                'Acompanhe a etapa atual do atendimento técnico pelo link público.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.flag_outlined, color: color, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _statusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    return _card(
      theme,
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _heroIcon(theme, color),
                      const SizedBox(width: 12),
                      Expanded(child: title),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[statusChip, _refreshButton(theme)],
                  ),
                ],
              )
              : Row(
                children: <Widget>[
                  _heroIcon(theme, color),
                  const SizedBox(width: 14),
                  Expanded(child: title),
                  const SizedBox(width: 14),
                  statusChip,
                  const SizedBox(width: 10),
                  _refreshButton(theme),
                ],
              ),
    );
  }

  Widget _buildProgress(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
  ) {
    final color = _statusColor(theme, status);
    final progress = _progresso(status);
    final etapas = _etapasVisiveis(status);

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t(
                    'atendimentoTecnico.publicStatus.progressTitle',
                    fallback: 'Progresso do atendimento',
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bulletProgress(
            theme: theme,
            progress: progress,
            steps: etapas.length,
            color: color,
            height: 34,
            trackHeight: 8,
            bulletSize: 18,
            duration: const Duration(milliseconds: 1350),
            valueKey: 'status-progress-${status.statusCodigo}',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: etapas.map((etapa) => _stepPill(theme, etapa)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bulletProgress({
    required ThemeData theme,
    required double progress,
    required int steps,
    required Color color,
    required double height,
    required double trackHeight,
    required double bulletSize,
    required Duration duration,
    required String valueKey,
  }) {
    final colorScheme = theme.colorScheme;
    final int safeSteps = steps <= 0 ? 1 : steps;
    final double safeProgress = progress.clamp(0, 1).toDouble();
    final double completedSteps = safeProgress * safeSteps;
    final int currentStep = completedSteps.ceil().clamp(0, safeSteps).toInt();
    final double lineProgress =
        safeSteps <= 1
            ? safeProgress
            : ((completedSteps - 1) / (safeSteps - 1)).clamp(0, 1).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Positioned(
                left: bulletSize / 2,
                right: bulletSize / 2,
                top: (height - trackHeight) / 2,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.82,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: bulletSize / 2,
                top: (height - trackHeight) / 2,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<String>(valueKey),
                  tween: Tween<double>(begin: 0, end: lineProgress),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Container(
                      width: (width - bulletSize) * value,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),
              for (int index = 0; index < safeSteps; index++)
                _progressBullet(
                  width: width,
                  height: height,
                  bulletSize: bulletSize,
                  index: index,
                  steps: safeSteps,
                  currentStep: currentStep,
                  color: color,
                  colorScheme: colorScheme,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _progressBullet({
    required double width,
    required double height,
    required double bulletSize,
    required int index,
    required int steps,
    required int currentStep,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    final double position = steps == 1 ? 0 : index / (steps - 1);
    final bool reached = index < currentStep;
    return Positioned(
      left: (width - bulletSize) * position,
      top: (height - bulletSize) / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: bulletSize,
        height: bulletSize,
        decoration: BoxDecoration(
          color: reached ? color : colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                reached
                    ? color
                    : colorScheme.outlineVariant.withValues(alpha: 0.95),
            width: reached ? 2 : 1.4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (reached ? color : Colors.black).withValues(alpha: 0.12),
              blurRadius: reached ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            reached
                ? Icon(
                  Icons.check_rounded,
                  size: bulletSize * 0.62,
                  color: Colors.white,
                )
                : null,
      ),
    );
  }

  Widget _buildResumo(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
  ) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'atendimentoTecnico.publicStatus.serviceData',
              fallback: 'Dados do serviço',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _infoLine(
            theme,
            context.t('common.number', fallback: 'Número'),
            status.numero.isEmpty ? '-' : status.numero,
          ),
          _infoLine(
            theme,
            context.t('common.customer', fallback: 'Cliente'),
            (status.nomeClienteSnapshot ?? '').trim().isEmpty
                ? context.t(
                  'atendimentoTecnico.customerNotInformed',
                  fallback: 'Cliente não informado',
                )
                : status.nomeClienteSnapshot!.trim(),
          ),
          _infoLine(
            theme,
            context.t('atendimentoTecnico.status', fallback: 'Status'),
            _statusLabel(status),
          ),
          _infoLine(
            theme,
            context.t(
              'atendimentoTecnico.expectedDelivery',
              fallback: 'Entrega prevista',
            ),
            _formatarData(status.dataEntregaPrevista),
          ),
          _infoLine(
            theme,
            context.t('common.updatedAt', fallback: 'Atualizado em'),
            _formatarDataHora(status.dataAtualizacao),
          ),
          if ((status.equipamentoResumo ?? '').trim().isNotEmpty)
            _infoLine(
              theme,
              context.t(
                'atendimentoTecnico.equipment',
                fallback: 'Equipamento',
              ),
              status.equipamentoResumo!.trim(),
            ),
          if ((status.defeitoRelatado ?? '').trim().isNotEmpty)
            _infoLine(
              theme,
              context.t(
                'atendimentoTecnico.reportedIssue',
                fallback: 'Defeito',
              ),
              status.defeitoRelatado!.trim(),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorico(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoModel status,
  ) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'atendimentoTecnico.publicStatus.history',
              fallback: 'Histórico de status',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (status.historicoStatus.isEmpty)
            Text(
              context.t(
                'atendimentoTecnico.publicStatus.noHistory',
                fallback: 'Nenhuma mudança de status registrada.',
              ),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            ...status.historicoStatus.reversed.map(
              (item) => _historyRow(theme, item),
            ),
        ],
      ),
    );
  }

  Widget _heroIcon(ThemeData theme, Color color) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.track_changes_rounded, color: color, size: 28),
    );
  }

  Widget _refreshButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _recarregar,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text(context.t('common.refresh', fallback: 'Atualizar')),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _stepPill(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoEtapaModel etapa,
  ) {
    final color = _colorFromHex(etapa.cor, theme.colorScheme.primary);
    final bool active = etapa.atual;
    final bool done = etapa.concluida;
    final Color foreground = active || done ? color : theme.colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            active
                ? color.withValues(alpha: 0.13)
                : done
                ? color.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.48,
                ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              active
                  ? color.withValues(alpha: 0.42)
                  : theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            done ? Icons.check_circle_rounded : _statusIcon(etapa.icone),
            color: foreground,
            size: 17,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _etapaLabel(etapa),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    active || done
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(
    ThemeData theme,
    AtendimentoTecnicoStatusPublicoHistoricoModel item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flag_outlined,
              color: theme.colorScheme.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _historicoLabel(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarDataHora(item.dataHora),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPublicoLinkInvalidoException implements Exception {
  const _StatusPublicoLinkInvalidoException();
}

class _LoadingStatusPublico extends StatelessWidget {
  const _LoadingStatusPublico({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErroStatusPublico extends StatelessWidget {
  const _ErroStatusPublico({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.link_off_rounded,
                color: theme.colorScheme.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                context.t(
                  'atendimentoTecnico.publicStatus.errorTitle',
                  fallback: 'Não foi possível carregar o status',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.t('common.tryAgain', fallback: 'Tentar novamente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
