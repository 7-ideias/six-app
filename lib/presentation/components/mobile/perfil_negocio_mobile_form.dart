import 'package:flutter/material.dart';

import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/perfil_negocio_texts.dart';
import '../../../providers/perfil_negocio_editor_controller.dart';
import '../perfil_negocio_icons.dart';
import '../six_backend_loading.dart';

class PerfilNegocioMobileForm extends StatelessWidget {
  const PerfilNegocioMobileForm({
    super.key,
    required this.controller,
    required this.etapa,
  });

  final PerfilNegocioEditorController controller;
  final int etapa;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    if (controller.carregando || controller.catalogo == null) {
      return SixBackendLoading(
        title: perfilNegocioText(context, 'loading'),
        subtitle: perfilNegocioText(context, 'description'),
        compact: true,
        backgroundColor: colors.surfaceElevated,
        borderColor: colors.border,
      );
    }

    if (controller.erro == 'forbidden') {
      return _MessageCard(
        icon: Icons.lock_outline_rounded,
        text: perfilNegocioText(context, 'forbidden'),
        colors: colors,
        error: true,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StepHeading(
              title: perfilNegocioText(
                context,
                etapa == 0
                    ? 'segmentTitle'
                    : etapa == 1
                    ? 'activityTitle'
                    : 'goalTitle',
              ),
              subtitle: perfilNegocioText(
                context,
                etapa == 0
                    ? 'segmentSubtitle'
                    : etapa == 1
                    ? 'activitySubtitle'
                    : 'goalSubtitle',
              ),
              colors: colors,
            ),
            const SizedBox(height: 18),
            if (etapa == 0) _segmentos(context, colors),
            if (etapa == 1) _atividades(context, colors),
            if (etapa == 2) _objetivos(context, colors),
            if (controller.erro != null &&
                controller.erro != 'forbidden') ...<Widget>[
              const SizedBox(height: 14),
              _MessageCard(
                icon: Icons.info_outline_rounded,
                text: perfilNegocioText(context, controller.erro!),
                colors: colors,
                error: controller.erro != null,
              ),
            ],
            if (etapa == 2) ...<Widget>[
              const SizedBox(height: 16),
              _MessageCard(
                icon: Icons.shield_outlined,
                text: perfilNegocioText(context, 'notice'),
                colors: colors,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _segmentos(BuildContext context, SixMobileColorScheme colors) {
    final segmentos = controller.catalogo!.segmentos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...segmentos.map((item) {
          final bool selected = controller.segmento == item.codigo;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableCard(
              selected: selected,
              colors: colors,
              icon: perfilNegocioIcon(item.codigo),
              title: perfilNegocioText(context, 'segment.${item.codigo}'),
              onTap: () => controller.selecionarSegmento(item.codigo),
            ),
          );
        }),
        if (controller.segmento != null &&
            controller.subsegmentos.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            perfilNegocioText(context, 'subsegment'),
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ChoiceChip(
                label: perfilNegocioText(context, 'noSpecialty'),
                selected: controller.subsegmento == null,
                colors: colors,
                onTap: () => controller.selecionarSubsegmento(null),
              ),
              ...controller.subsegmentos.map(
                (String value) => _ChoiceChip(
                  label: perfilNegocioText(context, 'sub.$value'),
                  selected: controller.subsegmento == value,
                  colors: colors,
                  onTap: () => controller.selecionarSubsegmento(value),
                ),
              ),
            ],
          ),
        ],
        if (controller.segmento == 'OUTRO') ...<Widget>[
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey<String>('perfil-negocio-outro-mobile'),
            initialValue: controller.descricaoOutro,
            maxLength: 120,
            onChanged: controller.atualizarDescricaoOutro,
            style: TextStyle(color: colors.titleText),
            decoration: InputDecoration(
              labelText: perfilNegocioText(context, 'otherDescription'),
              filled: true,
              fillColor: colors.softSurface,
              labelStyle: TextStyle(color: colors.mutedText),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _atividades(BuildContext context, SixMobileColorScheme colors) {
    return Column(
      children: controller.catalogo!.atividades.map((String codigo) {
        final bool selected = controller.atividades.contains(codigo);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SelectableCard(
            selected: selected,
            colors: colors,
            icon: perfilNegocioIcon(codigo),
            title: perfilNegocioText(context, 'activity.$codigo'),
            trailing: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: selected ? colors.accent : colors.mutedText,
            ),
            onTap: () => controller.alternarAtividade(codigo),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _objetivos(BuildContext context, SixMobileColorScheme colors) {
    return Column(
      children: controller.catalogo!.objetivos.map((String codigo) {
        final bool selected = controller.objetivo == codigo;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SelectableCard(
            selected: selected,
            colors: colors,
            icon: perfilNegocioIcon(codigo),
            title: perfilNegocioText(context, 'goal.$codigo'),
            trailing: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? colors.accent : colors.mutedText,
            ),
            onTap: () => controller.selecionarObjetivo(codigo),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: colors.titleText,
            fontSize: 24,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.mutedText,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.colors,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final SixMobileColorScheme colors;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.softAccentSurface : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? colors.softAccentSurface : colors.iconSurface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.accent : colors.mutedText,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.mutedText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final SixMobileColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.softAccentSurface : colors.softSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.accent : colors.titleText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.text,
    required this.colors,
    this.error = false,
  });

  final IconData icon;
  final String text;
  final SixMobileColorScheme colors;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Color foreground = error ? colors.error : colors.mutedText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: error
            ? colors.error.withValues(alpha: 0.08)
            : colors.softSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: error ? colors.errorBorder : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                height: 1.4,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
