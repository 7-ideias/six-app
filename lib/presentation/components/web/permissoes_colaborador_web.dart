import 'package:flutter/material.dart';
import 'package:sixpos/data/models/permissao_colaborador.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

class PermissoesColaboradorWeb extends StatelessWidget {
  const PermissoesColaboradorWeb({
    super.key,
    required this.marcadas,
    required this.onChanged,
  });
  final Set<PermissaoColaborador> marcadas;
  final void Function(PermissaoColaborador, bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final cores = WebThemeTokens.of(context);
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
          LayoutBuilder(
            builder: (context, constraints) {
              final colunas = (constraints.maxWidth / 300).floor().clamp(1, 4);
              final largura =
                  (constraints.maxWidth - (colunas - 1) * 10) / colunas;
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final p in PermissaoColaborador.values.where(
                    (p) => p.grupo == grupo,
                  ))
                    SizedBox(width: largura, child: tile(context, p, cores)),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget tile(
    BuildContext context,
    PermissaoColaborador p,
    WebThemeTokens cores,
  ) {
    final marcado = marcadas.contains(p);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: marcado ? cores.selectedBackground : cores.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.cardBorder),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        secondary: Icon(p.icone, size: 20, color: cores.info),
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
