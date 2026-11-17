import 'package:flutter/material.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'instituicao_open_finance_logo.dart';

Future<InstituicaoOpenFinance?> selecionarInstituicaoOpenFinance(
  BuildContext context,
  List<InstituicaoOpenFinance> instituicoes,
) {
  return showSearch<InstituicaoOpenFinance?>(
    context: context,
    delegate: _InstituicaoSearchDelegate(
      instituicoes: instituicoes,
      placeholder: context.t('cards.catalogSearch'),
      vazio: context.t('cards.catalogEmpty'),
    ),
  );
}

class _InstituicaoSearchDelegate extends SearchDelegate<InstituicaoOpenFinance?> {
  _InstituicaoSearchDelegate({
    required this.instituicoes,
    required this.placeholder,
    required this.vazio,
  }) : super(searchFieldLabel: placeholder);

  final List<InstituicaoOpenFinance> instituicoes;
  final String placeholder;
  final String vazio;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _lista(context);

  @override
  Widget buildSuggestions(BuildContext context) => _lista(context);

  Widget _lista(BuildContext context) {
    final texto = query.trim().toLowerCase();
    final encontrados = instituicoes
        .where((instituicao) =>
            texto.isEmpty || instituicao.nome.toLowerCase().contains(texto))
        .take(100)
        .toList(growable: false);
    if (encontrados.isEmpty) return Center(child: Text(vazio));

    return ListView.builder(
      itemCount: encontrados.length,
      itemBuilder: (context, index) {
        final instituicao = encontrados[index];
        return ListTile(
          leading: InstituicaoOpenFinanceLogo(
            url: instituicao.logotipoUrl,
            nome: instituicao.nome,
            size: 48,
          ),
          title: Text(instituicao.nome),
          onTap: () => close(context, instituicao),
        );
      },
    );
  }
}
