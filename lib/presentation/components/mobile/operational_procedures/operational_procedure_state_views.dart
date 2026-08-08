import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_demo_badge.dart';

class OperationalProcedureIntro extends StatelessWidget {
  const OperationalProcedureIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final String title = context.t(
      'procedimentos.introTitle',
      fallback: 'Configure orientações para vendas, atendimentos e entregas.',
    );
    final String demoLabel = context.t(
      'procedimentos.demoData',
      fallback: 'Dados demonstrativos',
    );

    return Semantics(
      container: true,
      label: '$title $demoLabel.',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                color: SixMobilePalette.accent,
                size: 21,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OperationalProcedureDemoBadge(label: demoLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OperationalProcedureNewAction extends StatelessWidget {
  const OperationalProcedureNewAction({
    super.key,
    required this.onTap,
    this.label,
    this.icon = Icons.add_rounded,
  });

  final VoidCallback onTap;
  final String? label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final String resolvedLabel =
        label ??
        context.t('procedimentos.newProcedure', fallback: 'Novo procedimento');

    return Semantics(
      button: true,
      label: resolvedLabel,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(
            resolvedLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: SixMobilePalette.accent,
            foregroundColor: SixMobilePalette.onPrimary,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class OperationalProcedureLoadingState extends StatelessWidget {
  const OperationalProcedureLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t(
        'procedimentos.loading',
        fallback: 'Carregando procedimentos',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OperationalProcedureIntro(),
          SizedBox(height: 14),
          _FilterSkeletonRow(),
          SizedBox(height: 16),
          _ProcedureCardSkeleton(),
          SizedBox(height: 12),
          _ProcedureCardSkeleton(),
          SizedBox(height: 12),
          _ProcedureCardSkeleton(),
        ],
      ),
    );
  }
}

class OperationalProcedureEmptyState extends StatelessWidget {
  const OperationalProcedureEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OperationalProcedureIntro(),
        SizedBox(height: 14),
        OperationalProcedureStateMessage(
          icon: Icons.fact_check_outlined,
          title: context.t(
            'procedimentos.emptyTitle',
            fallback: 'Nenhum procedimento configurado',
          ),
          description: context.t(
            'procedimentos.emptyDescription',
            fallback:
                'Crie orientações para apoiar a equipe nos momentos importantes da operação.',
          ),
          actionLabel: context.t(
            'procedimentos.createProcedure',
            fallback: 'Criar procedimento',
          ),
          actionIcon: Icons.add_rounded,
          onAction: onCreate,
        ),
      ],
    );
  }
}

class OperationalProcedureFilteredEmptyNotice extends StatelessWidget {
  const OperationalProcedureFilteredEmptyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return OperationalProcedureStateMessage(
      icon: Icons.filter_alt_off_outlined,
      title: context.t(
        'procedimentos.filteredEmptyTitle',
        fallback: 'Nenhum procedimento neste filtro',
      ),
      description: context.t(
        'procedimentos.filteredEmptyDescription',
        fallback:
            'Altere o filtro para ver outros procedimentos demonstrativos.',
      ),
    );
  }
}

class OperationalProcedureErrorState extends StatelessWidget {
  const OperationalProcedureErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OperationalProcedureStateMessage(
      icon: Icons.error_outline_rounded,
      title: context.t(
        'procedimentos.errorTitle',
        fallback: 'Não foi possível carregar os procedimentos',
      ),
      description: context.t(
        'procedimentos.errorDescription',
        fallback: 'Tente novamente em instantes.',
      ),
      actionLabel: context.t('common.tryAgain', fallback: 'Tentar novamente'),
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}

class OperationalProcedureStateMessage extends StatelessWidget {
  const OperationalProcedureStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $description',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: SixMobilePalette.accent, size: 28),
            SizedBox(height: 12),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.chevron_right_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: SixMobilePalette.accent,
                  foregroundColor: SixMobilePalette.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterSkeletonRow extends StatelessWidget {
  const _FilterSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _SkeletonBlock(width: 74, height: 40, radius: 999),
        _SkeletonBlock(width: 82, height: 40, radius: 999),
        _SkeletonBlock(width: 90, height: 40, radius: 999),
      ],
    );
  }
}

class _ProcedureCardSkeleton extends StatelessWidget {
  const _ProcedureCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _SkeletonBlock(height: 18, radius: 8)),
              SizedBox(width: 12),
              _SkeletonBlock(width: 86, height: 30, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          const _SkeletonBlock(height: 12, radius: 7),
          SizedBox(height: 6),
          FractionallySizedBox(
            widthFactor: 0.68,
            child: _SkeletonBlock(height: 12, radius: 7),
          ),
          SizedBox(height: 13),
          FractionallySizedBox(
            widthFactor: 0.82,
            child: _SkeletonBlock(height: 16, radius: 8),
          ),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              _SkeletonBlock(width: 92, height: 15, radius: 8),
              SizedBox(width: 12),
              _SkeletonBlock(width: 78, height: 15, radius: 8),
              Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: SixMobilePalette.mutedText,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height, this.radius = 18});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: SixMobilePalette.border),
        ),
      ),
    );
  }
}
