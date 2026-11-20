import 'package:flutter/material.dart';
import 'package:sixpos/data/models/permissao_colaborador.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';

class PermissoesColaboradorMobile extends StatelessWidget {
  const PermissoesColaboradorMobile({
    super.key,
    required this.marcadas,
    required this.onChanged,
  });
  final Set<PermissaoColaborador> marcadas;
  final void Function(PermissaoColaborador, bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final cores = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final grupo in GrupoPermissao.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              context.t(grupo.chave),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final p in PermissaoColaborador.values.where(
            (p) => p.grupo == grupo,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: tile(context, p, cores),
            ),
        ],
      ],
    );
  }

  Widget tile(
    BuildContext context,
    PermissaoColaborador p,
    SixMobileColorScheme cores,
  ) {
    final marcado = marcadas.contains(p);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: marcado ? cores.softAccentSurface : cores.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.border),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        secondary: Icon(p.icone, size: 20, color: cores.accent),
        title: Text(
          context.t(p.titulo),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(context.t(p.descricao)),
        value: marcado,
        onChanged: onChanged == null ? null : (v) => onChanged!(p, v),
      ),
    );
  }
}
