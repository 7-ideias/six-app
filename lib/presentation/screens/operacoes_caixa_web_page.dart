import 'package:flutter/material.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_completo_movimentos_models.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../data/models/caixa_models.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../providers/empresa_provider.dart';
import '../../providers/usuario_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_settings_provider.dart';

class OperacoesCaixaWebPage extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onBack;

  const OperacoesCaixaWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<OperacoesCaixaWebPage> createState() => _OperacoesCaixaWebPageState();
}

class _OperacoesCaixaWebPageState extends State<OperacoesCaixaWebPage> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _trocoInicialController =
  TextEditingController(text: '200,00');
  final TextEditingController _fechamentoDinheiroController =
  TextEditingController();
  final TextEditingController _fechamentoPixController =
  TextEditingController();
  final TextEditingController _fechamentoCartaoController =
  TextEditingController();
  final TextEditingController _fechamentoObservacaoController =
  TextEditingController();

  final CaixaService _caixaService = CaixaModule.caixaService;
  bool _isLoading = false;

  CaixaSessao? _sessaoAtual;
  OperacaoCaixaTipo? _tipoSelecionado;
  // FormaMovimento? _formaSelecionada;
  TiposRecebimento? _tipoRecebimentoSelecionado;
  CaixaOuGuiche? _caixaSelecionado;
  bool _vincularVenda = false;
  bool _mostrarPainelFechamento = false;
  bool _mostrarApenasHoje = true;

  late List<CaixaOuGuiche> _listaDeCaixasDisponiveisNaEmpresa;
  // late List<FormaMovimento> _formas;
  late List<TiposRecebimento> _tiposRecebimento;
  late InformacoesCaixaComSomatorioResponse? _movimentosComSomatorio;
  // late List<InformacoesBasicasCaixaResponse> _informacoesBasicasDoCaixa;
  late List<MovimentoCaixa> _movimentos;
  ResumoCaixa? _resumo;

  @override
  void initState() {
    super.initState();
    _listaDeCaixasDisponiveisNaEmpresa = [];
    // _formas = [];
    _tiposRecebimento = [];
    _tipoRecebimentoSelecionado = null;
    _movimentos = [];
    // _informacoesBasicasDoCaixa = [];
    _caixaSelecionado = null;
    // _formaSelecionada = null;
    _sessaoAtual = null;
    _tipoSelecionado = null;
    _movimentosComSomatorio = null;
    
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    try {
      final informacoesBasicasDoCaixa = await _caixaService.buscarInformacoesBasicasDoCaixa();
      if (mounted && informacoesBasicasDoCaixa.regionalizacao != null) {
        await context
            .read<LocaleSettingsProvider>()
            .atualizarConfiguracaoDaEmpresaPorResponse(
          informacoesBasicasDoCaixa.regionalizacao!,
        );
      }
      final sessao = await _caixaService.buscarSessaoAtual();
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

      setState(() {
        _listaDeCaixasDisponiveisNaEmpresa = informacoesBasicasDoCaixa.caixaOuGuiche.isNotEmpty
            ? informacoesBasicasDoCaixa.caixaOuGuiche
            : informacoesBasicasDoCaixa.caixas
            .map(
              (nomeCaixa) => CaixaOuGuiche(
            id: nomeCaixa,
            nome: nomeCaixa,
          ),
        )
            .toList();
        // _formas = informacoesBasicasDoCaixa.formas;
        _tiposRecebimento = informacoesBasicasDoCaixa.tiposRecebimento;
        if (_listaDeCaixasDisponiveisNaEmpresa.isNotEmpty) {
          _caixaSelecionado = _listaDeCaixasDisponiveisNaEmpresa.first;
        }

        final tiposAtivosOrdenados = _tiposRecebimento
            .where((item) => item.ativo)
            .toList()
          ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

        if (tiposAtivosOrdenados.isNotEmpty) {
          _tipoRecebimentoSelecionado = tiposAtivosOrdenados.first;
        }

        _sessaoAtual = sessao;
      });

      if (_sessaoAtual != null) {
        await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      }

    } catch (e) {
      _mostrarErro('Erro ao carregar dados do caixa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarMovimentosEResumo(String idCaixaSessao) async {
    try {
      final movimentos = await _caixaService.listarMovimentacoes(idCaixaSessao);
      final movimentosComSomatorio = await _caixaService.buscarResumoDeMovimentosComSomatorio(idCaixaSessao);
      final resumo = await _caixaService.buscarResumo(idCaixaSessao);
      setState(() {
        _movimentos = movimentos;
        _movimentosComSomatorio = movimentosComSomatorio;
        _resumo = resumo;
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar movimentações: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _referenciaController.dispose();
    _trocoInicialController.dispose();
    _fechamentoDinheiroController.dispose();
    _fechamentoPixController.dispose();
    _fechamentoCartaoController.dispose();
    _fechamentoObservacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(child: content),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final resumo = _resumo;
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1260;
          final isMedium = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: widget.embedded ? 0 : (isWide ? 28 : 18),
              vertical: widget.embedded ? 0 : 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded) ...[
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Voltar'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Retornar para os módulos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildHeader(theme, resumo, isMedium),
                  const SizedBox(height: 20),
                  if (!_temCaixaAberto)
                    _buildPainelAbertura(theme)
                  else if (resumo == null)
                    _buildResumoIndisponivel(theme)
                  else
                    isWide
                        ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              _buildContextoOperacao(theme),
                              const SizedBox(height: 20),
                              _buildAtalhosOperacao(theme),
                              const SizedBox(height: 20),
                              _buildFormularioMovimento(theme),
                              const SizedBox(height: 20),
                              _buildHistorico(theme),
                              const SizedBox(height: 20),
                              if (_mostrarPainelFechamento)
                                _buildPainelFechamento(theme),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _buildResumoLateral(theme, resumo),
                        ),
                      ],
                    )
                        : Column(
                      children: [
                        _buildContextoOperacao(theme),
                        const SizedBox(height: 20),
                        _buildResumoLateral(theme, resumo),
                        const SizedBox(height: 20),
                        _buildAtalhosOperacao(theme),
                        const SizedBox(height: 20),
                        _buildFormularioMovimento(theme),
                        const SizedBox(height: 20),
                        _buildHistorico(theme),
                        const SizedBox(height: 20),
                        if (_mostrarPainelFechamento)
                          _buildPainelFechamento(theme),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _temCaixaAberto =>
      _sessaoAtual != null && _sessaoAtual!.status.toLowerCase() == 'aberta';

  void _mostrarAvisoCaixaNaoAberto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Antes de lançar operações, faça a abertura do caixa.'),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ResumoCaixa? resumo,
    bool isMedium,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Wrap(
        runSpacing: 18,
        spacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xff1d4ed8), Color(0xff2563eb)],
              ),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operações de caixa',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _temCaixaAberto
                      ? 'Controle operacional do caixa com visão de entradas, saídas, conferência e fechamento.'
                      : 'Antes de registrar operações, faça a abertura do caixa e defina o troco inicial do dia.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (isMedium)
            ...[
              _buildTopInfoChip(
                theme: theme,
                icon: Icons.storefront_outlined,
                label: 'Empresa',
                value: EmpresaProvider().empresa!.nomeFantasia,
              ),
              _buildTopInfoChip(
                theme: theme,
                icon: Icons.person_outline_rounded,
                label: 'Operador',
                value: _sessaoAtual?.idColaboradorAbertura ?? 'Aguardando abertura',
              ),
              _buildTopInfoChip(
                theme: theme,
                icon: Icons.calendar_today_outlined,
                label: 'Movimentos',
                value: '${resumo?.quantidadeMovimentos ?? 0}',
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildTopInfoChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoIndisponivel(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: _cardDecoration(),
      child: Text(
        'Resumo do caixa indisponível.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: const Color(0xff475569),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPainelAbertura(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xffe8f0fe),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xff1d4ed8),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abertura de caixa',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff14213d),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Defina o caixa, o troco inicial e inicie a operação do dia.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xff5b6475),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _buildFieldBox(
                width: 260,
                label: 'Caixa / guichê',
                child: _buildDropdown<CaixaOuGuiche>(
                  value: _caixaSelecionado,
                  items: _listaDeCaixasDisponiveisNaEmpresa,
                  onChanged: (value) {
                    setState(() => _caixaSelecionado = value);
                  },
                  itemLabel: (item) => item.nome,
                ),
              ),
              _buildFieldBox(
                width: 220,
                label: 'Troco inicial',
                child: _buildTextField(
                  controller: _trocoInicialController,
                  hint: '0,00',
                  prefix: 'R\$ ',
                ),
              ),
              _buildFieldBox(
                width: 260,
                label: 'Colaborador responsável',
                child: _buildReadOnlyField(UsuarioProvider().usuario?.nomeDeGuerra ?? '--'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                ElevatedButton.icon(
                  onPressed: _abrirCaixa,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Abrir caixa'),
                  style: _primaryButtonStyle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextoOperacao(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          _buildMiniMetric(
            title: 'Sessão',
            value: _sessaoAtual?.idSessaoCaixa ?? '--',
            icon: Icons.badge_outlined,
          ),
          _buildMiniMetric(
            title: 'Caixa',
            value: _sessaoAtual?.nomeCaixa ?? '--',
            icon: Icons.store_mall_directory_outlined,
          ),
          _buildMiniMetric(
            title: 'Abertura',
            value: _formatDateTime(_sessaoAtual?.dataHoraAbertura),
            icon: Icons.schedule_rounded,
          ),
          _buildMiniMetric(
            title: 'Troco inicial',
            value: _formatCurrency(_sessaoAtual?.valorAbertura ?? 0),
            icon: Icons.account_balance_wallet_outlined,
          ),
          _buildMiniMetric(
            title: 'Status',
            value: _labelSessao(_sessaoAtual?.status),
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdde7f3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffe8f0fe),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xff2563eb), size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff7a8394),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff162033),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
    final cards = [
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.suprimento,
        titulo: 'Suprimento',
        descricao: 'Adicionar valores ao caixa para reforço operacional.',
        icone: Icons.add_card_rounded,
        cor: const Color(0xff0f766e),
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.sangria,
        titulo: 'Sangria',
        descricao: 'Retirar excesso de numerário para segurança.',
        icone: Icons.outbox_rounded,
        cor: const Color(0xffb45309),
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.retiradaDespesa,
        titulo: 'Despesa',
        descricao: 'Registrar saída para motoboy, café, material e similares.',
        icone: Icons.receipt_long_rounded,
        cor: const Color(0xffbe123c),
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.ajuste,
        titulo: 'Ajuste',
        descricao: 'Corrigir diferenças operacionais com rastreabilidade.',
        icone: Icons.tune_rounded,
        cor: const Color(0xff4338ca),
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.recebimentoAvulso,
        titulo: 'Recebimento avulso',
        descricao: 'Entrada operacional sem vínculo direto com venda.',
        icone: Icons.arrow_downward_rounded,
        cor: const Color(0xff047857),
      ),
      _AtalhoOperacaoData(
        tipo: OperacaoCaixaTipo.pagamentoAvulso,
        titulo: 'Pagamento avulso',
        descricao: 'Saída operacional pontual com justificativa.',
        icone: Icons.arrow_upward_rounded,
        cor: const Color(0xff991b1b),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações rápidas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xff14213d),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecione a operação para preencher o formulário com o contexto adequado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xff5b6475),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards.map((item) {
              final selecionado = _tipoSelecionado == item.tipo;
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  setState(() {
                    _tipoSelecionado = item.tipo;
                    _mostrarPainelFechamento = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 280,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                    selecionado ? item.cor.withOpacity(.10) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selecionado
                          ? item.cor
                          : const Color(0xffdbe4ef),
                      width: selecionado ? 1.6 : 1.0,
                    ),
                    boxShadow: selecionado
                        ? [
                      BoxShadow(
                        color: item.cor.withOpacity(.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: item.cor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.icone, color: item.cor, size: 26),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.titulo,
                        style: const TextStyle(
                          color: Color(0xff162033),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.descricao,
                        style: const TextStyle(
                          color: Color(0xff5f6878),
                          fontSize: 13.4,
                          height: 1.42,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
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
                style: _secondaryButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _confirmarEncerramentoSessao,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Encerrar sessão'),
                style: _dangerButtonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioMovimento(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lançamento operacional',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xff14213d),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tipoSelecionado == null
                ? 'Escolha uma ação rápida acima para orientar o lançamento.'
                : 'Preencha os dados da operação ${_labelTipo(_tipoSelecionado!)} com segurança e rastreabilidade.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xff5b6475),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _buildFieldBox(
                width: 260,
                label: 'Tipo da operação',
                child: _buildDropdown<OperacaoCaixaTipo>(
                  value: _tipoSelecionado,
                  items: OperacaoCaixaTipo.values
                      .where((e) => e != OperacaoCaixaTipo.fechamentoCaixa)
                      .toList(),
                  onChanged: (value) {
                    setState(() => _tipoSelecionado = value);
                  },
                  itemLabel: _labelTipo,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(
                width: 220,
                label: 'Valor',
                child: _buildTextField(
                  controller: _valorController,
                  hint: '0,00',
                  prefix: 'R\$ ',
                ),
              ),
              _buildFieldBox(
                width: 240,
                label: 'Forma relacionada',
                child: _buildDropdown<TiposRecebimento>(
                  value: _tipoRecebimentoSelecionado,
                  items: (_tiposRecebimento.where((item) => item.ativo).toList()
                    ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao))),
                  onChanged: (value) {
                    setState(() => _tipoRecebimentoSelecionado = value);
                  },
                  itemLabel: (item) => item.descricaoExibicao,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(
                width: 240,
                label: 'Caixa / guichê',
                child: _buildReadOnlyField(_sessaoAtual?.nomeCaixa ?? '--'),
              ),
              _buildFieldBox(
                width: 260,
                label: 'Referência / comprovante',
                child: _buildTextField(
                  controller: _referenciaController,
                  hint: 'Ex.: MOV-001',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              SizedBox(
                width: 540,
                child: _buildFieldBox(
                  width: 540,
                  label: 'Observação',
                  child: TextField(
                    controller: _observacaoController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      hint: 'Descreva o motivo da movimentação com clareza.',
                    ),
                  ),
                ),
              ),
              Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fbff),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffdbe4ef)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contexto adicional',
                      style: TextStyle(
                        color: Color(0xff162033),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: _vincularVenda,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Possui vínculo com venda',
                        style: TextStyle(fontSize: 13.5),
                      ),
                      onChanged: (value) {
                        setState(() => _vincularVenda = value ?? false);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use em estornos ou situações operacionais relacionadas a atendimento anterior.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12.8,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _salvarMovimento,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Registrar movimentação'),
                style: _primaryButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _limparFormularioMovimento,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Limpar formulário'),
                style: _secondaryButtonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico(ThemeData theme) {
    final movimentosVisiveis = _mostrarApenasHoje
        ? _movimentos
        .where((m) => _isSameDay(m.dataHoraMovimento, DateTime.now()))
        .toList()
        : _movimentos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Histórico de movimentações',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff14213d),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xffeef5ff),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${movimentosVisiveis.length} registros',
                  style: const TextStyle(
                    color: Color(0xff1d4ed8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Somente hoje'),
                selected: _mostrarApenasHoje,
                onSelected: (value) {
                  setState(() => _mostrarApenasHoje = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (movimentosVisiveis.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xfff8fbff),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffdbe4ef)),
              ),
              child: const Text(
                'Nenhuma movimentação registrada após a abertura do caixa.',
                style: TextStyle(
                  color: Color(0xff64748b),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: movimentosVisiveis.map((movimento) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildMovimentoCard(movimento),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMovimentoCard(MovimentoCaixa movimento) {
    final cor = _corPorNatureza(movimento.natureza);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffdce5f0)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    movimento.natureza == NaturezaMovimento.entrada
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: cor,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            _labelTipo(movimento.tipoMovimento),
                            style: const TextStyle(
                              color: Color(0xff162033),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _buildStatusPill(
                            _labelStatusMovimento(movimento.status),
                            _corPorStatus(movimento.status),
                          ),
                          _buildStatusPill(
                            _labelNatureza(movimento.natureza),
                            cor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movimento.observacao.isEmpty
                            ? 'Sem observação informada.'
                            : movimento.observacao,
                        style: const TextStyle(
                          color: Color(0xff5c6677),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _buildInlineInfo(
                            Icons.person_outline_rounded,
                            movimento.nomeColaborador,
                          ),
                          _buildInlineInfo(
                            Icons.store_outlined,
                            movimento.nomeColaborador,
                          ),
                          _buildInlineInfo(
                            Icons.payments_outlined,
                            movimento.descricao,
                          ),
                          _buildInlineInfo(
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
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(movimento.valor),
                  style: TextStyle(
                    color: cor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(movimento.dataHoraMovimento),
                  style: const TextStyle(
                    color: Color(0xff7a8394),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Detalhamento de ${_labelTipo(movimento.tipoMovimento)} preparado para futura integração.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Detalhes'),
                    ),
                    if (movimento.status != StatusMovimento.cancelada)
                      OutlinedButton(
                        onPressed: () => _cancelarMovimento(movimento),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xffb91c1c),
                        ),
                        child: const Text('Cancelar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLateral(ThemeData theme, dynamic resumo) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xfff8fbff),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffdce5f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conferência por forma',
                style: TextStyle(
                  color: Color(0xff162033),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildResumoSecundario(
                'Dinheiro',
                _formatCurrency(_movimentosComSomatorio?.tipo1 ?? 0)
              ),
              _buildResumoSecundario(
                'Pix',
                _formatCurrency(_movimentosComSomatorio?.tipo2 ?? 0)
              ),
              _buildResumoSecundario(
                'Cartão Crédito',
                _formatCurrency(_movimentosComSomatorio?.tipo3 ?? 0)
              ),
              _buildResumoSecundario(
                'Cartão Débito',
                _formatCurrency(_movimentosComSomatorio?.tipo4 ?? 0)
              ),
              _buildResumoSecundario(
                'Boleto',
                _formatCurrency(_movimentosComSomatorio?.tipo5 ?? 0)
              ),
              _buildResumoSecundario(
                'Fiado',
                _formatCurrency(_movimentosComSomatorio?.tipo6 ?? 0)
              ),
              _buildResumoSecundario(
                'Crediário',
                _formatCurrency(_movimentosComSomatorio?.tipo7 ?? 0)
              ),
              _buildResumoSecundario(
                'Convênio',
                _formatCurrency(_movimentosComSomatorio?.tipo8 ?? 0)
              ),
              _buildResumoSecundario(
                'Vale',
                _formatCurrency(_movimentosComSomatorio?.tipo9 ?? 0)
              ),
              _buildResumoSecundario(
                'Outros',
                _formatCurrency(_movimentosComSomatorio?.tipo10 ?? 0)
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checklist operacional',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff14213d),
                ),
              ),
              const SizedBox(height: 16),
              _buildChecklistItem(
                checked: _temCaixaAberto,
                title: 'Caixa aberto',
              ),
              _buildChecklistItem(
                checked: _movimentos.isNotEmpty,
                title: 'Movimentações registradas',
              ),
              _buildChecklistItem(
                checked: _movimentos.any(
                      (m) => m.status == StatusMovimento.pendenteConferencia,
                ),
                title: 'Há pendências para conferência',
              ),
              _buildChecklistItem(
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fechamento de caixa',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xff14213d),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Informe os valores apurados para comparar com o saldo esperado e concluir a sessão.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xff5b6475),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _buildFieldBox(
                width: 200,
                label: 'Dinheiro apurado',
                child: _buildTextField(
                  controller: _fechamentoDinheiroController,
                  hint: _formatCurrency(resumo!.totalDinheiro),
                  prefix: 'R\$ ',
                ),
              ),
              _buildFieldBox(
                width: 200,
                label: 'Pix apurado',
                child: _buildTextField(
                  controller: _fechamentoPixController,
                  hint: _formatCurrency(resumo.totalPix),
                  prefix: 'R\$ ',
                ),
              ),
              _buildFieldBox(
                width: 220,
                label: 'Cartão apurado',
                child: _buildTextField(
                  controller: _fechamentoCartaoController,
                  hint: _formatCurrency(resumo.totalCartaoCredito + resumo.totalCartaoDebito),
                  prefix: 'R\$ ',
                ),
              ),
              Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fbff),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffdbe4ef)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo esperado',
                      style: TextStyle(
                        color: Color(0xff7a8394),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(resumo.saldoEsperado),
                      style: const TextStyle(
                        color: Color(0xff0f172a),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFieldBox(
            width: double.infinity,
            label: 'Observação do fechamento',
            child: TextField(
              controller: _fechamentoObservacaoController,
              maxLines: 3,
              decoration: _inputDecoration(
                hint: 'Detalhe divergências, conferências e observações finais.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _fecharCaixa,
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Concluir fechamento'),
                style: _primaryButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _mostrarPainelFechamento = false);
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar fechamento'),
                style: _secondaryButtonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required bool checked,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? const Color(0xff16a34a) : const Color(0xff94a3b8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinha(String label, double valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                destaque ? const Color(0xff0f172a) : const Color(0xff64748b),
                fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatCurrency(valor),
            style: TextStyle(
              color:
              destaque ? const Color(0xff0f172a) : const Color(0xff1e293b),
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w800,
              fontSize: destaque ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSecundario(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff64748b),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff162033),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInlineInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xff64748b)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldBox({
    required double width,
    required String label,
    required Widget child,
  }) {
    return width == double.infinity
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff4b5563),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    )
        : SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff4b5563),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdbe4ef)),
      ),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xff162033),
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(
        hint: hint,
        prefixText: prefix,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T item) itemLabel,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _inputDecoration(hint: hint),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({
    required String? hint,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            theme.brightness == Brightness.dark ? .22 : .04,
          ),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      elevation: 0,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle _dangerButtonStyle() {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      side: BorderSide(color: theme.colorScheme.error.withOpacity(.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  Future<void> _abrirCaixa() async {
    if (_caixaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um caixa / guichê.')),
      );
      return;
    }

    final valor = _parseCurrency(_trocoInicialController.text);
    
    setState(() => _isLoading = true);
    try {
      await _caixaService.abrirCaixa(AbrirCaixaRequest(
        idCaixaOuGuiche: _caixaSelecionado!.id,
        nomeCaixa: _caixaSelecionado!.nome,
        valorAbertura: valor,
      ));
      
      await _carregarDadosIniciais();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa aberto com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao abrir caixa: $e');
    } finally {
      setState(() => _isLoading = false);
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

    final valorDoLancamentoOperacional = _parseCurrency(_valorController.text);
    if (valorDoLancamentoOperacional <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _caixaService.registrarMovimentacao(
        RegistrarMovimentoRequest(
          idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
          tipoMovimento: _tipoSelecionado!,
          codigoTipoRecebimento: _tipoRecebimentoSelecionado!.codigoTipo,
          valor: valorDoLancamentoOperacional,
          observacao: _observacaoController.text.trim(),
          referencia: _referenciaController.text.trim(),
          vinculadoVenda: _vincularVenda,
        ),
      );

      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      _limparFormularioMovimento();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentação registrada com sucesso.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao registrar movimentação: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _limparFormularioMovimento() {
    setState(() {
      _tipoSelecionado = null;
      _valorController.clear();
      _observacaoController.clear();
      _referenciaController.clear();
      _vincularVenda = false;

      final tiposAtivosOrdenados = _tiposRecebimento
          .where((item) => item.ativo)
          .toList()
        ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

      _tipoRecebimentoSelecionado =
      tiposAtivosOrdenados.isNotEmpty ? tiposAtivosOrdenados.first : null;
    });
  }

  Future<void> _fecharCaixa() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    final resumo = _resumo;
    final dinheiroInformado = _fechamentoDinheiroController.text.trim().isEmpty
        ? (resumo?.totalDinheiro ?? 0)
        : _parseCurrency(_fechamentoDinheiroController.text);
    final pixInformado = _fechamentoPixController.text.trim().isEmpty
        ? (resumo?.totalPix ?? 0)
        : _parseCurrency(_fechamentoPixController.text);
    final cartaoInformado = _fechamentoCartaoController.text.trim().isEmpty
        ? ((resumo?.totalCartaoCredito ?? 0) + (resumo?.totalCartaoDebito ?? 0))
        : _parseCurrency(_fechamentoCartaoController.text);

    setState(() => _isLoading = true);
    try {
      await _caixaService.fecharCaixa(FecharCaixaRequest(
        idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
        valorDinheiroApurado: dinheiroInformado,
        valorPixApurado: pixInformado,
        valorCartaoApurado: cartaoInformado,
        observacaoFechamento: _fechamentoObservacaoController.text.trim(),
      ));
      await _carregarDadosIniciais();

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
      setState(() => _isLoading = false);
    }
  }

  void _confirmarEncerramentoSessao() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    final confirmou = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Encerrar sessão?'),
              content: const Text(
                'Esta ação encerrará o caixa atual. Você ainda poderá consultar o histórico da sessão.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Encerrar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.encerrarSessao();
      await _carregarDadosIniciais();

      setState(() {
        _mostrarPainelFechamento = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão encerrada.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao encerrar sessão: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final confirmou = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Cancelar movimentação?'),
              content: Text(
                'Deseja cancelar a operação ${_labelTipo(movimento.tipoMovimento)} no valor de ${_formatCurrency(movimento.valor)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffb91c1c),
                  ),
                  child: const Text('Cancelar operação'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.cancelarMovimentacao(movimento.idMovimento);
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentação cancelada.')),
      );
    } catch (e) {
      _mostrarErro('Erro ao cancelar movimentação: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ResumoCaixa _calcularResumo() {
  //   final trocoInicial = _sessaoAtual?.valorAbertura ?? 0;
  //
  //   double totalEntradas = 0;
  //   double totalSaidas = 0;
  //
  //   double totalDinheiro = 0;
  //   double totalPix = 0;
  //   double totalCartaoCredito = 0;
  //   double totalCartaoDebito = 0;
  //   double totalBoleto = 0;
  //   double totalFiado = 0;
  //   double totalCrediario = 0;
  //   double totalConvenio = 0;
  //   double totalVale = 0;
  //   double totalOutros = 0;
  //
  //   for (final mov in _movimentos.where((m) => m.status.toLowerCase() != 'cancelada'))
  //
  //     switch (mov.codigoTipoRecebimento) {
  //       case 'tipo1':
  //         totalDinheiro += mov.valor;
  //         break;
  //       case 'tipo2':
  //         totalPix += mov.valor;
  //         break;
  //       case 'tipo3':
  //         totalCartaoCredito += mov.valor;
  //         break;
  //       case 'tipo4':
  //         totalCartaoDebito += mov.valor;
  //         break;
  //       case 'tipo5':
  //       case 'tipo10':
  //         totalBoleto += mov.valor;
  //         break;
  //       case 'tipo6':
  //         totalFiado += mov.valor;
  //         break;
  //       case 'tipo7':
  //         totalCrediario += mov.valor;
  //         break;
  //       case 'tipo8':
  //         totalConvenio += mov.valor;
  //         break;
  //       case 'tipo9':
  //         totalVale += mov.valor;
  //         break;
  //       default:
  //         totalOutros += mov.valor;
  //         break;
  //     }
  //
  //
  //   final saldoEsperado = trocoInicial + totalEntradas - totalSaidas;
  //   final totalCartao = totalCartaoCredito + totalCartaoDebito;
  //
  //   return ResumoCaixa(
  //     trocoInicial: trocoInicial,
  //     totalEntradas: totalEntradas,
  //     totalSaidas: totalSaidas,
  //     saldoEsperado: saldoEsperado,
  //     quantidadeMovimentos: _movimentos.length,
  //     totalDinheiro: totalDinheiro,
  //     totalPix: totalPix,
  //     totalCartao: totalCartao,
  //     totalCartaoCredito: totalCartaoCredito,
  //     totalCartaoDebito: totalCartaoDebito,
  //     totalBoleto: totalBoleto,
  //     totalFiado: totalFiado,
  //     totalCrediario: totalCrediario,
  //     totalConvenio: totalConvenio,
  //     totalVale: totalVale,
  //     totalOutros: totalOutros,
  //   );
  // }

  NaturezaMovimento _naturezaPorTipo(OperacaoCaixaTipo tipo) {
    switch (tipo) {
      case OperacaoCaixaTipo.aberturaCaixa:
      case OperacaoCaixaTipo.suprimento:
      case OperacaoCaixaTipo.recebimentoAvulso:
        return NaturezaMovimento.entrada;
      case OperacaoCaixaTipo.fechamentoCaixa:
      case OperacaoCaixaTipo.sangria:
      case OperacaoCaixaTipo.retiradaDespesa:
      case OperacaoCaixaTipo.ajuste:
      case OperacaoCaixaTipo.estorno:
      case OperacaoCaixaTipo.pagamentoAvulso:
        return NaturezaMovimento.saida;
    }
  }

  Color _corPorNatureza(String? natureza) {
    if (natureza == null) return const Color(0xff7a8394);
    return natureza.toLowerCase() == 'entrada'
        ? const Color(0xff15803d)
        : const Color(0xffb91c1c);
  }

  Color _corPorStatus(String? status) {
    if (status == null) return const Color(0xff7a8394);
    switch (status.toLowerCase()) {
      case 'aberta':
        return const Color(0xff1d4ed8);
      case 'concluida':
        return const Color(0xff15803d);
      case 'cancelada':
        return const Color(0xffb91c1c);
      case 'pendenteconferencia':
        return const Color(0xffb45309);
      default:
        return const Color(0xff7a8394);
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
        return 'Abertura de caixa';
      case 'fechamentoCaixa':
        return 'Fechamento de caixa';
      case 'suprimento':
        return 'Suprimento';
      case 'sangria':
        return 'Sangria';
      case 'retiradaDespesa':
        return 'Retirada para despesa';
      case 'ajuste':
        return 'Ajuste';
      case 'estorno':
        return 'Estorno';
      case 'recebimentoAvulso':
        return 'Recebimento avulso';
      case 'pagamentoAvulso':
        return 'Pagamento avulso';
      default:
        return tipo;
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
    final negative = value < 0;
    final absolute = value.abs();
    final fixed = absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      final position = integer.length - i;
      buffer.write(integer[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
  }

  double _parseCurrency(String text) {
    final cleaned = text
        .replaceAll('R\$', '')
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
    } catch (e) {
      return value;
    }
  }

  bool _isSameDay(String? a, DateTime b) {
    if (a == null || a.isEmpty) return false;
    try {
      final dateTimeA = DateTime.parse(a);
      return dateTimeA.year == b.year &&
          dateTimeA.month == b.month &&
          dateTimeA.day == b.day;
    } catch (e) {
      return false;
    }
  }
}

enum OperacaoCaixaTipo {
  aberturaCaixa,
  fechamentoCaixa,
  suprimento,
  sangria,
  retiradaDespesa,
  ajuste,
  estorno,
  recebimentoAvulso,
  pagamentoAvulso;

  String get OperacaoCaixaTipoEnum {
    switch (this) {
      case OperacaoCaixaTipo.aberturaCaixa:
        return 'ABERTURA_CAIXA';
      case OperacaoCaixaTipo.fechamentoCaixa:
        return 'FECHAMENTO_CAIXA';
      case OperacaoCaixaTipo.suprimento:
        return 'SUPRIMENTO';
      case OperacaoCaixaTipo.sangria:
        return 'SANGRIA';
      case OperacaoCaixaTipo.retiradaDespesa:
        return 'RETIRADA_DESPESA';
      case OperacaoCaixaTipo.ajuste:
        return 'AJUSTE';
      case OperacaoCaixaTipo.estorno:
        return 'ESTORNO';
      case OperacaoCaixaTipo.recebimentoAvulso:
        return 'RECEBIMENTO_AVULSO';
      case OperacaoCaixaTipo.pagamentoAvulso:
        return 'PAGAMENTO_AVULSO';
    }
  }
}


enum NaturezaMovimento {
  entrada,
  saida,
}

enum NaturezaRecebimento {
  imediato,
  futuro,
}

enum StatusMovimento {
  aberta,
  concluida,
  cancelada,
  pendenteConferencia,
}

enum StatusSessaoCaixa {
  aberta,
  fechada,
}

class _AtalhoOperacaoData {
  final OperacaoCaixaTipo tipo;
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;

  _AtalhoOperacaoData({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
  });
}
