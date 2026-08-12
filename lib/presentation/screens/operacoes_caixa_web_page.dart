import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_completo_movimentos_models.dart';
import '../../data/models/caixa_models.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/empresa_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';

class OperacoesCaixaWebPage extends StatefulWidget {
  const OperacoesCaixaWebPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OperacoesCaixaWebPage> createState() => _OperacoesCaixaWebPageState();
}

class _OperacoesCaixaWebPageState extends State<OperacoesCaixaWebPage> {
  final CaixaService _caixaService = CaixaModule.caixaService;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _trocoInicialController = TextEditingController(
    text: '200,00',
  );
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _fechamentoDinheiroController =
      TextEditingController();
  final TextEditingController _fechamentoPixController =
      TextEditingController();
  final TextEditingController _fechamentoCartaoController =
      TextEditingController();
  final TextEditingController _fechamentoObservacaoController =
      TextEditingController();

  bool _isLoading = false;
  bool _vincularVenda = false;
  bool _mostrarPainelFechamento = false;
  bool _mostrarApenasHoje = false;

  CaixaSessao? _sessaoAtual;
  CaixaOuGuiche? _caixaSelecionado;
  OperacaoCaixaTipo? _tipoSelecionado;
  TiposRecebimento? _tipoRecebimentoSelecionado;
  InformacoesCaixaComSomatorioResponse? _movimentosComSomatorio;
  ResumoCaixa? _resumo;

