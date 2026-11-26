import 'package:flutter/material.dart';
import '../../../l10n/six_i18n.dart';
import '../unidade_selecao_state.dart';
import '../unidades_status.dart';

class CatalogoUnidadesWeb extends StatefulWidget {
  const CatalogoUnidadesWeb({super.key});
  @override
  State<CatalogoUnidadesWeb> createState() => _CatalogoWebState();
}

class _CatalogoWebState extends State<CatalogoUnidadesWeb>
    with UnidadeSelecaoState<CatalogoUnidadesWeb> {
  @override
  void initState() {
    super.initState();
    carregarUnidades();
  }

  @override
  Widget build(BuildContext context) {
    final c = catalogo;
    if (c == null || erroUnidades)
      return UnidadesStatus(erro: erroUnidades, recarregar: carregarUnidades);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final u in c.unidades)
              FilterChip(
                selected: u.ativa,
                label: Text(u.label(lang)),
                avatar:
                    u.codigo == c.padrao
                        ? const Icon(Icons.star_outline, size: 16)
                        : null,
                onSelected:
                    c.podeEditar
                        ? (_) => editarOpcao(unidade: u, mobile: false)
                        : null,
              ),
          ],
        ),
        if (c.podeEditar)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.t('units.add')),
            onPressed: () => editarOpcao(mobile: false),
          ),
      ],
    );
  }
}
