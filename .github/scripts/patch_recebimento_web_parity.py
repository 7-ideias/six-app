from pathlib import Path

p = Path('lib/presentation/screens/recebimento_pagamento_web.dart')
s = p.read_text()

def rep(old: str, new: str):
    global s
    if old not in s:
        raise SystemExit('snippet missing: ' + old[:140].replace('\n', ' '))
    s = s.replace(old, new, 1)

rep(
    "  late bool _recebimentoParcial;\n  late final AnimationController _iconController;",
    "  late bool _recebimentoParcial;\n  late bool _tipoRecebimentoEscolhido;\n  late final AnimationController _iconController;\n\n  static const Color _totalReceiptColor = Color(0xFF16A34A);\n  static const Color _partialReceiptColor = Color(0xFFF59E0B);",
)
rep(
    "    _recebimentoParcial = widget.recebimentoParcialInicial;\n    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;",
    "    _recebimentoParcial = widget.recebimentoParcialInicial;\n    _tipoRecebimentoEscolhido =\n        widget.formasPagamentoIniciais.isNotEmpty ||\n        widget.descricoesFormasIniciais.isNotEmpty;\n    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;",
)
rep(
    "    _formasPagamento = _formasPagamentoFallback\n        .map((forma) => forma.copyWith())\n        .toList(growable: false);",
    "    _formasPagamento = _formasPagamentoFallback\n        .where((forma) => _codigoTipoValido(forma.codigo))\n        .map((forma) => forma.copyWith())\n        .toList(growable: false);",
)
rep(
    "    final List<TiposRecebimento> ativos =\n        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(\n          (TiposRecebimento a, TiposRecebimento b) =>\n              a.ordemExibicao.compareTo(b.ordemExibicao),\n        );",
    "    final List<TiposRecebimento> ativos = tipos\n        .where((TiposRecebimento tipo) => tipo.ativo)\n        .where(\n          (TiposRecebimento tipo) =>\n              tipo.naturezaRecebimento.trim().toUpperCase() != 'FUTURO',\n        )\n        .toList()\n      ..sort(\n        (TiposRecebimento a, TiposRecebimento b) =>\n            a.ordemExibicao.compareTo(b.ordemExibicao),\n      );",
)
rep(
    "    if (widget.formasPagamentoIniciais.isEmpty &&\n        widget.descricoesFormasIniciais.isEmpty) {\n      if (_formasPagamento.isEmpty) return;\n      final String codigoInicial = _formasPagamento.first.codigo;\n      setState(() {\n        _formasPagamento = _formasPagamento\n            .map(\n              (_FormaPagamentoWeb forma) => forma.copyWith(\n                selecionado: forma.codigo == codigoInicial,\n                valor:\n                    forma.codigo == codigoInicial ? widget.valorTotalVenda : 0,\n              ),\n            )\n            .toList(growable: false);\n      });\n      _controllerFor(_formasPagamento.first).text = widget.valorTotalVenda\n          .toStringAsFixed(2);\n      return;\n    }",
    "    if (widget.formasPagamentoIniciais.isEmpty &&\n        widget.descricoesFormasIniciais.isEmpty) {\n      setState(() {\n        _tipoRecebimentoEscolhido = false;\n        _formasPagamento = _formasPagamento\n            .map((forma) => forma.copyWith(selecionado: false, valor: 0))\n            .toList(growable: false);\n      });\n      return;\n    }",
)
rep(
    "  bool _codigoTipoValido(String codigo) {\n    return RegExp(r'^TIPO(10|[1-9])$').hasMatch(codigo);\n  }",
    "  bool _codigoTipoValido(String codigo) {\n    return const <String>{\n      'TIPO1',\n      'TIPO2',\n      'TIPO3',\n      'TIPO4',\n      'TIPO5',\n      'TIPO7',\n    }.contains(codigo.trim().toUpperCase());\n  }",
)
rep("      case 'TIPO7':\n        return 'Crediário';", "      case 'TIPO7':\n        return 'Débito automático';")
rep("      case 'TIPO7':\n        return Icons.event_note_outlined;", "      case 'TIPO7':\n        return Icons.event_repeat_outlined;")
rep(
    "  bool _distribuicaoValida() {\n    if (_montarFormasSelecionadas().isEmpty) return false;",
    "  bool _distribuicaoValida() {\n    if (!_tipoRecebimentoEscolhido || _montarFormasSelecionadas().isEmpty) {\n      return false;\n    }",
)
rep(
    "  void _alterarTipoRecebimento(bool parcial) {\n    if (_recebimentoParcial == parcial || _salvandoOperacao) return;\n\n    setState(() => _recebimentoParcial = parcial);\n    if (!parcial) {\n      final List<_FormaPagamentoWeb> formas = _formasPagamentoVisiveis();\n      if (formas.isNotEmpty) {\n        _preencherValorRestante(formas.first);\n      }\n    }\n  }",
    "  void _alterarTipoRecebimento(bool parcial) {\n    if (_salvandoOperacao) return;\n\n    final bool primeiraEscolha = !_tipoRecebimentoEscolhido;\n    setState(() {\n      _tipoRecebimentoEscolhido = true;\n      _recebimentoParcial = parcial;\n\n      if (primeiraEscolha && _formasPagamento.isNotEmpty) {\n        final String codigoInicial = _formasPagamento.first.codigo;\n        _formasPagamento = _formasPagamento\n            .map(\n              (forma) => forma.copyWith(\n                selecionado: forma.codigo == codigoInicial,\n                valor: !parcial && forma.codigo == codigoInicial\n                    ? widget.valorTotalVenda\n                    : 0,\n              ),\n            )\n            .toList(growable: false);\n      }\n    });\n\n    if (_formasPagamento.isEmpty) return;\n    final _FormaPagamentoWeb primeiraForma = _formasPagamento.first;\n    final TextEditingController controller = _controllerFor(primeiraForma);\n    if (parcial) {\n      if (primeiraEscolha ||\n          _parseValor(controller.text) >= widget.valorTotalVenda) {\n        controller.clear();\n        _alterarValorForma(primeiraForma, '');\n      }\n    } else {\n      controller.text = _formatarValorDigitavel(widget.valorTotalVenda);\n      _alterarValorForma(primeiraForma, controller.text);\n    }\n  }",
)

