part of 'compras_web_page.dart';

extension _ComprasWebEditor on _ComprasWebPageState {
  Widget _buildEditorCompra(_CompraDemo compra) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return LayoutBuilder(
      key: ValueKey<String>('compras-editor-${compra.id}'),
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 900;
        return Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      compacto ? 16 : 26,
                      compacto ? 16 : 22,
                      compacto ? 16 : 26,
                      24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        _buildEditorHeader(compra, compacto),
                        const SizedBox(height: 14),
                        const _CompraDemoBanner(),
                        const SizedBox(height: 16),
                        _buildEtapas(compra, compacto),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: WebThemeTokens.transitionDuration,
                          child: KeyedSubtree(
                            key: ValueKey<_CompraDemoStep>(_etapaAtual),
                            child: _buildConteudoEtapa(compra, compacto),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            _buildEditorFooter(compra, compacto, tokens),
          ],
        );
      },
    );
  }

  Widget _buildEditorHeader(_CompraDemo compra, bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton(
          tooltip: context.comprasT('compras.action.backToList'),
          onPressed: _voltarParaLista,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tokens.selectedBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: tokens.selectedBorder),
          ),
          child: Icon(
            compra.editavel
                ? Icons.edit_note_outlined
                : Icons.receipt_long_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 9,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    compra.identificadorVisual,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _CompraStatusBadge(status: compra.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                compra.editavel
                    ? context.comprasT('compras.editor.subtitleDraft')
                    : context.comprasT('compras.editor.subtitleReadOnly'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: () => _duplicarCompra(compra),
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: Text(context.comprasT('compras.action.duplicate')),
        ),
        if (compra.status != _CompraDemoStatus.cancelada)
          OutlinedButton.icon(
            onPressed: () => _solicitarCancelamento(compra),
            icon: Icon(Icons.cancel_outlined, size: 18, color: tokens.danger),
            label: Text(
              context.comprasT('compras.action.cancel'),
              style: TextStyle(color: tokens.danger),
            ),
          ),
      ],
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          title,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: title),
        const SizedBox(width: 18),
        actions,
      ],
    );
  }

  Widget _buildEtapas(_CompraDemo compra, bool compacto) {
    final List<(_CompraDemoStep, IconData, String)> etapas =
        <(_CompraDemoStep, IconData, String)>[
      (
        _CompraDemoStep.dados,
        Icons.description_outlined,
        context.comprasT('compras.step.data'),
      ),
      (
        _CompraDemoStep.itens,
        Icons.inventory_2_outlined,
        context.comprasT('compras.step.items'),
      ),
      (
        _CompraDemoStep.financeiro,
        Icons.account_balance_wallet_outlined,
        context.comprasT('compras.step.financial'),
      ),
      (
        _CompraDemoStep.anexos,
        Icons.attach_file_outlined,
        context.comprasT('compras.step.attachments'),
      ),
      (
        _CompraDemoStep.resumo,
        Icons.fact_check_outlined,
        context.comprasT('compras.step.summary'),
      ),
    ];
    return _CompraSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: etapas.indexed.map((entry) {
            final int index = entry.$1;
            final (_CompraDemoStep, IconData, String) etapa = entry.$2;
            return Padding(
              padding: EdgeInsets.only(right: index == etapas.length - 1 ? 0 : 8),
              child: _CompraStepButton(
                icon: etapa.$2,
                label: etapa.$3,
                active: _etapaAtual == etapa.$1,
                completed: _etapaConcluida(compra, etapa.$1),
                onTap: () => _rebuild(() => _etapaAtual = etapa.$1),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  bool _etapaConcluida(_CompraDemo compra, _CompraDemoStep etapa) {
    return switch (etapa) {
      _CompraDemoStep.dados =>
        compra.fornecedorNome.trim().isNotEmpty &&
            compra.numeroDocumento.trim().isNotEmpty,
      _CompraDemoStep.itens => compra.itens.isNotEmpty,
      _CompraDemoStep.financeiro =>
        !compra.gerarContaPagar || compra.quantidadeParcelas > 0,
      _CompraDemoStep.anexos => compra.anexos.isNotEmpty,
      _CompraDemoStep.resumo =>
        compra.status == _CompraDemoStatus.confirmada,
    };
  }

  Widget _buildConteudoEtapa(_CompraDemo compra, bool compacto) {
    return switch (_etapaAtual) {
      _CompraDemoStep.dados => _buildEtapaDados(compra, compacto),
      _CompraDemoStep.itens => _buildEtapaItens(compra, compacto),
      _CompraDemoStep.financeiro => _buildEtapaFinanceiro(compra, compacto),
      _CompraDemoStep.anexos => _buildEtapaAnexos(compra, compacto),
      _CompraDemoStep.resumo => _buildEtapaResumo(compra, compacto),
    };
  }

  Widget _buildEtapaDados(_CompraDemo compra, bool compacto) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editavel = compra.editavel;
    return _CompraSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CompraSectionHeader(
            icon: Icons.description_outlined,
            title: context.comprasT('compras.data.title'),
            subtitle: context.comprasT('compras.data.subtitle'),
          ),
          const SizedBox(height: 22),
          _buildResponsiveFieldRow(
            children: <Widget>[
              _buildLabeledField(
                label: context.comprasT('compras.field.supplier'),
                required: true,
                flex: 2,
                child: InkWell(
                  onTap: editavel ? () => _selecionarFornecedor(compra) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.storefront_outlined),
                      suffixIcon: editavel
                          ? const Icon(Icons.expand_more_rounded)
                          : const Icon(Icons.lock_outline_rounded, size: 18),
                      filled: true,
                      fillColor: tokens.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    isEmpty: compra.fornecedorNome.trim().isEmpty,
                    child: compra.fornecedorNome.trim().isEmpty
                        ? Text(
                            context.comprasT('compras.supplier.select'),
                            style: TextStyle(color: tokens.mutedText),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                compra.fornecedorNome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (compra.fornecedorDocumento.trim().isNotEmpty)
                                Text(
                                  compra.fornecedorDocumento,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: tokens.secondaryText),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.documentType'),
                child: DropdownButtonFormField<String>(
                  value: compra.tipoDocumento,
                  decoration: _inputDecoration(tokens),
                  items: const <String>[
                    'NF-e',
                    'NFC-e',
                    'Invoice',
                    'Factura',
                    'Recibo',
                    'Outro',
                  ]
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: editavel
                      ? (String? value) {
                          if (value != null) {
                            _rebuild(() {
                              compra.tipoDocumento = value;
                              _store.salvar(compra);
                            });
                          }
                        }
                      : null,
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.currency'),
                child: DropdownButtonFormField<String>(
                  value: compra.moeda,
                  decoration: _inputDecoration(tokens),
                  items: <String>{
                    context.read<LocaleSettingsProvider>().currencyCode,
                    'BRL',
                    'USD',
                    'EUR',
                    'ARS',
                    'MXN',
                    'COP',
                    'CLP',
                  }
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: editavel
                      ? (String? value) {
                          if (value != null) {
                            _rebuild(() {
                              compra.moeda = value;
                              _store.salvar(compra);
                            });
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponsiveFieldRow(
            children: <Widget>[
              _buildLabeledField(
                label: context.comprasT('compras.field.documentNumber'),
                required: true,
                flex: 2,
                child: TextFormField(
                  key: ValueKey<String>(
                    'documento-${compra.id}-${compra.numeroDocumento}',
                  ),
                  initialValue: compra.numeroDocumento,
                  enabled: editavel,
                  decoration: _inputDecoration(tokens).copyWith(
                    hintText: context.comprasT('compras.field.documentNumberHint'),
                    prefixIcon: const Icon(Icons.numbers_outlined),
                  ),
                  onChanged: (String value) {
                    compra.numeroDocumento = value;
                    _store.salvar(compra);
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.series'),
                child: TextFormField(
                  key: ValueKey<String>('serie-${compra.id}-${compra.serieDocumento}'),
                  initialValue: compra.serieDocumento,
                  enabled: editavel,
                  decoration: _inputDecoration(tokens).copyWith(
                    hintText: context.comprasT('compras.field.seriesHint'),
                  ),
                  onChanged: (String value) {
                    compra.serieDocumento = value;
                    _store.salvar(compra);
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.issueDate'),
                required: true,
                child: _buildDateField(
                  value: compra.dataEmissao,
                  enabled: editavel,
                  onChanged: (DateTime value) {
                    _rebuild(() {
                      compra.dataEmissao = value;
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.entryDate'),
                required: true,
                child: _buildDateField(
                  value: compra.dataEntrada,
                  enabled: editavel,
                  onChanged: (DateTime value) {
                    _rebuild(() {
                      compra.dataEntrada = value;
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CompraFieldLabel(text: context.comprasT('compras.field.notes')),
          TextFormField(
            key: ValueKey<String>('notas-${compra.id}-${compra.observacoes}'),
            initialValue: compra.observacoes,
            enabled: editavel,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDecoration(tokens).copyWith(
              hintText: context.comprasT('compras.field.notesHint'),
            ),
            onChanged: (String value) {
              compra.observacoes = value;
              _store.salvar(compra);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaItens(_CompraDemo compra, bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editavel = compra.editavel;
    return Column(
      children: <Widget>[
        _CompraSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: Icons.inventory_2_outlined,
                title: context.comprasT('compras.items.title'),
                subtitle: context.comprasT('compras.items.subtitle'),
                trailing: editavel && !compacto
                    ? Wrap(
                        spacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _adicionarItemLivre(compra),
                            icon: const Icon(Icons.post_add_outlined, size: 18),
                            label: Text(context.comprasT('compras.items.nonStock')),
                          ),
                          FilledButton.icon(
                            onPressed: () => _selecionarProduto(compra),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(context.comprasT('compras.items.addProduct')),
                          ),
                        ],
                      )
                    : null,
              ),
              if (editavel && compacto) ...<Widget>[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => _adicionarItemLivre(compra),
                      icon: const Icon(Icons.post_add_outlined, size: 18),
                      label: Text(context.comprasT('compras.items.nonStock')),
                    ),
                    FilledButton.icon(
                      onPressed: () => _selecionarProduto(compra),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.comprasT('compras.items.addProduct')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (compra.itens.isEmpty)
                _CompraEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: context.comprasT('compras.items.empty.title'),
                  description: context.comprasT('compras.items.empty.description'),
                  action: editavel
                      ? FilledButton.icon(
                          onPressed: () => _selecionarProduto(compra),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.comprasT('compras.items.addProduct')),
                        )
                      : null,
                )
              else
                ...compra.itens.indexed.map((entry) {
                  final int index = entry.$1;
                  final _CompraDemoItem item = entry.$2;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == compra.itens.length - 1 ? 0 : 12,
                    ),
                    child: _buildItemCompraCard(
                      compra: compra,
                      item: item,
                      index: index,
                      compacto: compacto,
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CompraSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: Icons.calculate_outlined,
                title: context.comprasT('compras.totals.title'),
                subtitle: context.comprasT('compras.totals.subtitle'),
              ),
              const SizedBox(height: 18),
              _buildResponsiveFieldRow(
                children: <Widget>[
                  _buildLabeledField(
                    label: context.comprasT('compras.field.freight'),
                    child: _buildMoneyField(
                      key: ValueKey<String>('frete-${compra.id}-${compra.frete}'),
                      value: compra.frete,
                      enabled: editavel,
                      onChanged: (double value) {
                        _rebuild(() {
                          compra.frete = value;
                          _store.salvar(compra);
                        });
                      },
                    ),
                  ),
                  _buildLabeledField(
                    label: context.comprasT('compras.field.generalDiscount'),
                    child: _buildMoneyField(
                      key: ValueKey<String>(
                        'desconto-geral-${compra.id}-${compra.descontoGeral}',
                      ),
                      value: compra.descontoGeral,
                      enabled: editavel,
                      onChanged: (double value) {
                        _rebuild(() {
                          compra.descontoGeral = value;
                          _store.salvar(compra);
                        });
                      },
                    ),
                  ),
                  _buildLabeledField(
                    label: context.comprasT('compras.field.otherAdditions'),
                    child: _buildMoneyField(
                      key: ValueKey<String>(
                        'acrescimos-${compra.id}-${compra.outrosAcrescimos}',
                      ),
                      value: compra.outrosAcrescimos,
                      enabled: editavel,
                      onChanged: (double value) {
                        _rebuild(() {
                          compra.outrosAcrescimos = value;
                          _store.salvar(compra);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Column(
                  children: <Widget>[
                    _CompraInfoRow(
                      label: context.comprasT('compras.summary.itemsSubtotal'),
                      value: _formatarMoeda(
                        compra.subtotalItens,
                        codigoMoeda: compra.moeda,
                      ),
                    ),
                    _CompraInfoRow(
                      label: context.comprasT('compras.summary.itemsDiscounts'),
                      value: '- ${_formatarMoeda(compra.descontoItens + compra.descontoGeral, codigoMoeda: compra.moeda)}',
                    ),
                    _CompraInfoRow(
                      label: context.comprasT('compras.summary.additions'),
                      value: _formatarMoeda(
                        compra.acrescimoItens +
                            compra.frete +
                            compra.outrosAcrescimos,
                        codigoMoeda: compra.moeda,
                      ),
                    ),
                    Divider(color: tokens.divider),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            context.comprasT('compras.summary.total'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _formatarMoeda(
                            compra.totalCompra,
                            codigoMoeda: compra.moeda,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCompraCard({
    required _CompraDemo compra,
    required _CompraDemoItem item,
    required int index,
    required bool compacto,
  }) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editavel = compra.editavel;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.movimentaEstoque
                      ? tokens.success.withValues(alpha: 0.09)
                      : tokens.info.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  item.movimentaEstoque
                      ? Icons.inventory_2_outlined
                      : Icons.design_services_outlined,
                  size: 19,
                  color: item.movimentaEstoque ? tokens.success : tokens.info,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.descricao,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.codigo.trim().isEmpty
                          ? context.comprasT('compras.items.noCode')
                          : item.codigo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (editavel)
                IconButton(
                  tooltip: context.comprasT('common.delete'),
                  onPressed: () {
                    _rebuild(() {
                      compra.itens.remove(item);
                      _store.salvar(compra);
                    });
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: tokens.danger),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildResponsiveFieldRow(
            minWidth: compacto ? 130 : 150,
            children: <Widget>[
              _buildLabeledField(
                label: context.comprasT('compras.field.quantity'),
                child: TextFormField(
                  key: ValueKey<String>(
                    'quantidade-${item.id}-${item.quantidade}',
                  ),
                  initialValue: _numeroEditavel(item.quantidade),
                  enabled: editavel,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: _inputDecoration(tokens),
                  onChanged: (String value) {
                    _rebuild(() {
                      item.quantidade = _parseNumero(value);
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.unit'),
                child: DropdownButtonFormField<String>(
                  value: <String>['UN', 'CX', 'PCT', 'KG', 'LT', 'MT', 'SV']
                          .contains(item.unidade)
                      ? item.unidade
                      : 'UN',
                  decoration: _inputDecoration(tokens),
                  items: const <String>['UN', 'CX', 'PCT', 'KG', 'LT', 'MT', 'SV']
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: editavel
                      ? (String? value) {
                          if (value != null) {
                            _rebuild(() {
                              item.unidade = value;
                              _store.salvar(compra);
                            });
                          }
                        }
                      : null,
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.unitCost'),
                child: _buildMoneyField(
                  key: ValueKey<String>('custo-${item.id}-${item.valorUnitario}'),
                  value: item.valorUnitario,
                  enabled: editavel,
                  onChanged: (double value) {
                    _rebuild(() {
                      item.valorUnitario = value;
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.discount'),
                child: _buildMoneyField(
                  key: ValueKey<String>('desconto-${item.id}-${item.desconto}'),
                  value: item.desconto,
                  enabled: editavel,
                  onChanged: (double value) {
                    _rebuild(() {
                      item.desconto = value;
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
              _buildLabeledField(
                label: context.comprasT('compras.field.addition'),
                child: _buildMoneyField(
                  key: ValueKey<String>('acrescimo-${item.id}-${item.acrescimo}'),
                  value: item.acrescimo,
                  enabled: editavel,
                  onChanged: (double value) {
                    _rebuild(() {
                      item.acrescimo = value;
                      _store.salvar(compra);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.comprasT('compras.items.movesStock'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item.movimentaEstoque
                        ? context.comprasT('compras.items.movesStock.yes')
                        : context.comprasT('compras.items.movesStock.no'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  ),
                  value: item.movimentaEstoque,
                  onChanged: editavel
                      ? (bool value) {
                          _rebuild(() {
                            item.movimentaEstoque = value;
                            _store.salvar(compra);
                          });
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    context.comprasT('compras.items.itemTotal'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatarMoeda(item.total, codigoMoeda: compra.moeda),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaFinanceiro(_CompraDemo compra, bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editavel = compra.editavel;
    final List<_ParcelaDemo> parcelas = _store.parcelasDa(compra);
    return Column(
      children: <Widget>[
        _CompraSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: Icons.account_balance_wallet_outlined,
                title: context.comprasT('compras.financial.title'),
                subtitle: context.comprasT('compras.financial.subtitle'),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Column(
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.comprasT('compras.financial.generatePayable'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        context.comprasT('compras.financial.generatePayable.help'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                        ),
                      ),
                      value: compra.gerarContaPagar,
                      onChanged: editavel
                          ? (bool value) {
                              _rebuild(() {
                                compra.gerarContaPagar = value;
                                if (!value) {
                                  compra.jaPago = false;
                                }
                                _store.salvar(compra);
                              });
                            }
                          : null,
                    ),
                    if (compra.gerarContaPagar)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          context.comprasT('compras.financial.alreadyPaid'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          context.comprasT('compras.financial.alreadyPaid.help'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.secondaryText,
                          ),
                        ),
                        value: compra.jaPago,
                        onChanged: editavel
                            ? (bool value) {
                                _rebuild(() {
                                  compra.jaPago = value;
                                  _store.salvar(compra);
                                });
                              }
                            : null,
                      ),
                  ],
                ),
              ),
              if (compra.gerarContaPagar) ...<Widget>[
                const SizedBox(height: 18),
                _buildResponsiveFieldRow(
                  children: <Widget>[
                    _buildLabeledField(
                      label: context.comprasT('compras.field.paymentMethod'),
                      child: DropdownButtonFormField<String>(
                        value: compra.formaPagamento,
                        decoration: _inputDecoration(tokens),
                        items: <String>[
                          'Boleto',
                          'Transferência',
                          'PIX',
                          'Cartão',
                          'Dinheiro',
                          'Outro',
                        ]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: editavel
                            ? (String? value) {
                                if (value != null) {
                                  _rebuild(() {
                                    compra.formaPagamento = value;
                                    _store.salvar(compra);
                                  });
                                }
                              }
                            : null,
                      ),
                    ),
                    _buildLabeledField(
                      label: context.comprasT('compras.field.installments'),
                      child: DropdownButtonFormField<int>(
                        value: compra.quantidadeParcelas.clamp(1, 12).toInt(),
                        decoration: _inputDecoration(tokens),
                        items: List<DropdownMenuItem<int>>.generate(
                          12,
                          (int index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text((index + 1).toString()),
                          ),
                        ),
                        onChanged: editavel && !compra.jaPago
                            ? (int? value) {
                                if (value != null) {
                                  _rebuild(() {
                                    compra.quantidadeParcelas = value;
                                    _store.salvar(compra);
                                  });
                                }
                              }
                            : null,
                      ),
                    ),
                    _buildLabeledField(
                      label: context.comprasT('compras.field.firstDueDate'),
                      child: _buildDateField(
                        value: compra.primeiroVencimento,
                        enabled: editavel && !compra.jaPago,
                        onChanged: (DateTime value) {
                          _rebuild(() {
                            compra.primeiroVencimento = value;
                            _store.salvar(compra);
                          });
                        },
                      ),
                    ),
                    _buildLabeledField(
                      label: context.comprasT('compras.field.intervalDays'),
                      child: TextFormField(
                        key: ValueKey<String>(
                          'intervalo-${compra.id}-${compra.intervaloDias}',
                        ),
                        initialValue: compra.intervaloDias.toString(),
                        enabled: editavel && !compra.jaPago,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(tokens),
                        onChanged: (String value) {
                          _rebuild(() {
                            compra.intervaloDias = int.tryParse(value) ?? 30;
                            _store.salvar(compra);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildResponsiveFieldRow(
                  children: <Widget>[
                    _buildLabeledField(
                      label: context.comprasT('compras.field.financialAccount'),
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: compra.contaFinanceira,
                        decoration: _inputDecoration(tokens),
                        items: <String>[
                          'Conta principal',
                          'Conta internacional',
                          'Caixa da loja',
                          'Cartão corporativo',
                        ]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: editavel
                            ? (String? value) {
                                if (value != null) {
                                  _rebuild(() {
                                    compra.contaFinanceira = value;
                                    _store.salvar(compra);
                                  });
                                }
                              }
                            : null,
                      ),
                    ),
                    _buildLabeledField(
                      label: context.comprasT('compras.field.financialNotes'),
                      flex: 3,
                      child: TextFormField(
                        key: ValueKey<String>(
                          'financeiro-notas-${compra.id}-${compra.observacaoFinanceira}',
                        ),
                        initialValue: compra.observacaoFinanceira,
                        enabled: editavel,
                        decoration: _inputDecoration(tokens).copyWith(
                          hintText: context.comprasT('compras.field.financialNotesHint'),
                        ),
                        onChanged: (String value) {
                          compra.observacaoFinanceira = value;
                          _store.salvar(compra);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (compra.gerarContaPagar && !compra.jaPago) ...<Widget>[
          const SizedBox(height: 14),
          _CompraSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CompraSectionHeader(
                  icon: Icons.calendar_month_outlined,
                  title: context.comprasT('compras.installments.preview.title'),
                  subtitle: context.comprasT('compras.installments.preview.subtitle'),
                ),
                const SizedBox(height: 16),
                if (parcelas.isEmpty)
                  Text(
                    context.comprasT('compras.installments.empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.secondaryText,
                    ),
                  )
                else
                  ...parcelas.map(
                    (_ParcelaDemo parcela) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tokens.selectedBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              parcela.numero.toString(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              context.comprasT('compras.installments.due')
                                  .replaceAll(
                                    '{date}',
                                    _formatarData(parcela.vencimento),
                                  ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatarMoeda(
                              parcela.valor,
                              codigoMoeda: compra.moeda,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEtapaAnexos(_CompraDemo compra, bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool editavel = compra.editavel;
    return _CompraSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CompraSectionHeader(
            icon: Icons.attach_file_outlined,
            title: context.comprasT('compras.attachments.title'),
            subtitle: context.comprasT('compras.attachments.subtitle'),
            trailing: editavel
                ? FilledButton.icon(
                    onPressed: () => _adicionarAnexoSimulado(compra),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(context.comprasT('compras.attachments.add')),
                  )
                : null,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: tokens.info.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: tokens.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.comprasT('compras.attachments.demoNotice'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (compra.anexos.isEmpty)
            _CompraEmptyState(
              icon: Icons.folder_open_outlined,
              title: context.comprasT('compras.attachments.empty.title'),
              description: context.comprasT('compras.attachments.empty.description'),
              action: editavel
                  ? OutlinedButton.icon(
                      onPressed: () => _adicionarAnexoSimulado(compra),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.comprasT('compras.attachments.add')),
                    )
                  : null,
            )
          else
            ...compra.anexos.map(
              (_CompraDemoAnexo anexo) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tokens.selectedBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconeAnexo(anexo.tipo),
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            anexo.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${anexo.tipo} • ${anexo.tamanho} • ${_formatarDataHora(anexo.adicionadoEm)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (editavel)
                      IconButton(
                        tooltip: context.comprasT('common.delete'),
                        onPressed: () {
                          _rebuild(() {
                            compra.anexos.remove(anexo);
                            _store.salvar(compra);
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: tokens.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconeAnexo(String tipo) {
    return switch (tipo) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'XML' => Icons.code_outlined,
      'Imagem' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Widget _buildEtapaResumo(_CompraDemo compra, bool compacto) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<String> pendencias = _validarCompra(compra);
    final List<_ParcelaDemo> parcelas = _store.parcelasDa(compra);
    return Column(
      children: <Widget>[
        _CompraSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: Icons.fact_check_outlined,
                title: context.comprasT('compras.summary.title'),
                subtitle: context.comprasT('compras.summary.subtitle'),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool narrow = constraints.maxWidth < 780;
                  final Widget dados = Column(
                    children: <Widget>[
                      _CompraInfoRow(
                        label: context.comprasT('compras.field.supplier'),
                        value: compra.fornecedorNome.trim().isEmpty
                            ? context.comprasT('common.notInformed')
                            : compra.fornecedorNome,
                      ),
                      _CompraInfoRow(
                        label: context.comprasT('compras.field.document'),
                        value: compra.numeroDocumento.trim().isEmpty
                            ? context.comprasT('common.notInformed')
                            : '${compra.tipoDocumento} ${compra.numeroDocumento}',
                      ),
                      _CompraInfoRow(
                        label: context.comprasT('compras.field.issueDate'),
                        value: _formatarData(compra.dataEmissao),
                      ),
                      _CompraInfoRow(
                        label: context.comprasT('compras.field.entryDate'),
                        value: _formatarData(compra.dataEntrada),
                      ),
                      _CompraInfoRow(
                        label: context.comprasT('compras.summary.items'),
                        value: compra.itens.length.toString(),
                      ),
                      _CompraInfoRow(
                        label: context.comprasT('compras.summary.stockItems'),
                        value: compra.itensComEstoque.toString(),
                      ),
                    ],
                  );
                  final Widget totals = Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: Column(
                      children: <Widget>[
                        _CompraInfoRow(
                          label: context.comprasT('compras.summary.itemsSubtotal'),
                          value: _formatarMoeda(
                            compra.subtotalItens,
                            codigoMoeda: compra.moeda,
                          ),
                        ),
                        _CompraInfoRow(
                          label: context.comprasT('compras.summary.discounts'),
                          value:
                              '- ${_formatarMoeda(compra.descontoItens + compra.descontoGeral, codigoMoeda: compra.moeda)}',
                        ),
                        _CompraInfoRow(
                          label: context.comprasT('compras.summary.freightAndAdditions'),
                          value: _formatarMoeda(
                            compra.frete +
                                compra.acrescimoItens +
                                compra.outrosAcrescimos,
                            codigoMoeda: compra.moeda,
                          ),
                        ),
                        Divider(color: tokens.divider),
                        _CompraInfoRow(
                          label: context.comprasT('compras.summary.total'),
                          value: _formatarMoeda(
                            compra.totalCompra,
                            codigoMoeda: compra.moeda,
                          ),
                          valueColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  );
                  if (narrow) {
                    return Column(
                      children: <Widget>[
                        dados,
                        const SizedBox(height: 14),
                        totals,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: dados),
                      const SizedBox(width: 24),
                      Expanded(child: totals),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CompraSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: Icons.hub_outlined,
                title: context.comprasT('compras.impacts.title'),
                subtitle: context.comprasT('compras.impacts.subtitle'),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int colunas = constraints.maxWidth >= 900 ? 3 : 1;
                  final double width =
                      (constraints.maxWidth - ((colunas - 1) * 10)) / colunas;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: width,
                        child: _CompraImpactTile(
                          icon: Icons.inventory_2_outlined,
                          title: context.comprasT('compras.impacts.stock.title'),
                          description: context.comprasT('compras.impacts.stock.description')
                              .replaceAll(
                                '{count}',
                                compra.itensComEstoque.toString(),
                              ),
                          enabled: compra.itensComEstoque > 0,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _CompraImpactTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: context.comprasT('compras.impacts.financial.title'),
                          description: compra.gerarContaPagar
                              ? context.comprasT('compras.impacts.financial.description')
                                  .replaceAll(
                                    '{count}',
                                    parcelas.isEmpty
                                        ? '1'
                                        : parcelas.length.toString(),
                                  )
                              : context.comprasT(
                                  'compras.impacts.financial.disabled',
                                ),
                          enabled: compra.gerarContaPagar,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _CompraImpactTile(
                          icon: Icons.price_change_outlined,
                          title: context.comprasT('compras.impacts.cost.title'),
                          description: context.comprasT(
                            'compras.impacts.cost.description',
                          ),
                          enabled: compra.itens.isNotEmpty,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CompraSurfaceCard(
          borderColor: pendencias.isEmpty
              ? tokens.success.withValues(alpha: 0.32)
              : tokens.warning.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CompraSectionHeader(
                icon: pendencias.isEmpty
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                title: pendencias.isEmpty
                    ? context.comprasT('compras.validation.ready.title')
                    : context.comprasT('compras.validation.pending.title'),
                subtitle: pendencias.isEmpty
                    ? context.comprasT('compras.validation.ready.description')
                    : context.comprasT('compras.validation.pending.description'),
              ),
              if (pendencias.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                ...pendencias.map(
                  (String pendencia) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: tokens.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pendencia,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (compra.status == _CompraDemoStatus.confirmada) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.comprasT('compras.confirmed.description')
                        .replaceAll(
                          '{number}',
                          compra.identificadorVisual,
                        )
                        .replaceAll(
                          '{date}',
                          _formatarDataHora(
                            compra.confirmadaEm ?? compra.atualizadaEm,
                          ),
                        ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (compra.status == _CompraDemoStatus.cancelada) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.danger.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.comprasT('compras.cancelled.description')
                        .replaceAll(
                          '{reason}',
                          compra.motivoCancelamento ??
                              context.comprasT('common.notInformed'),
                        ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.primaryText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorFooter(
    _CompraDemo compra,
    bool compacto,
    WebThemeTokens tokens,
  ) {
    final List<_CompraDemoStep> steps = _CompraDemoStep.values;
    final int currentIndex = steps.indexOf(_etapaAtual);
    final bool first = currentIndex == 0;
    final bool last = currentIndex == steps.length - 1;
    final bool editavel = compra.editavel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 16 : 26,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _voltarParaLista,
                icon: const Icon(Icons.list_alt_outlined, size: 18),
                label: Text(context.comprasT('compras.action.backToList')),
              ),
              if (editavel)
                TextButton.icon(
                  onPressed: () {
                    _store.salvar(compra);
                    _rebuild(() {});
                    _mostrarMensagem(context.comprasT('compras.message.draftSaved'));
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(context.comprasT('compras.action.saveDraft')),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (!first)
                OutlinedButton.icon(
                  onPressed: () => _rebuild(
                    () => _etapaAtual = steps[currentIndex - 1],
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(context.comprasT('common.back')),
                ),
              if (!last)
                FilledButton.icon(
                  onPressed: () => _rebuild(
                    () => _etapaAtual = steps[currentIndex + 1],
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(context.comprasT('common.continue')),
                )
              else if (editavel)
                FilledButton.icon(
                  onPressed: () => _confirmarCompra(compra),
                  icon: const Icon(Icons.check_circle_outline, size: 19),
                  label: Text(context.comprasT('compras.action.confirm')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _validarCompra(_CompraDemo compra) {
    final List<String> pendencias = <String>[];
    if (compra.fornecedorNome.trim().isEmpty) {
      pendencias.add(context.comprasT('compras.validation.supplier'));
    }
    if (compra.numeroDocumento.trim().isEmpty) {
      pendencias.add(context.comprasT('compras.validation.documentNumber'));
    }
    if (compra.itens.isEmpty) {
      pendencias.add(context.comprasT('compras.validation.items'));
    }
    if (compra.itens.any(
      (_CompraDemoItem item) =>
          item.descricao.trim().isEmpty ||
          item.quantidade <= 0 ||
          item.valorUnitario < 0,
    )) {
      pendencias.add(context.comprasT('compras.validation.invalidItems'));
    }
    if (compra.totalCompra <= 0) {
      pendencias.add(context.comprasT('compras.validation.total'));
    }
    if (compra.gerarContaPagar && compra.quantidadeParcelas <= 0) {
      pendencias.add(context.comprasT('compras.validation.installments'));
    }
    return pendencias;
  }

  Future<void> _confirmarCompra(_CompraDemo compra) async {
    final List<String> pendencias = _validarCompra(compra);
    if (pendencias.isNotEmpty) {
      _rebuild(() => _etapaAtual = _CompraDemoStep.resumo);
      _mostrarMensagem(context.comprasT('compras.message.fixPending'), erro: true);
      return;
    }
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(context.comprasT('compras.confirm.title')),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(context.comprasT('compras.confirm.description')),
                const SizedBox(height: 14),
                _CompraImpactTile(
                  icon: Icons.inventory_2_outlined,
                  title: context.comprasT('compras.impacts.stock.title'),
                  description: context.comprasT('compras.impacts.stock.description')
                      .replaceAll('{count}', compra.itensComEstoque.toString()),
                  enabled: compra.itensComEstoque > 0,
                ),
                const SizedBox(height: 8),
                _CompraImpactTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: context.comprasT('compras.impacts.financial.title'),
                  description: compra.gerarContaPagar
                      ? context.comprasT('compras.impacts.financial.description')
                          .replaceAll(
                            '{count}',
                            compra.quantidadeParcelas.toString(),
                          )
                      : context.comprasT('compras.impacts.financial.disabled'),
                  enabled: compra.gerarContaPagar,
                ),
                const SizedBox(height: 12),
                Text(
                  context.comprasT('compras.confirm.demoNotice'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WebThemeTokens.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.comprasT('common.cancel')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.check_rounded),
              label: Text(context.comprasT('compras.action.confirm')),
            ),
          ],
        );
      },
    );
    if (confirmado != true || !mounted) {
      return;
    }
    final int numero = _store.confirmar(compra);
    _rebuild(() => _etapaAtual = _CompraDemoStep.resumo);
    _mostrarMensagem(
      context.comprasT('compras.message.confirmed')
          .replaceAll('#{number}', '#${numero.toString().padLeft(6, '0')}'),
    );
  }

  Widget _buildResponsiveFieldRow({
    required List<Widget> children,
    double minWidth = 180,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count = math.max(1, (constraints.maxWidth / minWidth).floor());
        final int columns = math.min(count, children.length);
        final double width =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: children
              .map((Widget child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    bool required = false,
    int flex = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CompraFieldLabel(text: label, required: required),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(WebThemeTokens tokens) {
    return InputDecoration(
      filled: true,
      fillColor: tokens.inputBackground,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime value,
    required bool enabled,
    required ValueChanged<DateTime> onChanged,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InkWell(
      onTap: enabled
          ? () async {
              final DateTime? selected = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selected != null) {
                onChanged(selected);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(tokens).copyWith(
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: enabled
              ? const Icon(Icons.expand_more_rounded)
              : const Icon(Icons.lock_outline_rounded, size: 18),
        ),
        child: Text(_formatarData(value)),
      ),
    );
  }

  Widget _buildMoneyField({
    required Key key,
    required double value,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextFormField(
      key: key,
      initialValue: _numeroEditavel(value),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: _inputDecoration(tokens).copyWith(
        prefixText: '${context.read<LocaleSettingsProvider>().currencyCode} ',
      ),
      onChanged: (String text) => onChanged(_parseNumero(text)),
    );
  }

  Future<void> _selecionarFornecedor(_CompraDemo compra) async {
    final TextEditingController busca = TextEditingController();
    try {
      final _FornecedorDemo? selecionado = await showDialog<_FornecedorDemo>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(VoidCallback fn) setDialogState,
            ) {
              final WebThemeTokens tokens = WebThemeTokens.of(context);
              final String query = busca.text.trim().toLowerCase();
              final List<_FornecedorDemo> fornecedores = _store.fornecedores
                  .where((_FornecedorDemo fornecedor) {
                    if (query.isEmpty) {
                      return true;
                    }
                    return <String>[
                      fornecedor.nome,
                      fornecedor.documento,
                      fornecedor.email,
                      fornecedor.telefone,
                    ].join(' ').toLowerCase().contains(query);
                  })
                  .toList(growable: false);
              return AlertDialog(
                title: Text(context.comprasT('compras.supplier.dialog.title')),
                content: SizedBox(
                  width: 680,
                  height: 500,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: busca,
                        autofocus: true,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: context.comprasT('compras.supplier.dialog.search'),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: busca.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    busca.clear();
                                    setDialogState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: fornecedores.isEmpty
                            ? _CompraEmptyState(
                                icon: Icons.storefront_outlined,
                                title: context.comprasT(
                                  'compras.supplier.dialog.empty.title',
                                ),
                                description: context.comprasT(
                                  'compras.supplier.dialog.empty.description',
                                ),
                              )
                            : ListView.separated(
                                itemCount: fornecedores.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: tokens.divider, height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final _FornecedorDemo fornecedor =
                                      fornecedores[index];
                                  final bool selected =
                                      compra.fornecedorId == fornecedor.id;
                                  return ListTile(
                                    selected: selected,
                                    selectedTileColor: tokens.selectedBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: tokens.surfaceMuted,
                                      child: Icon(
                                        Icons.storefront_outlined,
                                        color: tokens.secondaryText,
                                      ),
                                    ),
                                    title: Text(
                                      fornecedor.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${fornecedor.documento}\n${fornecedor.email} • ${fornecedor.telefone}',
                                    ),
                                    isThreeLine: true,
                                    trailing: selected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: tokens.success,
                                          )
                                        : const Icon(Icons.chevron_right_rounded),
                                    onTap: () => Navigator.of(dialogContext).pop(
                                      fornecedor,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.comprasT('common.cancel')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final _FornecedorDemo? criado =
                          await _cadastrarFornecedorRapido(dialogContext);
                      if (criado != null && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(criado);
                      }
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: Text(context.comprasT('compras.supplier.quickAdd')),
                  ),
                ],
              );
            },
          );
        },
      );
      if (selecionado == null || !mounted) {
        return;
      }
      _rebuild(() {
        compra
          ..fornecedorId = selecionado.id
          ..fornecedorNome = selecionado.nome
          ..fornecedorDocumento = selecionado.documento;
        _store.salvar(compra);
      });
    } finally {
      busca.dispose();
    }
  }

  Future<_FornecedorDemo?> _cadastrarFornecedorRapido(
    BuildContext parentDialogContext,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nome = TextEditingController();
    final TextEditingController documento = TextEditingController();
    final TextEditingController email = TextEditingController();
    final TextEditingController telefone = TextEditingController();
    try {
      return await showDialog<_FornecedorDemo>(
        context: parentDialogContext,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.comprasT('compras.supplier.quickAdd.title')),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nome,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: context.comprasT('compras.supplier.name'),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      validator: (String? value) => value == null || value.trim().isEmpty
                          ? context.comprasT('common.required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: documento,
                      decoration: InputDecoration(
                        labelText: context.comprasT('compras.supplier.document'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: context.comprasT('compras.supplier.email'),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: telefone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: context.comprasT('compras.supplier.phone'),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.comprasT('compras.supplier.quickAdd.demoNotice'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WebThemeTokens.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.comprasT('common.cancel')),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  final _FornecedorDemo fornecedor = _store.criarFornecedor(
                    nome: nome.text.trim(),
                    documento: documento.text.trim(),
                    email: email.text.trim(),
                    telefone: telefone.text.trim(),
                  );
                  Navigator.of(dialogContext).pop(fornecedor);
                },
                child: Text(context.comprasT('common.save')),
              ),
            ],
          );
        },
      );
    } finally {
      nome.dispose();
      documento.dispose();
      email.dispose();
      telefone.dispose();
    }
  }

  Future<void> _selecionarProduto(_CompraDemo compra) async {
    final TextEditingController busca = TextEditingController();
    try {
      final _ProdutoCompraDemo? selecionado = await showDialog<_ProdutoCompraDemo>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(VoidCallback fn) setDialogState,
            ) {
              final WebThemeTokens tokens = WebThemeTokens.of(context);
              final String query = busca.text.trim().toLowerCase();
              final List<_ProdutoCompraDemo> produtos = _store.produtos
                  .where((_ProdutoCompraDemo produto) {
                    if (query.isEmpty) {
                      return true;
                    }
                    return '${produto.nome} ${produto.codigo}'
                        .toLowerCase()
                        .contains(query);
                  })
                  .toList(growable: false);
              return AlertDialog(
                title: Text(context.comprasT('compras.product.dialog.title')),
                content: SizedBox(
                  width: 760,
                  height: 520,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: busca,
                        autofocus: true,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: context.comprasT('compras.product.dialog.search'),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: busca.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    busca.clear();
                                    setDialogState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: produtos.isEmpty
                            ? _CompraEmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: context.comprasT(
                                  'compras.product.dialog.empty.title',
                                ),
                                description: context.comprasT(
                                  'compras.product.dialog.empty.description',
                                ),
                              )
                            : ListView.separated(
                                itemCount: produtos.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: tokens.divider, height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final _ProdutoCompraDemo produto = produtos[index];
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: tokens.surfaceMuted,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: tokens.secondaryText,
                                      ),
                                    ),
                                    title: Text(
                                      produto.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${produto.codigo} • ${produto.unidade} • ${context.comprasT('compras.product.stock')}: ${_numeroEditavel(produto.estoqueAtual)}',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          context.comprasT('compras.product.lastCost'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: tokens.secondaryText,
                                              ),
                                        ),
                                        Text(
                                          _formatarMoeda(
                                            produto.ultimoCusto,
                                            codigoMoeda: compra.moeda,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => Navigator.of(dialogContext).pop(
                                      produto,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.comprasT('common.cancel')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final _ProdutoCompraDemo? criado =
                          await _cadastrarProdutoRapido(
                        dialogContext,
                        compra.moeda,
                      );
                      if (criado != null && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(criado);
                      }
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: Text(context.comprasT('compras.product.quickAdd')),
                  ),
                ],
              );
            },
          );
        },
      );
      if (selecionado == null || !mounted) {
        return;
      }
      _rebuild(() {
        compra.itens.add(
          _CompraDemoItem(
            id: _store.novoId('item'),
            produtoId: selecionado.id,
            descricao: selecionado.nome,
            codigo: selecionado.codigo,
            unidade: selecionado.unidade,
            valorUnitario: selecionado.ultimoCusto,
          ),
        );
        _store.salvar(compra);
      });
    } finally {
      busca.dispose();
    }
  }

  Future<_ProdutoCompraDemo?> _cadastrarProdutoRapido(
    BuildContext parentDialogContext,
    String moeda,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nome = TextEditingController();
    final TextEditingController codigo = TextEditingController();
    final TextEditingController custo = TextEditingController();
    String unidade = 'UN';
    try {
      return await showDialog<_ProdutoCompraDemo>(
        context: parentDialogContext,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(VoidCallback fn) setDialogState,
            ) {
              return AlertDialog(
                title: Text(context.comprasT('compras.product.quickAdd.title')),
                content: SizedBox(
                  width: 560,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: nome,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: context.comprasT('compras.product.name'),
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                          ),
                          validator: (String? value) =>
                              value == null || value.trim().isEmpty
                                  ? context.comprasT('common.required')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: codigo,
                                decoration: InputDecoration(
                                  labelText: context.comprasT('compras.product.code'),
                                  prefixIcon: const Icon(Icons.qr_code_2_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: unidade,
                                decoration: InputDecoration(
                                  labelText: context.comprasT('compras.field.unit'),
                                ),
                                items: const <String>[
                                  'UN',
                                  'CX',
                                  'PCT',
                                  'KG',
                                  'LT',
                                  'MT',
                                ]
                                    .map(
                                      (String value) => DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setDialogState(() => unidade = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: custo,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: context.comprasT('compras.field.unitCost'),
                            prefixText: '$moeda ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.comprasT('compras.product.quickAdd.demoNotice'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: WebThemeTokens.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.comprasT('common.cancel')),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) {
                        return;
                      }
                      final _ProdutoCompraDemo produto = _store.criarProduto(
                        nome: nome.text.trim(),
                        codigo: codigo.text.trim(),
                        unidade: unidade,
                        custo: _parseNumero(custo.text),
                      );
                      Navigator.of(dialogContext).pop(produto);
                    },
                    child: Text(context.comprasT('common.save')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nome.dispose();
      codigo.dispose();
      custo.dispose();
    }
  }

  Future<void> _adicionarItemLivre(_CompraDemo compra) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController descricao = TextEditingController();
    final TextEditingController codigo = TextEditingController();
    final TextEditingController quantidade = TextEditingController(text: '1');
    final TextEditingController valor = TextEditingController();
    String unidade = 'SV';
    bool movimentaEstoque = false;
    try {
      final _CompraDemoItem? item = await showDialog<_CompraDemoItem>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(VoidCallback fn) setDialogState,
            ) {
              return AlertDialog(
                title: Text(context.comprasT('compras.items.nonStock.title')),
                content: SizedBox(
                  width: 600,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: descricao,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: context.comprasT('compras.items.description'),
                            prefixIcon: const Icon(Icons.notes_outlined),
                          ),
                          validator: (String? value) =>
                              value == null || value.trim().isEmpty
                                  ? context.comprasT('common.required')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codigo,
                          decoration: InputDecoration(
                            labelText: context.comprasT('compras.items.codeOptional'),
                            prefixIcon: const Icon(Icons.tag_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: quantidade,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: context.comprasT('compras.field.quantity'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: unidade,
                                decoration: InputDecoration(
                                  labelText: context.comprasT('compras.field.unit'),
                                ),
                                items: const <String>[
                                  'SV',
                                  'UN',
                                  'CX',
                                  'PCT',
                                  'KG',
                                  'LT',
                                ]
                                    .map(
                                      (String value) => DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setDialogState(() => unidade = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: valor,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: context.comprasT('compras.field.unitCost'),
                                  prefixText: '${compra.moeda} ',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(context.comprasT('compras.items.movesStock')),
                          subtitle: Text(
                            context.comprasT('compras.items.nonStock.toggleHelp'),
                          ),
                          value: movimentaEstoque,
                          onChanged: (bool value) {
                            setDialogState(() => movimentaEstoque = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.comprasT('common.cancel')),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) {
                        return;
                      }
                      Navigator.of(dialogContext).pop(
                        _CompraDemoItem(
                          id: _store.novoId('item'),
                          descricao: descricao.text.trim(),
                          codigo: codigo.text.trim(),
                          unidade: unidade,
                          quantidade: _parseNumero(quantidade.text),
                          valorUnitario: _parseNumero(valor.text),
                          movimentaEstoque: movimentaEstoque,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.comprasT('compras.items.add')),
                  ),
                ],
              );
            },
          );
        },
      );
      if (item == null || !mounted) {
        return;
      }
      _rebuild(() {
        compra.itens.add(item);
        _store.salvar(compra);
      });
    } finally {
      descricao.dispose();
      codigo.dispose();
      quantidade.dispose();
      valor.dispose();
    }
  }

  Future<void> _adicionarAnexoSimulado(_CompraDemo compra) async {
    final TextEditingController nome = TextEditingController();
    String tipo = 'PDF';
    try {
      final _CompraDemoAnexo? anexo = await showDialog<_CompraDemoAnexo>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(VoidCallback fn) setDialogState,
            ) {
              return AlertDialog(
                title: Text(context.comprasT('compras.attachments.dialog.title')),
                content: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        value: tipo,
                        decoration: InputDecoration(
                          labelText: context.comprasT('compras.attachments.type'),
                          prefixIcon: const Icon(Icons.file_present_outlined),
                        ),
                        items: const <String>['PDF', 'XML', 'Imagem', 'Outro']
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) {
                          if (value != null) {
                            setDialogState(() => tipo = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nome,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: context.comprasT('compras.attachments.fileName'),
                          hintText: switch (tipo) {
                            'PDF' => 'documento-compra.pdf',
                            'XML' => 'documento-compra.xml',
                            'Imagem' => 'foto-documento.jpg',
                            _ => 'arquivo-compra.dat',
                          },
                          prefixIcon: const Icon(Icons.drive_file_rename_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: WebThemeTokens.of(context).surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.comprasT('compras.attachments.dialog.demoNotice'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: WebThemeTokens.of(context).secondaryText,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.comprasT('common.cancel')),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      final String extension = switch (tipo) {
                        'PDF' => '.pdf',
                        'XML' => '.xml',
                        'Imagem' => '.jpg',
                        _ => '.dat',
                      };
                      final String typedName = nome.text.trim();
                      Navigator.of(dialogContext).pop(
                        _CompraDemoAnexo(
                          id: _store.novoId('anexo'),
                          nome: typedName.isEmpty
                              ? 'documento-${DateTime.now().millisecondsSinceEpoch}$extension'
                              : typedName,
                          tipo: tipo,
                          tamanho: '${12 + math.Random().nextInt(280)} KB',
                          adicionadoEm: DateTime.now(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.comprasT('compras.attachments.add')),
                  ),
                ],
              );
            },
          );
        },
      );
      if (anexo == null || !mounted) {
        return;
      }
      _rebuild(() {
        compra.anexos.add(anexo);
        _store.salvar(compra);
      });
    } finally {
      nome.dispose();
    }
  }

  Future<void> _solicitarCancelamento(_CompraDemo compra) async {
    if (compra.status == _CompraDemoStatus.cancelada) {
      return;
    }
    final TextEditingController motivo = TextEditingController();
    try {
      final String? motivoConfirmado = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.comprasT('compras.cancel.title')),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(context.comprasT('compras.cancel.description')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: motivo,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: context.comprasT('compras.cancel.reason'),
                      hintText: context.comprasT('compras.cancel.reasonHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.comprasT('compras.cancel.demoNotice'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WebThemeTokens.of(context).secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.comprasT('common.back')),
              ),
              FilledButton.icon(
                onPressed: () {
                  final String value = motivo.text.trim();
                  if (value.isEmpty) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                icon: const Icon(Icons.cancel_outlined),
                label: Text(context.comprasT('compras.action.cancel')),
              ),
            ],
          );
        },
      );
      if (motivoConfirmado == null || !mounted) {
        return;
      }
      _rebuild(() {
        _store.cancelar(compra, motivoConfirmado);
        _etapaAtual = _CompraDemoStep.resumo;
      });
      _mostrarMensagem(context.comprasT('compras.message.cancelled'));
    } finally {
      motivo.dispose();
    }
  }
}
