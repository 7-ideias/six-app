import 'package:flutter/material.dart';

import 'empresa_configuracao_screen.dart';

class ConfiguracaoSecaoWebPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  const ConfiguracaoSecaoWebPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
  });

  bool get _ehConfiguracaoEmpresa => title == 'Empresa';
  bool get _ehRegrasOperacionais => title == 'Regras operacionais';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: <Widget>[
          _buildHeader(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 860;
          final Widget titleBlock = Row(
            children: <Widget>[
              _headerIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget closeButton = Align(
            alignment: compact ? Alignment.centerRight : Alignment.center,
            child: IconButton.filledTonal(
              onPressed: onBack,
              tooltip: 'Fechar',
              icon: const Icon(Icons.close_rounded),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: 14),
                closeButton,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              closeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _headerIcon(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 28),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_ehConfiguracaoEmpresa) {
      return _buildEmpresaContent(context);
    }

    if (_ehRegrasOperacionais) {
      return const _RegrasOperacionaisConfiguracaoContent();
    }

    return _buildBlankContent(context);
  }

  Widget _buildEmpresaContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(22),
            child: EmpresaConfiguracaoForm(embedded: true),
          ),
        ),
      ),
    );
  }

  Widget _buildBlankContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RegrasOperacionaisConfiguracaoContent extends StatefulWidget {
  const _RegrasOperacionaisConfiguracaoContent();

  @override
  State<_RegrasOperacionaisConfiguracaoContent> createState() =>
      _RegrasOperacionaisConfiguracaoContentState();
}

