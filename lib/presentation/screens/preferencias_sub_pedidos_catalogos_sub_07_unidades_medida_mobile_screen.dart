import 'package:flutter/material.dart';
import '../../l10n/six_i18n.dart';
import '../components/unidade_selecao_state.dart';
import '../components/unidades_status.dart';
import '../components/mobile/six_mobile_page_shell.dart';

class UnidadesMedidaMobileScreen extends StatefulWidget {
  const UnidadesMedidaMobileScreen({super.key});
  @override
  State<UnidadesMedidaMobileScreen> createState() => _UnidadesState();
}

class _UnidadesState extends State<UnidadesMedidaMobileScreen>
    with UnidadeSelecaoState<UnidadesMedidaMobileScreen> {
  @override
  void initState() {
    super.initState();
    carregarUnidades();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final c = catalogo;
    final lang = Localizations.localeOf(context).languageCode;
    return SixMobilePageShell(
      title: context.t('units.title'),
      backgroundColor: cores.surface,
      primaryColor: cores.surface,
      secondaryColor: cores.surfaceContainer,
      accentColor: cores.primary,
      actions: [
        if (c?.podeEditar == true)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.t('units.add'),
            onPressed: () => editarOpcao(mobile: true),
          ),
      ],
      bodyBuilder:
          (context, scroll, top) => ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(16, top, 16, 24),
            children: [
              if (c == null || erroUnidades)
                UnidadesStatus(erro: erroUnidades, recarregar: carregarUnidades)
              else
                for (final u in c.unidades)
                  ListTile(
                    title: Text(u.label(lang)),
                    leading: Icon(
                      u.ativa
                          ? Icons.check_circle_outline
                          : Icons.circle_outlined,
                    ),
                    subtitle:
                        u.codigo == c.padrao
                            ? Text(context.t('units.default'))
                            : null,
                    trailing:
                        c.podeEditar ? const Icon(Icons.edit_outlined) : null,
                    onTap:
                        c.podeEditar
                            ? () => editarOpcao(unidade: u, mobile: true)
                            : null,
                  ),
            ],
          ),
    );
  }
}