old_selector = '''  Widget _buildTipoRecebimentoSelector() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Semantics(
      label: _txt('pdv.receipt.type', 'Tipo de recebimento'),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(_txt('recebimento.total', 'Total')),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.call_split_rounded, size: 18),
              label: Text(_txt('recebimento.parcial', 'Parcial')),
            ),
          ],
          selected: <bool>{_recebimentoParcial},
          showSelectedIcon: false,
          onSelectionChanged:
              _salvandoOperacao
                  ? null
                  : (Set<bool> selecao) =>
                      _alterarTipoRecebimento(selecao.first),
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size.fromHeight(46),
            ),
            textStyle: WidgetStatePropertyAll<TextStyle?>(
              theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: tokens.cardBorder),
            ),
          ),
        ),
      ),
    );
  }'''
new_selector = '''  Widget _buildTipoRecebimentoSelector() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    Widget opcao({
      required bool parcial,
      required String label,
      required IconData icon,
      required Color color,
    }) {
      final bool selected =
          _tipoRecebimentoEscolhido && _recebimentoParcial == parcial;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    color.withValues(alpha: 0.12),
                    tokens.surfaceElevated,
                  )
                : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : tokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.10),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _salvandoOperacao
                ? null
                : () => _alterarTipoRecebimento(parcial),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? color : tokens.primaryText,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? color : tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: _txt('pdv.receipt.type', 'Tipo de recebimento'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _txt(
              'recebimento.escolhaTipo',
              'Como deseja receber esta venda?',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              opcao(
                parcial: false,
                label: _txt('recebimento.total', 'Total'),
                icon: Icons.done_all_rounded,
                color: _totalReceiptColor,
              ),
              const SizedBox(width: 10),
              opcao(
                parcial: true,
                label: _txt('recebimento.parcial', 'Parcial'),
                icon: Icons.call_split_rounded,
                color: _partialReceiptColor,
              ),
            ],
          ),
        ],
      ),
    );
  }'''
