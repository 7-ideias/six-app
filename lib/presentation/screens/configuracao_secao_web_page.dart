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
  bool _permitirVendaCatalogoPorLink = true;
  bool _exigirClienteNoCatalogo = false;
  bool _permitirCompartilhamentoCatalogo = true;
  bool _cadastroGradeProdutos = true;
  bool _controlarEstoquePorVariacao = true;
  bool _exigirGradeParaProdutoVariavel = false;
  bool _vendaPorMesa = false;
  bool _mesaObrigatoria = true;
  bool _permitirTransferenciaMesa = true;
  bool _permitirJuntarMesas = true;
  bool _cobrarTaxaServicoMesa = true;
  bool _imprimirComandaMesa = true;
  bool _fecharMesaSomenteNoCaixa = true;
  bool _controlarEstoque = true;
  bool _venderComEstoqueNegativo = false;
  bool _concederDescontoNaVenda = true;
  bool _aberturaCaixaObrigatoria = true;
  bool _gerarComissaoColaborador = true;
  bool _produtoApenasComUnidadeMedida = true;
  bool _exigirJustificativaDesconto = true;
  bool _aplicarComissaoEmServicos = true;
  bool _aplicarComissaoEmProdutos = false;

  String _visibilidadeCatalogo = 'Público com link';
  String _validadeLinkCatalogo = 'Sem expiração';
  String _modoAtendimentoMesa = 'Mesa e balcão';
  String _statusInicialMesa = 'Livre';
  String _tipoDescontoSelecionado = 'Percentual e valor fixo';
  String _baseComissaoSelecionada = 'Valor líquido da venda';
  double _taxaServicoMesaPercentual = 10;
  double _limiteDescontoPercentual = 10;
  double _percentualComissaoPadrao = 5;

  final TextEditingController _nomeCatalogoController =
      TextEditingController(text: 'Catálogo Six Repair');
  final TextEditingController _slugCatalogoController =
      TextEditingController(text: 'six-repair-center');
  final TextEditingController _prefixoMesaController =
      TextEditingController(text: 'Mesa');
  final TextEditingController _quantidadeMesasController =
      TextEditingController(text: '20');

  final Set<String> _atributosGradeSelecionados = <String>{
    'Cor',
    'Tamanho',
    'Modelo',
  };

  final Set<String> _unidadesMedidaAutorizadas = <String>{
    'Unidade',
    'Área',
    'Distância',
    'Volume',
    'Tempo',
    'Peso',
  };

  static const List<String> _visibilidadesCatalogo = <String>[
    'Público com link',
    'Privado com aprovação',
    'Somente clientes cadastrados',
  ];

  static const List<String> _validadesCatalogo = <String>[
    'Sem expiração',
    '24 horas',
    '7 dias',
    '30 dias',
  ];

  static const List<String> _modosAtendimentoMesa = <String>[
    'Mesa e balcão',
    'Somente mesa',
    'Mesa, balcão e delivery',
    'Comanda individual',
  ];

  static const List<String> _statusMesa = <String>[
    'Livre',
    'Ocupada',
    'Aguardando pedido',
    'Em consumo',
    'Aguardando pagamento',
    'Fechada',
  ];

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

  static const List<_OpcaoOperacional> _atributosGradeDisponiveis =
      <_OpcaoOperacional>[
    _OpcaoOperacional(
      label: 'Cor',
      description: 'Permite variações como preto, branco, azul e outras cores comerciais.',
      icon: Icons.palette_outlined,
    ),
    _OpcaoOperacional(
      label: 'Tamanho',
      description: 'Útil para acessórios, peças e produtos com medidas comerciais.',
      icon: Icons.photo_size_select_small_rounded,
    ),
    _OpcaoOperacional(
      label: 'Voltagem',
      description: 'Diferencia itens 110V, 220V, bivolt ou padrões locais.',
      icon: Icons.bolt_outlined,
    ),
    _OpcaoOperacional(
      label: 'Modelo',
      description: 'Organiza produtos por modelo, geração ou linha compatível.',
      icon: Icons.devices_other_rounded,
    ),
    _OpcaoOperacional(
      label: 'Capacidade',
      description: 'Ajuda em variações como 64GB, 128GB, ml, kg ou pacote.',
      icon: Icons.data_usage_rounded,
    ),
    _OpcaoOperacional(
      label: 'Condição',
      description: 'Separa novo, usado, recondicionado ou peça de reposição.',
      icon: Icons.verified_outlined,
    ),
  ];

  static const List<_OpcaoOperacional> _unidadesDisponiveis = <_OpcaoOperacional>[
    _OpcaoOperacional(
      label: 'Unidade',
      description: 'Peças, acessórios e itens vendidos individualmente.',
      icon: Icons.inventory_2_outlined,
    ),
    _OpcaoOperacional(
      label: 'Área',
      description: 'm², cm² e serviços medidos por superfície.',
      icon: Icons.crop_square_rounded,
    ),
    _OpcaoOperacional(
      label: 'Distância',
      description: 'm, km e cobranças por deslocamento.',
      icon: Icons.straighten_rounded,
    ),
    _OpcaoOperacional(
      label: 'Volume',
      description: 'ml, l e insumos medidos por capacidade.',
      icon: Icons.water_drop_outlined,
    ),
    _OpcaoOperacional(
      label: 'Tempo',
      description: 'Hora técnica, diária, mensalidade e assinatura.',
      icon: Icons.schedule_rounded,
    ),
    _OpcaoOperacional(
      label: 'Peso',
      description: 'g, kg e materiais vendidos por massa.',
      icon: Icons.scale_rounded,
    ),
    _OpcaoOperacional(
      label: 'Moeda',
      description: 'Valores financeiros tratados como unidade de cobrança.',
      icon: Icons.paid_outlined,
    ),
  ];

  @override
  void dispose() {
    _nomeCatalogoController.dispose();
    _slugCatalogoController.dispose();
    _prefixoMesaController.dispose();
    _quantidadeMesasController.dispose();
    super.dispose();
  }

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
                  _buildCatalogoGradeCard(theme),
                  const SizedBox(height: 18),
                  _buildVendaPorMesaCard(theme),
                  const SizedBox(height: 18),
                  _buildEstoqueVendaCard(theme),
                  const SizedBox(height: 18),
                  _buildDescontoCard(theme),
                  const SizedBox(height: 18),
                  _buildComissaoCard(theme),
                  const SizedBox(height: 18),
                  _buildUnidadesMedidaCard(theme),
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
      _permitirVendaCatalogoPorLink,
      _cadastroGradeProdutos,
      _vendaPorMesa,
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
            width: 560,
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
                  'Esta tela prepara campos para catálogo por link, grade de produtos, venda por mesa, estoque, caixa, desconto, comissão e unidades de medida. Nenhuma integração com backend foi adicionada nesta etapa.',
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
            icon: Icons.table_restaurant_outlined,
            title: _vendaPorMesa ? 'Mesa ativa' : 'Mesa inativa',
            subtitle: _modoAtendimentoMesa,
          ),
          _buildSummaryPill(
            theme,
            icon: Icons.view_module_outlined,
            title: '${_atributosGradeSelecionados.length} atributos',
            subtitle: 'Grade',
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

  Widget _buildCatalogoGradeCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Catálogo por link e grade de produtos',
      subtitle:
          'Campos sugeridos para vender produtos por um link compartilhável e organizar variações de produto por grade.',
      icon: Icons.link_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _buildRuleSwitch(
                theme: theme,
                title: 'Permitir venda por catálogo de produtos por link',
                subtitle:
                    'Habilita uma vitrine compartilhável para o cliente consultar produtos e iniciar uma venda pelo link.',
                value: _permitirVendaCatalogoPorLink,
                onChanged: (bool value) {
                  setState(() => _permitirVendaCatalogoPorLink = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Exigir cliente identificado no catálogo',
                subtitle:
                    'Pede dados mínimos do cliente antes de concluir uma intenção de compra pelo link.',
                value: _exigirClienteNoCatalogo,
                enabled: _permitirVendaCatalogoPorLink,
                onChanged: (bool value) {
                  setState(() => _exigirClienteNoCatalogo = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Permitir compartilhamento do catálogo',
                subtitle:
                    'Prepara o fluxo para compartilhar o link por WhatsApp, email, SMS ou QR Code.',
                value: _permitirCompartilhamentoCatalogo,
                enabled: _permitirVendaCatalogoPorLink,
                onChanged: (bool value) {
                  setState(() => _permitirCompartilhamentoCatalogo = value);
                },
              ),
              _buildTextBox(
                theme: theme,
                label: 'Nome público do catálogo',
                controller: _nomeCatalogoController,
                enabled: _permitirVendaCatalogoPorLink,
              ),
              _buildTextBox(
                theme: theme,
                label: 'Identificador do link',
                controller: _slugCatalogoController,
                helperText: 'Exemplo futuro: /catalogo/six-repair-center',
                enabled: _permitirVendaCatalogoPorLink,
              ),
              _buildDropdownBox(
                theme: theme,
                label: 'Visibilidade do catálogo',
                value: _visibilidadeCatalogo,
                items: _visibilidadesCatalogo,
                enabled: _permitirVendaCatalogoPorLink,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _visibilidadeCatalogo = value);
                },
              ),
              _buildDropdownBox(
                theme: theme,
                label: 'Validade do link',
                value: _validadeLinkCatalogo,
                items: _validadesCatalogo,
                enabled: _permitirVendaCatalogoPorLink,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _validadeLinkCatalogo = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _buildRuleSwitch(
                theme: theme,
                title: 'Cadastro de grade de produtos',
                subtitle:
                    'Permite cadastrar variações como cor, tamanho, voltagem, modelo, capacidade ou condição.',
                value: _cadastroGradeProdutos,
                onChanged: (bool value) {
                  setState(() {
                    _cadastroGradeProdutos = value;
                    if (!value) {
                      _controlarEstoquePorVariacao = false;
                      _exigirGradeParaProdutoVariavel = false;
                    }
                  });
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Controlar estoque por variação',
                subtitle:
                    'Separa saldo por item da grade, como película preta, branca, P, M, G ou bivolt.',
                value: _controlarEstoquePorVariacao,
                enabled: _cadastroGradeProdutos,
                onChanged: (bool value) {
                  setState(() => _controlarEstoquePorVariacao = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Exigir grade para produto variável',
                subtitle:
                    'Impede que produtos com variações sejam cadastrados sem ao menos um atributo de grade.',
                value: _exigirGradeParaProdutoVariavel,
                enabled: _cadastroGradeProdutos,
                onChanged: (bool value) {
                  setState(() => _exigirGradeParaProdutoVariavel = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Atributos autorizados para grade',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Sugestão inicial de atributos que podem formar variações de produto.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _atributosGradeDisponiveis.map((_OpcaoOperacional atributo) {
              final bool selected = _atributosGradeSelecionados.contains(atributo.label);
              return _buildChoiceCard(
                theme,
                option: atributo,
                selected: selected,
                enabled: _cadastroGradeProdutos,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _atributosGradeSelecionados.remove(atributo.label);
                    } else {
                      _atributosGradeSelecionados.add(atributo.label);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVendaPorMesaCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Venda por mesa',
      subtitle:
          'Personalização para restaurante, lanchonete, bar ou atendimento em salão com mesa, comanda e fechamento no caixa.',
      icon: Icons.table_restaurant_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _buildRuleSwitch(
                theme: theme,
                title: 'Permitir venda por mesa',
                subtitle:
                    'Habilita atendimento por mesa para registrar consumo aberto até o fechamento da conta.',
                value: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _vendaPorMesa = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Mesa obrigatória na venda',
                subtitle:
                    'Exige seleção de mesa antes de lançar itens em operações de salão.',
                value: _mesaObrigatoria,
                enabled: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _mesaObrigatoria = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Permitir transferência de mesa',
                subtitle:
                    'Permite mover consumo de uma mesa para outra sem perder os itens lançados.',
                value: _permitirTransferenciaMesa,
                enabled: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _permitirTransferenciaMesa = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Permitir juntar mesas',
                subtitle:
                    'Permite combinar mesas para grupos, eventos ou atendimento compartilhado.',
                value: _permitirJuntarMesas,
                enabled: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _permitirJuntarMesas = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Imprimir comanda da mesa',
                subtitle:
                    'Prepara emissão de comanda para cozinha, balcão ou conferência do cliente.',
                value: _imprimirComandaMesa,
                enabled: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _imprimirComandaMesa = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Fechar mesa somente no caixa',
                subtitle:
                    'Mantém o fechamento centralizado no caixa para reduzir divergência de recebimento.',
                value: _fecharMesaSomenteNoCaixa,
                enabled: _vendaPorMesa,
                onChanged: (bool value) {
                  setState(() => _fecharMesaSomenteNoCaixa = value);
                },
              ),
              _buildDropdownBox(
                theme: theme,
                label: 'Modo de atendimento',
                value: _modoAtendimentoMesa,
                items: _modosAtendimentoMesa,
                enabled: _vendaPorMesa,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _modoAtendimentoMesa = value);
                },
              ),
              _buildDropdownBox(
                theme: theme,
                label: 'Status inicial da mesa',
                value: _statusInicialMesa,
                items: _statusMesa,
                enabled: _vendaPorMesa,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _statusInicialMesa = value);
                },
              ),
              _buildTextBox(
                theme: theme,
                label: 'Prefixo de identificação',
                controller: _prefixoMesaController,
                helperText: 'Exemplo: Mesa 01, Balcão 02 ou Comanda 15',
                enabled: _vendaPorMesa,
              ),
              _buildTextBox(
                theme: theme,
                label: 'Quantidade inicial de mesas',
                controller: _quantidadeMesasController,
                keyboardType: TextInputType.number,
                enabled: _vendaPorMesa,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRuleSwitch(
            theme: theme,
            title: 'Cobrar taxa de serviço',
            subtitle:
                'Sugere percentual de serviço no fechamento da mesa, sem alterar valores no backend nesta etapa.',
            value: _cobrarTaxaServicoMesa,
            enabled: _vendaPorMesa,
            onChanged: (bool value) {
              setState(() => _cobrarTaxaServicoMesa = value);
            },
          ),
          const SizedBox(height: 18),
          _buildSliderBox(
            theme: theme,
            title: 'Taxa de serviço sugerida: ${_taxaServicoMesaPercentual.toStringAsFixed(0)}%',
            subtitle:
                'Campo pensado para restaurantes e lanchonetes que trabalham com taxa de atendimento no fechamento da mesa.',
            value: _taxaServicoMesaPercentual,
            min: 0,
            max: 20,
            divisions: 20,
            enabled: _vendaPorMesa && _cobrarTaxaServicoMesa,
            onChanged: (double value) {
              setState(() => _taxaServicoMesaPercentual = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstoqueVendaCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Estoque, venda e caixa',
      subtitle:
          'Sugestão de campos para controlar disponibilidade, baixa de estoque, venda negativa e abertura de caixa.',
      icon: Icons.storefront_rounded,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _buildRuleSwitch(
            theme: theme,
            title: 'Controlar estoque',
            subtitle: 'Baixa saldo nas vendas e mantém relatórios de movimentação confiáveis.',
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
            subtitle: 'Impede vendas, recebimentos e sangrias antes da abertura formal do caixa.',
            value: _aberturaCaixaObrigatoria,
            onChanged: (bool value) {
              setState(() => _aberturaCaixaObrigatoria = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescontoCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Descontos na venda',
      subtitle: 'Campos sugeridos para liberar desconto no balcão sem perder governança operacional.',
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
                subtitle: 'Permite que o operador aplique desconto diretamente no fluxo de venda.',
                value: _concederDescontoNaVenda,
                onChanged: (bool value) {
                  setState(() => _concederDescontoNaVenda = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Exigir justificativa do desconto',
                subtitle: 'Registra o motivo informado pelo operador para auditoria futura.',
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
            title: 'Limite máximo de desconto: ${_limiteDescontoPercentual.toStringAsFixed(0)}%',
            subtitle: 'Campo sugerido para restringir descontos manuais conforme política do comércio.',
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
    );
  }

  Widget _buildComissaoCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Comissão de colaboradores',
      subtitle: 'Campos sugeridos para calcular comissão por venda, serviço técnico ou produto.',
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
                subtitle: 'Inclui mão de obra, assistência técnica e serviços avulsos no cálculo.',
                value: _aplicarComissaoEmServicos,
                enabled: _gerarComissaoColaborador,
                onChanged: (bool value) {
                  setState(() => _aplicarComissaoEmServicos = value);
                },
              ),
              _buildRuleSwitch(
                theme: theme,
                title: 'Aplicar comissão em produtos',
                subtitle: 'Inclui venda de peças, acessórios e mercadorias no cálculo da comissão.',
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
            title: 'Comissão padrão sugerida: ${_percentualComissaoPadrao.toStringAsFixed(0)}%',
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
    );
  }

  Widget _buildUnidadesMedidaCard(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Unidades de medida',
      subtitle: 'Campos sugeridos para limitar cadastro e venda de produtos às unidades aceitas pela empresa.',
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
            children: _unidadesDisponiveis.map((_OpcaoOperacional unidade) {
              final bool selected = _unidadesMedidaAutorizadas.contains(unidade.label);
              return _buildChoiceCard(
                theme,
                option: unidade,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _unidadesMedidaAutorizadas.remove(unidade.label);
                    } else {
                      _unidadesMedidaAutorizadas.add(unidade.label);
                    }
                  });
                },
              );
            }).toList(),
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
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

  Widget _buildTextBox({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: 430,
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
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

  Widget _buildChoiceCard(
    ThemeData theme, {
    required _OpcaoOperacional option,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
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
                child: Icon(option.icon, color: theme.colorScheme.primary),
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
                            option.label,
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
                      option.description,
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
            width: 680,
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

class _OpcaoOperacional {
  final String label;
  final String description;
  final IconData icon;

  const _OpcaoOperacional({
    required this.label,
    required this.description,
    required this.icon,
  });
}
