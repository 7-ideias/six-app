import 'package:flutter/material.dart';

import '../../../l10n/perfil_negocio_texts.dart';
import '../../../providers/perfil_negocio_editor_controller.dart';
import '../../theme/web_theme_tokens.dart';
import '../perfil_negocio_icons.dart';
import '../six_backend_loading.dart';

class PerfilNegocioWebForm extends StatelessWidget {
  const PerfilNegocioWebForm({
    super.key,
    required this.controller,
    required this.etapa,
  });

  final PerfilNegocioEditorController controller;
  final int etapa;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    if (controller.carregando || controller.catalogo == null) {
      return SixBackendLoading(
        title: perfilNegocioText(context, 'loading'),
        subtitle: perfilNegocioText(context, 'description'),
        backgroundColor: tokens.surfaceElevated,
        borderColor: tokens.cardBorder,
      );
    }

    if (controller.erro == 'forbidden') {
      return _Message(
        text: perfilNegocioText(context, 'forbidden'),
        error: true,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final String title = perfilNegocioText(
          context,
          etapa == 0
              ? 'segmentTitle'
              : etapa == 1
              ? 'activityTitle'
              : 'goalTitle',
        );
        final String subtitle = perfilNegocioText(
          context,
          etapa == 0
              ? 'segmentSubtitle'
              : etapa == 1
              ? 'activitySubtitle'
              : 'goalSubtitle',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: tokens.primaryText,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: TextStyle(
                color: tokens.secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (etapa == 0) _segmentos(context, tokens),
            if (etapa == 1) _atividades(context, tokens),
            if (etapa == 2) _objetivos(context, tokens),
            if (controller.erro != null &&
                controller.erro != 'forbidden') ...<Widget>[
              const SizedBox(height: 14),
              _Message(
                text: perfilNegocioText(context, controller.erro!),
                error: true,
              ),
            ],
            if (etapa == 2) ...<Widget>[
              const SizedBox(height: 16),
              _Message(text: perfilNegocioText(context, 'notice')),
            ],
          ],
        );
      },
    );
  }

  Widget _segmentos(BuildContext context, WebThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth >= 500
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: controller.catalogo!.segmentos.map((item) {
                final bool selected = controller.segmento == item.codigo;
                return SizedBox(
                  width: width,
                  child: _Tile(
                    title: perfilNegocioText(
                      context,
                      'segment.${item.codigo}',
                    ),
                    icon: perfilNegocioIcon(item.codigo),
                    selected: selected,
                    tokens: tokens,
                    onTap: () => controller.selecionarSegmento(item.codigo),
                  ),
                );
              }).toList(growable: false),
            );
          },
        ),
        if (controller.segmento != null &&
            controller.subsegmentos.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Text(
            perfilNegocioText(context, 'subsegment'),
            style: TextStyle(
              color: tokens.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Chip(
                text: perfilNegocioText(context, 'noSpecialty'),
                selected: controller.subsegmento == null,
                tokens: tokens,
                onTap: () => controller.selecionarSubsegmento(null),
              ),
              ...controller.subsegmentos.map(
                (String value) => _Chip(
                  text: perfilNegocioText(context, 'sub.$value'),
                  selected: controller.subsegmento == value,
                  tokens: tokens,
                  onTap: () => controller.selecionarSubsegmento(value),
                ),
              ),
            ],
          ),
        ],
        if (controller.segmento == 'OUTRO') ...<Widget>[
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey<String>('perfil-negocio-outro-web'),
            initialValue: controller.descricaoOutro,
            maxLength: 120,
            onChanged: controller.atualizarDescricaoOutro,
            style: TextStyle(color: tokens.primaryText),
            decoration: InputDecoration(
              labelText: perfilNegocioText(context, 'otherDescription'),
              filled: true,
              fillColor: tokens.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _atividades(BuildContext context, WebThemeTokens tokens) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.catalogo!.atividades.map((String codigo) {
            final bool selected = controller.atividades.contains(codigo);
            return SizedBox(
              width: width,
              child: _Tile(
                title: perfilNegocioText(context, 'activity.$codigo'),
                icon: perfilNegocioIcon(codigo),
                selected: selected,
                tokens: tokens,
                onTap: () => controller.alternarAtividade(codigo),
                trailing: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? const Color(0xFF2563EB) : tokens.mutedText,
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _objetivos(BuildContext context, WebThemeTokens tokens) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.catalogo!.objetivos.map((String codigo) {
            final bool selected = controller.objetivo == codigo;
            return SizedBox(
              width: width,
              child: _Tile(
                title: perfilNegocioText(context, 'goal.$codigo'),
                icon: perfilNegocioIcon(codigo),
                selected: selected,
                tokens: tokens,
                onTap: () => controller.selecionarObjetivo(codigo),
                trailing: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? const Color(0xFF2563EB) : tokens.mutedText,
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.tokens,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final WebThemeTokens tokens;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF2563EB);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : tokens.inputBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : tokens.cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? accent : tokens.secondaryText,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: tokens.mutedText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final WebThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF2563EB);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : tokens.inputBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent : tokens.cardBorder,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? accent : tokens.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = error ? tokens.danger : tokens.secondaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error
            ? tokens.danger.withValues(alpha: 0.08)
            : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: error
              ? tokens.danger.withValues(alpha: 0.28)
              : tokens.cardBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