rep(old_selector, new_selector)

rep(
    "        children: <Widget>[\n          _buildTipoRecebimentoSelector(),\n          const SizedBox(height: 16),\n          _buildResumoDistribuicao(),\n          const SizedBox(height: 22),\n          Row(",
    "        children: <Widget>[\n          _buildTipoRecebimentoSelector(),\n          if (_tipoRecebimentoEscolhido) ...<Widget>[\n            const SizedBox(height: 16),\n            _buildResumoDistribuicao(),\n            const SizedBox(height: 22),\n            Row(",
)
rep(
    "          if (!_carregandoFormas)\n            SizedBox(\n              width: double.infinity,\n              child: OutlinedButton.icon(\n                onPressed:\n                    podeAdicionar && !_salvandoOperacao\n                        ? _adicionarForma\n                        : null,\n                icon: const Icon(Icons.add_rounded),\n                label: Text(\n                  _txt('recebimento.adicionarForma', 'Adicionar forma'),\n                ),\n                style: addMethodStyle,\n              ),\n            ),\n        ],\n      ),",
    "          if (!_carregandoFormas)\n            SizedBox(\n              width: double.infinity,\n              child: OutlinedButton.icon(\n                onPressed:\n                    podeAdicionar && !_salvandoOperacao\n                        ? _adicionarForma\n                        : null,\n                icon: const Icon(Icons.add_rounded),\n                label: Text(\n                  _txt('recebimento.adicionarForma', 'Adicionar forma'),\n                ),\n                style: addMethodStyle,\n              ),\n            ),\n          ],\n        ],\n      ),",
)
rep(
    "  double _parseValor(String value) {\n    final LocaleSettingsProvider regionalizacao =\n        context.read<LocaleSettingsProvider>();\n    final String texto = regionalizacao.stripCurrencyMarkers(value);\n    final String normalizado =\n        texto.contains(',') && texto.contains('.')\n            ? texto.replaceAll('.', '').replaceAll(',', '.')\n            : texto.replaceAll(',', '.');\n    return double.tryParse(normalizado) ?? 0;\n  }",
    "  String _formatarValorDigitavel(double valor) {\n    final LocaleSettingsProvider regionalizacao =\n        context.read<LocaleSettingsProvider>();\n    return regionalizacao.formatCurrency(\n      valor,\n      showCurrencySymbol: false,\n      showCurrencyCode: false,\n    );\n  }\n\n  double _parseValor(String value) {\n    final LocaleSettingsProvider regionalizacao =\n        context.read<LocaleSettingsProvider>();\n    String texto = regionalizacao.stripCurrencyMarkers(value).trim();\n    if (regionalizacao.thousandSeparator.isNotEmpty) {\n      texto = texto.replaceAll(regionalizacao.thousandSeparator, '');\n    }\n    if (regionalizacao.decimalSeparator != '.') {\n      texto = texto.replaceAll(regionalizacao.decimalSeparator, '.');\n    }\n    return double.tryParse(texto) ?? 0;\n  }",
)
rep(
    "                      height: 3,\n                      color: Theme.of(context).colorScheme.primary,",
    "                      height: 3,\n                      color: !_tipoRecebimentoEscolhido\n                          ? Theme.of(context).colorScheme.primary\n                          : (_recebimentoParcial\n                              ? _partialReceiptColor\n                              : _totalReceiptColor),",
)

p.write_text(s)