  List<CaixaOuGuiche> _caixasDisponiveis = <CaixaOuGuiche>[];
  List<TiposRecebimento> _tiposRecebimento = <TiposRecebimento>[];
  List<MovimentoCaixa> _movimentos = <MovimentoCaixa>[];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _trocoInicialController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _referenciaController.dispose();
    _fechamentoDinheiroController.dispose();
    _fechamentoPixController.dispose();
    _fechamentoCartaoController.dispose();
    _fechamentoObservacaoController.dispose();
    super.dispose();
  }

  bool get _temCaixaAberto =>
      _sessaoAtual != null && _sessaoAtual!.status.toLowerCase() == 'aberta';

  Future<void> _carregarDadosIniciais({String? idCaixaPreferencial}) async {
    setState(() => _isLoading = true);
    try {
      final informacoesBasicas =
          await _caixaService.buscarInformacoesBasicasDoCaixa();

      if (mounted && informacoesBasicas.regionalizacao != null) {
        await context
            .read<LocaleSettingsProvider>()
            .atualizarConfiguracaoDaEmpresaPorResponse(
              informacoesBasicas.regionalizacao!,
            );
      }

      final sessao = await _caixaService.buscarSessaoAtual();
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

      final caixas =
          informacoesBasicas.caixaOuGuiche.isNotEmpty
              ? informacoesBasicas.caixaOuGuiche
              : informacoesBasicas.caixas
                  .map((nome) => CaixaOuGuiche(id: nome, nome: nome))
                  .toList(growable: false);

      final tiposAtivos = informacoesBasicas.tiposRecebimento
          .where((item) => item.ativo)
          .toList(growable: false)
        ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

      final idPreferencial = idCaixaPreferencial ?? _caixaSelecionado?.id;
      CaixaOuGuiche? caixaPreferencial;
      if (idPreferencial != null) {
        for (final caixa in caixas) {
          if (caixa.id == idPreferencial) {
            caixaPreferencial = caixa;
            break;
          }
        }
      }

      TiposRecebimento? tipoPreferencial;
      final codigoAtual = _tipoRecebimentoSelecionado?.codigoTipo;
      if (codigoAtual != null) {
        for (final tipo in tiposAtivos) {
          if (tipo.codigoTipo == codigoAtual) {
            tipoPreferencial = tipo;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _caixasDisponiveis = caixas;
        _tiposRecebimento = informacoesBasicas.tiposRecebimento;
        _caixaSelecionado =
            caixaPreferencial ??
            (_caixasDisponiveis.isNotEmpty ? _caixasDisponiveis.first : null);
        _tipoRecebimentoSelecionado =
            tipoPreferencial ??
            (tiposAtivos.isNotEmpty ? tiposAtivos.first : null);
        _sessaoAtual = sessao;
        _movimentos = <MovimentoCaixa>[];
        _movimentosComSomatorio = null;
        _resumo = null;
      });

      if (sessao != null) {
        await _carregarMovimentosEResumo(sessao.idSessaoCaixa);
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados do caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarMovimentosEResumo(String idCaixaSessao) async {
    try {
      final movimentos = await _caixaService.listarMovimentacoes(idCaixaSessao);
      if (!mounted) return;
      setState(() => _movimentos = movimentos);
    } catch (e) {
      _mostrarErro('Erro ao carregar movimentações: $e');
    }

    try {
      final movimentosComSomatorio = await _caixaService
          .buscarResumoDeMovimentosComSomatorio(idCaixaSessao);
      if (!mounted) return;
      setState(() {
        _movimentosComSomatorio = movimentosComSomatorio;
        if (_movimentos.isEmpty &&
            movimentosComSomatorio.movimento.isNotEmpty) {
          _movimentos = movimentosComSomatorio.movimento;
        }
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar resumo de movimentações: $e');
    }

    try {
      final resumo = await _caixaService.buscarResumo(idCaixaSessao);
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (e) {
      _mostrarErro('Erro ao carregar resumo do caixa: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _mostrarAvisoCaixaNaoAberto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Antes de lançar operações, faça a abertura do caixa.'),
      ),
    );
  }

  void _sairDaTela() {
    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bool podeFecharTela = widget.onBack != null || !widget.embedded;
    final Widget content = Focus(
      autofocus: podeFecharTela,
      child: _buildContent(context),
    );
    final Widget closeAwareContent = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _SairDaTelaIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SairDaTelaIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              _sairDaTela();
              return null;
            },
          ),
        },
        child: content,
      ),
    );

    if (widget.embedded) {
      return podeFecharTela ? closeAwareContent : content;
    }

    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(child: closeAwareContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final initialLoading =
        _isLoading && _sessaoAtual == null && _resumo == null;
    final Widget body =
        initialLoading
            ? KeyedSubtree(
              key: const ValueKey<String>('operacoes-caixa-loading'),
              child: _buildLoading(theme),
            )
            : KeyedSubtree(
              key: const ValueKey<String>('operacoes-caixa-content'),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1120;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SixWebEntry(order: 0, child: _buildKpis(theme)),
                        const SizedBox(height: 18),
                        if (!_temCaixaAberto)
                          SixWebEntry(
                            order: 1,
                            child: _buildPainelAbertura(theme),
                          )
                        else if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    SixWebEntry(
                                      order: 1,
                                      child: _buildContextoOperacao(theme),
                                    ),
                                    const SizedBox(height: 12),
                                    SixWebEntry(
                                      order: 2,
                                      child: _buildAtalhosOperacao(theme),
                                    ),
                                    const SizedBox(height: 12),
                                    SixWebEntry(
                                      order: 3,
                                      child: _buildFormularioMovimento(theme),
                                    ),
                                    if (_mostrarPainelFechamento) ...<Widget>[
                                      const SizedBox(height: 12),
                                      SixWebEntry(
                                        order: 4,
                                        child: _buildPainelFechamento(theme),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    SixWebEntry(
                                      order: 5,
                                      child: _buildHistorico(theme),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 390,
                                child: SixWebEntry(
                                  order: 4,
                                  child: _buildResumoLateral(theme),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: <Widget>[
                              SixWebEntry(
                                order: 1,
                                child: _buildContextoOperacao(theme),
                              ),
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 2,
                                child: _buildResumoLateral(theme),
                              ),
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 3,
                                child: _buildAtalhosOperacao(theme),
                              ),
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 4,
                                child: _buildFormularioMovimento(theme),
                              ),
                              if (_mostrarPainelFechamento) ...<Widget>[
                                const SizedBox(height: 12),
                                SixWebEntry(
                                  order: 5,
                                  child: _buildPainelFechamento(theme),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SixWebEntry(
                                order: 6,
                                child: _buildHistorico(theme),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            );

    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          _buildHeader(theme),
          Expanded(
            child: AnimatedContainer(
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              color: tokens.workspaceBackground,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: _softBox(theme),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Text('Carregando operações de caixa...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final empresa = EmpresaProvider().empresa?.nomeFantasia ?? 'Empresa';
    final movimentos = _resumo?.quantidadeMovimentos ?? _movimentos.length;
    return SixWebDashboardHeader(
      icon: Icons.point_of_sale_rounded,
      title: 'Operações de caixa',
      subtitle:
          '$empresa • $movimentos movimento(s) • ${_temCaixaAberto ? 'Caixa aberto' : 'Aguardando abertura'}',
      onBack: widget.embedded && widget.onBack == null ? null : _sairDaTela,
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _carregarDadosIniciais(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeData theme) {
    final resumo = _resumo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final width =
            compact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 36) / 4).clamp(210.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(
              theme,
              width: width,
              label: 'Saldo esperado',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'saldo-esperado',
                value: resumo?.saldoEsperado ?? 0,
                highlight: true,
              ),
              helper:
                  _temCaixaAberto ? 'Caixa em operação' : 'Aguardando abertura',
              icon: Icons.account_balance_wallet_outlined,
              highlight: true,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Entradas',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'total-entradas',
                value: resumo?.totalEntradas ?? 0,
              ),
              helper: 'Recebimentos e suprimentos',
              icon: Icons.south_west_rounded,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Saídas',
              value: _animatedCurrencyText(
                theme,
                animationKey: 'total-saidas',
                value: resumo?.totalSaidas ?? 0,
              ),
              helper: 'Sangrias e despesas',
              icon: Icons.north_east_rounded,
            ),
            _summaryCard(
              theme,
              width: width,
              label: 'Movimentos',
              value: Text(
                '${resumo?.quantidadeMovimentos ?? _movimentos.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              helper:
                  _mostrarApenasHoje
                      ? 'Filtro de hoje ativo'
                      : 'Todos visíveis',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required Widget value,
    required String helper,
    required IconData icon,
    bool highlight = false,
  }) {
    final colorScheme = theme.colorScheme;
    final tokens = WebThemeTokens.of(context);
    final Color accent = highlight ? tokens.info : colorScheme.primary;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? tokens.surfaceMuted : tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ? tokens.selectedBorder : tokens.cardBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    highlight ? tokens.selectedBackground : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  value,
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedCurrencyText(
    ThemeData theme, {
    required String animationKey,
    required double value,
    bool highlight = false,
    double fontSize = 20,
    TextAlign textAlign = TextAlign.end,
  }) {
    final regionalizacao = context.watch<LocaleSettingsProvider>();
    final color = WebThemeTokens.of(context).primaryText;
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(
        '$animationKey:${regionalizacao.currencyCode}:${value.toStringAsFixed(4)}',
      ),
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          regionalizacao.formatCurrency(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }

  Widget _buildPainelAbertura(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Abertura de caixa',
            subtitle:
                'Defina o caixa, o troco inicial e inicie a operação do dia.',
            icon: Icons.lock_open_rounded,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 340,
                label: 'Caixa / guichê',
                child: _buildDropdown<CaixaOuGuiche>(
                  theme,
                  value: _caixaSelecionado,
                  items: _caixasDisponiveis,
                  onChanged:
                      (value) => setState(() => _caixaSelecionado = value),
                  itemLabel: (item) => item.nome,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 220,
                label: 'Troco inicial',
                child: _buildTextField(
                  theme,
                  controller: _trocoInicialController,
                  hint: '0,00',
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 280,
                label: 'Colaborador responsável',
                child: _buildReadOnlyField(
                  theme,
                  UsuarioProvider().usuario?.nomeDeGuerra ?? '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isLoading ? null : _abrirCaixa,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Abrir caixa'),
          ),
        ],
      ),
    );
  }

  Widget _buildContextoOperacao(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          _miniMetric(
            theme,
            title: 'Sessão',
            value: _sessaoAtual?.idSessaoCaixa ?? '--',
            icon: Icons.badge_outlined,
          ),
          _miniMetric(
            theme,
            title: 'Caixa',
            value: _sessaoAtual?.nomeCaixa ?? '--',
            icon: Icons.store_mall_directory_outlined,
          ),
          _miniMetric(
            theme,
            title: 'Abertura',
            value: _formatDateTime(_sessaoAtual?.dataHoraAbertura),
            icon: Icons.schedule_rounded,
          ),
          _miniMetric(
            theme,
            title: 'Troco inicial',
            valueWidget: _animatedCurrencyText(
              theme,
              animationKey: 'contexto-troco-inicial',
              value: _sessaoAtual?.valorAbertura ?? 0,
              fontSize: 14.5,
              textAlign: TextAlign.start,
            ),
            icon: Icons.account_balance_wallet_outlined,
          ),
          _miniMetric(
            theme,
            title: 'Status',
            value: _labelSessao(_sessaoAtual?.status),
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    ThemeData theme, {
    required String title,
    String? value,
    Widget? valueWidget,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 270),
      padding: const EdgeInsets.all(14),
      decoration: _softBox(theme),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                valueWidget ??
                    Text(
                      value ?? '--',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhosOperacao(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    final cards = <_AtalhoOperacaoData>[
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.suprimento,
        titulo: 'Suprimento',
        descricao: 'Adicionar valores ao caixa para reforço operacional.',
        icone: Icons.add_card_rounded,
        cor: tokens.financialPositive,
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.sangria,
        titulo: 'Sangria',
        descricao: 'Retirar excesso de numerário para segurança.',
        icone: Icons.outbox_rounded,
        cor: tokens.financialNegative,
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.retiradaDespesa,
        titulo: 'Despesa',
        descricao: 'Registrar saída operacional com justificativa.',
        icone: Icons.receipt_long_rounded,
        cor: tokens.financialNegative,
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.ajuste,
        titulo: 'Ajuste',
        descricao: 'Corrigir diferenças operacionais com rastreabilidade.',
        icone: Icons.tune_rounded,
        cor: tokens.info,
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.recebimentoAvulso,
        titulo: 'Recebimento avulso',
        descricao: 'Entrada operacional sem vínculo direto com venda.',
        icone: Icons.arrow_downward_rounded,
        cor: tokens.financialPositive,
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.pagamentoAvulso,
        titulo: 'Pagamento avulso',
        descricao: 'Saída operacional pontual com justificativa.',
        icone: Icons.arrow_upward_rounded,
        cor: tokens.financialNegative,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Ações rápidas',
            subtitle:
                'Selecione a operação para preencher o formulário com o contexto adequado.',
            icon: Icons.bolt_outlined,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth < 720
                      ? constraints.maxWidth
                      : ((constraints.maxWidth - 32) / 3).clamp(220.0, 320.0);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    cards
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: _operationCard(theme, item),
                          ),
                        )
                        .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  if (!_temCaixaAberto) {
                    _mostrarAvisoCaixaNaoAberto();
                    return;
                  }
                  setState(() {
                    _mostrarPainelFechamento = !_mostrarPainelFechamento;
                    _tipoSelecionado = null;
                  });
                },
                icon: const Icon(Icons.rule_folder_outlined),
                label: Text(
                  _mostrarPainelFechamento
                      ? 'Ocultar fechamento'
                      : 'Preparar fechamento',
                ),
              ),
              OutlinedButton.icon(
                onPressed: _confirmarEncerramentoSessao,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Encerrar sessão'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _operationCard(ThemeData theme, _AtalhoOperacaoData item) {
    final selected = _tipoSelecionado == item.tipo;
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: selected ? tokens.selectedBackground : tokens.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _tipoSelecionado = item.tipo;
            _mostrarPainelFechamento = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(item.icone, color: item.cor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        height: 1.35,
                        fontSize: 12.6,
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

  Widget _buildFormularioMovimento(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Lançamento operacional',
            subtitle:
                _tipoSelecionado == null
                    ? 'Escolha uma ação rápida acima para orientar o lançamento.'
                    : 'Preencha os dados da operação ${_labelTipo(_tipoSelecionado!)}.',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 260,
                label: 'Tipo da operação',
                child: _buildWebSelectorDropdown<OperacaoCaixaTipo>(
                  theme,
                  menuWidth: 260,
                  value: _tipoSelecionado,
                  items: OperacaoCaixaTipo.values
                      .where((e) => e != OperacaoCaixaTipo.fechamentoCaixa)
                      .toList(growable: false),
                  onSelected:
                      (value) => setState(() => _tipoSelecionado = value),
                  itemLabel: _labelTipo,
                  itemSubtitle: (item) => item.codigoApi,
                  itemIcon: _iconeTipo,
                  hint: 'Selecione',
                  emptyMessage: 'Nenhum tipo disponível.',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 220,
                label: 'Valor',
                child: _buildTextField(
                  theme,
                  controller: _valorController,
                  hint: '0,00',
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 280,
                label: 'Forma relacionada',
                child: _buildWebSelectorDropdown<TiposRecebimento>(
                  theme,
                  menuWidth: 280,
                  value: _tipoRecebimentoSelecionado,
                  items: _tiposRecebimentoAtivosOrdenados(),
                  onSelected:
                      (value) =>
                          setState(() => _tipoRecebimentoSelecionado = value),
                  itemLabel:
                      (item) => _descricaoTipoRecebimentoConfigurado(item),
                  itemSubtitle: (item) => item.codigoTipo,
                  itemIcon: (_) => Icons.payments_outlined,
                  hint: 'Selecione',
                  emptyMessage: 'Nenhuma forma relacionada ativa.',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 240,
                label: 'Caixa / guichê',
                child: _buildReadOnlyField(
                  theme,
                  _sessaoAtual?.nomeCaixa ?? '--',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 260,
                label: 'Referência / comprovante',
                child: _buildTextField(
                  theme,
                  controller: _referenciaController,
                  hint: 'Ex.: MOV-001',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 540,
                label: 'Observação',
                child: TextField(
                  controller: _observacaoController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    theme,
                    hint: 'Descreva o motivo da movimentação com clareza.',
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: CheckboxListTile(
                  value: _vincularVenda,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Possui vínculo com venda'),
                  subtitle: const Text(
                    'Use em estornos ou situações relacionadas a atendimento anterior.',
                  ),
                  onChanged:
                      (value) =>
                          setState(() => _vincularVenda = value ?? false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isLoading ? null : _salvarMovimento,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Registrar movimentação'),
              ),
              OutlinedButton.icon(
                onPressed: _limparFormularioMovimento,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Limpar formulário'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico(ThemeData theme) {
    final movimentosVisiveis =
        _mostrarApenasHoje
            ? _movimentos
                .where((m) => _isSameDay(m.dataHoraMovimento, DateTime.now()))
                .toList(growable: false)
            : _movimentos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionHeader(
                  theme,
                  title: 'Histórico de movimentações',
                  subtitle: '${movimentosVisiveis.length} registros visíveis.',
                  icon: Icons.history_rounded,
                ),
              ),
              FilterChip(
                label: const Text('Somente hoje'),
                selected: _mostrarApenasHoje,
                onSelected:
                    (value) => setState(() => _mostrarApenasHoje = value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (movimentosVisiveis.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _softBox(theme),
              child: const Text(
                'Nenhuma movimentação registrada após a abertura do caixa.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: movimentosVisiveis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (context, index) =>
                      _buildMovimentoCard(theme, movimentosVisiveis[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildMovimentoCard(ThemeData theme, MovimentoCaixa movimento) {
    final cor = _corPorNatureza(movimento.natureza);
    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final main = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    cor.withValues(alpha: 0.10),
                    tokens.cardBackground,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  movimento.natureza.toLowerCase() == 'entrada'
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: cor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          _labelTipo(movimento.tipoMovimento),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _statusPill(
                          _labelStatusMovimento(movimento.status),
                          _corPorStatus(movimento.status),
                        ),
                        _statusPill(_labelNatureza(movimento.natureza), cor),
                        _statusPill(forma, tokens.info),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      movimento.observacao.isEmpty
                          ? 'Sem observação informada.'
                          : movimento.observacao,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: <Widget>[
                        _inlineInfo(
                          theme,
                          Icons.person_outline_rounded,
                          movimento.nomeColaborador,
                        ),
                        _inlineInfo(theme, Icons.payments_outlined, forma),
                        _inlineInfo(
                          theme,
                          Icons.receipt_long_outlined,
                          movimento.referencia.isEmpty
                              ? 'Sem referência'
                              : movimento.referencia,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _formatCurrency(movimento.valor),
                style: TextStyle(
                  color: cor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(movimento.dataHoraMovimento),
                style: TextStyle(
                  color: tokens.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Forma relacionada: $forma')),
                      );
                    },
                    child: const Text('Detalhes'),
                  ),
                  if (movimento.status.toLowerCase() != 'cancelada')
                    OutlinedButton(
                      onPressed: () => _cancelarMovimento(movimento),
                      child: const Text('Cancelar'),
                    ),
                ],
              ),
            ],
          );

          return compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[main, const SizedBox(height: 12), actions],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: main),
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 210),
                    child: actions,
                  ),
                ],
              );
        },
      ),
    );
  }

  Widget _buildResumoLateral(ThemeData theme) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader(
                theme,
                title: 'Conferência por forma',
                subtitle: 'Resumo pelos tipos configurados no caixa.',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 14),
              ..._linhasResumoPorTipoRecebimento().map(
                (linha) => _buildResumoSecundario(
                  theme,
                  label: linha.label,
                  value: linha.valor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader(
                theme,
                title: 'Checklist operacional',
                subtitle: 'Conferência rápida da sessão.',
                icon: Icons.rule_folder_outlined,
              ),
              const SizedBox(height: 14),
              _checkItem(
                theme,
                checked: _temCaixaAberto,
                title: 'Caixa aberto',
              ),
              _checkItem(
                theme,
                checked: _movimentos.isNotEmpty,
                title: 'Movimentações registradas',
              ),
              _checkItem(
                theme,
                checked: _movimentos.any(
                  (m) => m.status.toLowerCase() == 'pendenteconferencia',
                ),
                title: 'Há pendências para conferência',
              ),
              _checkItem(
                theme,
                checked: _mostrarPainelFechamento,
                title: 'Fechamento preparado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPainelFechamento(ThemeData theme) {
    final resumo = _resumo;
    if (resumo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(
            theme,
            title: 'Fechamento de caixa',
            subtitle:
                'Informe os valores apurados para comparar com o saldo esperado.',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(
                theme,
                width: 230,
                label:
                    '${_labelTipoRecebimentoPorCodigo('tipo1', 'Dinheiro')} apurado',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoDinheiroController,
                  hint: _formatCurrency(resumo.totalDinheiro),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 230,
                label:
                    '${_labelTipoRecebimentoPorCodigo('tipo2', 'Pix')} apurado',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoPixController,
                  hint: _formatCurrency(resumo.totalPix),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              _buildFieldBox(
                theme,
                width: 250,
                label: 'Cartões apurados',
                child: _buildTextField(
                  theme,
                  controller: _fechamentoCartaoController,
                  hint: _formatCurrency(
                    resumo.totalCartaoCredito + resumo.totalCartaoDebito,
                  ),
                  prefix: _currencyInputPrefix(),
                ),
              ),
              SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _softBox(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saldo esperado',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _animatedCurrencyText(
                        theme,
                        animationKey: 'fechamento-saldo-esperado',
                        value: resumo.saldoEsperado,
                        fontSize: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldBox(
            theme,
            width: double.infinity,
            label: 'Observação do fechamento',
            child: TextField(
              controller: _fechamentoObservacaoController,
              maxLines: 3,
              decoration: _inputDecoration(
                theme,
                hint:
                    'Detalhe divergências, conferências e observações finais.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isLoading ? null : _fecharCaixa,
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Concluir fechamento'),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => setState(() => _mostrarPainelFechamento = false),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar fechamento'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tokens.selectedBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tokens.info, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoSecundario(
    ThemeData theme, {
    required String label,
    required double value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _animatedCurrencyText(
                theme,
                animationKey: 'resumo-tipo-$label',
                value: value,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(
    ThemeData theme, {
    required bool checked,
    required String title,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? tokens.success : tokens.statusNeutral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.10),
          tokens.cardBackground,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _inlineInfo(ThemeData theme, IconData icon, String text) {
    final tokens = WebThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: tokens.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldBox(
    ThemeData theme, {
    required double width,
    required String label,
    required Widget child,
  }) {
    final tokens = WebThemeTokens.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: tokens.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
    return width == double.infinity
        ? SizedBox(width: double.infinity, child: content)
        : SizedBox(width: width, child: content);
  }

  Widget _buildReadOnlyField(ThemeData theme, String value) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBox(theme, radius: 16),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String hint,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(theme, hint: hint, prefixText: prefix),
    );
  }

  Widget _buildDropdown<T>(
    ThemeData theme, {
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T item) itemLabel,
    String? hint,
  }) {
    final tokens = WebThemeTokens.of(context);
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      dropdownColor: tokens.menuBackground,
      style: TextStyle(color: tokens.primaryText, fontWeight: FontWeight.w700),
      decoration: _inputDecoration(theme, hint: hint),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWebSelectorDropdown<T>(
    ThemeData theme, {
    required double menuWidth,
    required T? value,
    required List<T> items,
    required void Function(T) onSelected,
    required String Function(T item) itemLabel,
    required String Function(T item) itemSubtitle,
    required IconData Function(T item) itemIcon,
    required String hint,
    required String emptyMessage,
  }) {
    final tokens = WebThemeTokens.of(context);
    final T? selectedValue = items.contains(value) ? value : null;
    final String selectedLabel =
        selectedValue == null ? hint : itemLabel(selectedValue);
    final Color borderColor =
        selectedValue == null ? tokens.cardBorder : tokens.selectedBorder;

    return Semantics(
      button: true,
      label: selectedValue == null ? hint : selectedLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final selected = await _showWebSelectorDialog<T>(
            menuWidth: menuWidth,
            selected: selectedValue,
            items: items,
            itemLabel: itemLabel,
            itemSubtitle: itemSubtitle,
            itemIcon: itemIcon,
            emptyMessage: emptyMessage,
          );
          if (!mounted || selected == null) return;
          onSelected(selected);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tokens.inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selectedValue == null ? 1 : 1.2,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selectedValue == null
                    ? Icons.tune_rounded
                    : itemIcon(selectedValue),
                color: selectedValue == null ? tokens.mutedText : tokens.info,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selectedValue == null
                            ? tokens.secondaryText
                            : tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: tokens.mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<T?> _showWebSelectorDialog<T>({
    required double menuWidth,
    required T? selected,
    required List<T> items,
    required String Function(T item) itemLabel,
    required String Function(T item) itemSubtitle,
    required IconData Function(T item) itemIcon,
    required String emptyMessage,
  }) {
    final tokens = WebThemeTokens.of(context);
    return showDialog<T>(
      context: context,
      barrierColor: tokens.workspaceBackground.withValues(alpha: 0.72),
      builder:
          (context) => _WebSelectorDialog<T>(
            width: menuWidth,
            selected: selected,
            items: items,
            itemLabel: itemLabel,
            itemSubtitle: itemSubtitle,
            itemIcon: itemIcon,
            emptyMessage: emptyMessage,
          ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String? hint,
    String? prefixText,
  }) {
    final tokens = WebThemeTokens.of(context);
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: tokens.inputBackground,
      hintStyle: TextStyle(color: tokens.mutedText),
      prefixStyle: TextStyle(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    final tokens = WebThemeTokens.of(context);
    return BoxDecoration(
      color: tokens.cardBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: tokens.cardBorder),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.045),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  BoxDecoration _softBox(ThemeData theme, {double radius = 18}) {
    final tokens = WebThemeTokens.of(context);
    return BoxDecoration(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tokens.cardBorder),
    );
  }

  List<TiposRecebimento> _tiposRecebimentoAtivosOrdenados() {
    return _tiposRecebimento.where((item) => item.ativo).toList(growable: false)
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
  }

  String _descricaoTipoRecebimentoConfigurado(TiposRecebimento tipo) {
    final descricao = tipo.descricaoExibicao.trim();
    return descricao.isNotEmpty
        ? descricao
        : _labelTipoRecebimentoPorCodigo(tipo.codigoTipo, tipo.codigoTipo);
  }

  String _descricaoTipoRecebimentoMovimento(MovimentoCaixa movimento) {
    final descricao = movimento.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    return _labelTipoRecebimentoPorCodigo(
      movimento.codigoTipoRecebimento,
      movimento.descricao.trim().isNotEmpty
          ? movimento.descricao.trim()
          : 'Forma não informada',
    );
  }

  String _labelTipoRecebimentoPorCodigo(String codigoTipo, String fallback) {
    for (final tipo in _tiposRecebimento) {
      if (tipo.codigoTipo.toLowerCase() == codigoTipo.toLowerCase()) {
        final descricao = tipo.descricaoExibicao.trim();
        if (descricao.isNotEmpty) return descricao;
      }
    }
    return fallback;
  }

  List<_ResumoTipoRecebimentoData> _linhasResumoPorTipoRecebimento() {
    final tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      return <_ResumoTipoRecebimentoData>[
        _ResumoTipoRecebimentoData('Forma não informada', 0),
      ];
    }

    return tipos
        .map(
          (tipo) => _ResumoTipoRecebimentoData(
            _descricaoTipoRecebimentoConfigurado(tipo),
            _valorResumoPorCodigoTipo(tipo.codigoTipo),
          ),
        )
        .toList(growable: false);
  }

  double _valorResumoPorCodigoTipo(String codigoTipo) {
    final resumo = _movimentosComSomatorio;
    if (resumo == null) return 0;
    switch (codigoTipo.toLowerCase()) {
      case 'tipo1':
        return resumo.tipo1;
      case 'tipo2':
        return resumo.tipo2;
      case 'tipo3':
        return resumo.tipo3;
      case 'tipo4':
        return resumo.tipo4;
      case 'tipo5':
        return resumo.tipo5;
      case 'tipo6':
        return resumo.tipo6;
      case 'tipo7':
        return resumo.tipo7;
      case 'tipo8':
        return resumo.tipo8;
      case 'tipo9':
        return resumo.tipo9;
      case 'tipo10':
        return resumo.tipo10;
      default:
        return 0;
    }
  }

  Future<void> _abrirCaixa() async {
    if (_caixaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um caixa / guichê.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _caixaService.abrirCaixa(
        AbrirCaixaRequest(
          idCaixaOuGuiche: _caixaSelecionado!.id,
          nomeCaixa: _caixaSelecionado!.nome,
          valorAbertura: _parseCurrency(_trocoInicialController.text),
        ),
      );
      await _carregarDadosIniciais();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa aberto com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao abrir caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarMovimento() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo da operação.')),
      );
      return;
    }
    if (_tipoRecebimentoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a forma relacionada.')),
      );
      return;
    }

    final valor = _parseCurrency(_valorController.text);
    if (valor <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe um valor válido.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _caixaService.registrarMovimentacao(
        RegistrarMovimentoRequest(
          idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
          tipoMovimento: _tipoSelecionado!,
          codigoTipoRecebimento: _tipoRecebimentoSelecionado!.codigoTipo,
          valor: valor,
          observacao: _observacaoController.text.trim(),
          referencia: _referenciaController.text.trim(),
          vinculadoVenda: _vincularVenda,
        ),
      );
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      _limparFormularioMovimento();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentação registrada com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao registrar movimentação: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _limparFormularioMovimento() {
    setState(() {
      _tipoSelecionado = null;
      _valorController.clear();
      _observacaoController.clear();
      _referenciaController.clear();
      _vincularVenda = false;
      final tipos = _tiposRecebimentoAtivosOrdenados();
      _tipoRecebimentoSelecionado = tipos.isNotEmpty ? tipos.first : null;
    });
  }

  Future<void> _fecharCaixa() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() {
        _mostrarPainelFechamento = false;
        _fechamentoDinheiroController.clear();
        _fechamentoPixController.clear();
        _fechamentoCartaoController.clear();
        _fechamentoObservacaoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa fechado com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao fechar caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  FecharCaixaRequest _montarRequestFechamentoCaixa() {
    final resumo = _resumo;
    final dinheiro =
        _fechamentoDinheiroController.text.trim().isEmpty
            ? (resumo?.totalDinheiro ?? 0)
            : _parseCurrency(_fechamentoDinheiroController.text);
    final pix =
        _fechamentoPixController.text.trim().isEmpty
            ? (resumo?.totalPix ?? 0)
            : _parseCurrency(_fechamentoPixController.text);
    final cartao =
        _fechamentoCartaoController.text.trim().isEmpty
            ? ((resumo?.totalCartaoCredito ?? 0) +
                (resumo?.totalCartaoDebito ?? 0))
            : _parseCurrency(_fechamentoCartaoController.text);

    return FecharCaixaRequest(
      idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
      valorDinheiroApurado: dinheiro,
      valorPixApurado: pix,
      valorCartaoApurado: cartao,
      observacaoFechamento: _fechamentoObservacaoController.text.trim(),
    );
  }

  Future<void> _confirmarEncerramentoSessao() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    final tokens = WebThemeTokens.of(context);
    final confirmou =
        await showDialog<bool>(
          context: context,
          barrierColor: tokens.workspaceBackground.withValues(alpha: 0.72),
          builder:
              (context) => _buildConfirmDialog(
                title: 'Encerrar sessão?',
                message:
                    'Esta ação encerrará o caixa atual. Você ainda poderá consultar o histórico da sessão.',
                cancelLabel: 'Voltar',
                confirmLabel: 'Encerrar',
              ),
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() => _mostrarPainelFechamento = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sessão encerrada.')));
    } catch (e) {
      _mostrarErro('Erro ao encerrar sessão: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    final tokens = WebThemeTokens.of(context);
    final confirmou =
        await showDialog<bool>(
          context: context,
          barrierColor: tokens.workspaceBackground.withValues(alpha: 0.72),
          builder:
              (context) => _buildConfirmDialog(
                title: 'Cancelar movimentação?',
                message:
                    'Deseja cancelar a operação ${_labelTipo(movimento.tipoMovimento)} em $forma no valor de ${_formatCurrency(movimento.valor)}?',
                cancelLabel: 'Voltar',
                confirmLabel: 'Cancelar operação',
                danger: true,
              ),
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.cancelarMovimentacao(movimento.idMovimento);
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Movimentação cancelada.')));
    } catch (e) {
      _mostrarErro('Erro ao cancelar movimentação: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  AlertDialog _buildConfirmDialog({
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    bool danger = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return AlertDialog(
      backgroundColor: tokens.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: TextStyle(
          color: tokens.primaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(message, style: TextStyle(color: tokens.secondaryText)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style:
              danger
                  ? FilledButton.styleFrom(
                    backgroundColor: tokens.danger,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                  : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Color _corPorNatureza(String? natureza) {
    final tokens = WebThemeTokens.of(context);
    if (natureza == null) return tokens.statusNeutral;
    return natureza.toLowerCase() == 'entrada'
        ? tokens.financialPositive
        : tokens.financialNegative;
  }

  Color _corPorStatus(String? status) {
    final tokens = WebThemeTokens.of(context);
    if (status == null) return tokens.statusNeutral;
    switch (status.toLowerCase()) {
      case 'aberta':
        return tokens.info;
      case 'concluida':
        return tokens.success;
      case 'cancelada':
        return tokens.danger;
      case 'pendenteconferencia':
        return tokens.warning;
      default:
        return tokens.statusNeutral;
    }
  }

  IconData _iconeTipo(OperacaoCaixaTipo tipo) {
    switch (tipo) {
      case OperacaoCaixaTipo.aberturaCaixa:
        return Icons.lock_open_rounded;
      case OperacaoCaixaTipo.fechamentoCaixa:
        return Icons.lock_outline_rounded;
      case OperacaoCaixaTipo.suprimento:
        return Icons.add_circle_outline_rounded;
      case OperacaoCaixaTipo.sangria:
        return Icons.remove_circle_outline_rounded;
      case OperacaoCaixaTipo.retiradaDespesa:
        return Icons.receipt_long_outlined;
      case OperacaoCaixaTipo.ajuste:
        return Icons.tune_rounded;
      case OperacaoCaixaTipo.estorno:
        return Icons.undo_rounded;
      case OperacaoCaixaTipo.recebimentoAvulso:
        return Icons.call_received_rounded;
      case OperacaoCaixaTipo.pagamentoAvulso:
        return Icons.call_made_rounded;
    }
  }

  String _labelTipo(dynamic tipo) {
    String? tipoStr;
    if (tipo is OperacaoCaixaTipo) {
      tipoStr = tipo.name;
    } else if (tipo is String) {
      tipoStr = tipo;
    }
    if (tipoStr == null) return '--';
    switch (tipoStr) {
      case 'aberturaCaixa':
      case 'ABERTURA_CAIXA':
        return 'Abertura de caixa';
      case 'fechamentoCaixa':
      case 'FECHAMENTO_CAIXA':
        return 'Fechamento de caixa';
      case 'suprimento':
      case 'SUPRIMENTO':
        return 'Suprimento';
      case 'sangria':
      case 'SANGRIA':
        return 'Sangria';
      case 'retiradaDespesa':
      case 'RETIRADA_DESPESA':
        return 'Retirada para despesa';
      case 'ajuste':
      case 'AJUSTE':
        return 'Ajuste';
      case 'estorno':
      case 'ESTORNO':
        return 'Estorno';
      case 'recebimentoAvulso':
      case 'RECEBIMENTO_AVULSO':
        return 'Recebimento avulso';
      case 'RECEBIMENTO_FINANCEIRO':
        return 'Recebimento financeiro';
      case 'pagamentoAvulso':
      case 'PAGAMENTO_AVULSO':
        return 'Pagamento avulso';
      default:
        return tipoStr;
    }
  }

  String _labelNatureza(String? natureza) {
    if (natureza == null) return '--';
    switch (natureza.toLowerCase()) {
      case 'entrada':
        return 'Entrada';
      case 'saida':
        return 'Saída';
      default:
        return natureza;
    }
  }

  String _labelStatusMovimento(String? status) {
    if (status == null) return '--';
    switch (status.toLowerCase()) {
      case 'aberta':
        return 'Aberta';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      case 'pendenteconferencia':
        return 'Pendente conferência';
      default:
        return status;
    }
  }

  String _labelSessao(String? status) {
    if (status == null) return '--';
    switch (status.toLowerCase()) {
      case 'aberta':
        return 'Aberta';
      case 'fechada':
        return 'Fechada';
      default:
        return status;
    }
  }

  String _formatCurrency(double value) {
    try {
      return context.read<LocaleSettingsProvider>().formatCurrency(value);
    } catch (_) {
      final negative = value < 0;
      final absolute = value.abs();
      final fixed = absolute.toStringAsFixed(2);
      final parts = fixed.split('.');
      final integer = parts[0];
      final decimal = parts[1];
      final buffer = StringBuffer();
      for (var i = 0; i < integer.length; i++) {
        final position = integer.length - i;
        buffer.write(integer[i]);
        if (position > 1 && position % 3 == 1) buffer.write('.');
      }
      return '${negative ? '-' : ''}${buffer.toString()},$decimal';
    }
  }

  String _currencyInputPrefix() {
    try {
      return '${context.read<LocaleSettingsProvider>().currencyCode} ';
    } catch (_) {
      return '';
    }
  }

  double _parseCurrency(String text) {
    final cleaned =
        text
            .replaceAll(RegExp(r'[^0-9,.\-]'), '')
            .replaceAll('.', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '--';
    try {
      final dateTime = DateTime.parse(value);
      final dd = dateTime.day.toString().padLeft(2, '0');
      final mm = dateTime.month.toString().padLeft(2, '0');
      final yyyy = dateTime.year.toString();
      final hh = dateTime.hour.toString().padLeft(2, '0');
      final min = dateTime.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy às $hh:$min';
    } catch (_) {
      return value;
    }
  }

  bool _isSameDay(String? value, DateTime other) {
    if (value == null || value.isEmpty) return false;
    try {
      final dateTime = DateTime.parse(value);
      return dateTime.year == other.year &&
          dateTime.month == other.month &&
          dateTime.day == other.day;
    } catch (_) {
      return false;
    }
  }
}

class _WebSelectorDialog<T> extends StatelessWidget {
  const _WebSelectorDialog({
    required this.width,
    required this.selected,
    required this.items,
    required this.itemLabel,
    required this.itemSubtitle,
    required this.itemIcon,
    required this.emptyMessage,
  });

  final double width;
  final T? selected;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String Function(T item) itemSubtitle;
  final IconData Function(T item) itemIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: tokens.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width + 120,
          maxHeight: 420,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              items.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _WebSelectorMenuItem(
                        selected: item == selected,
                        title: itemLabel(item),
                        subtitle: itemSubtitle(item),
                        icon: itemIcon(item),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}

class _WebSelectorMenuItem extends StatelessWidget {
  const _WebSelectorMenuItem({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final accent = tokens.info;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tokens.selectedBorder : tokens.cardBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    selected ? tokens.cardBackground : tokens.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? accent : tokens.mutedText,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _SairDaTelaIntent extends Intent {
  const _SairDaTelaIntent();
}

enum NaturezaMovimento { entrada, saida }

enum NaturezaRecebimento { imediato, futuro }

enum StatusMovimento { aberta, concluida, cancelada, pendenteConferencia }

enum StatusSessaoCaixa { aberta, fechada }

class _AtalhoOperacaoData {
  _AtalhoOperacaoData({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
  });

  final OperacaoCaixaTipo tipo;
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
}

class _ResumoTipoRecebimentoData {
  const _ResumoTipoRecebimentoData(this.label, this.valor);

  final String label;
  final double valor;
}
