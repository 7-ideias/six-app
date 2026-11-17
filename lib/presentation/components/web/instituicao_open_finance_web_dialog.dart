import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/instituicao_open_finance_logo.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

import 'six_web_animated_dialog.dart';

/// Seletor próprio para Web. A versão Mobile mantém sua navegação de busca.
/// Preserva a instância escolhida, incluindo marcaOpenFinanceId e logo.
Future<InstituicaoOpenFinance?> selecionarInstituicaoOpenFinanceWeb(
  BuildContext context,
  List<InstituicaoOpenFinance> instituicoes,
) {
  return showSixWebAnimatedDialog<InstituicaoOpenFinance>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    padding: const EdgeInsets.all(16),
    builder: (_) => _InstituicaoOpenFinanceWebDialog(
      instituicoes: instituicoes,
    ),
  );
}

class _InstituicaoOpenFinanceWebDialog extends StatefulWidget {
  const _InstituicaoOpenFinanceWebDialog({required this.instituicoes});

  final List<InstituicaoOpenFinance> instituicoes;

  @override
  State<_InstituicaoOpenFinanceWebDialog> createState() =>
      _InstituicaoOpenFinanceWebDialogState();
}

class _InstituicaoOpenFinanceWebDialogState
    extends State<_InstituicaoOpenFinanceWebDialog> {
  final TextEditingController _busca = TextEditingController();
  final ScrollController _rolagem = ScrollController();
  String _filtro = '';

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  List<InstituicaoOpenFinance> get _resultados {
    final pesquisa = InstituicaoOpenFinance.normalizarNome(_filtro);
    return widget.instituicoes
        .where(
          (instituicao) =>
              pesquisa.isEmpty ||
              InstituicaoOpenFinance.normalizarNome(
                instituicao.nome,
              ).contains(pesquisa),
        )
        .take(100)
        .toList(growable: false);
  }

  void _pesquisar(String texto) {
    setState(() => _filtro = texto);
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
  }

  void _selecionar(InstituicaoOpenFinance instituicao) {
    Navigator.of(context).pop(instituicao);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final tamanho = MediaQuery.sizeOf(context);
    final largura = math.min(620.0, tamanho.width - 48);
    final altura = math.min(620.0, tamanho.height - 64);
    final titulo = context.t('cards.catalogSearch');
    final resultados = _resultados;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            namesRoute: true,
            label: titulo,
            child: Dialog(
              key: const ValueKey('openfinance-web-dialog'),
              insetPadding: EdgeInsets.zero,
              elevation: 20,
              shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.40),
              backgroundColor: tokens.surfaceElevated,
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: tokens.cardBorder),
              ),
              child: SizedBox(
                width: largura,
                height: altura,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.info.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.account_balance_outlined,
                                color: tokens.info,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('openfinance-web-close'),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: TextField(
                        key: const ValueKey('openfinance-web-search'),
                        controller: _busca,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: _pesquisar,
                        onSubmitted: (_) {
                          if (resultados.length == 1) {
                            _selecionar(resultados.single);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: titulo,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _filtro.isEmpty
                              ? null
                              : IconButton(
                                  key: const ValueKey('openfinance-web-clear'),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).deleteButtonTooltip,
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _busca.clear();
                                    _pesquisar('');
                                  },
                                ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: tokens.divider),
                    Expanded(
                      child: resultados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  context.t('cards.catalogEmpty'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: tokens.secondaryText),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Scrollbar(
                              controller: _rolagem,
                              child: ListView.builder(
                                key: const ValueKey('openfinance-web-results'),
                                controller: _rolagem,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                itemCount: resultados.length,
                                itemBuilder: (context, index) {
                                  final instituicao = resultados[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        key: ValueKey(
                                          'openfinance-web-item-$index',
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        hoverColor: tokens.hoverBackground,
                                        focusColor: tokens.selectedBackground,
                                        onTap: () => _selecionar(instituicao),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              InstituicaoOpenFinanceLogo(
                                                url: instituicao.logotipoExibicao,
                                                nome: instituicao.nome,
                                                size: 36,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(
                                                  instituicao.nome,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme.bodyMedium,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 18,
                                                color: tokens.mutedText,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    Divider(height: 1, color: tokens.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.t('space.cancel')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