class _RegrasOperacionaisConfiguracaoContentState
    extends State<_RegrasOperacionaisConfiguracaoContent> {
  bool _controlarEstoque = true;
  bool _venderComEstoqueNegativo = false;
  bool _concederDescontoNaVenda = true;
  bool _aberturaCaixaObrigatoria = true;
  bool _gerarComissaoColaborador = true;
  bool _produtoApenasComUnidadeMedida = true;
  bool _exigirJustificativaDesconto = true;
  bool _aplicarComissaoEmServicos = true;
  bool _aplicarComissaoEmProdutos = false;

  String _tipoDescontoSelecionado = 'Percentual e valor fixo';
  String _baseComissaoSelecionada = 'Valor líquido da venda';
  double _limiteDescontoPercentual = 10;
  double _percentualComissaoPadrao = 5;

  final Set<String> _unidadesMedidaAutorizadas = <String>{
    'Unidade',
    'Área',
    'Distância',
    'Volume',
    'Tempo',
    'Peso',
  };

  static const List<String> _tiposDesconto = <String>[
    'Percentual e valor fixo',
    'Apenas percentual',
    'Apenas valor fixo',
    'Somente com permissão',
  ];

  static const List<String> _basesComissao = <String>[
    'Valor líquido da venda',
    'Valor bruto da venda',
    'Apenas serviços',
    'Apenas produtos',
  ];

  static const List<_UnidadeMedidaOperacional> _unidadesDisponiveis =
      <_UnidadeMedidaOperacional>[
    _UnidadeMedidaOperacional(
      label: 'Unidade',
      description: 'Peças, acessórios e itens vendidos individualmente.',
      icon: Icons.inventory_2_outlined,
    ),
    _UnidadeMedidaOperacional(
      label: 'Área',
      description: 'm², cm² e serviços medidos por superfície.',
      icon: Icons.crop_square_rounded,
    ),
    _UnidadeMedidaOperacional(
      label: 'Distância',
      description: 'm, km e cobranças por deslocamento.',
      icon: Icons.straighten_rounded,
    ),
    _UnidadeMedidaOperacional(
      label: 'Volume',
      description: 'ml, l e insumos medidos por capacidade.',
      icon: Icons.water_drop_outlined,
    ),
    _UnidadeMedidaOperacional(
      label: 'Tempo',
      description: 'hora técnica, diária, mensalidade e assinatura.',
      icon: Icons.schedule_rounded,
    ),
    _UnidadeMedidaOperacional(
      label: 'Peso',
      description: 'g, kg e materiais vendidos por massa.',
      icon: Icons.scale_rounded,
    ),
    _UnidadeMedidaOperacional(
      label: 'Moeda',
      description: 'Valores financeiros tratados como unidade de cobrança.',
      icon: Icons.paid_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildIntroCard(theme),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Estoque e venda',
                    subtitle:
                        'Sugestão de campos para controlar disponibilidade, baixa de estoque e comportamento do PDV.',
                    icon: Icons.storefront_rounded,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        _buildRuleSwitch(
                          theme: theme,
                          title: 'Controlar estoque',
                          subtitle:
                              'Baixa saldo nas vendas e mantém relatórios de movimentação confiáveis.',
                          value: _controlarEstoque,
                          onChanged: (bool value) {
                            setState(() {
                              _controlarEstoque = value;
                              if (!value) _venderComEstoqueNegativo = false;
                            });
                          },
                        ),
                        _buildRuleSwitch(
                          theme: theme,
                          title: 'Vender com estoque negativo',
                          subtitle:
                              'Permite concluir a venda mesmo quando o saldo do produto estiver abaixo de zero.',
                          value: _venderComEstoqueNegativo,
                          enabled: _controlarEstoque,
                          disabledHint: 'Disponível apenas quando o controle de estoque estiver ativo.',
                          onChanged: (bool value) {
                            setState(() => _venderComEstoqueNegativo = value);
                          },
                        ),
                        _buildRuleSwitch(
                          theme: theme,
                          title: 'Abertura de caixa obrigatória',
                          subtitle:
                              'Impede vendas, recebimentos e sangrias antes da abertura formal do caixa.',
                          value: _aberturaCaixaObrigatoria,
                          onChanged: (bool value) {
                            setState(() => _aberturaCaixaObrigatoria = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Descontos na venda',
                    subtitle:
                        'Campos sugeridos para liberar desconto no balcão sem perder governança operacional.',
                    icon: Icons.percent_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: <Widget>[
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Conceder desconto na hora da venda',
                              subtitle:
                                  'Permite que o operador aplique desconto diretamente no fluxo de venda.',
                              value: _concederDescontoNaVenda,
                              onChanged: (bool value) {
                                setState(() => _concederDescontoNaVenda = value);
                              },
                            ),
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Exigir justificativa do desconto',
                              subtitle:
                                  'Registra o motivo informado pelo operador para auditoria futura.',
                              value: _exigirJustificativaDesconto,
                              enabled: _concederDescontoNaVenda,
                              onChanged: (bool value) {
                                setState(() => _exigirJustificativaDesconto = value);
                              },
                            ),
                            _buildDropdownBox(
                              theme: theme,
                              label: 'Tipo de desconto permitido',
                              value: _tipoDescontoSelecionado,
                              items: _tiposDesconto,
                              enabled: _concederDescontoNaVenda,
                              onChanged: (String? value) {
                                if (value == null) return;
                                setState(() => _tipoDescontoSelecionado = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSliderBox(
                          theme: theme,
                          title:
                              'Limite máximo de desconto: ${_limiteDescontoPercentual.toStringAsFixed(0)}%',
                          subtitle:
                              'Campo sugerido para restringir descontos manuais conforme política do comércio.',
                          value: _limiteDescontoPercentual,
                          min: 0,
                          max: 50,
                          divisions: 10,
                          enabled: _concederDescontoNaVenda,
                          onChanged: (double value) {
                            setState(() => _limiteDescontoPercentual = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Comissão de colaboradores',
                    subtitle:
                        'Campos sugeridos para calcular comissão por venda, serviço técnico ou produto.',
                    icon: Icons.groups_2_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: <Widget>[
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Gerar comissão para colaborador',
                              subtitle:
                                  'Habilita regra futura para comissionamento por responsável da venda ou serviço.',
                              value: _gerarComissaoColaborador,
                              onChanged: (bool value) {
                                setState(() => _gerarComissaoColaborador = value);
                              },
                            ),
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Aplicar comissão em serviços',
                              subtitle:
                                  'Inclui mão de obra, assistência técnica e serviços avulsos no cálculo.',
                              value: _aplicarComissaoEmServicos,
                              enabled: _gerarComissaoColaborador,
                              onChanged: (bool value) {
                                setState(() => _aplicarComissaoEmServicos = value);
                              },
                            ),
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Aplicar comissão em produtos',
                              subtitle:
                                  'Inclui venda de peças, acessórios e mercadorias no cálculo da comissão.',
                              value: _aplicarComissaoEmProdutos,
                              enabled: _gerarComissaoColaborador,
                              onChanged: (bool value) {
                                setState(() => _aplicarComissaoEmProdutos = value);
                              },
                            ),
                            _buildDropdownBox(
                              theme: theme,
                              label: 'Base de cálculo da comissão',
                              value: _baseComissaoSelecionada,
                              items: _basesComissao,
                              enabled: _gerarComissaoColaborador,
                              onChanged: (String? value) {
                                if (value == null) return;
                                setState(() => _baseComissaoSelecionada = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSliderBox(
                          theme: theme,
                          title:
                              'Comissão padrão sugerida: ${_percentualComissaoPadrao.toStringAsFixed(0)}%',
                          subtitle:
                              'Valor inicial para novas regras; pode evoluir depois para política por colaborador, produto ou serviço.',
                          value: _percentualComissaoPadrao,
                          min: 0,
                          max: 30,
                          divisions: 15,
                          enabled: _gerarComissaoColaborador,
                          onChanged: (double value) {
                            setState(() => _percentualComissaoPadrao = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Unidades de medida',
                    subtitle:
                        'Campos sugeridos para limitar cadastro e venda de produtos às unidades aceitas pela empresa.',
                    icon: Icons.category_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: <Widget>[
                            _buildRuleSwitch(
                              theme: theme,
                              title: 'Permitir cadastro de produto apenas por unidade de medida',
                              subtitle:
                                  'Exige unidade informada e restringe o cadastro às categorias autorizadas abaixo.',
                              value: _produtoApenasComUnidadeMedida,
                              onChanged: (bool value) {
                                setState(() => _produtoApenasComUnidadeMedida = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Unidades autorizadas para vendas',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Categorias disponíveis: unidades, área, distância, volume, tempo, peso e moeda.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _unidadesDisponiveis.map((
                            _UnidadeMedidaOperacional unidade,
                          ) {
                            final bool selected =
                                _unidadesMedidaAutorizadas.contains(unidade.label);
                            return _buildUnitChoice(theme, unidade, selected);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildFooterActions(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    final int regrasAtivas = <bool>[
      _controlarEstoque,
      _venderComEstoqueNegativo,
      _concederDescontoNaVenda,
      _aberturaCaixaObrigatoria,
      _gerarComissaoColaborador,
      _produtoApenasComUnidadeMedida,
    ].where((bool value) => value).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withOpacity(0.10),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.62),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.rule_folder_outlined, color: theme.colorScheme.primary, size: 30),
          ),
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Regras operacionais sugeridas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Esta tela prepara os campos de negócio para estoque, venda, caixa, desconto, comissão e unidades de medida. Nenhuma integração com backend foi adicionada nesta etapa.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _buildSummaryPill(
            theme,
            icon: Icons.check_circle_outline_rounded,
            title: '$regrasAtivas regras ativas',
            subtitle: 'Mock local',
          ),
          _buildSummaryPill(
            theme,
            icon: Icons.straighten_rounded,
            title: '${_unidadesMedidaAutorizadas.length} unidades',
            subtitle: 'Autorizadas',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRuleSwitch({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    String? disabledHint,
  }) {
    final Color borderColor = enabled
        ? theme.colorScheme.outlineVariant
        : theme.colorScheme.outlineVariant.withOpacity(0.60);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    disabledHint != null && !enabled ? disabledHint : subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch(
              value: enabled ? value : false,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownBox({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: 430,
        child: DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
          items: items
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSliderBox({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: '${value.toStringAsFixed(0)}%',
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitChoice(
    ThemeData theme,
    _UnidadeMedidaOperacional unidade,
    bool selected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          if (selected) {
            _unidadesMedidaAutorizadas.remove(unidade.label);
          } else {
            _unidadesMedidaAutorizadas.add(unidade.label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.10)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.35)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(unidade.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          unidade.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unidade.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(
            width: 620,
            child: Text(
              'Pronto para evoluir: os campos foram desenhados como rascunho de regra operacional e ainda não persistem no backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Rascunho das regras operacionais validado localmente. Backend não integrado.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Validar rascunho'),
          ),
        ],
      ),
    );
  }
}

class _UnidadeMedidaOperacional {
  final String label;
  final String description;
  final IconData icon;

  const _UnidadeMedidaOperacional({
    required this.label,
    required this.description,
    required this.icon,
  });
}
