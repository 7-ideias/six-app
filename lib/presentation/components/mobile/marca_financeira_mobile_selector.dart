import 'package:flutter/material.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/marca_financeira_avatar.dart';

/// Seletor mobile próprio; não reutiliza Dialog, rota ou view principal Web.
Future<InstituicaoOpenFinance?> selecionarMarcaFinanceiraMobile(
  BuildContext context, {
  required String titulo,
  required List<InstituicaoOpenFinance> instituicoes,
  required String tipo,
}) {
  return showModalBottomSheet<InstituicaoOpenFinance>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.sixMobileColors.surface,
    builder: (sheetContext) => _MarcaFinanceiraMobileSelector(
      titulo: titulo, instituicoes: instituicoes, tipo: tipo,
    ),
  );
}

class _MarcaFinanceiraMobileSelector extends StatefulWidget {
  const _MarcaFinanceiraMobileSelector({
    required this.titulo, required this.instituicoes, required this.tipo,
  });
  final String titulo;
  final String tipo;
  final List<InstituicaoOpenFinance> instituicoes;
  @override
  State<_MarcaFinanceiraMobileSelector> createState() =>
      _MarcaFinanceiraMobileSelectorState();
}

class _MarcaFinanceiraMobileSelectorState
    extends State<_MarcaFinanceiraMobileSelector> {
  final _busca = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    final filtro = InstituicaoOpenFinance.normalizarNome(_filtro);
    final resultados = widget.instituicoes.where((instituicao) =>
      filtro.isEmpty || InstituicaoOpenFinance.normalizarNome(
        instituicao.nome,
      ).contains(filtro),
    ).take(100).toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(children: [
              Expanded(child: Text(
                widget.titulo,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: colors.titleText),
              )),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              key: const ValueKey('financial-brand-mobile-search'),
              controller: _busca,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (text) => setState(() => _filtro = text),
              decoration: InputDecoration(
                hintText: widget.titulo,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colors.softSurface,
              ),
            ),
          ),
          Expanded(
            child: resultados.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.t('cards.catalogEmpty'),
                      textAlign: TextAlign.center),
                  ))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: resultados.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: colors.border, height: 1),
                    itemBuilder: (context, index) {
                      final item = resultados[index];
                      return ListTile(
                        key: ValueKey('financial-brand-mobile-$index'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                        leading: MarcaFinanceiraAvatar(
                          nome: item.nome,
                          tipo: widget.tipo,
                          logotipoUrl: item.logotipoExibicao,
                          size: 44,
                        ),
                        title: Text(item.nome, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.titleText)),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
